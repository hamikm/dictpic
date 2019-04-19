//
//  CustomNavigationController.swift
//  Tapdefine
//
//  Created by Hamik on 8/23/18.
//  Copyright © 2018 Hamik. All rights reserved.
//

import UIKit

class CustomNavigationController: UINavigationController {
    
    override var tabBarController: UITabBarController? {
        return nil
    }
    
    // Just pass along a reference to the main view controller so the cancel button will be able to close it by called a toggle function
    var collectionsTableDelegate: CollectionsTableViewControllerDelegate! {
        didSet {
            let myNextView = childViewControllers[0] as? CollectionsTableViewController
            myNextView?.collectionsTableDelegate = collectionsTableDelegate
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationBar.tintColor = Constants.TabBarButtonActiveColor
    }
}
