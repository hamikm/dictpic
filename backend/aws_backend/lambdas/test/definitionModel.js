const expect = require('chai').expect;

const util = require('../lib/util');
const modelFile = '../definition/definitionModel';
const BubbleUpProperties = require(modelFile).BubbleUpProperties;
const DefinitionModel = require(modelFile).DefinitionModel;
const Homograph = require(modelFile).Homograph;
const LexicalEntry = require(modelFile).LexicalEntry;
const Definition = require(modelFile).Definition;
const SubDefinition = require(modelFile).SubDefinition;
const SuggestionsModel = require(modelFile).SuggestionsModel;
const bubbleUpAll = require(modelFile).bubbleUpAll;

// TODO: the following init functions are from before there were non-default
// constructors in definitionModel. Remove them and refactor tests to call
// those constructors directly

const bpmToObj = mapping => {
    return new BubbleUpProperties(
        mapping.phoneticSpelling,
        mapping.pronunciationLink,
        mapping.register
    );
};

const initSubdef = (definition, bubblePropMapping, example = null) => {
    return new SubDefinition(
        definition, example, bpmToObj(bubblePropMapping));
}

const initDef = (definition, bubblePropMapping, subdefs, example = null) => {
    return new Definition(
        definition, example, subdefs, bpmToObj(bubblePropMapping));
}

const initLex = (lexicalCategory, bubblePropMapping, defs) => {
    return new LexicalEntry(
        lexicalCategory, defs, bpmToObj(bubblePropMapping));
}

const initHomograph = (bubblePropMapping, lexs) => {
    return new Homograph(lexs, bpmToObj(bubblePropMapping));
}

const initModel = (homographsDict) => {
    return new DefinitionModel('boom-boom', homographsDict);
}

const bpm = (phoneticSpelling, pronunciationLink, register) => {
    return { phoneticSpelling, pronunciationLink, register, };
};

const getBasicFixture = () => {

    // A complete tree:
    const s1 = initSubdef('s1 defn', bpm('/es/', null, 'technical'));
    const s2 = initSubdef('s2 defn', bpm('/es/', null, null));
    const s3 = initSubdef('s3 defn', bpm('/es/', null, 'mathematical'));
    const d1 = initDef('to get schwifty', bpm(null, null, null), [s1, s2, s3]);
    // d1 bubbleups before bubble down should be '/es/', null, null

    const s4 = initSubdef('s4 defn', bpm(null, 'hey.com/d2.mp3', null));
    const s5 = initSubdef('s5 defn', bpm(null, 'hey.com/d2.mp3', 'arcane'));
    const s6 = initSubdef('s6 defn', bpm(null, 'hey.com/d2.mp3', null));
    const d2 = initDef(
        'to boingyzoingy', bpm('/es/', 'hey.com/wow.mp3', null), [s4, s5, s6]);
    // d2 bubbleups before bubble down should be: '/es/', 'hey.com/d2.mp3', null

    const l1 = initLex('verb l1', bpm(null, null, null), [d1, d2]);
    // l1 bubbleups before bubble down should be '/es/', null, null

    const s7 = initSubdef('s7 defn', bpm(null, null, 'vulgar d3'));
    const s8 = initSubdef('s8 defn', bpm(null, null, 'vulgar d3'));
    const d3 = initDef(
        'an act of boingyzoingy', bpm(null, null, null), [s7, s8]);
    // d3 bubbleups before bubble down should be null, null, 'vulgar d3'

    const s9 = initSubdef('s9 defn', bpm(null, null, null));
    const s10 = initSubdef('s10 defn', bpm(null, null, null));
    const d4 = initDef('a disgusting dance', bpm(null, null, 'vulgar d3'), [s9, s10]);
    // d4 bubbleups before bubble down should be null, null, 'vulgar d3'

    const l2 = initLex('noun l2', bpm('/es/', null, null), [d3, d4]);
    // l2 bubbleups before bubble down should be '/es/', null, 'vulgar d3'

    const h1 = initHomograph(bpm(null, 'hey.com/h1.mp3', null), [l1, l2]);
    // h1 bubbleups before bubble down should be '/es/', 'hey.com/h1.mp3', null

    // A linear (path) tree:
    const s11 = initSubdef('s11 defn', bpm('/es11/', null, null));
    const d5 = initDef('d5 defn', bpm(null, 'hey.com/d5.mp3', null), [s11]);
    const l3 = initLex('noun', bpm(null, null, 'vulgar l3'), [d5]);
    const h2 = initHomograph(bpm(null, null, 'vulgar h2'), [l3]);
    // h2 bubbleups before bubble down should be '/es11/', 'hey.com/d5.mp3',
    //   'vulgar l3'

    const dm = initModel({ 1: h1, 2: h2 });
    bubbleUpAll(dm);

    return dm;
};

