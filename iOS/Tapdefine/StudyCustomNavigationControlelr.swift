//
//  StudyCustomNavigationControlelr.swift
//  Tapdefine
//
//  Created by Hamik on 9/21/18.
//  Copyright © 2018 Hamik. All rights reserved.
//

import UIKit

class StudyCustomNavigationController: UINavigationController {

    // Just pass along a reference to the main view controller so the cancel button will be able to close it by called a toggle function
    var masterViewController: CollectionsTableViewControllerDelegate! {
        didSet {
            let myNextView = childViewControllers[0] as? StudyCollectionsTableViewController
            myNextView?.masterViewController = masterViewController
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationBar.tintColor = Constants.TabBarButtonActiveColor
    }
}
