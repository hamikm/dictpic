const expect = require('chai').expect;

const makeOneLine = require('../lib/util').multiToSingleLine;

const getTemplatesFromWikitext = require('../wikipedia/wikitext').getTemplatesFromWikitext;
const getEmptyTemplateNameToListOfTemplateStringsMap =
    require('../wikipedia/wikitext').getEmptyTemplateNameToListOfTemplateStringsMap;

describe('getTemplatesFromWikitext()', function () {
    it('should extract all templates from wikitext', function () {

        const testerTemplateNameToRegex = {
            'Template:empty': /^\{\}/,
            'Template:a': /^\{a/i,
            'Template:b': /^\{b/i,
        };
        const wikitextToRet = {
            '{}': {
                'Template:empty': ['{}'],
                'Template:a': [],
                'Template:b': [],
            },
            'a{}': {
                'Template:empty': ['{}'],
                'Template:a': [],
                'Template:b': [],
            },
            '{a}': {
                'Template:empty': [],
                'Template:a': ['{a}'],
                'Template:b': [],
            },
            '{}a': {
                'Template:empty': ['{}'],
                'Template:a': [],
                'Template:b': [],
            },
            'a{b}c': {
                'Template:empty': [],
                'Template:a': [],
                'Template:b': ['{b}'],
            },
            '{b{}}': {
                'Template:empty': [],
                'Template:a': [],
                'Template:b': ['{b{}}'],
            },
            '}{': {
                'Template:empty': [],
                'Template:a': [],
                'Template:b': [],
            },
            'a}b{c': {
                'Template:empty': [],
                'Template:a': [],
                'Template:b': [],
            },
            '{a}}{': {
                'Template:empty': [],
                'Template:a': ['{a}'],
                'Template:b': [],
            },
            '}{{a}': {
                'Template:empty': [],
                'Template:a': ['{a}'],
                'Template:b': [],
            },
            '{}}': {
                'Template:empty': ['{}'],
                'Template:a': [],
                'Template:b': [],
            },
            '{}{': {
                'Template:empty': ['{}'],
                'Template:a': [],
                'Template:b': [],
            },  // cloudwatch output --> Malformed wikitext?
            '{{}': {
                'Template:empty': [],
                'Template:a': [],
                'Template:b': [],
            },  // cloudwatch output --> Malformed wikitext?
            '}{}': {
                'Template:empty': [],
                'Template:a': [],
                'Template:b': [],
            },
            'a{b}c{a}e': {
                'Template:empty': [],
                'Template:a': ['{a}'],
                'Template:b': ['{b}'],
            },
            'a{b}c{a{b}c}e': {
                'Template:empty': [],
                'Template:a': ['{a{b}c}'],
                'Template:b': ['{b}'],
            },
        };

        Object.keys(wikitextToRet).forEach(wikitext => {
            const expectedRet = wikitextToRet[wikitext];
            const ret = getEmptyTemplateNameToListOfTemplateStringsMap(
                testerTemplateNameToRegex);
            getTemplatesFromWikitext(ret, wikitext, testerTemplateNameToRegex);
            expect(JSON.stringify(ret)).to.be.equal(JSON.stringify(expectedRet));
        });

        const vodkaWikitext = makeOneLine('{{redirect|Wodka|other uses|Wódka \
            (disambiguation){{!}}Wódka|and|Vodka (disambiguation)}}{{For|\
            homemade vodkas and distilled beverages referred to as \
            "moonshine"|moonshine|Moonshine by country}}');
        const vodkaTemplates = {
            'Template:About': [],
            'Template:Redirect': [makeOneLine('{{redirect|Wodka|other uses|\
                Wódka (disambiguation){{!}}Wódka|and|Vodka \
                (disambiguation)}}')],
            'Template:Other uses': [],
            'Template:For': [makeOneLine('{{For|homemade vodkas and \
                distilled beverages referred to as "moonshine"|moonshine|\
                Moonshine by country}}')],
        };

        const ret = getEmptyTemplateNameToListOfTemplateStringsMap();
        getTemplatesFromWikitext(ret, vodkaWikitext);
        expect(JSON.stringify(ret)).to.be.equal(JSON.stringify(vodkaTemplates));
    });
});
