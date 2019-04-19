//
//  VanillaDefinitionViewController.swift
//  Tapdefine
//
//  Created by Hamik on 6/25/18.
//  Copyright © 2018 Hamik. All rights reserved.
//

import UIKit
import AVFoundation

class VanillaDefinitionViewController: DefinitionViewController {
    
    // MARK: - Static variables
    static let DefaultLanguage = "en"
    static let DefaultRegion: String? = "us"
    static let TapdefDefaultAudioFilename = ["tapdef", "mp3"]
    static let WordNotFound = "<p class=\"text\">😿 \"{{current-word}}\" doesn't have an entry. {{extra-sentence}}</p>"
    static let ChooseFromThese = "Did you mean one of these?"
    
    static let SupportedLangs = [
        "English (US)" : ["basic": "en", "region": "us"],
        "English (GB)" : ["basic": "en", "region": "gb"],
        "Spanish": ["basic": "es"],
    ]

    static let Style = """
    .word {
        font-weight: bolder;
        font-size: 12pt;
    }
    .word-superscript {
        font-size: 11pt;
    }
    .pronunciation {
        font-size: 11pt;
    }
    .listen-icon {
        color: #\(Constants.TabBarButtonActiveColor);
        font-size: 9pt;
    }
    .part-of-speech {
        font-style: italic;
        font-size: 11pt;
        color: #\(Constants.LightGrayString);
    }
    .sub-pop {
        color: #\(Constants.LightGrayString);
        font-size: 9pt;
    }
    .text {
        font-size: 11pt;
    }
    .example-sent {
        font-style: italic;
        font-size: 11pt;
    }
    .sub-example-sent {
        font-style: italic;
        font-size: 11pt;
    }
    .suggestion {
        color: #\(Constants.TabBarButtonActiveColor);
    }
    """
    
    static let DefaultContent = "<div><span class=\"word\">terrier </span><span class=\"word-superscript\">¹</span></div><div>&zwnj;<span class=\"pronunciation\">/ˈtɛriər/</span> <span class=\"listen-icon\"><a href=\"http://audio.oxforddictionaries.com/en/mp3/terrier_us_1.mp3#audio\">🔈</a></span></div><br><div><span class=\"part-of-speech\">noun</span><div><ol class=\"text\"><li><span class=\"definition\">a small dog of a breed originally used for turning out foxes and other burrowing animals from their lairs.</span><br><ul><li><span class=\"subdefinition\">used in similes to emphasize tenacity or eagerness</span></li></ul></li></ol></div></div><br><div><span class=\"word\">terrier </span><span class=\"word-superscript\">²</span></div><div>&zwnj;<span class=\"sub-pop\">HISTORICAL</span></div><br><div><span class=\"part-of-speech\">noun</span><div><ol class=\"text\"><li><span class=\"definition\">a register of the lands belonging to a landowner, originally including a list of tenants, their holdings, and the rents paid, later consisting of a description of the acreage and boundaries of the property.</span><br><ul><li><span class=\"subdefinition\">an inventory of property or goods.</span></li></ul></li></ol></div></div>"
    
    // Additional instance variables
    var navigator = BrowserNavigator()  // TODO: rehydrate from local storage
    
    var textviewNavLeftEnabled = false {
        didSet {
            if textviewNavLeftEnabled {
                leftArrow.isEnabled = true
            } else {
                leftArrow.isEnabled = false
            }
        }
    }
    
