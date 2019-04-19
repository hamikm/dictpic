//
//  GoogleDefinitionViewController.swift
//  Tapdefine
//
//  Created by Hamik on 7/24/18.
//  Copyright © 2018 Hamik. All rights reserved.
//

import UIKit
import Foundation
import WebKit

class GoogleDefinitionViewController: DefinitionViewController {

    // MARK: - Static variables
    static let GoogleSearchURLTemplate = "https://www.google.com/search?q={{term}}"

    override func viewDidLoad() {

        // Superclass doesn't have webview. Init here so superclass viewDidLoad can initContent
        initializeWebView()

        super.viewDidLoad()

        navbarTitle.title = "Google"
        hideUnneededViews()
    }

    func hideUnneededViews() {
        textview.isHidden = true
        rightLanguageButton.isEnabled = false
        rightLanguageButton.tintColor = UIColor.clear
    }

    override func refresh() {
        if jsonHandler == nil {
            print("Error: jsonHandler hasn't been initialized yet")
            return
        }

        loadGoogleSearchFor(term: currentWord)
    }
    
    override func persistenceKey() -> String? {
        return nil  // nil because we don't want to persist a google search
    }
}

// MARK: - Webview stuff
extension GoogleDefinitionViewController {

    func loadGoogleSearchFor(term: String) {
        let urlString = GoogleDefinitionViewController.GoogleSearchURLTemplate.replacingOccurrences(of: "{{term}}", with: term)

        guard let encodedURLString = urlString.stringByAddingPercentEncodingForRFC3986, let url = URL(string: encodedURLString) else {
            print("Error: could not form valid URL")
            return
        }

        let request = URLRequest(url: url)
        print("Loading URL", url)
        webview.load(request)
    }


    func initializeWebView() {
        // Initialize webview with config that includes hash reader
        webview = ButtonConsciousWebView(frame: CGRect.zero, configuration: getConfigWithURLObserverOnTimer())
        blurSubview.addSubview(webview)

        // Set up navigation delegates
        webview.viewController = self
        webview.navigationDelegate = webview

        // Set up constraints
        (_, _) = webview.snuglyConstrain(to: blurSubview, leftAmount: 0, rightAmount: 0)
        (_, _) = webview.snuglyConstrain(to: blurSubview, toTop: navbar, toBottom: blurSubview, topAmount: 0, bottomAmount: 0)
        
        loadGoogleSearchFor(term: currentWord)
    }
}

// MARK: - Handlers for buttons
extension GoogleDefinitionViewController {

    @IBAction func handleLeftArrow(_ sender: UIBarButtonItem) {
        if webview.canGoBack {
            webview.goBack()
        } else {
            print("Error: webview can't go back!")
        }
    }

    @IBAction func handleRightArrow(_ sender: UIBarButtonItem) {
        if webview.canGoForward {
            webview.goForward()
        } else {
            print("Error: webview can't go forward!")
        }
    }
}
