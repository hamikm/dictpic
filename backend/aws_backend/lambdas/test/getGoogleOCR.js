const expect = require('chai').expect;

const centroid = require('../ocr/ocrLib').centroidOfConvexPolygon;
const isPhrase = require('../ocr/ocrLib').isProbablyPhraseAt;
const closestWord = require('../ocr/ocrLib').getWordClosestTo;

const polygonFixture1 = [
    {
        x: 0,
        y: 0,
    },
    {
        x: 3,
        y: 0,
    },
    {
        x: 0,
        y: 3,
    },
];
const centroid1 = {
    x: 1,
    y: 1,
};

const polygonFixture2 = [
    {
        x: 0,
        y: 0,
    },
    {
        x: 10,
        y: 0,
    },
    {
        x: 10,
        y: 10,
    },
    {
        x: 0,
        y: 10,
    },
];
const centroid2 = {
    x: 5,
    y: 5,
};

describe('centroidOfConvexPolygon()', function () {
    it('should get centroid of given convex polygon', function () {

        const computedCentroid1 = JSON.stringify(centroid(polygonFixture1));
        expect(computedCentroid1).to.be.equal(JSON.stringify(centroid1));

        const computedCentroid2 = JSON.stringify(centroid(polygonFixture2));
        expect(computedCentroid2).to.be.equal(JSON.stringify(centroid2));
    });
});

// Let s be a square wholly in the first quadrant of the cartesian plane and
// with a vertex on the origin. Divide s into four quadrants. Each of the 
// words in 'Hi you are nice' appears in one quadrant, in order, starting
// from the upper left
const textAnnotations = [{
    locale: 'en',
    description: 'Hi you\nare nice',
    boundingPoly: {
        vertices: [{
            x: 0,
            y: 0,
        },
        {
            x: 10,
            y: 0,
        },
        {
            x: 10,
            y: 10,
        },
        {
            x: 0,
            y: 10,
        }],
    },
},
{
    description: 'Hi',
    boundingPoly: {
        vertices: [{
            x: 0,
            y: 5,
        },
        {
            x: 5,
            y: 5,
        },
        {
            x: 5,
            y: 10,
        },
        {
            x: 0,
            y: 10,
        }],
    },
},
{
    description: 'you',
    boundingPoly: {
        vertices: [{
            x: 5,
            y: 5,
        },
        {
            x: 10,
            y: 5,
        },
        {
            x: 10,
            y: 10,
        },
        {
            x: 5,
            y: 10,
        }],
    },
},
{
    description: 'are',
    boundingPoly: {
        vertices: [{
            x: 0,
            y: 0,
        },
        {
            x: 5,
            y: 0,
        },
        {
            x: 5,
            y: 5,
        },
        {
            x: 0,
            y: 5,
        }],
    },
},
{
    description: 'nice',
    boundingPoly: {
        vertices: [{
            x: 5,
            y: 0,
        },
        {
            x: 10,
            y: 0,
        },
        {
            x: 10,
            y: 5,
        },
        {
            x: 5,
            y: 5,
        }],
    },
}];

describe('isProbablyPhrase()', function () {
    it('returns true if the given text annotation is a phrase', function () {
        expect(isPhrase(0, textAnnotations)).to.be.equal(true);
        expect(isPhrase(1, textAnnotations)).to.be.equal(false);
    });
});

// Iterate over each point of a square grid of given size with given
// deltas, asserting that word returned is same for each point in the
// grid. startPt is at lower-left of grid
const expectWordReturnedForEachPointInGridIs = (word, startPt, n, delta) => {
    var currX, currY;
    for (var i = 0; i < n; i++) {
        currX = startPt.x + i * delta;
        for (var j = 0; j < n; j++) {
            currY = startPt.y + j * delta;
            resp = closestWord(textAnnotations, { x: currX, y: currY }, 0);
            expect(resp.word).to.be.equal(word);
        }
    }
};

describe('getWordClosestTo()', function () {
    it('should get word closest to a given tap', function () {
        expectWordReturnedForEachPointInGridIs('Hi', { x: 0, y: 5.1 }, 3, 2.5);
        expectWordReturnedForEachPointInGridIs('you', { x: 5.1, y: 5.1 }, 3, 2.5);
        expectWordReturnedForEachPointInGridIs('are', { x: 0, y: -0.1 }, 3, 2.5);
        expectWordReturnedForEachPointInGridIs('nice', { x: 5.1, y: -0.1 }, 3, 2.5);
    });
});
