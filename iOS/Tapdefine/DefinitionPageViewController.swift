//
//  DefinitionPageViewController.swift
//  Tapdefine
//
//  Created by Hamik on 6/25/18.
//  Copyright © 2018 Hamik. All rights reserved.
//

import UIKit

protocol DefinitionPageViewControllerDelegate {
    func vanillaVCSelected()
    func wikipediaVCSelected()
    func translationVCSelected()
    func isExpanded() -> Bool
}

class DefinitionPageViewController: UIPageViewController {
    
    var currentWord = Constants.DefaultWord {
        didSet {
            if currentWord != "" {
                orderedViewControllers.forEach { viewController in
                    if let castVC = viewController as? DefinitionViewController {
                        castVC.currentWord = currentWord
                    }
                }
            }
        }
    }
    
    var expandDefinitionViewFunc: (() -> Void)? {
        didSet {
            orderedViewControllers.forEach { viewController in
                if let castVC = viewController as? DefinitionViewController {
                    castVC.expandDefinitionViewFunc = expandDefinitionViewFunc
                }
            }
        }
    }
    
    var contractDefinitionViewFunc: (() -> Void)? {
        didSet {
            orderedViewControllers.forEach { viewController in
                if let castVC = viewController as? DefinitionViewController {
                    castVC.contractDefinitionViewFunc = contractDefinitionViewFunc
                }
            }
        }
    }
    
    var manualEntryUpdateFunc: ((String?, Bool) -> Void)? {
        didSet {
            orderedViewControllers.forEach { viewController in
                if let castVC = viewController as? DefinitionViewController {
                    castVC.manualEntryUpdateFunc = manualEntryUpdateFunc
                }
            }
        }
    }

    var expanded = false {
        didSet {
            orderedViewControllers.forEach { viewController in
                if let castVC = viewController as? DefinitionViewController {
                    castVC.expanded = expanded
                }
            }
        }
    }
    
    var definitionVCDelegate: DefinitionViewControllerDelegate! {
        didSet {
            orderedViewControllers.forEach { viewController in
                if let castVC = viewController as? DefinitionViewController {
                    castVC.myDelegate = definitionVCDelegate
                }
            }
        }
    }
    
    var vanillaVC: VanillaDefinitionViewController!
    var wikipediaVC: WikipediaDefinitionViewController!
    var translateVC: TranslateDefinitionViewController!
    var definitionPVCDelegate: DefinitionPageViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        dataSource = self
        delegate = self
        
        // Instantiate all the view controllers so (1) there's no lag on first swipe and (2) content isn't nil for pages 2 and 3 when flashcard is saved
        orderedViewControllers.forEach { viewController in
            viewController.view.layoutSubviews()
        }
        
        if let firstViewController = orderedViewControllers.first {
            setViewControllers([firstViewController], direction: .forward, animated: true, completion: nil)
        }
        
        vanillaVC = orderedViewControllers[0] as? VanillaDefinitionViewController
        wikipediaVC = orderedViewControllers[1] as? WikipediaDefinitionViewController
        translateVC = orderedViewControllers[2] as? TranslateDefinitionViewController
        
        expanded = definitionPVCDelegate?.isExpanded() ?? false
    }
    
    private var orderedViewControllers: [UIViewController] = [
        UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "VanillaDefinition"),
        UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "WikipediaDefinition"),
        UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TranslateDefinition"),
    ]
    
    func getPersistableDict() -> [String: NSAttributedString] {
        var rtn: [String: NSAttributedString] = [FlashcardCollections.WordAttributeName : NSAttributedString(string: currentWord)]
        orderedViewControllers.forEach { viewController in
            if let castVC = viewController as? DefinitionViewController, let key = castVC.persistenceKey() {
                rtn[key] = castVC.getPersistableAttributedText()
            }
        }
        return rtn
    }
    
    func someAggregatedSearchParams() -> [String: Any] {
        return [
            "definitionLanguageCode": self.vanillaVC.getRightSelectedLanguage(),
            "wikipediaLanguageCode": self.wikipediaVC.getRightSelectedLanguage(),
            "languageRegion": self.vanillaVC.getRightSelectedRegion(),
            "sourceLanguage": self.translateVC.getLeftSelectedLanguage(),
            "targetLanguage": self.translateVC.getRightSelectedLanguage()
        ]
    }
    
    func fanOutDefinitionSearch(response results: [String: Any]) {

        if let definitionStr: String = Utilities.GetProp(named: "definition", from: results), let definition = Utilities.ConvertToDictionary(text: definitionStr) {
            vanillaVC.jsonHandler!(definition)
        }
        if let wikipediaIntroStr: String = Utilities.GetProp(named: "wikipediaIntroduction", from: results), let wikipediaIntro = Utilities.ConvertToDictionary(text: wikipediaIntroStr) {
            wikipediaVC.jsonHandler!(wikipediaIntro)
        }
        if let translationStr: String = Utilities.GetProp(named: "translation", from: results), let translation = Utilities.ConvertToDictionary(text: translationStr) {
            translateVC.jsonHandler!(translation)
        }
    }
    
    func getDefinitionViewNavbarHeight() -> CGFloat {
        return vanillaVC.navbar.frame.height
    }

    func getHeightOfTransparentPagingPart() -> CGFloat {
        return view.frame.height - vanillaVC.baseview.frame.height
    }
}

// MARK: UIPageViewControllerDataSource
extension DefinitionPageViewController: UIPageViewControllerDataSource {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.index(of: viewController) else {
            return nil
        }
        
        let previousIndex = viewControllerIndex - 1
        
        guard previousIndex >= 0 else {
            return nil
        }
        
        guard orderedViewControllers.count > previousIndex else {
            return nil
        }
        
        return orderedViewControllers[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.index(of: viewController) else {
            return nil
        }
        
        let nextIndex = viewControllerIndex + 1
        let orderedViewControllersCount = orderedViewControllers.count
        
        guard orderedViewControllersCount != nextIndex else {
            return nil
        }
        
        guard orderedViewControllersCount > nextIndex else {
            return nil
        }
        
        return orderedViewControllers[nextIndex]
    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return orderedViewControllers.count
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        guard let firstViewController = viewControllers?.first, let firstViewControllerIndex = orderedViewControllers.index(of: firstViewController) else {
                return 0
        }
        
        return firstViewControllerIndex
    }
}

extension DefinitionPageViewController: UIPageViewControllerDelegate {

    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        
        if finished && completed {
            // Tell search view controller we paged so it can handle tutorial stuff
            if let pvcDelegate = definitionPVCDelegate, let currentVC = viewControllers?.first {
                switch currentVC {
                case vanillaVC:
                    pvcDelegate.vanillaVCSelected()
                case wikipediaVC:
                    pvcDelegate.wikipediaVCSelected()
                case translateVC:
                    pvcDelegate.translationVCSelected()
                default:
                    print("Paged to unknown view controller")
                }
            }
        }
    }
}