    var textviewNavRightEnabled = false {
        didSet {
            if textviewNavRightEnabled {
                rightArrow.isEnabled = true
            } else {
                rightArrow.isEnabled = false
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Additional initialization below
        textview.delegate = self  // to follow links in text view
    }
    
    // MARK: - some getters
    override func getApiPath() -> String {
        return Constants.AggregatedSearchApiPath
    }

    override func getNavbarTitleName() -> String {
        return "Definition"
    }
    
    override func getRightSelectedLanguage() -> String {
        if rightSelectedLanguage == nil {
            rightSelectedLanguage = VanillaDefinitionViewController.DefaultLanguage
            if rightSelectedRegion == nil {
                rightSelectedRegion = VanillaDefinitionViewController.DefaultRegion
            }
        }
        return rightSelectedLanguage!
    }
    
    func getRightSelectedRegion() -> String {
        if rightSelectedRegion == nil {
            rightSelectedRegion = VanillaDefinitionViewController.DefaultRegion
        }
        return rightSelectedRegion!
    }
    
    override func getSupportedLangs() -> [String: [String: String]] {
        return VanillaDefinitionViewController.SupportedLangs
    }
    
    override func getJsonObj(iCloudHash: String, text: String) -> [String: Any] {
        var ret = super.getJsonObj(iCloudHash: iCloudHash, text: text)
        
        let code = getRightSelectedLanguage()
        let currLang = langCodeToName(languages: getSupportedLangs(), matchCode: getRightSelectedLanguage())
        let codes = VanillaDefinitionViewController.SupportedLangs[currLang!]!
        let region = codes["region"] ?? ""
        
        ret["endpoints"] = ["definition"]
        ret["definitionLanguageCode"] = code
        ret["languageRegion"] = region

        return ret
    }
    
    override func didSelectRowHandler(row: Int, view pickerView: UIPickerView) {
        let rowEntry = getSupportedLangs()[getSupportedLangs().keys.sorted()[row]]!
        rightSelectedLanguage = rowEntry["basic"]
        rightSelectedRegion = rowEntry["region"]
        rightLanguageButton.title = shortenLanguage(title: langCodeToName(languages: getSupportedLangs(), matchCode: getRightSelectedLanguage())!)
        hidePickerShowOriginalView()
        refresh()
    }
    
    func displayHtml(body: String) {
        let withStyle = DefinitionViewController.ContentTemplate.replacingOccurrences(of: "{{more-style}}", with: VanillaDefinitionViewController.Style)
        let withBody = withStyle.replacingOccurrences(of: "{{body}}", with: body)
        updateViewContents(with: withBody)
        handleDisplayAndNavigation(data: [FlashcardCollections.WordAttributeName: self.currentWord, "contents": withBody])
    }

    override func prepDictForJsonHandler(dict: [String: Any]) -> [String: Any]? {
        if let searchSuccess: Bool = Utilities.GetProp(named: "searchSuccess", from: dict), searchSuccess, let definitionPartStr: String = Utilities.GetProp(named: "definition", from: dict), let definitionPart = Utilities.ConvertToDictionary(text: definitionPartStr) {
           return definitionPart
        }
        return nil
    }
    
    override func initJSONHandler() {
        jsonHandler = { jsonDict in
            DispatchQueue.main.async {  // Update view (crashes if called in callback thread)

                // Get the definition, if available
                var htmlContent: String? = Utilities.GetProp(named: "htmlDefinition", from: jsonDict)

                // Otherwise get suggestions. Some plurals, inflections, and misspellings won't have a definition available
                if htmlContent == nil || htmlContent == "" {
                     htmlContent = Utilities.GetProp(named: "htmlSuggestions", from: jsonDict)

                    if htmlContent != nil && htmlContent != "" {
                        htmlContent = VanillaDefinitionViewController.WordNotFound.replacingOccurrences(of: "{{current-word}}", with: self.currentWord).replacingOccurrences(of: "{{extra-sentence}}", with: VanillaDefinitionViewController.ChooseFromThese) + htmlContent!
                    }
                }

                // If there are no suggestions either, then display a sad message
                if (htmlContent == nil || htmlContent == "") {
                    htmlContent = VanillaDefinitionViewController.WordNotFound.replacingOccurrences(of: "{{current-word}}", with: self.currentWord).replacingOccurrences(of: "{{extra-sentence}}", with: "")
                }

                self.displayHtml(body: htmlContent!)
            }
        }
    }
    
    func setLeftRightNavClickability() {
        textviewNavLeftEnabled = navigator.canGoBack()
        textviewNavRightEnabled = navigator.canGoForward()
    }
    
    func handleDisplayAndNavigation(data: [String: String]) {
        navigator.displayed(data: data)
        setLeftRightNavClickability()
    }
    
    override func initContent() {
        // This comes first so we don't show lorem ipsum when connection is slow/offline
        displayHtml(body: VanillaDefinitionViewController.DefaultContent)
        if currentWord != Constants.DefaultWord {
            refresh()  // does handleDisplayAndNavigation in jsonHandler
        }
    }
    
    @IBAction func handleLeftArrow(_ sender: UIBarButtonItem) {
        guard navigator.canGoBack() else {
            print("Error: not allowed to go back...")
            return
        }
        let htmlContents = navigator.goBack()!["contents"]!
        updateViewContents(with: htmlContents)
        setLeftRightNavClickability()
    }

    @IBAction func handleRightArrow(_ sender: UIBarButtonItem) {
        guard navigator.canGoForward() else {
            print("Error: not allowed to go forward...")
            return
        }
        let htmlContents = navigator.goForward()!["contents"]!
        updateViewContents(with: htmlContents)
        setLeftRightNavClickability()
    }

    // MARK: Handle links. TODO: synonyms, antonyms, cross-references
    override func textviewLinkClickHandler(url: URL) {
        let (linkType, arg) = LinkType.Get(from: url.absoluteString.removingPercentEncoding)
        if linkType == nil {
            print("Link type was nil")
            return
        }

        switch linkType! {
        case .audio:  // If audio link, play sound
            let defaultAudioFilename = VanillaDefinitionViewController.TapdefDefaultAudioFilename
            let filename = defaultAudioFilename[0]
            let fileExtension = defaultAudioFilename[1]
            let fullFilename = defaultAudioFilename.joined(separator: ".").lowercased()
            var soundURL = url
            if soundURL.absoluteString.lowercased().contains(fullFilename) {
                soundURL = Bundle.main.url(forResource: filename, withExtension: fileExtension)!
            }
            Utilities.PlaySound(url: soundURL)
        case .suggestion:  // If suggestion, update the current word
            if let arg = arg {
                print("Navigating to suggestion \(arg)")
                manualEntryUpdateFunc!(arg, false)
            } else {
                print("Suggestion doesn't have a word attached!")
                manualEntryUpdateFunc!("Please try again", true)
            }
        default:
            print("Currently unsupported link type \(linkType!)")
        }
    }
    
    override func persistenceKey() -> String? {
        return FlashcardCollections.DefinitionAttributeName
    }
}

enum LinkType: String {
    case audio, suggestion, synonym, antonym, crossref
    
    // MARK: Return link type (audio, suggestion, synonym, etc.) and word to search for, if relevant
    static func Get(from url: String?) -> (LinkType?, String?) {
        guard let url = url else {
            print("URL was nil")
            return (nil, nil)
        }
        
        let splitUrl = url.split(separator: "#")
        if splitUrl.count <= 1 {
            return (nil, nil)
        }
        
        let lastPart = splitUrl[splitUrl.count - 1]
        let splitLastPart = lastPart.split(separator: "=")
        let linkTypeString = String(splitLastPart[0])
        var arg: String?
        if splitLastPart.count > 1 {
            arg = String(splitLastPart[1])
        }
        return (LinkType(rawValue: linkTypeString), arg)
    }
}
