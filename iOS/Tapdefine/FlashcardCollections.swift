//
//  FlashcardCollections.swift
//  Tapdefine
//
//  Created by Hamik on 8/24/18.
//  Copyright © 2018 Hamik. All rights reserved.
//

import UIKit

// MARK: - naive, horrible version of flashcard persistence using user defaults
struct FlashcardCollections {

    // MARK: - Standard attribute names for cards
    static let WordAttributeName = "word"
    static let DefinitionAttributeName = "definition"
    static let WikipediaAttributeName = "wikipedia"
    static let TranslationAttributeName = "translation"
    static let UserSuppliedContentsAttributeName = "user_contents"
    static let UuidAttributeName = "uuid"
    static let DatTName = "t"
    static let TutorialStepName = "leftOffAtThisTutorialStep"
    static let DoneWithTutorialFlagName = "tutorialFinished"
    
    // MARK: - Sample Deck
    static let SampleDeckName = "Sample Deck"
    static let SampleDefinitionBody = """
        <div><span class=\"word\">terrier </span><span class=\"word-superscript\">¹</span></div><div>&zwnj;<span class=\"pronunciation\">/ˈtɛriər/</span> <span class=\"listen-icon\"><a href=\"http://audio.oxforddictionaries.com/en/mp3/terrier_us_1.mp3#audio\">🔈</a></span></div><br><div><span class=\"part-of-speech\">noun</span><div><ol class=\"text\"><li><span class=\"definition\">a small dog of a breed originally used for turning out foxes and other burrowing animals from their lairs.</span><br><ul><li><span class=\"subdefinition\">used in similes to emphasize tenacity or eagerness</span></li></ul></li></ol></div></div><br><div><span class=\"word\">terrier </span><span class=\"word-superscript\">²</span></div><div>&zwnj;<span class=\"sub-pop\">HISTORICAL</span></div><br><div><span class=\"part-of-speech\">noun</span><div><ol class=\"text\"><li><span class=\"definition\">a register of the lands belonging to a landowner, originally including a list of tenants, their holdings, and the rents paid, later consisting of a description of the acreage and boundaries of the property.</span><br><ul><li><span class=\"subdefinition\">an inventory of property or goods.</span></li></ul></li></ol></div></div>
    """
    static let SampleWikipediaBody = """
        <div class="introcontent">
            <p>A <b>terrier</b> is a dog of any one of many breeds or landraces of the terrier type, which are typically small, wiry and fearless. Terrier breeds vary greatly in size from just 1 kg (2 lb) to over 32 kg (70 lb) and are usually categorized by size or function. There are five different groups, with each group having several different breeds.
            </p>
        </div>
    """
    static let SampleTranslateBody = """
        <span class="language">English 👉 French</span>
        <br><br>
        <span class="text"><p class="text">terrier</p></span>
    """
    static let SampleDeck: [[String: NSAttributedString]] = [
        [
            WordAttributeName: NSAttributedString(string: "Welcome!"),
            UserSuppliedContentsAttributeName: Constants.ContentTemplate.replacingOccurrences(of: "{{more-style}}", with: StudyViewController.UserDefinedCardStyle).replacingOccurrences(of: "{{body}}", with: "<div class=\"text\">You just flipped this card to its definition side.<br><br>Swipe to go to the next card. Swiping <b>left</b> means you still want to review your card - it will stay in the study deck.<br><br>Swiping <b>right</b> means you've learned it - it will be removed from your study deck, but you can always bring it back later.</div>").htmlToAttributedString!
        ],
        [
            WordAttributeName: NSAttributedString(string: "Create cards"),
            UserSuppliedContentsAttributeName: Constants.ContentTemplate.replacingOccurrences(of: "{{more-style}}", with: StudyViewController.UserDefinedCardStyle).replacingOccurrences(of: "{{body}}", with: "<div class=\"text\">Click the add button above to make a card.<br><br>Instead of swiping left or right, you can tap the buttons below.</div>").htmlToAttributedString!
        ],
        [
            WordAttributeName: NSAttributedString(string: "Create cards faster"),
            UserSuppliedContentsAttributeName: Constants.ContentTemplate.replacingOccurrences(of: "{{more-style}}", with: StudyViewController.UserDefinedCardStyle).replacingOccurrences(of: "{{body}}", with: "<div class=\"text\">When you look up a word, click the bookmark button to save it to a deck.<br><br>The next card shows what happens when you look up \"terrier\" and bookmark it.</div>").htmlToAttributedString!
        ],
        [
            WordAttributeName: NSAttributedString(string: "Terrier"),
            DefinitionAttributeName: Constants.ContentTemplate.replacingOccurrences(of: "{{more-style}}", with: VanillaDefinitionViewController.Style).replacingOccurrences(of: "{{body}}", with: SampleDefinitionBody).htmlToAttributedString!,
            WikipediaAttributeName: Constants.ContentTemplate.replacingOccurrences(of: "{{more-style}}", with: WikipediaDefinitionViewController.Style).replacingOccurrences(of: "{{body}}", with: SampleWikipediaBody).htmlToAttributedString!,
            TranslationAttributeName: Constants.ContentTemplate.replacingOccurrences(of: "{{more-style}}", with: TranslateDefinitionViewController.Style).replacingOccurrences(of: "{{body}}", with: SampleTranslateBody).htmlToAttributedString!
        ],
        [
            WordAttributeName: NSAttributedString(string: "Bring cards back"),
            UserSuppliedContentsAttributeName: Constants.ContentTemplate.replacingOccurrences(of: "{{more-style}}", with: StudyViewController.UserDefinedCardStyle).replacingOccurrences(of: "{{body}}", with: "<div class=\"text\">When you swipe right, your card is removed from the study deck. Swipe right when you've learned a word.<br><br>If you want the card back, press the back or back all button above.</div>").htmlToAttributedString!
        ],
        [
            WordAttributeName: NSAttributedString(string: "Review Reminders"),
            UserSuppliedContentsAttributeName: Constants.ContentTemplate.replacingOccurrences(of: "{{more-style}}", with: StudyViewController.UserDefinedCardStyle).replacingOccurrences(of: "{{body}}", with: "<div class=\"text\">Studies show that spaced repetition is the best way to learn.<br><br>After you've swiped right on all your cards, you can schedule a reminder to review your deck later.</div>").htmlToAttributedString!
        ],
        [
            WordAttributeName: NSAttributedString(string: "Deck Sharing"),
            UserSuppliedContentsAttributeName: Constants.ContentTemplate.replacingOccurrences(of: "{{more-style}}", with: StudyViewController.UserDefinedCardStyle).replacingOccurrences(of: "{{body}}", with: "<div class=\"text\">Try swiping left on a deck name in the Open menu. You can airdrop or share decks with your friends.</div>").htmlToAttributedString!
        ],
        [
            WordAttributeName: NSAttributedString(string: "Shuffle"),
            UserSuppliedContentsAttributeName: Constants.ContentTemplate.replacingOccurrences(of: "{{more-style}}", with: StudyViewController.UserDefinedCardStyle).replacingOccurrences(of: "{{body}}", with: "<div class=\"text\">Shuffle your deck to test your memory by tapping 🔀 above.</div>").htmlToAttributedString!
        ]
    ]
    
