//
//  BrowserNavigator.swift
//  Tapdefine
//
//  Created by Hamik on 7/23/18.
//  Copyright © 2018 Hamik. All rights reserved.
//

import UIKit

class BrowserNavigator: NSObject {
    static let MaxCapacity = 50
    
    var backwardStack = [[String: String]]()
    var currentPage: [String: String]!
    var forwardStack = [[String: String]]()
    
    func displayed(data: [String: String]) {
        if currentPage != nil {
            backwardStack.append(currentPage)
        }
        currentPage = data
        forwardStack = [[String: String]]()
        
        // If more than max capacity number of stored pages, ditch the first half of them
        if backwardStack.count + 1 > BrowserNavigator.MaxCapacity {
            backwardStack.removeSubrange(0 ..< BrowserNavigator.MaxCapacity / 2)
        }
    }
    
    func goBack() -> [String: String]? {
        guard let oneBack = backwardStack.popLast() else {
            print("error! backward stack countains nothing")
            return nil
        }
        forwardStack.append(currentPage)
        currentPage = oneBack
        return currentPage
    }
    
    func goForward() -> [String: String]? {
        guard let oneForward = forwardStack.popLast() else {
            print("error! forward stack countains nothing")
            return nil
        }
        backwardStack.append(currentPage)
        currentPage = oneForward
        return currentPage
    }
    
    func canGoBack() -> Bool {
        return backwardStack.count > 0
    }
    
    func canGoForward() -> Bool {
        return forwardStack.count > 0
    }
}
