const utf8 = require('utf8');

const apiMeter = require('./lib/apiMeter');
const resp = require('./lib/responseHelpers');
const util = require('./lib/util');

const definitionFunc = require('./definition/getDefinition').main;
const wikiIntroFunc = require('./wikipedia/getIntro').main;
const translationFunc = require('./translation/getGoogleTranslation').main;

const getDefinition = async (doCall, entry, lang, region) => {
    if (!doCall) {
        return null;
    }
    const body = {
        entry,
        lang,
        region,
    };

    var resp;
    try {
        resp = await definitionFunc({ body: JSON.stringify(body) });
    } catch (err) {
        util.cloudwatchLog(`--> Error getting definition: ${err}`);
        return null;
    }
    return resp.body;
};

const getWikipediaIntro = async (doCall, lang, article) => {
    if (!doCall) {
        return null;
    }
    const body = {
        lang,
        article,
    };

    var resp;
    try {
        resp = await wikiIntroFunc({ body: JSON.stringify(body) });
    } catch (err) {
        util.cloudwatchLog(`--> Error getting wiki intro: ${err}`);
        return null; 
    }
    return resp.body;
};

const getTranslation = async (doCall, phrase, sourceLang, targetLang) => {
    if (!doCall) {
        return null;
    }
    const body = {
        phrase,
        sourceLang,
        targetLang,
    };
    
    var resp;
    try {
        resp = await translationFunc({ body: JSON.stringify(body) });
    } catch (err) {
        util.cloudwatchLog(`--> Error getting translation: ${err}`);
        return null; 
    }
    return resp.body;
};

const generateDeviceCheckArgs = () => {

    const meterTableName = process.env.SEARCH_COUNTS_TABLE;
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
        h: Number(process.env.GLOBAL_SEARCH_THRESHOLD_HR),
        d: Number(process.env.GLOBAL_SEARCH_THRESHOLD_DAY),
        w: Number(process.env.GLOBAL_SEARCH_THRESHOLD_WEEK),
        m: Number(process.env.GLOBAL_SEARCH_THRESHOLD_MONTH),
        y: Number(process.env.GLOBAL_SEARCH_THRESHOLD_YEAR),
    };
    const freeThresholds = {
        h: Number(process.env.FREE_SEARCH_THRESHOLD_HR),
        d: Number(process.env.FREE_SEARCH_THRESHOLD_DAY),
        w: Number(process.env.FREE_SEARCH_THRESHOLD_WEEK),
        m: Number(process.env.FREE_SEARCH_THRESHOLD_MONTH),
        y: Number(process.env.FREE_SEARCH_THRESHOLD_YEAR),
    };
    const maxDevicesPerICloudUser =
        Number(process.env.MAX_DEVICES_PER_ICLOUD_USER);

    return [meterTableName, iCloudUsersTableName, cert, keyId, teamId,
        deviceCheckHost, globalThresholds, freeThresholds, reqHashLength,
        maxDevicesPerICloudUser];
};

// Returns the definition, wikipedia article intro, and translation
// for the given search text
exports.main = async (event, context, callback) => {

    // Handle inputs
    const body = JSON.parse(event.body);
    const searchText = body.searchText;
    const definitionLanguageCode = body.definitionLanguageCode;
    const wikipediaLanguageCode = body.wikipediaLanguageCode;
    const languageRegion = body.languageRegion;
    const sourceLanguage = body.sourceLanguage;
    const targetLanguage = body.targetLanguage;
    const iCloudUserNameHash = body.iCloudUserNameHash;
    const deviceCheckToken = body.deviceCheckToken;
    const userPrefsToken = body.t;
    const endpoints = body.endpoints;

    // Response helper
    const errBody = (reason, errMsg) => ({
        searchSuccess: false,
        failureReason: { reason, qualifiers: { error: errMsg } },
    });

    // Make sure at least one definition type was requested
    if (!endpoints || endpoints.length === 0) {
        const msg = 'No endpoints specified.';
        util.cloudwatchLog(`--> ${msg}`);
        return callback(null, resp.badRequest(errBody('noEndpoints', msg)));
    }

    // Check if device is allowed to use API before searching
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
        const msg = `Error seeing if search is allowed: ${err}`;
        util.cloudwatchLog(`--> ${msg}`);
        return callback(null, resp.serverFailure(errBody('unknown', msg)));
    }

    if (isAllowed) {
        try {
            const [definition, wikipediaIntroduction, translation] =
                await Promise.all([
                    getDefinition(endpoints.includes('definition'),
                        searchText, definitionLanguageCode, languageRegion),
                    getWikipediaIntro(endpoints.includes('wikipediaIntro'),
                        wikipediaLanguageCode, searchText),
                    getTranslation(endpoints.includes('translation'),
                        searchText, sourceLanguage, targetLanguage),
                ]);
            const rtnBody = {
                definition,
                wikipediaIntroduction,
                translation,
                searchSuccess: true,
            };
            if (util.exists(newUserPrefsToken)) {
                rtnBody.t = newUserPrefsToken;
            }
            return callback(null, resp.success(rtnBody));
        } catch (err) {
            const msg = `Error doing at least one search: ${err}`;
            util.cloudwatchLog(`--> ${msg}`);
            return callback(null, resp.serverFailure(errBody('unknown', msg)));
        }
    } else {
        return callback(null, resp.badRequest({
            searchSuccess: false,
            failureReason: reasonIsNotAllowed,
        }));
    }
};