const allProps = ['phoneticSpelling', 'pronunciationLink', 'register'];

function expectTheseBubbleUpPropsAreNull(member, props) {
    for (var i = 0; i < props.length; i++) {
        const val = member.bubbleUpProperties[props[i]];
        expect(val).to.be.equal(null);
    }
}

function expectTheseLowerBubbleUpPropsAreNull(rootMember, props) {
    if (!rootMember.downPtr()) { return; }
    for (var i = 0; i < rootMember.downPtr().length; i++) {
        const downMember = rootMember.downPtr()[i];
        expectTheseBubbleUpPropsAreNull(downMember, props);
        expectTheseLowerBubbleUpPropsAreNull(downMember, props);
    }
}

describe('shouldBubbleUpValue()', function() {
    it('should return V if all members in L have same V for P', function () {

        // Arrange
        const dm = getBasicFixture();

        // Act
        // Happens in getBasicFixture()

        // Assert
        const h1 = dm.homographsDict[1];
        const h1PhoneticSpelling = h1.bubbleUpProperties.phoneticSpelling;
        const h1PronunciationLink = h1.bubbleUpProperties.pronunciationLink;
        const h1Register = h1.bubbleUpProperties.register;
        expect(h1PhoneticSpelling).to.be.equal('/es/');
        expect(h1PronunciationLink).to.be.equal('hey.com/h1.mp3');
        expect(h1Register).to.be.equal(null);
        expectTheseLowerBubbleUpPropsAreNull(h1, ['phoneticSpelling']);
        const l2 = h1.lexicalEntries[1];
        expectTheseLowerBubbleUpPropsAreNull(l2, ['register']);
        const d2 = h1.lexicalEntries[0].definitions[1];
        expectTheseLowerBubbleUpPropsAreNull(d2, ['pronunciationLink']);

        const h2 = dm.homographsDict[2];
        const h2PhoneticSpelling = h2.bubbleUpProperties.phoneticSpelling;
        const h2PronunciationLink = h2.bubbleUpProperties.pronunciationLink;
        const h2Register = h2.bubbleUpProperties.register;
        expect(h2PhoneticSpelling).to.be.equal('/es11/');
        expect(h2PronunciationLink).to.be.equal('hey.com/d5.mp3');
        expect(h2Register).to.be.equal('vulgar l3');
        expectTheseLowerBubbleUpPropsAreNull(h2, allProps);
    });
});

const expectTheseAsHtmlEqualThese = (fixtures, expectedResults, args) => {
    expect(fixtures.length).to.be.equal(expectedResults.length);
    const htmlFixtures = fixtures.map(
        fixture => args ? fixture.toHtml(args[0], args[1]) : fixture.toHtml());
    const noWhitespaceExpectedResults = expectedResults.map(
        expectedResult => util.multiToSingleLine(expectedResult));
    for (var i = 0; i < htmlFixtures.length; i++) {
        const htmlFixture = htmlFixtures[i];
        const expectedResult = noWhitespaceExpectedResults[i];
        expect(htmlFixture).to.be.equal(expectedResult);
    }
};

