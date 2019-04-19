const expect = require('chai').expect;

const util = require('../lib/util');
const mapperFile = '../definition/oedToModelMapper';
const modelsFile = '../definition/definitionModel';
const SuggestionsModel = require(modelsFile).SuggestionsModel;
const mapper = require(mapperFile).mapper;
const getLemmas = require(mapperFile).getLemmas;
const getWordsFromSearch = require(mapperFile).getWordsFromSearch;

describe('oedMapper()', function () {
    it('should return DefinitionModel from OED API JSON', function () {
        const dm1 = mapper(oedDefinitionForRowFixture().results[0]);
        const dm2 = mapper(noHomographsResultsArrayEntryFixture);
        expect(dm1.toHtml()).to.be.equal(util.multiToSingleLine(correctHtmlOutputForRow));
        expect(dm2.toHtml()).to.be.equal(util.multiToSingleLine(expectedNoHomographsOutputHtml));  
    });
});

describe('getLemmas()', function () {
    it('should get all lemmas from lemmatron response', function () {
        const lemmas1 = getLemmas(lemmatronResultsArrayEntryFixture1);
        const lemmas2 = getLemmas(lemmatronResultsArrayEntryFixture2);
        expect(lemmas1.equals(new SuggestionsModel(expectedLemmas1))).to.be.equal(true);
        expect(lemmas2.equals(new SuggestionsModel(expectedLemmas2))).to.be.equal(true);
    });
});

describe('getWordsFromSearch()', function () {
    it('should get list of all words resulting from search', function () {
        const words1 = getWordsFromSearch(searchResultsFixture1);

        // Use listEqual b/c order of words is important: there is higher
        // confidence in earlier ones.
        expect(words1.equals(new SuggestionsModel(expectedWords1))).to.be.equal(true);
    });
});

// Make sure that when homograph number is absent, superscripts make sense
const noHomographsResultsArrayEntryFixture = {
    id: 'queso',
    language: 'es',
    lexicalEntries: [{
        entries: [{
            homographNumber: '100',
            grammaticalFeatures: [
                {
                    text: 'Masculine',
                    type: 'Gender',
                },
                {
                    text: 'Singular',
                    type: 'Number',
                },
            ],
            senses: [
                {
                    definitions: [
                        'Alimento sólido que se obtiene por maduración de la cuajada de la leche una vez eliminado el suero; sus diferentes variedades dependen del origen de la leche empleada, de los métodos de elaboración seguidos y del grado de madurez alcanzado',
                    ],
                    id: 'genID_d122689e1857805',
                },
                {
                    definitions: ['Pie de una persona'],
                    examples: [{text: '¿puedes apartar tus quesos y dejarme pasar?'}],
                    id: 'genID_d122689e1857811',
                    registers: ['informal'],
                },
            ],
        }],
        language: 'es',
        lexicalCategory: 'Noun',
        text: 'queso',
    }],
    type: 'headword',
    word: 'queso',
};

const expectedNoHomographsOutputHtml = '<div><span class="word">queso \
    </span><span class="word-superscript"></span></div><br><div><span \
    class="part-of-speech">noun</span><div><ol class="text"><li><span \
    class="definition">Alimento sólido que se obtiene por maduración de \
    la cuajada de la leche una vez eliminado el suero; sus diferentes \
    variedades dependen del origen de la leche empleada, de los métodos \
    de elaboración seguidos y del grado de madurez alcanzado</span></li>\
    <li>&zwnj;<span class="sub-pop">INFORMAL</span><br><span class=\
    "definition">Pie de una persona</span><br><span class="example-sent">\
    ¿puedes apartar tus quesos y dejarme pasar?</span></li></ol></div></div>';

const lemmatronResultsArrayEntryFixture1 = {
    id: 'settings',
    language: 'en',
    lexicalEntries: [{
        grammaticalFeatures: [],
        inflectionOf: [{
            id: 'setting',
            text: 'setting',
        }],
        language: 'en',
        lexicalCategory: 'Noun',
        text: 'settings',
    }],
    word: 'settings',
};
const expectedLemmas1 = ['setting'];

