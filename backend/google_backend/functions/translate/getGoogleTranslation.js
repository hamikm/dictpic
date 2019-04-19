const axios = require('axios');
const resp = require('../lib/responseHelpers');
const util = require('../lib/util.js');

// const axiosInstance = axios.create({
//     baseURL: process.env.TRANSLATION_API_URL,
//     headers: {
//     },
//     timeout: 1000,
// });

// const getTranslation = async (sourceWord, sourceLanguage, targetLanguage) => {
//     try {
//         const response = await axiosInstance.get('', {
//             params: {
//                 q: sourceWord,
//                 source: sourceLanguage,
//                 target: targetLanguage,
//                 format: 'text',
//                 key: process.env.GOOGLE_TRANSLATE_API_KEY,
//             },
//         });
//         return response;
//     } catch (err) {
//         util.cloudwatchLog('--> error! ${err}');
//         return null;
//     }
// };

exports.main = async (event, context, callback) => {
    // const body = JSON.parse(event.body);
    // const sourceWord = body.source;
    // let response = await getTranslation(sourceWord);

    // if (!response) {
    //     return callback(resp.serverFailure);
    // }

    return callback(null, resp.success("ok"));
};