describe('BubbleUpProperties.toHtml()', function () {
    it('should convert bubble props into HTML', function () {
        expectTheseAsHtmlEqualThese(
            [
                bpmToObj(bpm(null, null, null)),
                bpmToObj(bpm('/pron./', null, null)),
                bpmToObj(bpm(null, 'link.com', null)),
                bpmToObj(bpm(null, null, 'vulgar')),
                bpmToObj(bpm('/pron./', null, 'vulgar')),
                bpmToObj(bpm('/pron./', 'link.com', 'vulgar')),
            ],
            [
                '',
                '&zwnj;<span class="pronunciation">/pron./</span>',
                `&zwnj;<span class="listen-icon"><a href="link.com#audio">🔈
                    </a></span>`,
                '&zwnj;<span class="sub-pop">VULGAR</span>',
                `&zwnj;<span class="sub-pop">VULGAR
                    </span> <span class="pronunciation">/pron./</span>`,
                `&zwnj;<span class="sub-pop">VULGAR</span> <span class=
                    "pronunciation">/pron./</span> <span class="listen-icon">
                    <a href="link.com#audio">🔈</a></span>`,
            ]
        );
    });
});

const getSubdefinitionHtmlTestFixture = (def, ex, bubbleUps) => {
    const sd = initSubdef(def, bubbleUps, ex);
    return sd;
};

describe('SubDefinition.toHtml()', function () {
    it('should convert a subdefinition into HTML', function () {
        expectTheseAsHtmlEqualThese(
            [
                getSubdefinitionHtmlTestFixture(
                    'def 1', 'sent 1', bpm(null, null, null)),
                getSubdefinitionHtmlTestFixture(
                    'def 2', 'sent 2', bpm('/pron./', 'link.com', 'vulgar')),
            ],
            [
                `<li><span class="subdefinition">def 1</span><br><span class=
                    "sub-example-sent">sent 1</span></li>`,
                `<li>&zwnj;<span class="sub-pop">VULGAR</span> <span class=
                    "pronunciation">/pron./</span> <span class="listen-icon">
                    <a href="link.com#audio">🔈</a></span><br><span class=
                    "subdefinition">def 2</span><br><span class=
                    "sub-example-sent">sent 2</span></li>`,
            ]
        );
    });
});

const getDefinitionHtmlTestFixture = (def, ex, bubbleUps, subs = false) => {
    const subdefsList = [];
    if (subs) {
        subdefsList.push(initSubdef('definition one', bpm(null, null, null)));
        subdefsList.push(initSubdef(
            'definition two', bpm('/pron./', 'link.com', 'vulgar')));
        subdefsList.push(initSubdef(
            'definition three',
            bpm('/pron./', 'link.com', null),
            'example sentence'
        ));
    }
    const d = initDef(def, bubbleUps, subdefsList, ex);
    return d;
};

describe('Definition.toHtml()', function () {
    it('should convert a definition into HTML', function () {
        expectTheseAsHtmlEqualThese(
            [
                getDefinitionHtmlTestFixture(
                    'def 1', 'sent 1', bpm(null, null, null)),
                getDefinitionHtmlTestFixture(
                    'def 2', 'sent 2', bpm('/pron./', 'link.com', 'vulgar')),
                getDefinitionHtmlTestFixture(
                    'def 3', 'sent 3', bpm(null, null, null), true),
            ],
            [
                `<li><span class="definition">def 1</span><br><span class=
                    "example-sent">sent 1</span></li>`,
                `<li>&zwnj;<span class="sub-pop">VULGAR</span> <span class=
                    "pronunciation">/pron./</span> <span class="listen-icon">
                    <a href="link.com#audio">🔈</a></span><br><span class=
                    "definition">def 2</span><br><span class="example-sent">
                    sent 2</span></li>`,
                `<li><span class="definition">def 3</span><br><span class=
                    "example-sent">sent 3</span><br><ul><li><span class=
                    "subdefinition">definition one</span></li>
                    <li>&zwnj;<span class="sub-pop">VULGAR</span> <span class=
                    "pronunciation">/pron./</span> <span class="listen-icon">
                    <a href="link.com#audio">🔈</a></span><br><span class=
                    "subdefinition">definition two</span></li>
                    <li>&zwnj;<span class="pronunciation">/pron./
                    </span> <span class="listen-icon">
                    <a href="link.com#audio">🔈</a></span><br>
                    <span class="subdefinition">definition 
                    three</span><br><span class="sub-example-sent">example 
                    sentence</span></li></ul></li>`,
            ]
        );
    });
});

