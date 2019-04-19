//
//  TranslateDefinitionViewController.swift
//  Tapdefine
//
//  Created by Hamik on 6/25/18.
//  Copyright © 2018 Hamik. All rights reserved.
//

import UIKit

class TranslateDefinitionViewController: DefinitionViewController {
    
    static let DefaultSourceLanguage = "en"
    static let DefaultTargetLanguage = "fr"
    static let BackupDefaultTargetLanguage = "es"
    static let SupportedSourceLanguages = Constants.DefaultSupportedLangs
    
    static let LogoHeight = CGFloat(16)
    static let LogoBottomMargin = CGFloat(5)
    static let LineViewWidth = CGFloat(10)
    
    static let NoTranslationAvailable = "<p class=\"text\">No translation available 😫</p>"
    static let DefaultTranslation = "terrier"
    static let DefaultContent = "<p class=\"text\">{{default-translation}}</p>"
    static let SourceTemplate = "<p class=\"text\">{{word}}</p>"
    static let Style = """
    .text {
        font-size: 11pt;
    }
    .language {
        font-weight: bold;
        font-size: 11pt;
    }
    """
    static let PersistableHtmlBodyTemplate = """
    <span class="language">{{source-language}} 👉 {{target-language}}</span><br>
    <br>
    <span class="text">{{translation}}</span>
    """
    
    @IBOutlet weak var leftLanguagePicker: UIPickerView!
    @IBOutlet weak var leftLanguageButton: UIBarButtonItem!
    @IBOutlet weak var rightTextView: UITextView!
    
    var lastTranslation = TranslateDefinitionViewController.DefaultTranslation
    var googleLogoView: UIImageView!
    var lineView: LineView!
    var leftSelectedLanguage: String?
    var supportedTargetLanguages = [
        "Spanish": ["basic": "es"],
        "French": ["basic": "fr"]
    ]
    // should be set to true when getApiPath should give langs endpoint instead of translate
    var shouldGetLanguages = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
     
        // Put more init here
        initLeftLanguagePicker()
        updateRightLanguagePicker()
        
