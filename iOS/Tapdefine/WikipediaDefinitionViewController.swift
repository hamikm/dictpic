//
//  WikipediaDefinitionViewController.swift
//  Tapdefine
//
//  Created by Hamik on 6/25/18.
//  Copyright © 2018 Hamik. All rights reserved.
//

import UIKit
import Foundation
import WebKit

class WikipediaDefinitionViewController: DefinitionViewController {
    
    // MARK: - Static variables
    static let DefaultLanguage = Constants.DefaultLanguage
    static let SupportedLangs = Constants.DefaultSupportedLangs
    static let WikiWebpageURLTemplate = "https://{{lang-code}}.wikipedia.org/wiki/{{article-name}}"
    static let WikiPageidURLTemplate = "https://{{lang-code}}.m.wikipedia.org/?curid={{pageid}}"
    static let PreIntroBodyTemplate = "<div class=\"wikitemplate\">{{pre-intro-content}}</div>"
    static let IntroBodyTemplate = "<div class=\"introcontent\">{{intro-content}}</div>"
    static let NoArticleIntroStatusMessage = "💔 No article summary available. Expand by swiping up on Wikipedia title bar to see full article."

    static let Style = """
    a {
        color: #\(Constants.TabBarButtonActiveColor);
    }
    .wikitemplate {
        font-size: 9pt;
    }
    .introcontent {
        font-size: 11pt;
    }
    """

    static let DefaultIntro = """
    <p>A <b>terrier</b> is a dog of any one of many breeds or landraces of the terrier type, which are typically small, wiry and fearless. Terrier breeds vary greatly in size from just 1 kg (2 lb) to over 32 kg (70 lb) and are usually categorized by size or function. There are five different groups, with each group having several different breeds.
    </p>
    """

    static let DefaultPreIntro = """
    <div class=\"mw-parser-output\"><div role=\"note\" class=\"hatnote navigation-not-searchable\">For other uses, see <a href=\"/wiki/Terrier_(disambiguation)\" class=\"mw-disambig\" title=\"Terrier (disambiguation)\">Terrier (disambiguation)</a>.
    </div>
    """
    
    // MARK: - Additional instance variables
    var textnavigator = BrowserNavigator()  // TODO: rehydrate from local storage
    
    var pageid = 176426 {  // pageid for "Meerkat" in English
        didSet {
            loadWikiPage(withLang: getRightSelectedLanguage(), forArticle: pageid)
        }
    }
    
    var normalizedTitle = WikipediaDefinitionViewController.BasicNormalize(word: Constants.DefaultWord) {
        didSet {
            loadWikiPage(withLang: getRightSelectedLanguage(), forArticle: normalizedTitle)
        }
    }
    
    var textviewNavLeftEnabled = false {
        didSet {
            if !expanded {
                if textviewNavLeftEnabled {
                    leftArrow.isEnabled = true
                } else {
                    leftArrow.isEnabled = false
                }
            }
        }
    }
    
    var textviewNavRightEnabled = false {
        didSet {
            if !expanded {
                if textviewNavRightEnabled {
                    rightArrow.isEnabled = true
                } else {
                    rightArrow.isEnabled = false
                }
            }
        }
    }
    
    override func didSetMainLeftNavEnabled() {
        if expanded {
            if mainLeftNavEnabled {
                leftArrow.isEnabled = true
            } else {
                leftArrow.isEnabled = false
            }
        }
    }
    