const getLexicalhHtmlTestFixture = (bubbleUps, additionalDefs = 0) => {
    const d = initDef('', bpm(null, null, null), []);
    const l = initLex('noun', bubbleUps, [d]);
    for (var i = 0; i < additionalDefs; i++) {
        l.definitions.push(initDef('', bpm(null, null, null), []));
    }
    return l;
};

describe('LexicalEntry.toHtml()', function () {
    it('should convert a lexical entey into HTML', function () {
        expectTheseAsHtmlEqualThese(
            [
                getLexicalhHtmlTestFixture(bpm(null, null, null)),
                getLexicalhHtmlTestFixture(bpm('pron.', 'link.com', 'bad')),
                getLexicalhHtmlTestFixture(bpm(null, null, null), 1),
            ],
            [
                `<span class="part-of-speech">noun</span><div><ol class=
                    "text"><li><span class="definition"></span></li></ol>
                    </div>`,
                `<span class="part-of-speech">noun</span> &zwnj;<span class=
                    "sub-pop">BAD</span> <span class="pronunciation">
                    pron.</span> <span class="listen-icon">
                    <a href="link.com#audio">🔈</a></span><div>
                    <ol class="text"><li><span class="definition"></span>
                    </li></ol></div>`,
                `<span class="part-of-speech">noun</span><div><ol class=
                    "text"><li><span class="definition"></span></li><li>
                    <span class="definition"></span></li></ol></div>`,
            ]
        );
    });
});

const getHomographHtmlTestFixture = (bubbleUps, additionalLexs = 0) => {
    const d = initDef('', bpm(null, null, null), []);
    const l = initLex('noun', bpm(null, null, null), [d]);
    const h = initHomograph(bubbleUps, [l]);
    for (var i = 0; i < additionalLexs; i++) {
        h.lexicalEntries.push(initLex('verb', bpm(null, null, null), [
            initDef('', bpm(null, null, null), [])
        ]));
    }
    return h;
};

describe('Homograph.definitionCount()', function () {
    it('should count total number of definitions', function () {
        const homographWithoutDefs =
            getHomographHtmlTestFixture(bpm(null, null, null));
        homographWithoutDefs.lexicalEntries[0].definitions = [];
        expect(homographWithoutDefs.definitionCount()).to.be.equal(0);
    })
});

describe('Homograph.toHtml()', function () {
    it('should convert a homograph into HTML', function () {
        expectTheseAsHtmlEqualThese(
            [
                getHomographHtmlTestFixture(bpm(null, null, null)),
                getHomographHtmlTestFixture(bpm('pron.', 'link.com', 'bad')),
                getHomographHtmlTestFixture(bpm(null, null, null), 1),
            ],
            [
                `<div><span class="word">boom-boom </span>
                    <span class="word-superscript">¹</span></div><br><div>
                    <span class="part-of-speech">noun</span><div>
                    <ol class="text"><li><span class="definition"></span>
                    </li></ol></div></div>`,
                `<div><span class="word">boom-boom </span>
                    <span class="word-superscript">¹</span></div><div>&zwnj;
                    <span class="sub-pop">BAD</span> <span class=
                    "pronunciation">pron.</span> <span class="listen-icon">
                    <a href="link.com#audio">🔈</a></span></div><br><div>
                    <span class="part-of-speech">noun</span><div><ol class=
                    "text"><li><span class="definition"></span></li></ol>
                    </div></div>`,
                `<div><span class="word">boom-boom </span>
                    <span class="word-superscript">¹</span></div><br><div>
                    <span class="part-of-speech">noun</span><div><ol class=
                    "text"><li><span class="definition"></span></li></ol>
                    </div><br><span class="part-of-speech">verb</span><div>
                    <ol class="text"><li><span class="definition"></span>
                    </li></ol></div></div>`,
            ],
            ['boom-boom', 1]
        );
    });
});