const lemmatronResultsArrayEntryFixture2 = {
    id: 'settings',
    language: 'en',
    lexicalEntries: [
        {
            grammaticalFeatures: [],
            inflectionOf: [
                {
                    id: 'setting',
                    text: 'setting',
                },
                {
                    id: 'setting2',
                    text: 'setting',
                },
            ],
            language: 'en',
            lexicalCategory: 'Noun',
            text: 'settings',
        },
        {
            grammaticalFeatures: [],
            inflectionOf: [{
                id: 'setting3',
                text: 'set',
            }],
            language: 'en',
            lexicalCategory: 'Verb',
            text: 'settings',
        },
    ],
    word: 'settings',
};
const expectedLemmas2 = ['setting', 'set'];

const searchResultsFixture1 = [
    {
        id: 'setting',
        matchString: 'seytings',
        word: 'setting',
        matchType: 'fuzzy',
        score: 8.972399,
        region: 'us',
    },
    {
        id: 'seating',
        matchString: 'seytings',
        word: 'seating',
        matchType: 'fuzzy',
        score: 8.972399,
        region: 'us',
    },
];
const expectedWords1 = ['setting', 'seating'];

const oedDefinitionForRowFixture = () => {
    return {
        metadata: {
            provider: 'Oxford University Press',
        },
        results: [
            {
                id: 'row',
                language: 'en',
                lexicalEntries: [
                    {
                        entries: [
                            {
                                etymologies: [
                                    'Old English rāw, of Germanic origin; related to Dutch rij and German Reihe',
                                ],
                                grammaticalFeatures: [
                                    {
                                        text: 'Singular',
                                        type: 'Number',
                                    },
                                ],
                                homographNumber: '100',
                                pronunciations: [
                                    {
                                        audioFile: 'http://audio.oxforddictionaries.com/en/mp3/row_gb_1.mp3',
                                        dialects: [
                                            'British English',
                                        ],
                                        phoneticNotation: 'IPA',
                                        phoneticSpelling: 'rəʊ',
                                    },
                                ],
                                senses: [
                                    {
                                        definitions: [
                                            'a number of people or things in a more or less straight line',
                                        ],
                                        examples: [
                                            {
                                                text: 'her villa stood in a row of similar ones',
                                            },
                                        ],
                                        id: 'm_en_gbus0885130.005',
                                        short_definitions: [
                                            'several people or things in more or less straight line',
                                        ],
                                        subsenses: [
                                            {
                                                definitions: [
                                                    'a line of seats in a theatre',
                                                ],
                                                examples: [
                                                    {
                                                        text: 'they sat in the front row',
                                                    },
                                                ],
                                                id: 'm_en_gbus0885130.008',
                                                short_definitions: [
                                                    'line of seats in theatre',
                                                ],
                                                thesaurusLinks: [
                                                    {
                                                        entry_id: 'row',
                                                        sense_id: 't_en_gb0012754.002',
                                                    },
                                                ],
                                            },
                                            {
                                                definitions: [
                                                    'a street with a continuous line of houses along one or both of its sides',
                                                ],
                                                examples: [
                                                    {
                                                        text: 'he lives at 23 Saville Row',
                                                    },
                                                ],
                                                id: 'm_en_gbus0885130.009',
                                                notes: [
                                                    {
                                                        text: 'often in place names',
                                                        type: 'grammaticalNote',
                                                    },
                                                ],
                                                short_definitions: [
                                                    'street with continuous line of houses along one',
                                                ],
                                            },
                                            {
                                                definitions: [
                                                    'a horizontal line of entries in a table',
                                                ],
                                                examples: [
                                                    {
                                                        text: 'visualize the subject in the form of a sheet of paper divided into columns and rows',
                                                    },
                                                ],
                                                id: 'm_en_gbus0885130.010',
                                                short_definitions: [
                                                    'horizontal line of entries in table',
                                                ],
                                            },
                                            {
                                                definitions: [
                                                    'a complete line of stitches in knitting or crochet.',
                                                ],
                                                domains: [
                                                    'Knitting',
                                                ],
                                                id: 'm_en_gbus0885130.011',
                                                short_definitions: [
                                                    'complete line of stitches in knitting or crochet',
                                                ],
                                            },
                                        ],
                                        thesaurusLinks: [
                                            {
                                                entry_id: 'row',
                                                sense_id: 't_en_gb0012754.001',
                                            },
                                        ],
                                    },
                                ],
                            },
                            {
                                grammaticalFeatures: [
                                    {
                                        text: 'Singular',
                                        type: 'Number',
                                    },
                                ],
                                homographNumber: '201',
                                pronunciations: [
                                    {
                                        audioFile: 'http://audio.oxforddictionaries.com/en/mp3/row_gb_1.mp3',
                                        dialects: [
                                            'British English',
                                        ],
                                        phoneticNotation: 'IPA',
                                        phoneticSpelling: 'rəʊ',
                                    },
                                ],
                                senses: [
                                    {
                                        definitions: [
                                            'a spell of rowing.',
                                        ],
                                        domains: [
                                            'Rowing',
                                        ],
                                        id: 'm_en_gbus0885140.018',
                                        short_definitions: [
                                            'spell of rowing',
                                        ],
                                    },
                                ],
                            },
                            {
                                etymologies: [
                                    'mid 18th century: of unknown origin',
                                ],
                                grammaticalFeatures: [
                                    {
                                        text: 'Singular',
                                        type: 'Number',
                                    },
                                ],
                                homographNumber: '300',
                                pronunciations: [
                                    {
                                        audioFile: 'http://audio.oxforddictionaries.com/en/mp3/row_gb_2.mp3',
                                        dialects: [
                                            'British English',
                                        ],
                                        phoneticNotation: 'IPA',
                                        phoneticSpelling: 'raʊ',
                                    },
                                ],
                                senses: [
                                    {
                                        definitions: [
                                            'a noisy acrimonious quarrel',
                                        ],
                                        examples: [
                                            {
                                                text: 'they had a row and she stormed out of the house',
                                            },
                                        ],
                                        id: 'm_en_gbus0885150.006',
                                        regions: [
                                            'British',
                                        ],
                                        registers: [
                                            'informal',
                                        ],
                                        short_definitions: [
                                            'noisy acrimonious quarrel',
                                        ],
                                        subsenses: [
                                            {
                                                definitions: [
                                                    'a serious dispute',
                                                ],
                                                examples: [
                                                    {
                                                        text: 'the director is at the centre of a row over policy decisions',
                                                    },
                                                ],
                                                id: 'm_en_gbus0885150.009',
                                                regions: [
                                                    'British',
                                                ],
                                                registers: [
                                                    'informal',
                                                ],
                                                short_definitions: [
                                                    'serious dispute',
                                                ],
                                            },
                                            {
                                                definitions: [
                                                    'a severe reprimand',
                                                ],
                                                examples: [
                                                    {
                                                        text: 'I always got a row if I left food on my plate',
                                                    },
                                                ],
                                                id: 'm_en_gbus0885150.010',
                                                regions: [
                                                    'British',
                                                ],
                                                registers: [
                                                    'informal',
                                                ],
                                                short_definitions: [
                                                    'severe reprimand',
                                                ],
                                                thesaurusLinks: [
                                                    {
                                                        entry_id: 'row',
                                                        sense_id: 't_en_gb0012755.003',
                                                    },
                                                ],
                                            },
                                        ],
                                        thesaurusLinks: [
                                            {
                                                entry_id: 'row',
                                                sense_id: 't_en_gb0012755.001',
                                            },
                                        ],
                                    },
                                    {
                                        definitions: [
                                            'a loud noise or uproar',
                                        ],
                                        examples: [
                                            {
                                                text: 'if he\'s at home he must have heard that row',
                                            },
                                        ],
                                        id: 'm_en_gbus0885150.012',
                                        regions: [
                                            'British',
                                        ],
                                        registers: [
                                            'informal',
                                        ],
                                        short_definitions: [
                                            'loud noise or uproar',
                                        ],
                                        thesaurusLinks: [
                                            {
                                                entry_id: 'row',
                                                sense_id: 't_en_gb0012755.002',
                                            },
                                        ],
                                    },
                                ],
                            },
                        ],
                        language: 'en',
                        lexicalCategory: 'Noun',
                        text: 'row',
                    },
                    {
                        entries: [
                            {
                                etymologies: [
                                    'Old English rōwan, of Germanic origin; related to rudder; from an Indo-European root shared by Latin remus ‘oar’, Greek eretmon ‘oar’',
                                ],
                                grammaticalFeatures: [
                                    {
                                        text: 'Transitive',
                                        type: 'Subcategorization',
                                    },
                                    {
                                        text: 'Present',
                                        type: 'Tense',
                                    },
                                ],
                                homographNumber: '200',
                                pronunciations: [
                                    {
                                        audioFile: 'http://audio.oxforddictionaries.com/en/mp3/row_gb_1.mp3',
                                        dialects: [
                                            'British English',
                                        ],
                                        phoneticNotation: 'IPA',
                                        phoneticSpelling: 'rəʊ',
                                    },
                                ],
                                senses: [
                                    {
                                        definitions: [
                                            'propel (a boat) with oars',
                                        ],
                                        domains: [
                                            'Rowing',
                                        ],
                                        examples: [
                                            {
                                                text: 'out in the bay a small figure was rowing a rubber dinghy',
                                            },
                                        ],
                                        id: 'm_en_gbus0885140.005',
                                        short_definitions: [
                                            'propel boat with oars',
                                        ],
                                        subsenses: [
                                            {
                                                definitions: [
                                                    'travel by rowing a boat',
                                                ],
                                                examples: [
                                                    {
                                                        text: 'we rowed down the river all day',
                                                    },
                                                ],
                                                id: 'm_en_gbus0885140.011',
                                                notes: [
                                                    {
                                                        text: 'no object, with adverbial of direction',
                                                        type: 'grammaticalNote',
                                                    },
                                                ],
                                                short_definitions: [
                                                    'travel by rowing boat',
                                                ],
                                            },
                                            {
                                                definitions: [
                                                    'convey (a passenger) in a boat by rowing it',
                                                ],
                                                examples: [
                                                    {
                                                        text: 'her father was rowing her across the lake',
                                                    },
                                                ],
                                                id: 'm_en_gbus0885140.012',
                                                short_definitions: [
                                                    'convey passenger in boat by rowing it',
                                                ],
                                            },
                                            {
                                                definitions: [
                                                    'engage in the sport of rowing, especially competitively',
                                                ],
                                                domains: [
                                                    'Rowing',
                                                ],
                                                examples: [
                                                    {
                                                        text: 'he rowed stroke in the University Eight',
                                                    },
                                                    {
                                                        text: 'he rowed for England',
                                                    },
                                                ],
                                                id: 'm_en_gbus0885140.013',
                                                notes: [
                                                    {
                                                        text: 'no object',
                                                        type: 'grammaticalNote',
                                                    },
                                                ],
                                                short_definitions: [
                                                    'engage in sport of rowing',
                                                ],
                                            },
                                        ],
                                    },
                                ],
                            },
                            {
                                grammaticalFeatures: [
                                    {
                                        text: 'Intransitive',
                                        type: 'Subcategorization',
                                    },
                                    {
                                        text: 'Present',
                                        type: 'Tense',
                                    },
                                ],
                                homographNumber: '301',
                                pronunciations: [
                                    {
                                        audioFile: 'http://audio.oxforddictionaries.com/en/mp3/row_gb_2.mp3',
                                        dialects: [
                                            'British English',
                                        ],
                                        phoneticNotation: 'IPA',
                                        phoneticSpelling: 'raʊ',
                                    },
                                ],
                                senses: [
                                    {
                                        definitions: [
                                            'have a quarrel',
                                        ],
                                        examples: [
                                            {
                                                text: 'they rowed about who would receive the money from the sale',
                                            },
                                            {
                                                text: 'she had rowed with her boyfriend the day before',
                                            },
                                        ],
                                        id: 'm_en_gbus0885150.020',
                                        regions: [
                                            'British',
                                        ],
                                        registers: [
                                            'informal',
                                        ],
                                        short_definitions: [
                                            'have quarrel',
                                        ],
                                        subsenses: [
                                            {
                                                definitions: [
                                                    'rebuke severely',
                                                ],
                                                examples: [
                                                    {
                                                        text: 'she was rowed for leaving her younger brother alone',
                                                    },
                                                ],
                                                id: 'm_en_gbus0885150.026',
                                                notes: [
                                                    {
                                                        text: 'with object',
                                                        type: 'grammaticalNote',
                                                    },
                                                ],
                                                regions: [
                                                    'British',
                                                ],
                                                registers: [
                                                    'informal',
                                                ],
                                                short_definitions: [
                                                    'rebuke severely',
                                                ],
                                            },
                                        ],
                                        thesaurusLinks: [
                                            {
                                                entry_id: 'row',
                                                sense_id: 't_en_gb0012755.004',
                                            },
                                        ],
                                    },
                                ],
                            },
                        ],
                        language: 'en',
                        lexicalCategory: 'Verb',
                        text: 'row',
                    },
                ],
                type: 'headword',
                word: 'row',
            },
        ],
    };
};

