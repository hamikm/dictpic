const util = require('../lib/util');

// If an article contains one of these templates, it should be expanded and
// returned with the intro HTML. Key is template name in wikitext (e.g.
// 'Template:About'), and value is regex that lets us match strings in a
// list of templates
const TEMPLATES_TO_EXPAND = {
    'Template:About': /^\{\{about/i,
    'Template:Redirect': /^\{\{redir/i,
    'Template:Other uses': /^\{\{other uses/i,
    'Template:For': /^\{\{for/i,
};

// Wikitext has a bunch of templates that look like {{stuff}}. This function
// finds them and sets them in the template name --> template string map
// named 'rtn'
const getTemplatesFromWikitext = (rtn, wikitext, templateNameToRegex=TEMPLATES_TO_EXPAND) => {
    if (!wikitext) {
        return;
    }

    // Consider     'abc{{}}def{{abc{{abc}}}}'
    // Idx           012345678901234567890123
    // Want starts:     x      x
    // Want ends:          x                x
    // I.e., [3, 10] and [6, 23]
    const indicesOfStarts = [];
    const indicesOfEnds = [];
    var nesting = 0;
    for (var i = 0; i < wikitext.length; i++) {
        const currChar = wikitext[i];
        if (currChar === '{') {
            if (nesting === 0) {
                indicesOfStarts.push(i);
            }
            nesting++;
        }
        if (currChar === '}') {
            nesting--;
            if (nesting === 0) {
                indicesOfEnds.push(i);
            }
        }
    }
    
    // If braces are mismatched, log it but return as many templates as possible.
    // We do regex matching later, so a bad template isn't going to make it in
    if (indicesOfStarts.length !== indicesOfEnds.length) {
        util.cloudwatchLog('--> Malformed wikitext?', wikitext);
    }

    for (var i = 0; i < Math.min(indicesOfStarts.length, indicesOfEnds.length); i++) {
        const startIdx = indicesOfStarts[i];
        const endIdx = indicesOfEnds[i];
        if (endIdx <= startIdx) {
            util.cloudwatchLog('--> Malformed template.', wikitext.substring(endIdx, startIdx + 1));
            continue;
        }

        // If the current template matches, include it
        const currTemplateStr = wikitext.substring(startIdx, endIdx + 1);
        Object.keys(templateNameToRegex).forEach(templateName => {
            const templateRegex = templateNameToRegex[templateName];
            if (templateRegex.test(currTemplateStr)) {
                rtn[templateName].push(currTemplateStr);
            }
        });
    }
};

const getEmptyTemplateNameToListOfTemplateStringsMap = (templateNameToRegex=TEMPLATES_TO_EXPAND) => {
    const ret = {};
    Object.keys(templateNameToRegex).forEach(key => { ret[key] = [] });
    return ret;
};

exports.getTemplatesFromWikitext = getTemplatesFromWikitext;
exports.getEmptyTemplateNameToListOfTemplateStringsMap =
    getEmptyTemplateNameToListOfTemplateStringsMap;
