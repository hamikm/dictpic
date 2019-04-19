const axios = require('axios');

const resp = require('../lib/responseHelpers');
const util = require('../lib/util.js');

const getEmptyTemplateNameToListOfTemplateStringsMap =
    require('./wikitext').getEmptyTemplateNameToListOfTemplateStringsMap;
const getTemplatesFromWikitext = require('./wikitext').getTemplatesFromWikitext;

var langCode = 'en';
const axiosInstance = (lang) => {
    const baseURL = process.env.WIKIPEDIA_API_URL.replace(
        process.env.LANG_CODE_TEMPLATE_TOKEN, lang);
    return axios.create({
        baseURL,
        headers: {
            'Api-User-Agent': process.env.USER_AGENT,
        },
        timeout: 1000,
    });
}

const extractQueryPage = (response, field) => {
    if (response.data && response.data.query && response.data.query.pages) {
        const pages = response.data.query.pages;
        const pageids = Object.keys(pages);
        for (var i = 0; i < pageids.length; i++) {
            const pageid = pageids[i];
            // since we only used one title, just need first page
            return {
                pageid,
                data: pages[pageid][field],
            };
        }
    }
    return null;
};

const extractParseText = (response) => {
    const hasParseText = response.data && response.data.parse
        && response.data.parse.text && response.data.parse.text['*'];
    if (hasParseText) {
        return response.data.parse.text['*'];
    }
    return null;
};

const extractNormalizationData = (response) => {
    const hasNormalizationData =
        response.data && response.data.query && response.data.query.normalized;
    if (hasNormalizationData) {
        return response.data.query.normalized;
    }
    return null;
};

// Gets the raw wikitext markup for each template in TEMPLATES_TO_EXPAND.
// E.g. getRawWikitext('turkey')
// returns  {
//   'Template:About': '[{{about|...}}]',
//   'Template:Redirect': '[{{redir|...}}, {{redir|...}}]',
//   ...
// }
const getRawWikitext = async (articleName) => {
    const ret = getEmptyTemplateNameToListOfTemplateStringsMap();

    try {
        const response = await axiosInstance(langCode).get('', {
            params: {
                action: 'query',
                titles: articleName,
                prop: 'revisions',
                rvprop: 'content',
                format: 'json',
                rvlimit: 1,
                redirects: true,
            },
        });

        const extracted = extractQueryPage(response, 'revisions');
        const revisionsList = extracted ? extracted.data : null;
        const hasRevisions =
            revisionsList && revisionsList.length > 0 && revisionsList[0]['*'];
        if (hasRevisions) {
            const wikitext = revisionsList[0]['*'];
            getTemplatesFromWikitext(ret, wikitext);
        }
    } catch (err) {
        util.cloudwatchLog(`Error getting raw wikitext! ${err}`);
    }
    return ret;
};

// Assuming well-formed HTML, remove all comments from given string
const removeComments = str => {
    const COMMENT_START = '<!--';
    const COMMENT_END = '-->';

    var newStr = '';
    var end = -COMMENT_END.length;
    var start = str.indexOf(COMMENT_START, end)
    while (start > -1) {
        newStr += str.substring(end + COMMENT_END.length, start);
        end = str.indexOf(COMMENT_END, start);
        start = str.indexOf(COMMENT_START, end);
    }
    return newStr;
};

// Expands one line of raw wikitext markup into HTML
const singleTemplateToHTML = async (templateText) => {
    const REMOVE_THESE = [/\t/g, /\n/g];

    try {
        const response = await axiosInstance(langCode).get('', {
            params: {
                action: 'parse',
                text: templateText,
                format: 'json',
            },
        });

        const untidyHTML = extractParseText(response);
        if (untidyHTML) {
            var tidierHTML = removeComments(untidyHTML);
            REMOVE_THESE.forEach(regex => {
                tidierHTML = tidierHTML.replace(regex, '');
            });
            return tidierHTML;
        }
    } catch (err) {
        util.cloudwatchLog(`Error converting wikitext to HTML! ${err}`);
    }
    return null;
};

