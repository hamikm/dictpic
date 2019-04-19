const axios = require('axios');
const resp = require('../lib/responseHelpers');

const util = require('../lib/util');

const axiosInstance = axios.create({
    baseURL: process.env.TRANSLATION_LANGUAGES_API_URL,
    headers: {},
    timeout: 5000,
});

// Get all target languages available for the given source language
const getAvailableLangs = async source => {
    try {
        const resp = await axiosInstance.get('', {
            params: {
                target: source,
                key: process.env.GOOGLE_TRANSLATE_API_KEY,
            },
        });

        if (resp && resp.data && resp.data.data && resp.data.data.languages
                && resp.data.data.languages.length > 0) {
            const rtn = {};
            resp.data.data.languages.forEach(nameCodePair => {
                rtn[nameCodePair.name] = {
                    'basic': nameCodePair.language,
                };
            });
            return rtn;
        } else {
            util.cloudwatchLog('Did not get Google Translate response');
            return [];
        }
    } catch (err) {
        util.cloudwatchLog(`Error getting Google translate langs! ${err}`);
        return [];
    }
};

exports.main = async (event, context, callback) => {
    const body = JSON.parse(event.body);
    const source = body.sourceLang;

    return callback(null, resp.success(
        { targetLangs: await getAvailableLangs(source) }
    ));
};