        // Run this function when entering foreground
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: .UIApplicationWillEnterForeground, object: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // This is to make sure textview starts at top
        rightTextView.setContentOffset(CGPoint.zero, animated: false)
    }
    
    override func initContent() {
        displayHtml(body: TranslateDefinitionViewController.DefaultContent.replacingOccurrences(of: "{{default-translation}}", with: TranslateDefinitionViewController.DefaultTranslation))
        if currentWord != Constants.DefaultWord {
            refresh()  // does handleDisplayAndNavigation in jsonHandler
        }
    }
    
    override func initNavButtons() {
        // Do nothing - just want to avoid nil pointer exception from accessing leftArrow or rightArrow
    }
    
    func displayHtml(body: String) {
        // Update the right text view with the translated word
        let targetWithStyle = DefinitionViewController.ContentTemplate.replacingOccurrences(of: "{{more-style}}", with: TranslateDefinitionViewController.Style)
        let targetWithBody = targetWithStyle.replacingOccurrences(of: "{{body}}", with: body)
        updateRightViewContents(with: targetWithBody)
        
        // Update the left text view with the source word
        let sourceContentWithStyle = String(targetWithStyle)
        let sourceContentWithBody = sourceContentWithStyle.replacingOccurrences(of: "{{body}}", with: TranslateDefinitionViewController.SourceTemplate.replacingOccurrences(of: "{{word}}", with: currentWord))
        updateViewContents(with: sourceContentWithBody)
    }
    
    func updateRightViewContents(with htmlStr: String?) {
        guard let htmlStr = htmlStr else {
            return
        }
        let extendedStr = htmlStr
        if let attrbStr = extendedStr.htmlToAttributedString {
            let mutableAttrbStr = NSMutableAttributedString(attributedString: attrbStr)
            rightTextView.attributedText = mutableAttrbStr.trimmedAttributedString(set: .whitespacesAndNewlines)
        }
    }
    
    override func prepDictForJsonHandler(dict: [String: Any]) -> [String: Any]? {
        if shouldGetLanguages {
            return dict
        } else {  // if regular translation call
            if let searchSuccess: Bool = Utilities.GetProp(named: "searchSuccess", from: dict), searchSuccess, let translationPartStr: String = Utilities.GetProp(named: "translation", from: dict), let translationPart = Utilities.ConvertToDictionary(text: translationPartStr) {
                return translationPart
            } else {
                return nil
            }
        }
    }
    
    override func initJSONHandler() {
        jsonHandler = { jsonDict in
            if let rightLangs: [String: [String: String]] = Utilities.GetProp(named: "targetLangs", from: jsonDict) {  // received a getLanguages payload
                DispatchQueue.main.async {
                    self.supportedTargetLanguages = rightLangs
                    
                    // Remove left selected lang from this list
                    let leftCode = self.getLeftSelectedLanguage()
                    let removeThis = self.langCodeToName(languages: self.getSupportedLangs(), matchCode: leftCode)
                    if let removeThisKey = removeThis {
                        self.supportedTargetLanguages.removeValue(forKey: removeThisKey)
                    }

                    // Make sure the same right lang is selected, but that the title of the button is in the newly selected left lang
                    if self.getRightSelectedLanguage() == leftCode {
                        // reset to nil so rightSelectedLanguage can choose a new one
                        self.rightSelectedLanguage = nil
                    }
                    self.rightLanguageButton.title = self.shortenLanguage(title: self.langCodeToName(languages: self.getSupportedLangs(), matchCode: self.getRightSelectedLanguage())!)
                    let rowOfDefaultLang = self.getSupportedLangs().keys.sorted().index(of: self.langCodeToName(languages: self.getSupportedLangs(), matchCode: self.getRightSelectedLanguage())!)
                    self.rightLanguagePicker.selectRow(rowOfDefaultLang!, inComponent: 0, animated: true)
                    self.rightLanguagePicker.reloadAllComponents()
                    
                    self.shouldGetLanguages = false
                    self.refresh()
                }
            } else if let translation: String = Utilities.GetProp(named: "translatedPhrase", from: jsonDict) {  // receiving a translation payload
                DispatchQueue.main.async {  // Update view (crashes if called in callback thread)
                    self.lastTranslation = translation != "" ? translation : TranslateDefinitionViewController.NoTranslationAvailable
                    self.displayHtml(body: self.lastTranslation)
                }
            }
        }
    }
    
    override func getJsonObj(iCloudHash: String, text: String) -> [String: Any] {
        if shouldGetLanguages {
            return ["sourceLang": getLeftSelectedLanguage()]
        }

        var ret = super.getJsonObj(iCloudHash: iCloudHash, text: text)

        ret["endpoints"] = ["translation"]
        ret["sourceLanguage"] = getLeftSelectedLanguage()
        ret["targetLanguage"] = getRightSelectedLanguage()

        return ret
    }
    
    func getLeftSelectedLanguage() -> String {
        if leftSelectedLanguage == nil {
            leftSelectedLanguage = TranslateDefinitionViewController.DefaultSourceLanguage
        }
        return leftSelectedLanguage!
    }

    override func getRightSelectedLanguage() -> String {
        if rightSelectedLanguage == nil {
            if getLeftSelectedLanguage() != TranslateDefinitionViewController.DefaultTargetLanguage {
                rightSelectedLanguage = TranslateDefinitionViewController.DefaultTargetLanguage
            } else {
                rightSelectedLanguage = TranslateDefinitionViewController.BackupDefaultTargetLanguage
            }
        }
        return rightSelectedLanguage!
    }
    
    func initLeftLanguagePicker() {
        leftLanguageButton.title = langCodeToName(languages: getSupportedLeftLangs(), matchCode: getLeftSelectedLanguage())
        leftLanguagePicker.delegate = self
        leftLanguagePicker.dataSource = self
        let rowOfDefaultLang = getSupportedLeftLangs().keys.sorted().index(of: langCodeToName(languages: getSupportedLeftLangs(), matchCode: getLeftSelectedLanguage())!)
        leftLanguagePicker.selectRow(rowOfDefaultLang!, inComponent: 0, animated: true)
        leftLanguagePicker.isHidden = true

        (_, _) = leftLanguagePicker.snuglyConstrain(to: blurSubview, leftAmount: 0, rightAmount: 0)
        (_, _) = leftLanguagePicker.snuglyConstrain(to: blurSubview, toTop: navbar, toBottom: blurSubview, topAmount: 0, bottomAmount: 0)
    }
    
    func updateRightLanguagePicker() {
        shouldGetLanguages = true
        refresh()
        // getLanguages is set to false in jsonHandler and cleanupAfterFailedRPC()
    }
    
    override func initTextview() {
        initializeGoogleLogo()
        
        // Set some text view properties
        rightTextView.backgroundColor = UIColor.clear
        
        // Create constraints for right text view
        (_, _) = rightTextView.snuglyConstrain(to: blurSubview, toTop: navbar, toBottom: googleLogoView, topAmount: 0, bottomAmount: Constants.BottomMarginInDefView)
        let rtvr = NSLayoutConstraint(item: rightTextView, attribute: .right, relatedBy: .equal, toItem: blurSubview, attribute: .right, multiplier: 1, constant: -Constants.LeftRightMarginInDefView)
        let rtvw = NSLayoutConstraint(item: rightTextView, attribute: .width, relatedBy: .equal, toItem: textview, attribute: .width, multiplier: 1, constant: 0)
        
        // Create the line separator view
        lineView = LineView()
        lineView.viewWidth = TranslateDefinitionViewController.LineViewWidth
        lineView.backgroundColor = UIColor.clear
        blurSubview.addSubview(lineView)
        
        // Create constraints for the line separator view
        (_, _) = lineView.snuglyConstrain(to: blurSubview, toTop: navbar, toBottom: googleLogoView, topAmount: Constants.SeparatorTopBottomMargin, bottomAmount: Constants.SeparatorTopBottomMargin)
        let lvw = NSLayoutConstraint(item: lineView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: TranslateDefinitionViewController.LineViewWidth)
        let lvr = NSLayoutConstraint(item: lineView, attribute: .right, relatedBy: .equal, toItem: rightTextView, attribute: .left, multiplier: 1, constant: 0)
        
        // Finally create constraints for the left text view
        (_, _) = textview.snuglyConstrain(to: blurSubview, toTop: navbar, toBottom: googleLogoView, topAmount: 0, bottomAmount: Constants.BottomMarginInDefView)
        (_, _) = textview.snuglyConstrain(to: blurSubview, toLeft: blurSubview, toRight: lineView, leftAmount: Constants.LeftRightMarginInDefView, rightAmount: 0)
        
        // Add all remaining constraints
        rightTextView.translatesAutoresizingMaskIntoConstraints = false
        lineView.translatesAutoresizingMaskIntoConstraints = false
        blurSubview.addConstraints([rtvr, rtvw, lvw, lvr])
    }
    
    func initializeGoogleLogo() {
        let logoImg = UIImage(named: "googleTranslateLogoGray")
        googleLogoView = UIImageView(image: logoImg)
        googleLogoView.contentMode = .scaleAspectFit
        blurSubview.addSubview(googleLogoView)
        (_, _) = googleLogoView.snuglyConstrain(to: blurSubview, leftAmount: 0, rightAmount: 0)
        let heightConstraint = NSLayoutConstraint(item: googleLogoView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: TranslateDefinitionViewController.LogoHeight)
        let bottomConstraint = NSLayoutConstraint(item: googleLogoView, attribute: .bottom, relatedBy: .equal, toItem: blurSubview, attribute: .bottom, multiplier: 1, constant: -TranslateDefinitionViewController.LogoBottomMargin)
        googleLogoView.translatesAutoresizingMaskIntoConstraints = false
        blurSubview.addConstraints([heightConstraint, bottomConstraint])
    }
    
    func persistableTextAux() -> String {
        let leftLang = langCodeToName(languages: TranslateDefinitionViewController.SupportedSourceLanguages, matchCode: getLeftSelectedLanguage()) ?? getLeftSelectedLanguage()
        let rightLang = langCodeToName(languages: supportedTargetLanguages, matchCode: getRightSelectedLanguage()) ?? getRightSelectedLanguage()
        
        let withStyle = DefinitionViewController.ContentTemplate.replacingOccurrences(of: "{{more-style}}", with: TranslateDefinitionViewController.Style)
        let bodyPart = TranslateDefinitionViewController.PersistableHtmlBodyTemplate.replacingOccurrences(of: "{{source-language}}", with: leftLang).replacingOccurrences(of: "{{target-language}}", with: rightLang).replacingOccurrences(of: "{{translation}}", with: lastTranslation)
        return withStyle.replacingOccurrences(of: "{{body}}", with: bodyPart)
    }
    
    override func getPersistableAttributedText() -> NSAttributedString {
        return persistableTextAux().htmlToAttributedString ?? NSAttributedString(string: "")
    }
    
    override func getPersistableText() -> String {
        return persistableTextAux().htmlToString
    }
    
    override func persistenceKey() -> String? {
        return FlashcardCollections.TranslationAttributeName
    }
    
    override func getNavbarTitleName() -> String {
        return "Translate"
    }
    
    // This is for right languages
    override func getSupportedLangs() -> [String: [String: String]] {
        return supportedTargetLanguages
    }
    
    func getSupportedLeftLangs() -> [String: [String: String]] {
        return TranslateDefinitionViewController.SupportedSourceLanguages
    }
    
    override func getRowCount(in pickerView: UIPickerView) -> Int {
        if pickerView == leftLanguagePicker {
           return getSupportedLeftLangs().count
        } else {  // right one
            return super.getRowCount(in: pickerView)
        }
    }
    
    override func getNameFor(row: Int, in pickerView: UIPickerView) -> String? {
        if pickerView == leftLanguagePicker {
            return getSupportedLeftLangs().keys.sorted()[row]
        } else {  // right one
            return super.getNameFor(row: row, in: pickerView)
        }
    }
    
    override func didSelectRowHandler(row: Int, view pickerView: UIPickerView) {
        if pickerView == leftLanguagePicker {
            leftSelectedLanguage = getSupportedLeftLangs()[getSupportedLeftLangs().keys.sorted()[row]]?["basic"]
            leftLanguageButton.title = langCodeToName(languages: getSupportedLeftLangs(), matchCode: getLeftSelectedLanguage())
            hideLeftPickerShowOriginalView()
            updateRightLanguagePicker()  // get target langs available for this source lang
        } else {  // right one
            super.didSelectRowHandler(row: row, view: pickerView)
        }
    }
    
    override func hidePickerShowOriginalView() {
        rightLanguagePicker.isHidden = true
        setTextViewVisibility(to: true)
        googleLogoView.isHidden = false
    }
    
    func hideLeftPickerShowOriginalView() {
        leftLanguagePicker.isHidden = true
        setTextViewVisibility(to: true)
        googleLogoView.isHidden = false
    }
    
    override func getApiPath() -> String {
        if shouldGetLanguages {
            return "translate/google/languages"
        } else {
            return Constants.AggregatedSearchApiPath
        }
    }

    func setTextViewVisibility(to notHidden: Bool) {
        textview.isHidden = !notHidden
        rightTextView.isHidden = !notHidden
        lineView.isHidden = !notHidden
    }

    @IBAction override func handleRightLanguageButton(_ sender: UIBarButtonItem) {
        leftLanguagePicker.isHidden = true
        if rightLanguagePicker.isHidden {
            googleLogoView.isHidden = true
            setTextViewVisibility(to: false)
            rightLanguagePicker.isHidden = false
        } else {
            googleLogoView.isHidden = false
            setTextViewVisibility(to: true)
            rightLanguagePicker.isHidden = true
        }
    }
    
    @IBAction func handleLeftLanguageButton(_ sender: UIBarButtonItem) {
        rightLanguagePicker.isHidden = true
        if leftLanguagePicker.isHidden {
            googleLogoView.isHidden = true
            setTextViewVisibility(to: false)
            leftLanguagePicker.isHidden = false
        } else {
            googleLogoView.isHidden = false
            setTextViewVisibility(to: true)
            leftLanguagePicker.isHidden = true
        }
    }
}
