const util = require('../lib/util');
const model = '../definition/definitionModel';
const BubbleUpProperties = require(model).BubbleUpProperties;
const DefinitionModel = require(model).DefinitionModel;
const Homograph = require(model).Homograph;
const LexicalEntry = require(model).LexicalEntry;
const Definition = require(model).Definition;
const SubDefinition = require(model).SubDefinition;
const SuggestionsModel = require(model).SuggestionsModel;
const bubbleUpAll = require(model).bubbleUpAll;
const MISSING_HOMOGRAPH_MARKER = require(model).MISSING_HOMOGRAPH_MARKER;

// TODO support multiple pronunciations. Right now just taking the first
const generateBubbleUpProps = (member) => {
    var currPron = null;
    var currPronUrl = null;
    if (member.pronunciations && member.pronunciations.length > 0) {
        if (member.pronunciations[0].phoneticSpelling) {
            currPron = `/${member.pronunciations[0].phoneticSpelling}/`;
        }
        currPronUrl = member.pronunciations[0].audioFile || null;
    }
    var register = null;
    if (member.registers && member.registers.length > 0) {
        register = member.registers[0];
    }
    return new BubbleUpProperties(currPron, currPronUrl, register);
};

const errString = (n, c, t) => {
    return `${n}, ${c}, ${JSON.stringify(t)}`;
}

const mapper = result => {
    const headwordEntry = result;

    // Initialize definition model (homographs added below)
    const dm = new DefinitionModel(headwordEntry.word, []);

    // Iterate over lexical entities (e.g., noun, verb)
    const lexs = headwordEntry.lexicalEntries;
    for (var i = 0; i < lexs.length; i++) {
        const lex = lexs[i];
        const currLexCategory = lex.lexicalCategory.toLowerCase();
        const lexBubbleUps = generateBubbleUpProps(lex);

        // Iterate over entries, which contain homograph groups
        for (var j = 0; j < lex.entries.length; j++) {
            const entry = lex.entries[j];
            var homographNumber = entry.homographNumber;
            const homograph = dm.getHomographFromNumber(homographNumber);
            const homographBubbleUps = generateBubbleUpProps(entry);
            const currLexicalEntry = new LexicalEntry(
                currLexCategory, [], lexBubbleUps);

            const errMsgInfo = errString(
                homographNumber, currLexCategory, headwordEntry.word);

            // If we haven't seen this homograph, create it
            if (!homograph) {
                // If a homograph number isn't present, use imaginary number
                if (!homographNumber) {
                    homographNumber = MISSING_HOMOGRAPH_MARKER;
                }
                const homograph = new Homograph(
                    [currLexicalEntry], homographBubbleUps);
                dm.addHomograph(homograph, homographNumber);
            // If the current lexical entry is different from all, add it in
            } else if (!homograph.containsLex(currLexicalEntry)) {
                homograph.lexicalEntries.push(currLexicalEntry);
            } else {  // Unexpected OED API behavior. Log info
                util.cloudwatchLog(`Error: extra homographs. ${errMsgInfo}`);
            }

            // Now that homographs and lexical entries are handled,
            // add in definitions and subdefinitions
            const senses = entry.senses;
            for (var k = 0; k < (senses ? entry.senses.length : 0); k++) {
                const sense = entry.senses[k];
                // definition, example, subDefinitions, bubbleUpProperties

                // A definition is required, so skip if no definition
                if (!sense.definitions || sense.definitions.length === 0) {
                    const msg = `Warning: Maybe xref? ${errMsgInfo}`;
                    util.cloudwatchLog(util.multiToSingleLine(msg));
                    continue;
                }
                const def = sense.definitions[0];

                // TODO support more examples?
                var example = null;
                if (sense.examples && sense.examples.length > 0
                        && sense.examples[0].text) {
                    example = sense.examples[0].text;
                }
                
                const defBubbleUps = generateBubbleUpProps(sense);

                const definition = new Definition(
                    def, example, [], defBubbleUps);
                currLexicalEntry.definitions.push(definition);

                const subs = sense.subsenses;
                for (var l = 0; l < (subs ? subs.length : 0); l++) {
                    const sub = sense.subsenses[l];

                    // A definition is required, so skip if no definition
                    if (!sub.definitions || sub.definitions.length === 0) {
                        util.cloudwatchLog(
                            'Error: no defs! Skipping this subsense');
                        continue;
                    }
                    const subdef = sub.definitions[0];

                    // TODO support more examples?
                    var subexample = null;
                    if (sub.examples && sub.examples.length > 0
                        && sub.examples[0].text) {
                        example = sub.examples[0].text;
                    }

                    const subdefBubbleUps = generateBubbleUpProps(sub);

                    const subdefinition = new SubDefinition(
                        subdef, subexample, subdefBubbleUps);
                    definition.subDefinitions.push(subdefinition);
                }
            }
        }
    }

    bubbleUpAll(dm);
    return dm;
};

// Returns list of unique strings
const getLemmas = result => {
    const lemmas = [];
    for (var i = 0; i < result.lexicalEntries.length; i++) {
        const lexicalEntry = result.lexicalEntries[i];
        for (var j = 0; j < lexicalEntry.inflectionOf.length; j++) {
            const idWordUnit = lexicalEntry.inflectionOf[j];
            const lemma = idWordUnit.text;
            lemmas.push(lemma);
        }
    }
    return new SuggestionsModel(util.listToSet(lemmas));
};

// Returns list of unique strings (uniqueness enforced by API)
// NB, order in list is important: there is higher confidence in earlier words
const getWordsFromSearch = results => {
    const words = [];
    for (var i = 0; i < results.length; i++) {
        const searchResult = results[i];
        words.push(searchResult.word);
    }
    return new SuggestionsModel(words);
};

exports.mapper = mapper;
exports.getLemmas = getLemmas;
exports.getWordsFromSearch = getWordsFromSearch;
