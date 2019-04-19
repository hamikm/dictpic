'use strict';

const glog = require('../lib/util').stackdriverLog;

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

// Checks if the text annotation at the given index is probably a phrase
const isProbablyPhrase = (idx, textAnnotations) => {
    if (textAnnotations.length === 0) {
        glog('No elements in text annotations');
        return null;
    }
    if (idx < 0 || idx >= textAnnotations.length) {
        glog('Idx into text annotations list is bad');
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
            glog('No word');
            continue;
        }
        const polygon = textAnnotation.boundingPoly
            && textAnnotation.boundingPoly.vertices;
        if (!polygon || polygon.length < 3) {
            glog('Word did not have a bounding polygon');
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

exports.centroidOfConvexPolygon = centroidOfConvexPolygon;
exports.isProbablyPhrase = isProbablyPhrase;
exports.getWordClosestTo = getWordClosestTo;
