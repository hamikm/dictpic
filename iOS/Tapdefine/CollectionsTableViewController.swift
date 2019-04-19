//
//  CollectionsTableViewController.swift
//  Tapdefine
//
//  Created by Hamik on 8/23/18.
//  Copyright © 2018 Hamik. All rights reserved.
//

import UIKit

protocol CollectionsTableViewControllerDelegate {
    func toggleTableViewModal()
    func performPostCloseAction(for row: Int)
    func getCurrentWord() -> String?
    func getPersistableDict() -> [String : NSAttributedString]?
    func didDelete(deck: String?, passDataToOtherTab: Bool)
    func didSelect(deck: String?, passDataToOtherTab: Bool)
    func setCollectionsListView(view: CollectionsTableViewController?)  // used to deselect row when modal closes
}

class CollectionsTableViewController: UITableViewController {

    static let DefaultCellHeight = CGFloat(44)
    static let DeletionPrompt = "Permanently delete {{deck-name}}?"
    static let SelectionPrompt = "Add {{current-word}} to this deck?"
    static let DefaultCardName = "this card"  // must be shorter than MaxPromptLength chars
    static let ShareString = "Share"
    static let DeleteString = "Delete"
    static let SharedAFileString = "Check out my Dictpic flashcard deck"
    static let MaxPromptLength = 10

    // Receive a reference to the main view controller so the cancel button will be able to close it by called a toggle function
    var collectionsTableDelegate: CollectionsTableViewControllerDelegate! {
        didSet {
            collectionsTableDelegate.setCollectionsListView(view: self)
        }
    }
    var selectionInEscrow: IndexPath?
    var popoverInEscrow: ConfirmationPopoverViewController?
    var popoverVCID = "confirmSelectionOptionsViewController"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Colors and style
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: Constants.DarkGray]
        tableView.backgroundColor = UIColor.clear
        tableView.separatorColor = Constants.LightGray
        
        // Misc.
        self.clearsSelectionOnViewWillAppear = true
        self.edgesForExtendedLayout = []
        self.extendedLayoutIncludesOpaqueBars = false
    }

    override func viewDidAppear(_ animated: Bool) {
        tableView.reloadData()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        deselectRow()
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return FlashcardCollections.GetCollectionNames()?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "collectionName", for: indexPath)

        // Set the text of this cell to the collection name at this row
        guard let collectionName = FlashcardCollections.GetCollectionName(at: indexPath.row) else {
            return cell
        }
        cell.textLabel?.text = collectionName
        cell.backgroundColor = UIColor.clear
        cell.textLabel?.textColor = Constants.DarkGray
        cell.textLabel?.font = cell.textLabel?.font.withSize(Constants.DefaultFontSize)
        
        // Make a custom line separator view
        let lineView = LineView()
        lineView.vertical = false
        lineView.backgroundColor = UIColor.clear
        
        // Position it with constraints
        cell.contentView.addSubview(lineView)
        (_, _) = lineView.snuglyConstrain(to: cell.contentView, leftAmount: Constants.SeparatorLeftRightMargin, rightAmount: Constants.SeparatorLeftRightMargin)
        (_, _) = lineView.snuglyConstrain(to: cell.contentView, toTop: cell.textLabel!, toBottom: cell.contentView, topAmount: -Constants.SeparatorViewWidth, bottomAmount: 0)

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectionInEscrow = indexPath
        popoverInEscrow = confirmationPopover(forCellAt: indexPath, forDeletion: false)
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {

        let shareAction = UITableViewRowAction(style: .normal, title: CollectionsTableViewController.ShareString) { (rowAction, indexPath) in

            // Get the collection name and collection
            guard let collectionName = FlashcardCollections.GetCollectionName(at: indexPath.row), let collection = FlashcardCollections.GetCollection(named: collectionName) else {
                print("Couldn't get collection or its name when sharing")
                return
            }

            let contents: [String : Any] = ["collectionName": collectionName, "collection": NSKeyedArchiver.archivedData(withRootObject: collection)]

            guard let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                print("Couldn't provision file for deck we're trying to share")
                return
            }

            let saveFileURL = path.appendingPathComponent("/\(collectionName).deck")
            
            guard (contents as NSDictionary).write(to: saveFileURL, atomically: true) else {
                print("Couldn't save deck to file")
                return
            }
            
            let activityViewController = UIActivityViewController(
                activityItems: [CollectionsTableViewController.SharedAFileString, saveFileURL], applicationActivities: nil)
            activityViewController.completionWithItemsHandler = {
                (activity, success, items, error) in
                do {
                    try FileManager.default.removeItem(at: saveFileURL)
                    print("File Removed from Documents Folder")
                } catch {
                    print("Failed to remove item from Documents Folder")
                }
            }
            if let popoverPresentationController = activityViewController.popoverPresentationController {
                popoverPresentationController.sourceRect = tableView.rectForRow(at: indexPath)
                popoverPresentationController.sourceView = tableView
            }

            self.present(activityViewController, animated: true, completion: nil)
            
            return
        }
        shareAction.backgroundColor = Constants.TabBarButtonActiveColor
        
        let deleteAction = UITableViewRowAction(style: .normal, title: CollectionsTableViewController.DeleteString) { (rowAction, indexPath) in
            
            self.selectionInEscrow = indexPath
            self.popoverInEscrow = self.confirmationPopover(forCellAt: indexPath, forDeletion: true)
        }
        deleteAction.backgroundColor = .red
        
        return [shareAction, deleteAction]
    }
    
    // MARK: accept shared flashcard collections
    static func ImportData(from url: URL) -> String? {
        
        guard let uncastCollectionInfo = NSDictionary(contentsOf: url), let collectionInfo = uncastCollectionInfo as? [String: Any], let collectionName = collectionInfo["collectionName"] as? String, let collectionAsData = collectionInfo["collection"] as? Data, let collection = NSKeyedUnarchiver.unarchiveObject(with: collectionAsData) as? [[String: NSAttributedString]] else {
            print("Could not import from", url)
            return nil
        }
        
        FlashcardCollections.AddCollection(named: collectionName, containing: collection)
        
        do {
            try FileManager.default.removeItem(at: url)
            return collectionName
        } catch {
            print("Failed to remove item from inbox")
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        // Done in tableView(_:editActionsForRowAt)
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return CollectionsTableViewController.DefaultCellHeight
    }
    
    func confirmationPopover(forCellAt indexPath: IndexPath, forDeletion: Bool) -> ConfirmationPopoverViewController? {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let optionsVC = storyboard.instantiateViewController(
            withIdentifier: popoverVCID) as? ConfirmationPopoverViewController else {
                print("Error getting the confirmation popover")
                return nil
        }
        guard let collectionName = FlashcardCollections.GetCollectionName(at: indexPath.row) else {
            return optionsVC
        }
        
        // Set basic popover properties
        optionsVC.modalPresentationStyle = .popover
        optionsVC.popoverPresentationController?.delegate = self
        optionsVC.popoverPresentationController?.sourceView = self.view
        
        // Set the popover's anchor (the arrow that points to where the popover came from)
        let sourceRect = tableView.rectForRow(at: indexPath)
        optionsVC.popoverPresentationController?.sourceRect = sourceRect
        
        // Set size
        let containerWidth = view.frame.width
        let popoverWidth = containerWidth - 2 * Constants.LeftRightMarginDefViewSpacing
        let popoverHeight = CGFloat(100)
        optionsVC.preferredContentSize = CGSize(width: popoverWidth, height: popoverHeight)
        
        // Set popover content properties
        optionsVC.usedWidth = popoverWidth
        optionsVC.usedHeight = popoverHeight
        optionsVC.callerRef = self
        optionsVC.selectionName = collectionName
        if forDeletion {
            optionsVC.prompt = CollectionsTableViewController.DeletionPrompt.replacingOccurrences(of: "{{deck-name}}", with: collectionName.abbreviateWithDots(after: CollectionsTableViewController.MaxPromptLength))
            optionsVC.popoverType = .delete
        } else {
            optionsVC.prompt = CollectionsTableViewController.SelectionPrompt.replacingOccurrences(of: "{{current-word}}", with: (collectionsTableDelegate.getCurrentWord() ?? CollectionsTableViewController.DefaultCardName).abbreviateWithDots(after: CollectionsTableViewController.MaxPromptLength))
            optionsVC.popoverType = .select
        }
        
        // Present the view controller (in a popover)
        self.present(optionsVC, animated: true) {
            // Runs right after popover shows up
        }
        return optionsVC
    }

    func deselectRow() {
        if let index = self.tableView.indexPathForSelectedRow{
            tableView.deselectRow(at: index, animated: true)
        }
    }

    @IBAction func cancelButton(_ sender: Any) {
        deselectRow()
        collectionsTableDelegate.toggleTableViewModal()
    }
}