    override func didSetMainRightNavEnabled() {
        if expanded {
            if mainRightNavEnabled {
                rightArrow.isEnabled = true
            } else {
                rightArrow.isEnabled = false
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        initializeWebView()  // superclass doesn't have webview
        
        // In case we expanded before initializing this view, show webview
        if expanded {
            expandHook()
        }
        
        textview.delegate = self  // to follow links in text view
    }
    
    override func initContent() {
        
        // This comes first so we don't flash lorem ipsum when word has been changed before first page swiped
        updateViewContents(with: WikipediaDefinitionViewController.DefaultIntro, prefixedBy: WikipediaDefinitionViewController.DefaultPreIntro)
        if currentWord != Constants.DefaultWord {
            refresh()  // does handleDisplayAndNavigation in jsonHandler
        } else {
            handleDisplayAndNavigation(data: [
                "pageid": String(pageid),
                "normalizedTitle": "",  // Empty string means we navigated to webpage with pageid
                "preintro": WikipediaDefinitionViewController.DefaultPreIntro,
                "intro": WikipediaDefinitionViewController.DefaultIntro
            ])
        }
    }

    // MARK: - instance variable getters
    override func getApiPath() -> String {
        return Constants.AggregatedSearchApiPath
    }

    override func getNavbarTitleName() -> String {
        return "Wikpedia"
    }

    override func getRightSelectedLanguage() -> String {
        if rightSelectedLanguage == nil {
            rightSelectedLanguage = WikipediaDefinitionViewController.DefaultLanguage
        }
        return rightSelectedLanguage!
    }

    override func getSupportedLangs() -> [String: [String: String]] {
        return WikipediaDefinitionViewController.SupportedLangs
    }

    func replaceEmptyContentWithDefaultMessage(intro: String, preIntro: String?, title: String) -> String {
        if (preIntro == nil || preIntro!.isEmpty) && intro.isEmpty {
            return "<p>\(WikipediaDefinitionViewController.NoArticleIntroStatusMessage)</p>"
        }
        return intro
    }
    
    override func prepDictForJsonHandler(dict: [String: Any]) -> [String: Any]? {
        if let searchSuccess: Bool = Utilities.GetProp(named: "searchSuccess", from: dict), searchSuccess, let wikipediaIntroStr: String = Utilities.GetProp(named: "wikipediaIntroduction", from: dict), let wikipediaIntro = Utilities.ConvertToDictionary(text: wikipediaIntroStr) {
            return wikipediaIntro
        }
        return nil
    }
    
    override func initJSONHandler() {
        jsonHandler = { jsonDict in
            DispatchQueue.main.async {  // Update view (crashes if called in callback thread)

                // Find normalized title, if any
                let word = self.currentWord
                
                // Get a pageid and use its setter to load webpage. If it doesn't exist, use normalized name
                var usedPageid = false
                let title = self.getNormalizedTitle(from: jsonDict, relativeTo: word) ?? word
                if let pageid: Int = Utilities.GetProp(named: "pageid", from: jsonDict), pageid >= 0 {
                    self.pageid = pageid
                    usedPageid = true
                } else {
                    self.normalizedTitle = title
                }

                // Get pre-intro content and intro content then display it
                if var introHTML: String = Utilities.GetProp(named: "intro", from: jsonDict) {

                    let templates: String! = Utilities.GetProp(named: "templates", from: jsonDict)
                    let templateHTML: String? = !templates.isEmpty ? templates : nil
                    
                    introHTML = self.replaceEmptyContentWithDefaultMessage(intro: introHTML, preIntro: templateHTML, title: title)
                    
                    self.updateViewContents(with: introHTML, prefixedBy: templateHTML)
                    self.handleDisplayAndNavigation(data: [
                        "pageid": usedPageid ? String(self.pageid) : "",
                        "normalizedTitle": usedPageid ? "" : self.normalizedTitle,
                        "preintro": templateHTML ?? "",
                        "intro": introHTML])
                }
            }
        }
    }
    
    override func getJsonObj(iCloudHash: String, text: String) -> [String: Any] {
        var ret = super.getJsonObj(iCloudHash: iCloudHash, text: text)
        
        let lang = getRightSelectedLanguage()
        
        ret["endpoints"] = ["wikipediaIntro"]
        ret["wikipediaLanguageCode"] = lang

        return ret
    }
    
    override func expandHook() {  // called after expand variable is set
        if textview != nil && webview != nil {
            textview.isHidden = true
            
            // For edge case when expanding with picker open
            if rightLanguagePicker.isHidden {
                webview.isHidden = false
            } else {
                webview.isHidden = true
            }
            
            // Left/right arrows may not have had isEnabled flags set correctly b/c of "if expanded" in didSet
            leftArrow.isEnabled = mainLeftNavEnabled
            rightArrow.isEnabled = mainRightNavEnabled
        }
    }

    override func contractHook() {  // called after expand variable is set
        if textview != nil && webview != nil {
            webview.isHidden = true
            
            // For edge case when contracting with picker open
            if rightLanguagePicker.isHidden {
                textview.isHidden = false
            } else {
                textview.isHidden = true
            }
            
            // Left/right arrows may not have had isEnabled flags set correctly b/c of "if expanded" in didSet
            leftArrow.isEnabled = textviewNavLeftEnabled
            rightArrow.isEnabled = textviewNavRightEnabled
        }
    }
    
    override func hidePickerShowOriginalView() {
        rightLanguagePicker.isHidden = true
        if expanded {
            webview.isHidden = false
        } else {
            textview.isHidden = false
        }
    }
    
    // MARK: If the link is for a wikipedia article, refresh this view with an intro for the new article
    override func textviewLinkClickHandler(url: URL) {
        let splits = url.absoluteString.split(separator: "/")
        let length = splits.count
        if length > 1 {
            let wikiPart = (splits[length - 2] as NSString).trimmingCharacters(in: .whitespacesAndNewlines)
            if wikiPart.lowercased() == "wiki" {
                let newArticleName = (splits[length - 1] as NSString).trimmingCharacters(in: .whitespacesAndNewlines)
                currentWord = newArticleName
                refresh()
            }
        }
    }
    
    func setLeftRightNavClickability() {
        textviewNavLeftEnabled = textnavigator.canGoBack()
        textviewNavRightEnabled = textnavigator.canGoForward()
    }
    
    func handleDisplayAndNavigation(data: [String: String]){
        textnavigator.displayed(data: data)
        setLeftRightNavClickability()
    }
    
    override func persistenceKey() -> String? {
        return FlashcardCollections.WikipediaAttributeName
    }
}

// MARK: - Webview stuff
extension WikipediaDefinitionViewController {

    // Perform basic normalization
    static func BasicNormalize(word: String) -> String {
        guard !word.isEmpty else {
            return ""
        }

        let split = word.split(whereSeparator: { (c: Character) -> Bool in
            if c == " " || c == "_" {
                return true
            }
            return false
        })
        var rtn = split[0].capitalized
        if split.count > 1 {
            rtn += "_" + split.dropFirst().joined(separator: "_")
        }
        return rtn
    }
    
    // MARK: Load Wikipedia page from a pageid
    func loadWikiPage(withLang lang: String, forArticle pageid: Int) {
        let langCode = lang
        let urlString = WikipediaDefinitionViewController.WikiPageidURLTemplate.replacingOccurrences(of: "{{lang-code}}", with: langCode).replacingOccurrences(of: "{{pageid}}", with: "\(pageid)")

        guard let encodedURLString = urlString.stringByAddingPercentEncodingForRFC3986, let url = URL(string: encodedURLString) else {
            print("Error: could not form valid URL")
            return
        }
        
        let request = URLRequest(url: url)
        print("Loading URL", url)
        webview.load(request)
    }
    
    // MARK: Load Wikipedia page from an article name
    func loadWikiPage(withLang lang: String, forArticle article: String) {
        let langCode = lang
        let urlString = WikipediaDefinitionViewController.WikiWebpageURLTemplate.replacingOccurrences(of: "{{lang-code}}", with: langCode).replacingOccurrences(of: "{{article-name}}", with: article)
        
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

        loadWikiPage(withLang: getRightSelectedLanguage(), forArticle: pageid)
        webview.isHidden = true
    }
}

// MARK: - Handlers for buttons
extension WikipediaDefinitionViewController {

    func syncWebviewWithNavigationInTextview(data: [String: String]) {
        let title = data["normalizedTitle"]!
        let pageid = Int(data["pageid"]!)
        let usedPageid = title.isEmpty

        if usedPageid, let pageid = pageid, pageid >= 0 {
            loadWikiPage(withLang: getRightSelectedLanguage(), forArticle: pageid)
        } else if usedPageid {
            print ("Error: was supposed to use pageid, but it's malformed or negative")
        } else {
             loadWikiPage(withLang: getRightSelectedLanguage(), forArticle: title)
        }
    }
    
    @IBAction func handleLeftArrow(_ sender: UIBarButtonItem) {
        if expanded {
            if webview.canGoBack {
                webview.goBack()
            } else {
                print("Error: webview can't go back!")
            }
        } else {
            guard textnavigator.canGoBack() else {
                print("Error: not allowed to go back...")
                return
            }
            let oneback = textnavigator.goBack()!
            updateViewContents(with: oneback["intro"]!, prefixedBy: oneback["preintro"])
            setLeftRightNavClickability()
            syncWebviewWithNavigationInTextview(data: oneback)
        }
    }

    @IBAction func handleRightArrow(_ sender: UIBarButtonItem) {
        if expanded {
            if webview.canGoForward {
                webview.goForward()
            } else {
                print("Error: webview can't go forward!")
            }
        } else {
            guard textnavigator.canGoForward() else {
                print("Error: not allowed to go forard...")
                return
            }
            let oneforward = textnavigator.goForward()!
            updateViewContents(with: oneforward["intro"]!, prefixedBy: oneforward["preintro"])
            setLeftRightNavClickability()
            syncWebviewWithNavigationInTextview(data: oneforward)
        }
    }

    @IBAction override func handleRightLanguageButton(_ sender: UIBarButtonItem) {
        if rightLanguagePicker.isHidden {
            if expanded {
                webview.isHidden = true
            } else {
                textview.isHidden = true
            }
            rightLanguagePicker.isHidden = false
        } else {
            if expanded {
                webview.isHidden = false
            } else {
                textview.isHidden = false
            }
            rightLanguagePicker.isHidden = true
        }
    }
}

// MARK: - Intro content stuff
extension WikipediaDefinitionViewController {
    
    func updateViewContents(with processedWikiHTML: String, prefixedBy templateHTML: String?) {
        
        // Make pre-intro-content attributed string
        var preIntroStr = DefinitionViewController.ContentTemplate.replacingOccurrences(of: "{{more-style}}", with: WikipediaDefinitionViewController.Style)
        preIntroStr = preIntroStr.replacingOccurrences(of: "{{body}}", with: WikipediaDefinitionViewController.PreIntroBodyTemplate)
        
        // Make intro-content attributed string
        var introStr = DefinitionViewController.ContentTemplate.replacingOccurrences(of: "{{more-style}}", with: WikipediaDefinitionViewController.Style)
        introStr = introStr.replacingOccurrences(of: "{{body}}", with: WikipediaDefinitionViewController.IntroBodyTemplate)
        
        // Convert pre-intro content to attributed string then trim it
        var preIntroContentAttributed = NSMutableAttributedString()
        if let templateHTML = templateHTML {
            let preIntroContent = preIntroStr.replacingOccurrences(of: "{{pre-intro-content}}", with: templateHTML)
            preIntroContentAttributed = NSMutableAttributedString(attributedString:  (preIntroContent.htmlToAttributedString)!).trimmedAttributedString(set: CharacterSet.whitespacesAndNewlines)
            preIntroContentAttributed.append(NSAttributedString(string: "\n\n"))
        }

        // Convert intro content to attributed string then trim it
        let introContent = introStr.replacingOccurrences(of: "{{intro-content}}", with: processedWikiHTML)
        let introContentAttributed = NSMutableAttributedString(attributedString: introContent.htmlToAttributedString!).trimmedAttributedString(set: CharacterSet.whitespacesAndNewlines)

        // Concatenate the two trimmed attributed strings
        let contentAttributed = NSMutableAttributedString()
        contentAttributed.append(preIntroContentAttributed)
        contentAttributed.append(introContentAttributed)

        // Set view's attributed text to concatenated, trimmed attributed string
        textview.attributedText = contentAttributed.trimmedAttributedString(set: .whitespacesAndNewlines)
    }

    func getNormalizedTitle(from jsonDictionary: [String: Any], relativeTo original: String) -> String? {
        if let normalizedProp = jsonDictionary["normalization"] as? [Any] {
            for pair in normalizedProp {
                if let currDict = pair as? [String: String], currDict["from"] == original {
                    return currDict["to"]
                }
            }
        }
        return nil
    }
}