    // MARK: - Miscellaneous
    static let NoPersistenceDebugMode = false
    static let KeyForCollectionNamesArrayInUserDefaults = "flashcardCollections"
    
    static var UserDDB = UserDefaults.standard

    static func InitializeFlashcardCollections() {
        // If we're debugging...
        if NoPersistenceDebugMode {
            ResetCollections()
        } else {
            // If first launch, then make a new collection names array and add sample deck to it
            if AppDelegate.IsFirstLaunch() {
                UserDDB.set([], forKey: KeyForCollectionNamesArrayInUserDefaults)
                AddCollection(named: SampleDeckName, containing: SampleDeck)
            } else {
                print("Not first launch, so not making new collectionNames array or adding sample deck to it")
            }
        }
    }
    
    // MARK: Check user defaults to see if there's a key collision with the given name
    static func IsCollisionFor(collectionName name: String) -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        return UserDDB.object(forKey: trimmedName) != nil
    }
    
    // MARK: dangerous - wipe all collections, including the flashcards themselves, the collections that hold them, and the list of collection names. We're left with an empty array with key KeyForCollectionNamesDict
    private static func ResetCollections() {
        for name in (GetCollectionNames() ?? []) {
            RemoveCollection(named: name)
        }
    }

    static func CollectionNamesContains(name collectionName: String) -> Bool? {
        guard let collectionNames = GetCollectionNames() else {
            print("Collection names array wasn't initialized")
            return nil
        }
        let trimmedName = collectionName.trimmingCharacters(in: .whitespaces)
        return collectionNames.contains(trimmedName)
    }
    
    // MARK: Get all collection names
    static func GetCollectionNames() -> [String]? {
        return UserDDB.array(forKey: KeyForCollectionNamesArrayInUserDefaults) as? [String]
    }
    
    // MARK: Get the collection name at the given index
    static func GetCollectionName(at i: Int) -> String? {
        let collectionNames = GetCollectionNames() ?? []
        guard i >= 0, i < collectionNames.count else {
            return nil
        }
        return collectionNames[i]
    }
    
    // MARK: Get the flashcard array with the given name
    static func GetCollection(named collectionName: String) -> [[String: NSAttributedString]]? {
        let trimmedName = collectionName.trimmingCharacters(in: .whitespaces)
        if let flashcardsAsData = UserDDB.object(forKey: trimmedName) as? Data, let flashCardsAsArrayOfDicts = NSKeyedUnarchiver.unarchiveObject(with: flashcardsAsData) as? [[String: NSAttributedString]] {
            return flashCardsAsArrayOfDicts
        }
        return nil
    }
    
    static func GetLearnedCollection(named collectionName: String) -> [[String: NSAttributedString]]? {
        let trimmedName = collectionName.trimmingCharacters(in: .whitespaces)
        return GetCollection(named: "__" + trimmedName + "__")
    }
    
    // MARK: Add given collection name to array of collection names and create an empty array of flashcards keyed on the given name
    static func AddCollection(named collectionName: String, containing collection: [[String: NSAttributedString]]? = nil) {
        let trimmedName = collectionName.trimmingCharacters(in: .whitespaces)
        guard !IsCollisionFor(collectionName: trimmedName) else {
            print("There was a collection name collision in user defaults for", collectionName)
            return
        }
        
        var names = GetCollectionNames() ?? []
        names.append(trimmedName)
        
        // Add collection NAME
        UserDDB.set(names, forKey: KeyForCollectionNamesArrayInUserDefaults)
        
        // Make new array of flashcards keyed on collection name
        let newArray: [[String: NSAttributedString]] = []
        let newArrayAsData = NSKeyedArchiver.archivedData(withRootObject: newArray)
        UserDDB.set(newArrayAsData, forKey: trimmedName)
        
        // Make new array of learned flashcards
        let newLearnedArray: [[String: NSAttributedString]] = []
        let newLearnedArrayAsData = NSKeyedArchiver.archivedData(withRootObject: newLearnedArray)
        UserDDB.set(newLearnedArrayAsData, forKey: "__" + trimmedName + "__")
        
        if collection != nil {
            for card in collection! {
                _ = AddFlashcard(to: collectionName, containing: card)
            }
        }
    }
    
    static func ShuffleCollection(named name: String) -> String? {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard var collection = GetCollection(named: trimmedName) else {
            print("No collection \(name)")
            return nil
        }

        collection.shuffle()
        let collectionAsData = NSKeyedArchiver.archivedData(withRootObject: collection)
        UserDDB.set(collectionAsData, forKey: trimmedName)
        return trimmedName
    }
    
    // MARK: Move the flashcard at the given index in the given collection to the complementary learned collection
    static func LearnedFlashcard(at index: Int, in collectionName: String) {
        let trimmedName = collectionName.trimmingCharacters(in: .whitespaces)
        guard let flashcardRemovedFromCollection = RemoveFlashcard(at: index, in: trimmedName) else {
            print("Couldn't remove flashcard... returning")
            return
        }

        _ = AddFlashcard(to: "__" + trimmedName + "__", containing: flashcardRemovedFromCollection)
    }
    
    // MARK: Inverse of learnedFlashcard(at:in:)
    static func UnlearnedLastFlashcard(in collectionName: String) -> [String: NSAttributedString]? {
        let trimmedName = collectionName.trimmingCharacters(in: .whitespaces)
        guard let flashcardRemovedFromLearned = RemoveLastFlashcard(from: "__" + trimmedName + "__") else {
            print("Couldn't remove last flashcard... returning")
            return nil
        }

        _ = AddFlashcard(to: trimmedName, containing: flashcardRemovedFromLearned)
        return flashcardRemovedFromLearned
    }
    
    static func UnlearnedAllFlashcards(in collectionName: String) -> [[String: NSAttributedString]]? {
        let trimmedName = collectionName.trimmingCharacters(in: .whitespaces)
        while UnlearnedLastFlashcard(in: trimmedName) != nil {}
        return GetCollection(named: trimmedName)
    }
    
    // MARK: Add flashcard to COLLECTION at given index in list of collection names
    static func AddFlashcard(at i: Int, containing contents: [String: NSAttributedString]) -> String? {
        guard let collectionName = GetCollectionName(at: i) else {
            print("There is no collection with that name")
            return nil
        }

        return AddFlashcard(to: collectionName, containing: contents)
    }
    
    static func AddFlashcard(to collectionName: String, containing contents: [String: NSAttributedString]) -> String? {
        let trimmedName = collectionName.trimmingCharacters(in: .whitespaces)
        guard var collection = GetCollection(named: trimmedName) else {
            print("There is no collection with that name")
            return nil
        }
        
        let uuidRtn: String?
        if let oldUUIDStr = contents[UuidAttributeName]?.string {
            collection.append(contents)
            uuidRtn = oldUUIDStr
        } else {
            var augmentedContents = contents
            let newUuidStr = UUID().uuidString
            augmentedContents[UuidAttributeName] = NSAttributedString(string: newUuidStr)
            collection.append(augmentedContents)
            uuidRtn = newUuidStr
        }

        let collectionAsData = NSKeyedArchiver.archivedData(withRootObject: collection)
        UserDDB.set(collectionAsData, forKey: trimmedName)
        return uuidRtn
    }
    
    static func IndexOfCard(with uuidStr: String, in collectionName: String) -> Int? {
        let trimmedName = collectionName.trimmingCharacters(in: .whitespaces)
        guard var collection = GetCollection(named: trimmedName) else {
            print("There is no collection with that name")
            return nil
        }
        
        for i in 0..<collection.count {
            let currentCard = collection[i]
            if currentCard[UuidAttributeName]?.string.lowercased().trimmingCharacters(in: .whitespaces) == uuidStr.lowercased().trimmingCharacters(in: .whitespaces) {
                return i
            }
        }
        return nil
    }
    
    // MARK: Remove the collection name at the given index in the collection names array, as well as the collection of flashcards that the name keys
    static func RemoveCollection(at idx: Int) {
        var collectionNames = GetCollectionNames()
        let collectionName = collectionNames?.remove(at: idx)
        
        // Remove the collection of flashcards itself
        if let name = collectionName, let _ = UserDDB.object(forKey: name) {
            UserDDB.removeObject(forKey: name)
            
            let learnedComplementCollectionName = "__" + name + "__"
            if let _ = UserDDB.object(forKey: learnedComplementCollectionName) {
                UserDDB.removeObject(forKey: learnedComplementCollectionName)
            }
        }
        
        // Now remove the entry from the array of collection names
        UserDDB.set(collectionNames, forKey: KeyForCollectionNamesArrayInUserDefaults)
    }

    // MARK: find index of given collection name then call RemoveCollectino(at:)
    static func RemoveCollection(named collectionName: String) {
        let trimmedName = collectionName.trimmingCharacters(in: .whitespaces)
        if let idx = GetCollectionNames()?.firstIndex(of: trimmedName) {
            RemoveCollection(at: idx)
        }
    }
    
    static func RemoveFlashcard(at index: Int, in collectionName: String) -> [String: NSAttributedString]? {
        let trimmedName = collectionName.trimmingCharacters(in: .whitespaces)
        guard var collection = GetCollection(named: trimmedName) else {
            print("Couldn't find collection \(trimmedName)")
            return nil
        }
        guard index >= 0, index < collection.count else {
            print("Index out of bounds for card removal")
            return nil
        }
        
        let rtn = collection.remove(at: index)
        let collectionAsData = NSKeyedArchiver.archivedData(withRootObject: collection)
        UserDDB.set(collectionAsData, forKey: trimmedName)
        return rtn
    }
    
    static func RemoveLastFlashcard(from collectionName: String) -> [String: NSAttributedString]? {
        let trimmedName = collectionName.trimmingCharacters(in: .whitespaces)
        guard let collection = GetCollection(named: trimmedName) else {
            print("Couldn't find collection \(trimmedName)")
            return nil
        }
        guard collection.count > 0 else {
            print("Collection \(trimmedName) is already empty. Returning nil")
            return nil
        }
        
        return RemoveFlashcard(at: collection.count - 1, in: collectionName)
    }
    
    static func AddAttributeToFlashcard(in collectionName: String, at index: Int, named attributeName: String, containing contents: NSAttributedString) -> [String: NSAttributedString]? {
        let trimmedName = collectionName.trimmingCharacters(in: .whitespaces)
        guard var collection = GetCollection(named: trimmedName) else {
            print("Couldn't find collection \(trimmedName)")
            return nil
        }
        guard index >= 0, index < collection.count else {
            print("Index out of bounds for attribute addition")
            return nil
        }

        collection[index][attributeName] = contents
        let collectionAsData = NSKeyedArchiver.archivedData(withRootObject: collection)
        UserDDB.set(collectionAsData, forKey: trimmedName)
        
        return collection[index]
    }
    
    static func DatT() -> String? {
        return UserDDB.string(forKey: DatTName)
    }
    
    static func EatT(t: String) {
        UserDDB.set(t, forKey: DatTName)
    }
    
    static func SaveTutorialState(step: Int) {
        UserDDB.set(step, forKey: TutorialStepName)
    }
    
    // Returns zero if doesn't exist yet
    static func GetTutorialState() -> Int {
        return UserDDB.integer(forKey: TutorialStepName)
    }
    
    static func DoneWithTutorial() {
        UserDDB.set(true, forKey: DoneWithTutorialFlagName)
    }
    
    static func IsDoneWithTutorial() -> Bool {
        return UserDDB.bool(forKey: DoneWithTutorialFlagName)
    }
}