const getBigHtmlTestFixture = () => {
    // Start homograph 1
    const s1 = initSubdef('to get all bazongalonga', bpm(null, null, null),
        'they did boom boom five times per day');
    const s2 = initSubdef('to boing the zoing', bpm(null, null, null));
    const d1 = initDef('to get schwifty', bpm(null, null, null), [s1, s2],
        'boom booming was a major attraction at the colosseum');
    const d2 = initDef('to make suzy', bpm(null, null, null), [],
        'boom booming for suzy is like gcc with unsafe optimizations');
    const l1 = initLex('verb', bpm(null, null, null), [d1, d2]);
    const d3 = initDef('an act of bazongalonga', bpm(null, null, null), []);
    const l2 = initLex('noun', bpm(null, null, null), [d3]);
    const h1 = initHomograph(bpm('/bo͞om bo͞om/', null, 'vulgar'), [l1, l2]);

    // Start homograph 2
    const d5 = initDef('the sound of fireworks',
        bpm('/bo͞om bo͞om/', null, null),
        [],
        'bailey found the boom booms scary');
    const l3 = initLex('noun', bpm(null, null, null), [d5]);
    const h2 = initHomograph(bpm(null, null, null), [l3]);

    const dm = initModel({ 1: h1, 2: h2 });
    bubbleUpAll(dm);
    return dm;
};

const getFixtureHomographs = (num = 2) => {
    const d1 = initDef('', bpm(null, null, null), []);
    const l1 = initLex('noun', bpm(null, null, null), [d1]);
    const h1 = initHomograph(bpm(null, null, null), [l1]);

    const d2 = initDef('', bpm(null, null, null), []);
    const l2 = initLex('noun', bpm(null, null, null), [d2]);
    const h2 = initHomograph(bpm(null, null, null), [l2]);

    const d3 = initDef('', bpm(null, null, null), []);
    const l3 = initLex('noun', bpm(null, null, null), [d3]);
    const h3 = initHomograph(bpm(null, null, null), [l3]);

    const arr = [h1, h2, h3];
    const numToRemove = arr.length - num;
    const startIdx = arr.length - numToRemove;
    arr.splice(startIdx, numToRemove);
    return arr;
};

const getDefinitionModelHtmlTestFixture = () => {
    const hs = getFixtureHomographs();
    const dm = initModel({ 1: hs[0], 2: hs[1] });
    return dm;
};

const getDefinitionModelSuperscriptZeroTestFixture = () => {
    const hs = getFixtureHomographs();
    const dm = initModel({});
    dm.addHomograph(hs[0], '000');
    dm.addHomograph(hs[1], '001');
    // Since there's only one homograph group, there should be no superscript

    return dm;
};

const getDefinitionModelSuperscriptFromZeroTestFixture = () => {
    const hs = getFixtureHomographs(3);
    const dm = initModel({});
    dm.addHomograph(hs[0], '000');
    dm.addHomograph(hs[1], '100');
    dm.addHomograph(hs[2], '200');
    // Since there's more than one homograph group but they're
    // indexed from 0, superscripts should be numbered 1, 2, 3

    return dm;
};

const getDefinitionModelSuperscriptFromOneTestFixture = () => {
    const hs = getFixtureHomographs(3);
    const dm = initModel({});
    dm.addHomograph(hs[0], '100');
    dm.addHomograph(hs[1], '200');
    dm.addHomograph(hs[2], '300');
    // Since there's more than one homograph group and they're
    // indexed from 1, superscripts should be numbered 1, 2, 3

    return dm;
};

const getDefinitionModelSuperscriptIrregularTestFixture = () => {
    const hs = getFixtureHomographs(3);
    const dm = initModel({});
    dm.addHomograph(hs[0], '000');
    dm.addHomograph(hs[1], '201');
    dm.addHomograph(hs[2], '500');
    // Superscripts should be numbered 1, 2, 3 despite irregularity
    // of homograph numbers

    return dm;
};

