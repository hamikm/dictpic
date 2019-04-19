'use strict';

// const axios = require('axios');
const vision = require('@google-cloud/vision');

const glog = require('../lib/util').stackdriverLog;
const errorResponse = require('../lib/util').errorResponse;
const isPhrase = require('./resultsProcessor').isProbablyPhrase;
const closestWord = require('./resultsProcessor').getWordClosestTo;

const client = new vision.ImageAnnotatorClient();

// Call Google images.annotate endpoint. Return all individual words in the
// response. First element of textAnnotations array might be a phrase
// containing all words
const getOcrResults = async imageBase64 => {
    vision.v1.f
    const request = {
        image: { content: imageBase64 },
        features: [{ type: 'TEXT_DETECTION' }],
    };
    try {
        const resp = await client.annotateImage(request);

        if (resp.length > 0) {
            const phraseIdx = 0;
            const annotations = resp[0].textAnnotations;
            const rtn = {
                textAnnotations: annotations,
                skipIdx: -1,
            };
            if (isPhrase(phraseIdx, annotations)) {
                rtn.splitIdx = phraseIdx;
            }
            return rtn;
        } else {
            glog('Did not get any responses');
            return null;
        }
    } catch (err) {
        glog(`--> error performing ocr! ${err}`);
        return null;
    }
};

exports.main = async (request, response) => {
    const body = request.body;
    const imageBase64 = body.image;
    const x = body.tapX;
    const y = body.tapY;

    const res = await getOcrResults(imageBase64);

    if (!res || !res.textAnnotations || res.textAnnotations.length === 0) {
        errorResponse(response, 'No text annotations returned');
    } else {
        const closest = closestWord(res.textAnnotations, { x, y }, res.splitIdx);
        if (closest && closest.word) {
            glog('Resolved word', closest.word);
            response.status(200).send({ word: closest.word });
        } else {
            errorResponse(response, 'Could not resolve a word');
        }
    }
};