// Expands arrays of raw wikitext markup into HTML.
// E.g. wikitextToHTML({ 'Template:About': '[{{about|stuff}}]', ...})
// returns '<div class=\"mw-parser-output\"><div role=\"note\"  ... </div>'
const wikitextToHTML = async (templateNameToWikitextList) => {    
    const givenTemplates = [];
    Object.keys(templateNameToWikitextList).forEach(key => {
        const wikitextList = templateNameToWikitextList[key];
        wikitextList.forEach(wikitext => {
            givenTemplates.push(wikitext);
        });
    });
    const templateHTMLs =
        await axios.all(givenTemplates.map(singleTemplateToHTML));
    return templateHTMLs.join('<br>');
};

// Gets the introduction of the given article as HTML sans wikitext templates.
// Also gets normalized form of article name.
const getWikiIntroAndNormalization = async (articleName) => {
    try {
        const response = await axiosInstance(langCode).get('', {
            params: {
                action: 'query',
                titles: articleName,
                prop: 'extracts',
                exintro: true,
                format: 'json',
                redirects: true,
            },
        });

        const extracted = extractQueryPage(response, 'extract');
        rtn = {
            pageid: -1,
            intro: '',
            normalization: null,
        };
        if (extracted) {
            if (extracted.pageid !== undefined && extracted.pageid !== null) {
                rtn.pageid = parseInt(extracted.pageid)
            }
            rtn.intro = extracted.data || '';
            rtn.normalization = extractNormalizationData(response);
        }
        return rtn;
    } catch (err) {
        util.cloudwatchLog(`Error getting intro! ${err}`);
        throw err;
    }
};

const searchForCorrectArticleName = async givenName => {
    try {
        const response = await axiosInstance(langCode).get('', {
            params: {
                action: 'query',
                list: 'prefixsearch',
                format: 'json',
                pssearch: givenName,
                pslimit: 3,
            },
        });

        if (response.data.query.prefixsearch.length === 0) {
            util.cloudwatchLog(
                `No results for wiki search of ${givenName}`);
            return null;
        }

        return response.data.query.prefixsearch[0].title;
    } catch (err) {
        util.cloudwatchLog(`Error performing search! ${err}`);
        throw err;
    }
};

// Get the expanded, rendered templates and intro in HTML. Return null if
// error or no result.
const getWikiIntroWithTemplates = async (articleName) => {

    // Search for the correct article name
    try {
        // Get the raw wikitext for each existing template
        articleName = await searchForCorrectArticleName(articleName);
    } catch (err) {
        util.cloudwatchLog(
            `Search for correct article name failed. using given one. ${err}`);
    }

    // Look for presence of interesting templates and expand them into HTML
    var templatesHTMLBlob = '';
    try {
        // Get the raw wikitext for each existing template
        const templateNameToWikitextList = await getRawWikitext(articleName);

        // Expand the wikitext into HTML
        templatesHTMLBlob = await wikitextToHTML(templateNameToWikitextList);
    } catch (err) {
        const errMsg = `Couldn't find/expand templates, but continuing. ${err}`;
        util.cloudwatchLog(errMsg);
    }

    // Get the intro HTML then prepend expanded templates and return
    var rtn = {
        templates: templatesHTMLBlob,
        pageid: -1,
        intro: null,
        normalization: null,
    };
    try {
        const queryResult = await getWikiIntroAndNormalization(articleName);
        rtn.intro = queryResult.intro;
        rtn.normalization = queryResult.normalization;
        rtn.pageid = queryResult.pageid;
    } catch (err) {
        const errMsg = `Returning template str to explain no intro. ${err}`;
        util.cloudwatchLog(errMsg);
    }

    // Sometimes template include "API_..." instead of "<real title>_..."
    // E.g. "...API (disambiguation)</a>" instead of "Turkey_(disambiguation)".
    // Replace them
    var toWord = articleName;
    if (rtn.normalization && rtn.normalization.length > 0) {
        toWord = rtn.normalization[0].to;
    }
    rtn.templates = rtn.templates.replace(/API_/g, toWord + '_');
    rtn.templates = rtn.templates.replace(/API /g, toWord + ' ');

    return rtn;
};

exports.main = async (event) => {
    const body = JSON.parse(event.body);
    langCode = body.lang;
    const article = body.article;

    var wikiIntro;
    try {
        wikiIntro = await getWikiIntroWithTemplates(article);
    } catch (err) {
        util.cloudwatchLog(`--> Error getting wiki intro: ${err}`);
        return resp.serverFailure({});
    }
    if (!wikiIntro) {
        return resp.serverFailure({});
    } else {
        return resp.success(wikiIntro);
    }
};
