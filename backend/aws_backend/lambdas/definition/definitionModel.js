const util = require('../lib/util');

const superscripts = ['⁰', '¹', '²', '³', '⁴', '⁵', '⁶', '⁷', '⁸', '⁹'];
const MISSING_HOMOGRAPH_MARKER = 'x';

// Bubble properties templates
const registerSpan = '<span class="sub-pop">{{register}}</span>';
const pronunciationSpan =
    '<span class="pronunciation">{{pronunciation}}</span>';
const pronunciationAudioLinkSpan =
    '<span class="listen-icon"><a href="{{audio-link}}#audio">🔈</a></span>';
// NB links must have #<enum type> suffix so front-end can perform correct
// action based on link type

// Homograph templates
const homographTitleLine =
'<div>\
<span class="word">{{word}} </span>\
<span class="word-superscript">{{superscript}}</span>\
</div>';
const homographOptionalBubblePropsLine = '<div>{{bubble-props}}</div>';
const homographRequiredLexicalEntriesLines =
    '<br><div>{{lexical-entries}}</div>';

const lexicalCategorySpan =
    '<span class="part-of-speech">{{lexical-category}}</span>';

const definitionsLines =
'<div>\
<ol class="text">\
{{list-of-definitions}}\
</ol>\
</div>';

const definitionSpan = '<span class="definition">{{definition}}</span>';
const exampleSentenceSpan = '<span class="example-sent">{{example}}</span>';
const definitionListElementLines =
'<li>\
{{content}}\
</li>';

const subdefinitionSpan =
    '<span class="subdefinition">{{subdefinition}}</span>';
const subExampleSentenceSpan =
    '<span class="sub-example-sent">{{sub-example}}</span>';
const subdefinitionLines =
'<ul>\
{{list-of-subdefinitions}}\
</ul>';

const suggestionsLines =
'<ul class="text">\
{{list-of-suggestions}}\
</ul>';
const suggestionLinkLine =
'<li>\
<a class="suggestion" href="bihedral.com#suggestion={{word}}">{{word}}</a>\
</li>';
// NB links must end with #<enum type> so front-end can perform correct
// action based on link type. This one has additional info after = sign

const getSuperscriptFor = (num) => {
    if (num < 0) {
        return '';
    }
    var str = '';
    do {
        str = superscripts[num % 10] + str;
        num = Math.floor(num / 10);
    } while (num > 0);
    return str;
};

const joinLines = (lst, separator = '') => {
    return lst.filter(e => e && e.length > 0).join(separator);
};

// If all members of a given level L have the same value V for a property P,
// return V. Otherwise return null
const shouldBubbleUpValue = (listOfMembersOfL, propertyNameP) => {
    if (listOfMembersOfL.length === 0) {
        return null;
    }
    const lst = [];
    for (var i = 0; i < listOfMembersOfL.length; i++) {
        const member = listOfMembersOfL[i];
        const currValue = member.bubbleUpProperties[propertyNameP];
        lst.push(currValue);
    }
    return lst.every(elem => elem === lst[0]) ? lst[0] : null;
};

const bubbleUpAll = (definitionModelInstance) => {
    ['phoneticSpelling', 'pronunciationLink', 'register'].forEach((p) => {
        bubbleUp(definitionModelInstance, p);
    });
};

// If all members of a given level L have the same value V for propertyNameP,
// then L's members' propertyNameP values are set to null and L's propertyNameP
// value is set to V (even if L's propertyNameP value is not null and != V).
const bubbleUp = (defModelInstance, propertyNameP) => {
    const homographDigits = defModelInstance.existingHomographNumbers();
    for (var i = 0; i < homographDigits.length; i++) {
        const homographDigit = homographDigits[i];
        const homograph = defModelInstance.homographsDict[homographDigit];
        bubbleUpAux(homograph, propertyNameP);
    }
};