extension CollectionsTableViewController: UIPopoverPresentationControllerDelegate {
    // This is necessary to get the popover to display in the desired compact size
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
}

extension CollectionsTableViewController: DisplaysConfirmationPopover {
    func cancelHandler(for popoverType: PopoverType) {
        guard let popoverInEscrow = popoverInEscrow else {
            print("popoverInEscrow was never set. Probably missing some ConfirmationPopoverViewController inits")
            return
        }
        popoverInEscrow.dismiss(animated: true, completion: nil)
    }
    
    func okHandler(for popoverType: PopoverType) {
        guard let popoverInEscrow = popoverInEscrow else {
            print("popoverInEscrow was never set. Probably missing some ConfirmationPopoverViewController inits")
            return
        }
        guard let idx = selectionInEscrow?.row else {
            print("Selection wasn't put into escrow before calling confirmation popover")
            popoverInEscrow.dismiss(animated: true, completion: nil)
            return
        }

        switch popoverType {
        case .select:  // create flashcard and save it in search mode. Select deck in study mode
            guard let flashcard = collectionsTableDelegate.getPersistableDict() else {
                print("Could not save flashcard")
                return
            }
            _ = FlashcardCollections.AddFlashcard(at: idx, containing: flashcard)
            collectionsTableDelegate.toggleTableViewModal()
            collectionsTableDelegate.didSelect(deck: popoverInEscrow.selectionName, passDataToOtherTab: true)
        case .delete:  // delete this deck of flashcards
            FlashcardCollections.RemoveCollection(at: idx)
            tableView.reloadData()
            collectionsTableDelegate.didDelete(deck: popoverInEscrow.selectionName, passDataToOtherTab: true)
        }
        popoverInEscrow.dismiss(animated: true, completion: nil)
    }
}