const correctHtmlOutputForRow = `
<div><span class="word">row </span><span class="word-superscript">¹</span></div>
<div>&zwnj;<span class="pronunciation">/rəʊ/</span> <span class="listen-icon"><a href="http://audio.oxforddictionaries.com/en/mp3/row_gb_1.mp3#audio">🔈</a></span></div>
<br>
<div>
    <span class="part-of-speech">noun</span>
    <div>
        <ol class="text">
            <li>
                <span class="definition">a number of people or things in a more or less straight line</span><br><span class="example-sent">her villa stood in a row of similar ones</span><br>
                <ul>
                    <li><span class="subdefinition">a line of seats in a theatre</span></li>
                    <li><span class="subdefinition">a street with a continuous line of houses along one or both of its sides</span></li>
                    <li><span class="subdefinition">a horizontal line of entries in a table</span></li>
                    <li><span class="subdefinition">a complete line of stitches in knitting or crochet.</span></li>
                </ul>
            </li>
        </ol>
    </div>
</div>
<br>
<div><span class="word">row </span><span class="word-superscript">²</span></div>
<div>&zwnj;<span class="pronunciation">/rəʊ/</span> <span class="listen-icon"><a href="http://audio.oxforddictionaries.com/en/mp3/row_gb_1.mp3#audio">🔈</a></span></div>
<br>
<div>
    <span class="part-of-speech">noun</span>
    <div>
        <ol class="text">
            <li><span class="definition">a spell of rowing.</span></li>
        </ol>
    </div>
    <br><span class="part-of-speech">verb</span>
    <div>
        <ol class="text">
            <li>
                <span class="definition">propel (a boat) with oars</span><br><span class="example-sent">out in the bay a small figure was rowing a rubber dinghy</span><br>
                <ul>
                    <li><span class="subdefinition">travel by rowing a boat</span></li>
                    <li><span class="subdefinition">convey (a passenger) in a boat by rowing it</span></li>
                    <li><span class="subdefinition">engage in the sport of rowing, especially competitively</span></li>
                </ul>
            </li>
        </ol>
    </div>
</div>
<br>
<div><span class="word">row </span><span class="word-superscript">³</span></div>
<div>&zwnj;<span class="sub-pop">INFORMAL</span> <span class="pronunciation">/raʊ/</span> <span class="listen-icon"><a href="http://audio.oxforddictionaries.com/en/mp3/row_gb_2.mp3#audio">🔈</a></span></div>
<br>
<div>
    <span class="part-of-speech">noun</span>
    <div>
        <ol class="text">
            <li>
                <span class="definition">a noisy acrimonious quarrel</span><br><span class="example-sent">they had a row and she stormed out of the house</span><br>
                <ul>
                    <li><span class="subdefinition">a serious dispute</span></li>
                    <li><span class="subdefinition">a severe reprimand</span></li>
                </ul>
            </li>
            <li><span class="definition">a loud noise or uproar</span><br><span class="example-sent">if he's at home he must have heard that row</span></li>
        </ol>
    </div>
    <br><span class="part-of-speech">verb</span>
    <div>
        <ol class="text">
            <li>
                <span class="definition">have a quarrel</span><br><span class="example-sent">they rowed about who would receive the money from the sale</span><br>
                <ul>
                    <li><span class="subdefinition">rebuke severely</span></li>
                </ul>
            </li>
        </ol>
    </div>
</div>
`;