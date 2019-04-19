//
//  StudyCollectionsTableViewController.swift
//  Tapdefine
//
//  Created by Hamik on 9/20/18.
//  Copyright © 2018 Hamik. All rights reserved.
//

import UIKit

class StudyCollectionsTableViewController: CollectionsTableViewController {
    
    override var tabBarController: UITabBarController? {
        return nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        popoverVCID = "studyConfirmSelectionOptionsViewController"
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        collectionsTableDelegate.toggleTableViewModal()
        collectionsTableDelegate.performPostCloseAction(for: indexPath.row)
    }
    
    func refreshViewController() {
        tableView.reloadData()
    }
}
