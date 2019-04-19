// The main purpose of this file is to gate access to paid APIs like the OED
// and Google translate ones. We don't require users to login on the frontend,
// so we rely on Apple Device Check, hashed iCloud user names, and a custom
// token scheme to verify that requests are legitimate.
//
// We use an iCloud user name hash, which has the property of being constant
// across all devices for a given app and user, to key API usage rate tables.
// Rate limits are dynamically configurable in a serverless YAML file and in
// an AWS web dashboard.

const AWS = require('aws-sdk');
const uuidv4 = require('uuid/v4');

const asyncAWS = require('./awsPromiseWrappers');
const deviceCheck = require('./deviceCheck');
const timeUtils = require('./timeIntervals');
const util = require('./util');

// AWS globals
const dynamodb = new AWS.DynamoDB.DocumentClient();


// Validate device with Apple Device Check API
const isValidDevice = async (
    iCloudUserNameHash, cert, keyId, teamId,
    deviceCheckToken, deviceCheckHost) => {

    try {
        await deviceCheck.validateDevice(
            cert, keyId, teamId, deviceCheckToken, deviceCheckHost);
        return true;
    } catch (err) {
        const msg =
            `--> DC validation failed for ${iCloudUserNameHash}: ${err}`;
        util.cloudwatchLog(msg);
        return false;
    }
};

// Validates given device, generates a token, stores it in this user's row,
// then returns it. If anything fails, logs failure and returns null.
const validateGenerateStore = async (
    iCloudUserNameHash, cert, keyId, teamId,
    deviceCheckToken, deviceCheckHost, iCloudUsersTableName, oldTs) => {

    const valid = await isValidDevice(iCloudUserNameHash, cert, keyId, teamId,
        deviceCheckToken, deviceCheckHost);
    if (!valid) {
        return null;
    }

    // Store iCloud user name and generated token
    const newUserPrefsToken = uuidv4();
    oldTs.push(newUserPrefsToken);
    const putParamsUserNamesTable = {
        Item: {
            u: iCloudUserNameHash,
            t: oldTs,
        },
        TableName: iCloudUsersTableName,
    };
    try {
        await asyncAWS.invokeDynamoDBPut(dynamodb, putParamsUserNamesTable);
        return newUserPrefsToken;
    } catch (err) {
        const msg =
            `--> Couldn't set row for user ${iCloudUserNameHash}: ${err}`;
        util.cloudwatchLog(msg);
        return null;
    }
};