const bubbleUpAux = (member, propertyNameP, lvl = 1) => {
    const listOfMembersOfL = member.downPtr();

    // Base case is if we've reached subdefinition level
    if (!listOfMembersOfL) {
        return;
    }

    // If not, iterate over members of this level and do depth-first traversal
    for (var i = 0; i < listOfMembersOfL.length; i++) {
        const downMember = listOfMembersOfL[i];
        bubbleUpAux(downMember, propertyNameP, lvl + 1);
    }

    // Now that levels > L + 1 have bubbled up, bubble up L + 1
    const bubbledValueV = shouldBubbleUpValue(listOfMembersOfL, propertyNameP);
    if (bubbledValueV) {
        member.bubbleUpProperties[propertyNameP] = bubbledValueV;
        // Set downmembers' propertyNameP vals to null, since we bubbled up
        for (var i = 0; i < listOfMembersOfL.length; i++) {
            const downMember = listOfMembersOfL[i];
            downMember.bubbleUpProperties[propertyNameP] = null;
        }
    }
};

const addDownMembers = (member, downMembersLst) => {
    for (var i = 0; i < downMembersLst.length; i++) {
        member.downPtr().push(downMembersLst[i]);
    }
};

const dictEquals = (d1, d2) => {
    if (Object.keys(d1).length !== Object.keys(d2).length) {
        return false;
    }
    return Object.keys(d1).every(idx => d1[idx].equals(d2[idx]));
};

const arrEquals = dictEquals;

// The Swift HTML to attribuetd string converter has a bug: sometimes style
// classes on adjacent elements leak into neighboring elements. This character
// keeps that from happening
const zeroWidthNonJoiner = '&zwnj;';

// Each of these properties can be attached at any of four levels: to a
// homograph, a lexical entry, a a definition, or a sub-definition. If all
// members of a given level L have the same value V for one of these properties,
// P, then L's members' P values are set to null and L's P value is set to V
class BubbleUpProperties {
    constructor(phoneticSpelling, pronunciationLink, register) {
        // Optional. Unicode string, like /bou/
        this.phoneticSpelling = phoneticSpelling || null;
        // Optional. String url
        this.pronunciationLink = pronunciationLink || null;
        // Optional. E.g. 'informal' or 'vulgar'
        this.register = register || null;
    }

    getRegister() {
        return this.register ? this.register.toUpperCase(): '';
    }

    copyOfThis() {
        return new BubbleUpProperties(
            this.phoneticSpelling, this.pronunciationLink, this.register);
    }

    equals(otherBUP) {
        return otherBUP && this.phoneticSpelling === otherBUP.phoneticSpelling
            && this.pronunciationLink === otherBUP.pronunciationLink
            && this.register === otherBUP.register;
    }

    // E.g.
    // VULGAR /bo͞om bo͞om/ <audio-link>
    toHtml() {
        const elements = [];
        if (this.register) {
            elements.push(registerSpan
                .replace('{{register}}', this.getRegister()));
        }
        if (this.phoneticSpelling) {
            elements.push(pronunciationSpan
                .replace('{{pronunciation}}', this.phoneticSpelling || ''));
        }
        if (this.pronunciationLink) {
            elements.push(pronunciationAudioLinkSpan
                .replace('{{audio-link}}', this.pronunciationLink || ''));
        }
        return (elements.length > 0 ? zeroWidthNonJoiner : '')
            + joinLines(elements, ' ');
    }
}

// A sub-definition (subsense) with an optional usage example
class SubDefinition {
    constructor(definition, example, bubbleUpProperties) {
        this.definition = definition;  // Required. String
        this.example = example || null;  // Optional. String
        this.bubbleUpProperties =
            bubbleUpProperties || BubbleUpProperties(null, null, null);
    }

    downPtr() {
        return null;
    }

    equals(otherSubDef) {
        return otherSubDef && this.definition === otherSubDef.definition
            && this.example === otherSubDef.example
            && this.bubbleUpProperties.equals(otherSubDef.bubbleUpProperties);
    }

    toHtml() {
        const lines = [];

        lines.push(this.bubbleUpProperties.toHtml());
        lines.push(subdefinitionSpan
            .replace('{{subdefinition}}', this.definition));
        if (this.example && this.example.length > 0) {
            lines.push(subExampleSentenceSpan
                .replace('{{sub-example}}', this.example));
        }

        return definitionListElementLines
            .replace('{{content}}', joinLines(lines, '<br>'));
    }
}

// A definition (sense) with an optional usage example. Might contain
// subdefinitions
class Definition {
    constructor(definition, example, subDefinitions, bubbleUpProperties) {
        this.definition = definition;  // Required. String
        this.example = example || null;  // Optional. String
        this.subDefinitions = subDefinitions || [];  // Min size 0
        this.bubbleUpProperties =
            bubbleUpProperties || BubbleUpProperties(null, null, null);
    }