const getDefinitionModelMissingSomeDefs = () => {
    const hs = getFixtureHomographs();
    hs[0].lexicalEntries.forEach(lexicalEntry => {
        lexicalEntry.definitions.forEach(def => {
            def.definition = 'much wow';
        });
    });
    hs[1].lexicalEntries.forEach(lexicalEntry => {
        lexicalEntry.definitions = [];
    });
    const dm = initModel({ 1: hs[0], 2: hs[1] });
    return dm;
};

const htmlForSuperscripts123 = `
<div><span class="word">boom-boom </span><span class="word-superscript">¹
</span></div><br><div><span class="part-of-speech">noun</span><div>
<ol class="text"><li><span class="definition"></span></li></ol></div></div>
<br><div><span class="word">boom-boom </span><span class="word-superscript">²
</span></div><br><div><span class="part-of-speech">noun</span><div><ol class=
"text"><li><span class="definition"></span></li></ol></div></div><br><div>
<span class="word">boom-boom </span><span class="word-superscript">³</span>
</div><br><div><span class="part-of-speech">noun</span><div><ol class="text">
<li><span class="definition"></span></li></ol></div></div>`;

describe('DefinitionModel.toHtml()', function () {
    it('should convert a model into HTML', function () {
        expectTheseAsHtmlEqualThese(
            [
                getDefinitionModelHtmlTestFixture(),
                getBigHtmlTestFixture(),
                getDefinitionModelSuperscriptZeroTestFixture(),
                getDefinitionModelSuperscriptFromZeroTestFixture(),
                getDefinitionModelSuperscriptFromOneTestFixture(),
                getDefinitionModelSuperscriptIrregularTestFixture(),
                getDefinitionModelMissingSomeDefs(),
            ],
            [
                `<div><span class="word">boom-boom </span><span class=
                    "word-superscript">¹</span></div><br><div><span class=
                    "part-of-speech">noun</span><div><ol class="text"><li>
                    <span class="definition"></span></li></ol></div></div>
                    <br><div><span class="word">boom-boom </span><span class=
                    "word-superscript">²</span></div><br><div><span class=
                    "part-of-speech">noun</span><div><ol class="text"><li>
                    <span class="definition"></span></li></ol></div></div>`,
                `<div><span class="word">boom-boom </span><span class=
                    "word-superscript">¹</span></div><div>&zwnj;<span class=
                    "sub-pop">VULGAR</span> <span class="pronunciation">
                    /bo͞om bo͞om/</span></div><br><div><span class=
                    "part-of-speech">verb</span><div><ol class="text">
                    <li><span class="definition">to get schwifty</span><br>
                    <span class="example-sent">
                    boom booming was a major attraction at the colosseum
                    </span><br><ul><li><span class="subdefinition">
                    to get all bazongalonga</span><br><span class=
                    "sub-example-sent">they did boom boom five times per day
                    </span></li><li><span class="subdefinition">
                    to boing the zoing</span></li></ul></li><li><span class=
                    "definition">to make suzy</span><br><span class=
                    "example-sent">
                    boom booming for suzy is like gcc with unsafe optimizations
                    </span></li></ol></div><br><span class="part-of-speech">
                    noun</span><div><ol class="text"><li><span class=
                    "definition">an act of bazongalonga</span></li></ol></div>
                    </div><br><div><span class="word">boom-boom </span>
                    <span class="word-superscript">²</span></div><div>&zwnj;
                    <span class="pronunciation">/bo͞om bo͞om/</span></div><br>
                    <div><span class="part-of-speech">noun</span><div>
                    <ol class="text"><li><span class="definition">
                    the sound of fireworks</span><br><span class=
                    "example-sent">bailey found the boom booms scary</span>
                    </li></ol></div></div>`,
                `<div><span class="word">boom-boom </span><span class=
                    "word-superscript"></span></div><br><div><span class=
                    "part-of-speech">noun</span><div><ol class="text"><li>
                    <span class="definition"></span></li></ol></div></div>`,
                htmlForSuperscripts123,
                htmlForSuperscripts123,
                htmlForSuperscripts123,
                `<div><span class="word">boom-boom </span><span class=
                    "word-superscript">¹</span></div><br><div><span class=
                    "part-of-speech">noun</span><div><ol class="text"><li>
                    <span class="definition">much wow</span></li></ol></div>
                    </div>`,
            ]
        );
    });
});

