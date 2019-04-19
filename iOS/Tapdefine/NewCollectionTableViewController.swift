//
//  NewCollectionTableViewController.swift
//  Tapdefine
//
//  Created by Hamik on 8/22/18.
//  Copyright © 2018 Hamik. All rights reserved.
//

import UIKit

enum InputState {
    case good, nameAlreadyExists, userDefaultsKeyCollision, nameCannotBeEmpty
}

class NewCollectionTableViewController: UITableViewController {

    static let CellTextMargin = CGFloat(10)
    static let AlreadyExistsString = "A deck with that name already exists"
    static let CollisionString = "Please choose a different name"
    static let NameCannotBeEmpty = "Name cannot be empty"
    
    @IBOutlet weak var collectionNameCell: UITableViewCell!
    @IBOutlet weak var cellContentView: UIView!
    @IBOutlet weak var cellTextField: UITextField!
    
    var inputState = InputState.good {
        didSet {
            handleInputStateDidSet()
        }
    }
    
    func handleInputStateDidSet() {
        tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up navbar
        let rightButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(self.handleDoneButton))
        self.navigationItem.rightBarButtonItem = rightButton
        self.navigationItem.title = "New Deck"

        // Colors
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: Constants.DarkGray]
        tableView.backgroundColor = UIColor.clear
        tableView.separatorColor = Constants.LightGray
        cellTextField.textColor = Constants.DarkGray
        cellTextField.font = cellTextField.font?.withSize(Constants.DefaultFontSize)
        collectionNameCell.backgroundColor = UIColor.clear
        
        // To silence warning about ambiguous cell height
        self.tableView.rowHeight = Constants.TableCellHeight
        
        // To put the text field inside the content view
        let (_, _) = cellTextField.snuglyConstrain(to: cellContentView, leftAmount: NewCollectionTableViewController.CellTextMargin, rightAmount: NewCollectionTableViewController.CellTextMargin)
        let (_, _) = cellTextField.snuglyConstrain(to: cellContentView, topAmount: 0, bottomAmount: 0)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        viewDidAppearHook()
    }
    
    func viewDidAppearHook() {
        popKeyboardAndStartEditing()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch inputState {
        case .good:
            return nil
        case .nameAlreadyExists:
            return NewCollectionTableViewController.AlreadyExistsString
        case .userDefaultsKeyCollision:
            return NewCollectionTableViewController.CollisionString
        case .nameCannotBeEmpty:
            return NewCollectionTableViewController.NameCannotBeEmpty
        }
    }
    
    @IBAction func startedToEdit() {
        // Set color back to dark gray in case it was set to red b/c of error
        cellTextField.textColor = Constants.DarkGray
        setCollectionName(to: getCollectionName())  // reassign to force color to update
    }
    
    func getCollectionName() -> String {
        return cellTextField.text ?? ""
    }
    
    func setCollectionName(to name: String) {
        cellTextField.text = name
    }

    @IBAction func handleReturnKey() {
        inputState = .good  // innocent until proven guilty
    }
    
    @objc func handleDoneButton() {
        let name = getCollectionName()

        if name.count == 0 {
            inputState = .nameCannotBeEmpty
        } else if let alreadySaw = FlashcardCollections.CollectionNamesContains(name: name), alreadySaw {
            inputState = .nameAlreadyExists
        } else if (FlashcardCollections.IsCollisionFor(collectionName: name)) {
            inputState = .userDefaultsKeyCollision
        } else {  // otherwise not in collection names and not a key in UD, so make new collection
            FlashcardCollections.AddCollection(named: name)
            setCollectionName(to: "")
            inputState = .good
            navigationController?.popViewController(animated: true)
        }
    }
    
    func popKeyboardAndStartEditing() {
        cellTextField.becomeFirstResponder()
    }
}