    downPtr() {
        return this.subDefinitions;
    }

    equals(otherDef) {
        return otherDef && this.definition === otherDef.definition
            && this.example === otherDef.example
            && arrEquals(this.subDefinitions, otherDef.subDefinitions)
            && this.bubbleUpProperties.equals(otherDef.bubbleUpProperties);
    }

    // e.g., for the word 'boom-boom':
    // 1. to get schwifty
    //     {{optional bubble props}}
    //     "we like to bazongalong before we boom-boom"
    //   {{optional subdefinitions list}}
    toHtml() {
        const subdefLines = [];
        for (var i = 0; i < this.subDefinitions.length; i++) {
            const subDefinition = this.subDefinitions[i];
            subdefLines.push(subDefinition.toHtml());
        }

        const lines = [];

        lines.push(this.bubbleUpProperties.toHtml());
        lines.push(definitionSpan
            .replace('{{definition}}', this.definition));
        if (this.example && this.example.length > 0) {
            lines.push(exampleSentenceSpan
                .replace('{{example}}', this.example));
        }

        if (subdefLines.length > 0) {
            lines.push(subdefinitionLines
                .replace('{{list-of-subdefinitions}}', joinLines(subdefLines)));
        }

        const htmlDefinition = definitionListElementLines
            .replace('{{content}}', joinLines(lines, '<br>'));
        return htmlDefinition;
    }
}

// Definition describing same homograph and same part of speech
class LexicalEntry {
    constructor(lexicalCategory, definitions, bubbleUpProperties) {
        this.lexicalCategory = lexicalCategory; // Required. e.g. noun, verb
        this.definitions = definitions || [];  // Min size 1
        this.bubbleUpProperties =
            bubbleUpProperties || BubbleUpProperties(null, null, null);
    }

    downPtr() {
        return this.definitions;
    }

    equals(otherLex) {
        return otherLex && this.lexicalCategory === otherLex.lexicalCategory
            && arrEquals(this.definitions, otherLex.definitions)
            && this.bubbleUpProperties.equals(otherLex.bubbleUpProperties);
    }

    // e.g., for the word 'boom-boom'
    // verb {{optional bubble props}}
    //   1. {{definition 1}}
    //   2. {{definition 2}}
    toHtml() {
        const htmlDefinitionLines = [];
        for (var i = 0; i < this.definitions.length; i++) {
            const definition = this.definitions[i];
            htmlDefinitionLines.push(definition.toHtml());
        }

        const lines = [];

        // Lexical categoy + optional bubble props line
        const spans = [];
        spans.push(lexicalCategorySpan
            .replace('{{lexical-category}}', this.lexicalCategory));
        spans.push(this.bubbleUpProperties.toHtml());
        lines.push(joinLines(spans, ' '));

        // List of definitions
        lines.push(definitionsLines.replace(
            '{{list-of-definitions}}', joinLines(htmlDefinitionLines)));

        return joinLines(lines);
    }
}

// Means 'same spelling, different meaning'. E.g. for 'bow' one homograph is for
// the shape (noun) and bowing a violin (verb), while another is for bowing to
// show respect
class Homograph {
    constructor(lexicalEntries, bubbleUpProperties) {
        this.lexicalEntries = lexicalEntries;  // Min size 1
        this.bubbleUpProperties =
            bubbleUpProperties || BubbleUpProperties(null, null, null);
    }

    downPtr() {
        return this.lexicalEntries;
    }

    equals(otherHomograph) {
        return otherHomograph
            && arrEquals(this.lexicalEntries, otherHomograph.lexicalEntries)
            && this.bubbleUpProperties.equals(
                otherHomograph.bubbleUpProperties);
    }

    // Total number of definitions across all lexical entries
    definitionCount() {
        var num = 0;
        this.lexicalEntries.forEach(lexicalEntry => {
            num += (lexicalEntry.definitions ?
                lexicalEntry.definitions.length : 0);
        });
        return num;
    }

    containsLex(lexicalEntry) {
        return this.lexicalEntries.some(lex => lex.equals(lexicalEntry));
    }