// Return [true, newUserPrefsToken] if this is a valid first request to the
// API from this user and device. If it's a valid later request, just return
// [true, null]. If it's an invalid request, return [false, null].
const isLegitRequest = async (
    deviceCheckToken, iCloudUserNameHash, userPrefsToken, iCloudUsersTableName,
    cert, keyId, teamId, deviceCheckHost, maxDevicesPerICloudUser) => {

    // Response helpers
    const failureResponse = [false, null];
    const successResponse = token => [true, token];

    // Try to get the iCloud user name row
    const getParamsUserNamesTable = {
        TableName: iCloudUsersTableName,
        Key: { u: iCloudUserNameHash },
    };
    var userNameRow;
    try {
        userNameRow = await asyncAWS.invokeDynamoDBGet(
            dynamodb, getParamsUserNamesTable);
    } catch (err) {
        const msg =
            `--> Failed to get row for user ${iCloudUserNameHash}: ${err}`;
        util.cloudwatchLog(msg);
        return failureResponse;
    }

    // If the iCloud user name exists in the table, check if the given token
    // matches with one of the stored ones. If it does, return [true, null].
    // Otherwise check if there aren't too many tokens (i.e., devices) for this
    // user; if so, use Apple Device Check to validate the device then generate
    // a token, store it, and return [true, token]. Else return [false, null].
    if (util.exists(userNameRow)) {
        const oldTs = userNameRow.t;
        if (util.exists(oldTs) && Array.isArray(oldTs)) {

            // If given token matches one of the stores ones
            if (oldTs.includes(userPrefsToken)) {
                return successResponse(null);
            } else {

                // If it doesn't match but user is allowed more devices
                if (oldTs.length < maxDevicesPerICloudUser) {
                    // then validate, generate, store, return
                    const newUserPrefsToken = await validateGenerateStore (
                        iCloudUserNameHash, cert, keyId, teamId,
                        deviceCheckToken, deviceCheckHost,
                        iCloudUsersTableName, oldTs);
                    if (util.exists(newUserPrefsToken)) {
                        return successResponse(newUserPrefsToken);
                    }
                    return failureResponse;
                } else {  // Doesn't match but no more allowed devices
                    const msg =
                        `--> Too many devices for ${iCloudUserNameHash}!`;
                    util.cloudwatchLog(msg);
                    return failureResponse;
                }
            }
        } else {  // fail if row doesn't contain a tokens array
            const msg =
                `--> Row for ${iCloudUserNameHash} missing tokens array!`;
            util.cloudwatchLog(msg);
            return failureResponse;
        }
    }
    
    // If the user name doesn't exist in the table, validate the device before
    // storing a row for the user name with a generated token. Return [true,
    // token] in that case. If validation fails return [false, null].
    else {
        const newUserPrefsToken = await validateGenerateStore (
            iCloudUserNameHash, cert, keyId, teamId,
            deviceCheckToken, deviceCheckHost, iCloudUsersTableName, []);
        if (util.exists(newUserPrefsToken)) {
            return successResponse(newUserPrefsToken);
        }
        return failureResponse;
    }
};

// Return [true, null] if under thresholds of given type. Otherwise return
// [false, { thresholdType: String, level: String, error: Error } ].
// threshold type is 'free' xor 'global'
// level is one of 'h', 'd', 'w', 'm', or 'y'
// error is passed along when DB operations fail, null otherwise
const isUnderThresholds = async (thresholdType, iCloudUserNameHash,
    meterTableName, globalThresholds, freeThresholds) => {

    const failureResponse = (error, level) => {
        return [false, {thresholdType, level, error}];
    };
    const successResponse = [true, null];

    // Get column metadata and thresholds
    const columnMetadata = timeUtils.getColumnMetadata();

    // Get current counts row from DynamoDB
    const getParams = {
        TableName: meterTableName,
        Key: { u: iCloudUserNameHash },
    };
    var countsRow;
    try {
        countsRow = await asyncAWS.invokeDynamoDBGet(dynamodb, getParams);
    } catch (err) {
        const msg =
            `--> Couldn't get counts for user ${iCloudUserNameHash}: ${err}`;
        util.cloudwatchLog(msg);
        return failureResponse(err, null);
    }

    // If we haven't seen this iCloud user yet, initialize his row
    const secsSinceEpoch = (new Date()).getTime() / 1000;
    if (!countsRow) {
        const msg =
            `Initializing row in ${meterTableName} for ${iCloudUserNameHash}`;
        util.cloudwatchLog(`--> ${msg}`);
        countsRow = {
            h: [0, secsSinceEpoch],
            d: [0, secsSinceEpoch],
            w: [0, secsSinceEpoch],
            m: [0, secsSinceEpoch],
            y: [0, secsSinceEpoch],
            a: 0,
            u: iCloudUserNameHash,
        };
    }

    // Now that counts row exists for sure, update it for imminent usage
    const MOD_COLS = ['h', 'd', 'w', 'm', 'y']  // reset to 0 after delta t
    const LIN_COLS = ['a']  // increment by 1 forever
    const SKIP_COLS = ['u'];  // skip iCloud user name hash column
    const keys = Object.keys(countsRow);
    for (var i = 0; i < keys.length; i++) {
        const columnName = keys[i];

        // Increment all-time counter
        if (LIN_COLS.includes(columnName)) {
            countsRow[columnName] = countsRow[columnName] + 1;
        } else if (MOD_COLS.includes(columnName)) {  // incr resettable counter
            const [lastCount, lastAccessTime] = countsRow[columnName];
            const startTime = columnMetadata[columnName][0];
            const deltaTime = columnMetadata[columnName][1];

            // If the old usage count is too high, error out
            const maxCount = (thresholdType === 'free' ?
                freeThresholds[columnName] : globalThresholds[columnName]);
            if (lastCount >= maxCount) {
                return failureResponse(null, columnName);
            }

            // If last access time is between the time this column started
            // and when it ends, increment counter
            const inSameTimeInterval = (lastAccessTime > startTime
                && lastAccessTime < startTime + deltaTime);
            if (inSameTimeInterval) {
                countsRow[columnName] = [lastCount + 1, secsSinceEpoch];
            } else {  // otherwise reset counter
                countsRow[columnName] = [1, secsSinceEpoch];
            }
        } else if (SKIP_COLS.includes(columnName)) {
            // do nothing
        } else {
            util.cloudwatchLog(`--> Unsupported column name ${columnName}`);
        }
    }
    const putParams = {
        Item: countsRow,
        TableName: meterTableName,
    };
    try {
        await asyncAWS.invokeDynamoDBPut(dynamodb, putParams);
    } catch (err) {
        const msg =
            `--> Couldn't set counts for ${iCloudUserNameHash}: ${err}`;
        util.cloudwatchLog(msg);
        return failureResponse(err, null);
    }

    return successResponse;
};

