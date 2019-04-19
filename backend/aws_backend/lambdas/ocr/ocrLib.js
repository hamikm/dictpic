const axios = require('axios');

const util = require('../lib/util');

// Call Google images.annotate endpoint. Return all individual words in the
// response. First element of textAnnotations array might be a phrase
// containing all words
const getGoogleOcrResults = async imageBase64 => {

    const axiosInstanceGoogle = axios.create({
        baseURL: process.env.GOOGLE_OCR_API_URL.replace(
            process.env.API_KEY_TEMPLATE_CODE, process.env.GOOGLE_OCR_API_KEY),
        headers: {},
        timeout: 5000,
    });

    try {
        const resp = await axiosInstanceGoogle.post('', {
            requests: [{
                image: {
                    content: imageBase64,
                },
                features: [{
                    type: 'TEXT_DETECTION',
                }],
            }],
        });

        const containsResponse = resp.data && resp.data.responses
            && resp.data.responses.length > 0
            && resp.data.responses[0].textAnnotations;
        if (containsResponse) {
            const phraseIdx = 0;
            const response = resp.data.responses[0];
            const annotations = response.textAnnotations;
            const rtn = {
                textAnnotations: annotations,
                skipIdx: -1,
            };
            if (isProbablyPhraseAt(phraseIdx, annotations)) {
                rtn.splitIdx = phraseIdx;
            }
            return rtn;
        } else {
            util.cloudwatchLog('Did not get any responses');
            return null;
        }
    } catch (err) {
        util.cloudwatchLog(`Error performing OCR! ${err}`);
        return null;
    }
};

// Return the centroid of the given polygon, which is assumed to be convex.
// Pts looks like [ { x: 45, y: 43 }, ... ]
const centroidOfConvexPolygon = pts => {
    if (pts.length === 0) {
        return null;
    }
    var totX = 0, totY = 0;
    for (var i = 0; i < pts.length; i++) {
        const pt = pts[i];
        totX += pt.x;
        totY += pt.y;
    }
    return { x: totX / pts.length, y: totY / pts.length };
};

const dist = (p1, p2) => {
    return Math.sqrt(
        (p2.x - p1.x) * (p2.x - p1.x) + (p2.y - p1.y) * (p2.y - p1.y));
};

const annotationsWithoutPhrase = textAnnotations => {
    const rtn = [];
    if (!textAnnotations || textAnnotations.length === 0) {
        util.cloudwatchLog('No elements in text annotations');
        return rtn;
    }
    var phraseIdx = 0;
    for (var idx = 0; idx < textAnnotations.length; idx++) {
        if (isProbablyPhraseAt(idx, textAnnotations)) {
            phraseIdx = idx;
            break;
        }
    }
    return textAnnotations.slice(0, phraseIdx).concat(
        textAnnotations.slice(phraseIdx + 1));
};

// Checks if the text annotation at the given index is probably a phrase
const isProbablyPhraseAt = (idx, textAnnotations) => {
    if (!textAnnotations || textAnnotations.length === 0) {
        util.cloudwatchLog('No elements in text annotations');
        return null;
    }
    if (idx < 0 || idx >= textAnnotations.length) {
        util.cloudwatchLog('Idx into text annotations list is bad');
        return null;
    }

    let phraseCandidate = textAnnotations[idx].description;
    var isLongerThanAllOthers = true;
    var containsAllOthers = true;
    for (var i = 0; i < textAnnotations.length; i++) {
        if (i === idx) {
            continue;
        }
        const currWord = textAnnotations[i].description;
        const currWordLen = currWord.length || 0;
        // Contains this
        if (phraseCandidate.indexOf(currWord) === -1) {
            containsAllOthers = false;
            break;
        }
        // Longer than
        if (phraseCandidate.length <= currWordLen) {
            isLongerThanAllOthers = false;
            break;
        }
    }
    return isLongerThanAllOthers && containsAllOthers;
}

// Iterate over all words in the response, choosing the one with a
// bounding box with centroid nearest the given point. skipIdx is
// intended to be the index of the phrase in the textAnnotations list
const getWordClosestTo = (textAnnotations, tapLocation, skipIdx = -1) => {
    var closest = {
        word: '',
        polygon: [],
        distanceFromTap: Number.MAX_SAFE_INTEGER,
    };
    for (var i = 0; i < textAnnotations.length; i++) {
        if (i === skipIdx) {
            continue;
        }
        const textAnnotation = textAnnotations[i];
        const word = textAnnotation.description;
        if (!word || word.length === 0) {
            util.cloudwatchLog('No word');
            continue;
        }
        const polygon = textAnnotation.boundingPoly
            && textAnnotation.boundingPoly.vertices;
        if (!polygon || polygon.length < 3) {
            util.cloudwatchLog('Word did not have a bounding polygon');
            continue;
        }

        const centroid = centroidOfConvexPolygon(polygon);
        const currDistanceFromTap = dist(tapLocation, centroid);
        if (currDistanceFromTap < closest.distanceFromTap) {
            closest.word = word;
            closest.polygon = polygon;
            closest.distanceFromTap = currDistanceFromTap;
        }
    }
    return closest;
};

exports.getGoogleOcrResults = getGoogleOcrResults;
exports.centroidOfConvexPolygon = centroidOfConvexPolygon;
exports.isProbablyPhraseAt = isProbablyPhraseAt;
exports.getWordClosestTo = getWordClosestTo;
exports.annotationsWithoutPhrase = annotationsWithoutPhrase;