    // e.g., for the word 'boom-boom'
    // boom-boom ¹
    // VULGAR /bo͞om bo͞om/
    //
    // verb
    //   1. ...
    toHtml(word, num) {        
        const htmlLexicalEntries = [];
        for (var i = 0; i < this.lexicalEntries.length; i++) {
            const lexicalEntry = this.lexicalEntries[i];
            htmlLexicalEntries.push(lexicalEntry.toHtml());
        }

        const lines = [];
        // Title line, e.g. boom-boom ¹
        lines.push(homographTitleLine
            .replace('{{word}}', word)
            .replace('{{superscript}}', getSuperscriptFor(num)));

        // Optional bubble props line, e.g. VULGAR /bo͞om bo͞om/
        const htmlBubbleProps = this.bubbleUpProperties.toHtml();
        if (htmlBubbleProps && htmlBubbleProps.length > 0) {
            lines.push(homographOptionalBubblePropsLine
                .replace('{{bubble-props}}', htmlBubbleProps));
        }

        // Lexical entries lines, e.g.
        // verb
        //   1. ...
        lines.push(homographRequiredLexicalEntriesLines.replace(
            '{{lexical-entries}}', joinLines(htmlLexicalEntries, '<br>')));

        return joinLines(lines);
    }
}

class DefinitionModel {
    constructor(word, homographsDict) {
        this.word = word;  // Required

        // Min size 1. Map from digit to homograph
        this.homographsDict = homographsDict;
    }

    downPtr() {
        return Object.values(this.homographsDict);
    }

    equals(otherModel) {
        return otherModel && this.word === otherModel.word
            && dictEquals(this.homographsDict, otherModel.homographsDict);
    }

    existingHomographNumbers() {
        return Object.keys(this.homographsDict).sort();
    }

    addHomograph(homograph, num) {
        const strIdx = num[0];
        this.homographsDict[strIdx] = homograph;
    }

    // A homograph number consists of three digits, the first of which
    // describes the homograph group. E.g., a word with homograph
    // number 301 belongs to group 3. The second two digits identity a
    // word within a homograph number. Given a string like '301', return
    // the third homograph
    getHomographFromNumber(num) {
        if (num === undefined || num === null || num === '') {
            util.cloudwatchLog('Bad num in getHomographFromNumber');
            return null;
        }
        const rtn = this.homographsDict[num[0]];
        return rtn ? rtn : null;
    }

    // e.g., for the word 'boom-boom'
    // {{homograph 1}}
    // {{homograph 2}}
    // ...
    toHtml(shortForm = false) {
        var htmlHomographs = [];
        var homographDigits = this.existingHomographNumbers();

        // homographDigits might not be contiguous, might not start at 1,
        // and might not even consist only of numbers. E.g., 'x' for
        // missing homograph numbers
        var superscripts = Object.keys(homographDigits).map(
            idx => parseInt(idx) + 1);

        for (var i = 0; i < homographDigits.length; i++) {
            const homographDigit = homographDigits[i];
            const homograph = this.homographsDict[homographDigit];
            if (homograph.definitionCount() === 0) {
                continue;
            }

            // No superscript needed if there's just one homograph
            const superscript =
                superscripts.length === 1 ? -1 : superscripts[i];
            htmlHomographs.push(homograph.toHtml(this.word, superscript));
        }
        return joinLines(htmlHomographs, '<br>');
    };
}

class SuggestionsModel {
    constructor(words) {
        this.words = words;  // Required
    }

    equals(otherModel) {
        return otherModel && util.setEqual(this.words, otherModel.words);
    }

    count() {
        return this.words ? this.words.length : 0;
    }

    toHtml() {
        if (!this.words || this.words.length === 0) {
            return '';
        }
        const suggestionLines = [];
        for (var i = 0; i < this.words.length; i++) {
            const word = this.words[i];
            const line = suggestionLinkLine.replace(/\{\{word\}\}/g, word);
            suggestionLines.push(line);
        }

        return suggestionsLines
            .replace('{{list-of-suggestions}}', joinLines(suggestionLines));
    }
}

exports.bubbleUpAll = bubbleUpAll;
exports.addDownMembers = addDownMembers;
exports.BubbleUpProperties = BubbleUpProperties;
exports.SubDefinition = SubDefinition;
exports.Definition = Definition;
exports.LexicalEntry= LexicalEntry;
exports.Homograph = Homograph;
exports.DefinitionModel = DefinitionModel;
exports.SuggestionsModel = SuggestionsModel;
exports.MISSING_HOMOGRAPH_MARKER = MISSING_HOMOGRAPH_MARKER;