describe('DefinitionModel.getHomographFromNumber()', function () {
    it('should return a homograph from a homographNumber', function () {
        // Arrange
        const dm = getBasicFixture();

        // Act
        // In asserts

        // Assert
        expect(dm.getHomographFromNumber('100')).to.be.equal(dm.homographsDict[1]);
        expect(dm.getHomographFromNumber('101')).to.be.equal(dm.homographsDict[1]);
        expect(dm.getHomographFromNumber('200')).to.be.equal(dm.homographsDict[2]);
        expect(dm.getHomographFromNumber('210')).to.be.equal(dm.homographsDict[2]);
        expect(dm.getHomographFromNumber('000')).to.be.equal(null);
        expect(dm.getHomographFromNumber('300')).to.be.equal(null);
    });
});

describe('DefinitionModel.addHomograph()', function () {
    it('should add a homograph with a homographNumber', function () {
        // Arrange
        const dmTmp = getBasicFixture();
        const h1 = dmTmp.homographsDict[1];
        const h2 = dmTmp.homographsDict[2];
        const dm1 = new DefinitionModel('boom-boom', {});
        dm1.addHomograph(h1, '100');
        dm1.addHomograph(h2, '201');

        // Act
        // In asserts

        // Assert
        expect(dm1.homographsDict[1]).to.be.equal(h1);
        expect(dm1.homographsDict[2]).to.be.equal(h2);
        expect(Object.keys(dm1.homographsDict).length).to.be.equal(2);
    });
});

describe('DefinitionModel.equals()', function () {
    it('should do deep equals op', function () {
        // Arrange
        const dm1 = getBasicFixture();
        const dm2 = getBasicFixture();
        const dm3 = getBasicFixture();
        dm3.homographsDict[1].lexicalEntries[0].definitions[0].example = 'ew';

        // Act
        // In asserts

        // Assert
        expect(dm1.equals(dm2)).to.be.equal(true);
        expect(dm1.equals(dm3)).to.be.equal(false);
        expect(dm2.equals(dm3)).to.be.equal(false);
    });
});

describe('DefinitionModel.containsLex()', function () {
    it('should check if this model contains this lexical entry', function () {
        // Arrange
        const dm = getBasicFixture();
        const d1 = dm.homographsDict[1];
        const d2 = dm.homographsDict[2];
        const l1 = d1.lexicalEntries[0];
        const l2 = d2.lexicalEntries[0];

        // Act
        // In asserts

        // Assert
        expect(d1.containsLex(l1)).to.be.equal(true);
        expect(d1.containsLex(l2)).to.be.equal(false);
        expect(d2.containsLex(l1)).to.be.equal(false);
        expect(d2.containsLex(l2)).to.be.equal(true);
    });
});

describe('SuggestionsModel.toHtml()', function () {
    it('should return list of word suggestions in HTML', function () {
        // Arrange
        const words1 = ['setting', 'seating'];
        const suggestionsHtml1 = `
            <ul class="text"><li><a class="suggestion" href="bihedral.com#suggestion=setting">setting
                </a></li><li><a class="suggestion" href="bihedral.com#suggestion=seating">seating</a>
                </li></ul>`;
        const words2 = [];
        const suggestionsHtml2 = '';

        // Act
        const suggestions1 = new SuggestionsModel(words1);
        const suggestions2 = new SuggestionsModel(words2);

        // Assert
        expect(suggestions1.toHtml()).to.be.equal(util.multiToSingleLine(suggestionsHtml1));
        expect(suggestions2.toHtml()).to.be.equal(util.multiToSingleLine(suggestionsHtml2));
    });
});
