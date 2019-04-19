const resp = require('../lib/responseHelpers');

const util = require('../lib/util.js');
const ocrLib = require('./ocrLib');

// Returns the word closest to the tap location
exports.main = async (event, context, callback) => {
    const body = JSON.parse(event.body);
    const imageBase64 = body.image;
    const x = body.tapX;
    const y = body.tapY;
    // TODO: get the language?

    // Call the API then get the recognized word closest to the tap
    const res = await ocrLib.getGoogleOcrResults(imageBase64);
    if (!res || !res.textAnnotations || res.textAnnotations.length === 0) {
        return callback(null, resp.success({ word: '' }));
    } else {
        const closest = ocrLib.getWordClosestTo(
            res.textAnnotations, { x, y }, res.splitIdx);
        if (closest && closest.word) {
            util.cloudwatchLog(`Resolved word ${closest.word}`);
            return callback(null, resp.success({ word: closest.word }));
        } else {
            util.cloudwatchLog('Could not resolve a word');
            return callback(null, resp.success({ word: '' }));
        }        
    }
};
