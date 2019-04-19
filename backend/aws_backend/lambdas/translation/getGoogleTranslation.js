const axios = require('axios');

const resp = require('../lib/responseHelpers');
const util = require('../lib/util.js');

const axiosInstance = axios.create({
    baseURL: process.env.TRANSLATION_API_URL,
    headers: {},
    timeout: 5000,
});

const getTranslation = async (phrase, sourceLanguage, targetLanguage) => {
    try {
        const resp = await axiosInstance.get('', {
            params: {
                q: phrase,
                source: sourceLanguage,
                target: targetLanguage,
                format: 'text',
                key: process.env.GOOGLE_TRANSLATE_API_KEY,
            },
        });
        if (resp && resp.data && resp.data.data && resp.data.data.translations
                && resp.data.data.translations.length > 0) {
            return resp.data.data.translations[0].translatedText;
        } else {
            return '';
        }
    } catch (err) {
        util.cloudwatchLog(`--> Unable to translate. ${err}`);
        return '';
    }
};

exports.main = async (event) => {
    const body = JSON.parse(event.body);
    const phrase = body.phrase;
    const source = body.sourceLang;
    const target = body.targetLang;

    var translatedPhrase;
    try {
        translatedPhrase = await getTranslation(phrase, source, target);
    } catch (err) {
        util.cloudwatchLog(`--> Error getting translation ${err}`);
        return resp.serverFailure({});
    }
    if (translatedPhrase) {
        return resp.success({
            translatedPhrase: `<p class="text">${translatedPhrase}</p>`,
        });
    } else {
        return resp.success({ translatedPhrase: '' });
    }
};
