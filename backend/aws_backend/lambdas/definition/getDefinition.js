const axios = require('axios');

const request = require('request-promise-native');
const mapper = require('./oedToModelMapper').mapper;
const getLemmas = require('./oedToModelMapper').getLemmas;
const getWordsFromSearch = require('./oedToModelMapper').getWordsFromSearch;
const resp = require('../lib/responseHelpers');
const util = require('../lib/util');

const getOedDefinition = async (entry, lang, region, abortEarly = false) => {
    const headers = {
        app_id: process.env.OED_APP_ID.trim(),
        app_key: process.env.OED_API_KEY.trim(),
    };

    // Do a straightforward lookup
    try {
        var relativePath = `/entries/${lang}/${entry}`;
        relativePath += (region ? `/regions=${region}` : '');
        const url = process.env.OED_API_BASE_URL + relativePath;
        const resp = await request(url, {
            json: true,
            headers,
        });

        var resultsArr = resp.results || [];
        var firstEntry = resultsArr.length > 0 ? resultsArr[0] : null;
        if (firstEntry) {
            const definitionModel = mapper(firstEntry);
            if (definitionModel) {
                return {
                    definition: true,
                    contents: definitionModel.toHtml(),
                };
            } else {
                util.cloudwatchLog('Mapper failed');
            }
        } else {
            throw new Error('Definition results array empty');
        }
    // There was a problem. It was probably weird inflection, so use lemmatron
    } catch (definitionErr) {
        util.cloudwatchLog(`Error getting oed def! ${definitionErr}`);

        // Avoid infinite recursion
        if (abortEarly) {
            util.cloudwatchLog('Probably second try, so aborting');
            return null;
        }

        // If the error was a 404 not found, the word might be a plural
        // or weird inflection. Use lemmatron to find the the root word
        try {
            const lemmatronPath = `/inflections/${lang}/${entry}`;
            const lemmatronUrl = process.env.OED_API_BASE_URL + lemmatronPath;
            const lemmatronResp = await request(lemmatronUrl, {
                json: true,
                headers,
            });

            resultsArr = lemmatronResp.results || [];
            firstEntry = resultsArr.length > 0 ? resultsArr[0] : null;
            if (firstEntry) {
                const lemmas = getLemmas(firstEntry);

                // If there's just one, get the definition and peace out.
                // Otherwise, let the user disambiguate
                if (!lemmas || lemmas.count() === 0) {
                    throw new Error('Lemma array empty');
                } else if (lemmas.count() === 1) {
                    return getOedDefinition(lemmas.words[0], lang, region, true);
                } else {
                    return {
                        suggestions: true,
                        contents: lemmas.toHtml(),
                    };
                }
            } else {
                throw new Error('Lemma results array empty');
            }
        // There was still a problem, so do a fuzzy search for other words
        // and suggest them to the caller
        } catch (lemmatronError) {
            util.cloudwatchLog(`Error finding lemma! ${lemmatronError}`);

            // If there was still 404 not found, word is probably misspelled.
            // Search for the nearest words and return top three so user can
            // disambiguate
            try {
                const limit = process.env.SEARCH_LIMIT;
                var searchPath =
                    `/search/${lang}?q=${entry}&prefix=false&limit=${limit}`;
                searchPath += (region ? `&regions=${region}`: '');
                const searchUrl = process.env.OED_API_BASE_URL + searchPath;
                const searchResp = await request(searchUrl, {
                    json: true,
                    headers,
                });
                const suggestions = getWordsFromSearch(searchResp.results);
                const words = suggestions.words;

                // Use only the words that actually have an entry. Some of
                // the suggestions, like "you are welcome," don't have one
                const wordsWithEntries = [];
                const existsList = await axios.all(words.map(async (word) => {
                    try {
                        var relPath = `/entries/${lang}/${word}`;
                        relPath += (region ? `/regions=${region}` : '');
                        const absUrl = process.env.OED_API_BASE_URL + relPath;
                        const response = await request(absUrl,
                            { json: true, headers });
                        var resArr = response.results || [];
                        var entry1 = resArr.length > 0 ? resArr[0] : null;
                        if (entry1) { return true; }
                        else { return false; }
                    } catch (err) { return false; }
                }));
                for (var i = 0; i < existsList.length; i++) {
                    if (existsList[i]) {
                        wordsWithEntries.push(words[i]);
                    }
                }
                suggestions.words = wordsWithEntries;

                return {
                    suggestions: true,
                    contents: suggestions.toHtml(),
                };
            } catch (searchErr){
                util.cloudwatchLog(`Search error! ${searchErr}`);
            };
        }
    }
    return null;
};

exports.main = async (event) => {
    const body = JSON.parse(event.body);
    const entry = body.entry;
    const lang = body.lang;
    const region = body.region;

    var response;
    try {
        response = await getOedDefinition(entry, lang, region);
    } catch (err) {
        util.cloudwatchLog(`--> Error getting definition: ${err}`);
        return resp.serverFailure({});
    }
    if (response && response.definition) {
        return resp.success({ htmlDefinition: response.contents });
    } else if (response && response.suggestions) {
        return resp.success({ htmlSuggestions: response.contents });
    } else {
        util.cloudwatchLog('Unexpected');
        return resp.serverFailure({});
    }
};
