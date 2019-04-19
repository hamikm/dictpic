//
//  TabBarViewController.swift
//  Tapdefine
//
//  Created by Hamik on 8/25/18.
//  Copyright © 2018 Hamik. All rights reserved.
//

import UIKit

class TabBarViewController: UITabBarController {

    static let SearchTabTagAndIndex = 0
    static let StudyTabTagAndIndex = 1
    
    var searchVC: ViewController?
    var studyVC: StudyViewController?
    var lastTabTag = TabBarViewController.SearchTabTagAndIndex
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // More init here
        tabBar.items?.forEach({ currItem in
            currItem.imageInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        })
        
        tabBar.tintColor = Constants.TabBarButtonActiveColor
        tabBar.isTranslucent = true
        
        searchVC = self.viewControllers?[TabBarViewController.SearchTabTagAndIndex] as? ViewController
        studyVC = self.viewControllers?[TabBarViewController.StudyTabTagAndIndex] as? StudyViewController
    }
    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        
        guard item.tag != lastTabTag else {
            print("Already on that tab")
            return
        }
        
        switch item.tag {
        case TabBarViewController.SearchTabTagAndIndex:
            print("Selected search tab")
            lastTabTag = item.tag
        case TabBarViewController.StudyTabTagAndIndex:
            print("Selected study tab")
            studyVC?.comingFromAnotherTab()
            lastTabTag = item.tag
            if let tutorial = searchVC?.tutorial{
                _ = tutorial.completed(action: .flashcardsTap)
            }
        default:
            print("Tab tag misconfigured")
        }
    }
}