// Return [true, null, userPrefsToken] if API call is allowed. Otherwise
//     [
//         false,
//         {
//             reason: String,
//             qualifiers: { thresholdType: String, level: String },
//         },
//         null,
//     ].
// Values for reason: 'deviceCheckFailure', 'thresholdExceeded',
//     'invalidICloudUserID'
// Qualifiers for 'deviceCheckFailure': none
// Qualifiers for 'invalidICloudUserID': none
// Qualifiers for 'thresholdExceeded':
//     thresholdType: 'free', 'global'
//     level: 'hour', 'day', 'week', 'month', 'year'
const isUsageAllowed = async (
    iCloudUserNameHash, deviceCheckToken, userPrefsToken,
    meterTableName, iCloudUsersTableName, cert, keyId, teamId,
    deviceCheckHost, globalThresholds, freeThresholds, reqHashLength,
    maxDevicesPerICloudUser) => {

    const failureResponse = (reason, qualifiers) => {
        return [false, {reason, qualifiers}, null];
    };
    const successResponse = token => [true, null, token];

    if (process.env.OVERRIDE_DEVICE_CHECK === 'yes') {
        return successResponse('');
    }

    console.log('--> tmp', iCloudUserNameHash, iCloudUserNameHash.length, reqHashLength);

    // If there's no iCloud user name hash, usage not allowed
    if (!iCloudUserNameHash || iCloudUserNameHash.length !== reqHashLength) {
        return failureResponse('invalidICloudUserID', {});
    } else {   // If it's OK, check request came from tapdef & legit iPhone
        const [deviceCheckSucceeded, newUserPrefsToken] =
            await isLegitRequest(deviceCheckToken, iCloudUserNameHash,
                userPrefsToken, iCloudUsersTableName, cert, keyId,
                teamId, deviceCheckHost, maxDevicesPerICloudUser);
        if (deviceCheckSucceeded) {  // If did, verify usage amt < thresholds
            const thresholdType = 'global';  // TODO set based on subscription
            const [underThresholds, thresholdQualifiers] =
                await isUnderThresholds(thresholdType, iCloudUserNameHash,
                    meterTableName, globalThresholds, freeThresholds);
            if (underThresholds) {
                return successResponse(newUserPrefsToken);
            } else {
                return failureResponse(
                    'thresholdExceeded', thresholdQualifiers);
            }
        } else {
            return failureResponse('deviceCheckFailure', {});
        }
    }
};

exports.isUsageAllowed = isUsageAllowed;
