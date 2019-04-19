const utf8 = require('utf8');

const apiMeter = require('../lib/apiMeter');
const ocrLib = require('./ocrLib');
const resp = require('../lib/responseHelpers');
const util = require('../lib/util');

const generateDeviceCheckArgs = () => {

    const meterTableName = process.env.OCR_COUNTS_TABLE;
    const iCloudUsersTableName = process.env.ICLOUD_USER_NAMES_TABLE;
    const reqHashLength = Number(process.env.ICLOUD_USER_ID_HASH_LENGTH);

    // Apple Device Check keys
    const cert = utf8.encode([
        process.env.BEGIN_PRIVATE_KEY,
        process.env.APPLE_DEVICE_CHECK_CERT,
        process.env.END_PRIVATE_KEY,
    ].join('\n'));  // utf8 encoding & newlines are necessary for jwt to do job
    const keyId = process.env.APPLE_DEVICE_CHECK_KEY_ID;
    const teamId = process.env.APPLE_ITUNES_CONNECT_TEAM_ID;

    // Pick the correct (dev or prod) Device Check API URL
    var deviceCheckHost;
    if (process.env.STAGE === 'dev') {
        deviceCheckHost = process.env.DEV_DEVICE_CHECK_API_URL;
    } else if (process.env.STAGE === 'prod') {
        deviceCheckHost = process.env.PROD_DEVICE_CHECK_API_URL;
    } else {
        util.cloudwatchLog(`--> Unrecognized stage ${stage}. Aborting DC`);
        return;
    }

    // Generate API usage limits
    const globalThresholds = {
        h: Number(process.env.GLOBAL_OCR_THRESHOLD_HR),
        d: Number(process.env.GLOBAL_OCR_THRESHOLD_DAY),
        w: Number(process.env.GLOBAL_OCR_THRESHOLD_WEEK),
        m: Number(process.env.GLOBAL_OCR_THRESHOLD_MONTH),
        y: Number(process.env.GLOBAL_OCR_THRESHOLD_YEAR),
    };
    const freeThresholds = {
        h: Number(process.env.FREE_OCR_THRESHOLD_HR),
        d: Number(process.env.FREE_OCR_THRESHOLD_DAY),
        w: Number(process.env.FREE_OCR_THRESHOLD_WEEK),
        m: Number(process.env.FREE_OCR_THRESHOLD_MONTH),
        y: Number(process.env.FREE_OCR_THRESHOLD_YEAR),
    };
    const maxDevicesPerICloudUser =
        Number(process.env.MAX_DEVICES_PER_ICLOUD_USER);

    return [meterTableName, iCloudUsersTableName, cert, keyId, teamId,
        deviceCheckHost, globalThresholds, freeThresholds, reqHashLength,
        maxDevicesPerICloudUser];
};

// Returns all words in image along with bounding boxes as in following:
// [
//   {
//     "description": "the word",
//     "boundingPoly": {
//       "vertices": [
//         {
//           "x": 27,
//           "y": 86
//         },
//         ...
//       ]
//     }
//   },
//   ...
// ]
exports.main = async (event, context, callback) => {
    const body = JSON.parse(event.body);
    const imageBase64 = body.image;
    const iCloudUserNameHash = body.iCloudUserNameHash;
    const deviceCheckToken = body.deviceCheckToken;
    const userPrefsToken = body.t;

    // Response helper
    const errBody = (reason, errMsg) => ({
        ocrSuccess: false,
        failureReason: { reason, qualifiers: { error: errMsg } },
    });

    // Check if device is allowed to use API before doing OCR
    var isAllowed;
    var reasonIsNotAllowed;
    var newUserPrefsToken;
    try {
        [isAllowed, reasonIsNotAllowed, newUserPrefsToken] =
            await apiMeter.isUsageAllowed(
                iCloudUserNameHash, deviceCheckToken, userPrefsToken,
                ...generateDeviceCheckArgs()
            );
    } catch (err) {
        const msg = `Error seeing if OCR is allowed: ${err}`;
        util.cloudwatchLog(`--> ${msg}`);
        return callback(null, resp.serverFailure(errBody('unknown', msg)));
    }

    if (isAllowed) {
        try {
            // Call the API and return all words
            const r = await ocrLib.getGoogleOcrResults(imageBase64);
            const rtnBody = { ocrSuccess: true, results: [] };
            if (util.exists(newUserPrefsToken)) {
                rtnBody.t = newUserPrefsToken;
            }
            if (!r || !r.textAnnotations || r.textAnnotations.length === 0) {
                return callback(null, resp.success(rtnBody));
            } else {
                rtnBody.results =
                    ocrLib.annotationsWithoutPhrase(r.textAnnotations);
                return callback(null, resp.success(rtnBody));
            }
        } catch (err) {
            const msg = `Error doing ocr: ${err}`;
            util.cloudwatchLog(`--> ${msg}`);
            return callback(null, resp.serverFailure(errBody('unknown', msg)));
        }
    } else {
        return callback(null, resp.badRequest({
            ocrSuccess: false,
            failureReason: reasonIsNotAllowed,
        }));
    }
};
