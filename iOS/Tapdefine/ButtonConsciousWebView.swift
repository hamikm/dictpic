//
//  MyWebView.swift
//  Tapdefine
//
//  Created by Hamik on 7/10/18.
//  Copyright © 2018 Hamik. All rights reserved.
//

import UIKit
import WebKit

class ButtonConsciousWebView: WKWebView{
    var viewController: DefinitionViewController?

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        setNavigationButtonEnableFlags()
    }
}

extension ButtonConsciousWebView: WKNavigationDelegate {
    
    func setNavigationButtonEnableFlags() {
        if canGoBack {
            viewController?.mainLeftNavEnabled = true
        } else {
            viewController?.mainLeftNavEnabled = false
        }
        
        if canGoForward {
            viewController?.mainRightNavEnabled = true
        } else {
            viewController?.mainRightNavEnabled = false
        }
    }
}
