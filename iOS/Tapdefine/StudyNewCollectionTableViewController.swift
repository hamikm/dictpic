//
//  StudyNewCollectionTableViewController.swift
//  Tapdefine
//
//  Created by Hamik on 9/22/18.
//  Copyright © 2018 Hamik. All rights reserved.
//

import UIKit

class StudyNewCollectionTableViewController: NewCollectionTableViewController {

    override func handleInputStateDidSet() {
        // Do reloads manually
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppearHook() {
        // popKeyboardAndStartEditing is called manually in study mode because this view controller isn't on a navigation stack
    }
    
    // MARK: Make a new deck, returning true if no error, false if error
    func createNewDeck() -> String? {
        let name = getCollectionName()
        
        if name.count == 0 {
            print("Empty new deck name")
            inputState = .nameCannotBeEmpty
            tableView.reloadData()
            return nil
        } else if let alreadySaw = FlashcardCollections.CollectionNamesContains(name: name), alreadySaw {
            print("Already saw that collection name")
            inputState = .nameAlreadyExists
            tableView.reloadData()
            return nil
        } else if (FlashcardCollections.IsCollisionFor(collectionName: name)) {
            print("Collision in user defaults")
            inputState = .userDefaultsKeyCollision
            tableView.reloadData()
            return nil
        } else {  // otherwise not in collection names and not a key in UD, so make new collection
            print("Making new flashcard collection")
            FlashcardCollections.AddCollection(named: name)
            inputState = .good
            return name
        }
    }
    
    func resetEverything() {
        setCollectionName(to: "")
        inputState = .good
        tableView.reloadData()
    }
}
