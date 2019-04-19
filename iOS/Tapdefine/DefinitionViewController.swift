//
//  DefinitionViewController.swift
//  Tapdefine
//
//  Created by Hamik on 7/14/18.
//  Copyright © 2018 Hamik. All rights reserved.
//

import Foundation
import UIKit
import WebKit

protocol DefinitionViewControllerDelegate {
    func getICloudUserNameHash() -> String
}

class DefinitionViewController: UIViewController {

    static let MaxLanguageTitleLength = 10
    
    // MARK: View outlets
    @IBOutlet weak var baseview: UIView!
    @IBOutlet weak var blurSuperview: UIView!
    @IBOutlet weak var blurview: UIVisualEffectView!
    @IBOutlet weak var blurSubview: UIView!
    @IBOutlet weak var textview: UITextView!
    @IBOutlet weak var rightLanguagePicker: UIPickerView!
    
    // MARK: Navbar outlets
    @IBOutlet weak var navbar: UINavigationBar!
    @IBOutlet weak var navbarTitle: UINavigationItem!
    @IBOutlet weak var leftArrow: UIBarButtonItem!
    @IBOutlet weak var rightArrow: UIBarButtonItem!
    @IBOutlet weak var rightLanguageButton: UIBarButtonItem!
    
    // MARK: Static variables
    static let ContentTemplate = Constants.ContentTemplate

    // MARK: - Instance variables
    var webview: ButtonConsciousWebView!  // used only in some subclasses, where it must be initialized
    var expandDefinitionViewFunc: (() -> Void)?
    var contractDefinitionViewFunc: (() -> Void)?
    var manualEntryUpdateFunc: ((String?, Bool) -> Void)?
    var rightSelectedLanguage: String?
    var jsonHandler: (([String: Any]) -> Void)?  // override this by overriding initJSONHandler
    var rightSelectedRegion: String?
    var retries = 0
    var myDelegate: DefinitionViewControllerDelegate!

    var currentWord = Constants.DefaultWord {
        didSet {
            retries = 0
        }
    }
    

    var expanded = false {
        didSet {
            if expanded {
                expandHook()
            } else {
                contractHook()
            }
        }
    }

    var mainLeftNavEnabled = false {
        didSet {
            didSetMainLeftNavEnabled()
        }
    }

    var mainRightNavEnabled = false {
        didSet {
            didSetMainRightNavEnabled()
        }
    }
    
    func didSetMainLeftNavEnabled() {
        if mainLeftNavEnabled {
            leftArrow.isEnabled = true
        } else {
            leftArrow.isEnabled = false
        }
    }
    
    func didSetMainRightNavEnabled() {
        if mainRightNavEnabled {
            rightArrow.isEnabled = true
        } else {
            rightArrow.isEnabled = false
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initJSONHandler()
        initUIElements()
        initContent()
        initNotifications()
    }
    
    @objc func willEnterForeground() {
        print("Definition view controller coming back into foreground")
        
        // We want to reset retries to 0 when there is a user action (foregrounding the app, in this case)
        retries = 0
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // We want to reset retries to 0 when there is a user action (swiping to the translate view, in this case)
        retries = 0
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // This is to make sure textview starts at top
        textview.setContentOffset(CGPoint.zero, animated: false)
    }
    
    // Should probably override this in subclasses
    func initJSONHandler() {
        jsonHandler = { jsonDict in
            if let value: String? = Utilities.GetProp(named: "value", from: jsonDict) {
                DispatchQueue.main.async {  // Update view (crashes if called in callback thread)
                    self.updateViewContents(with: value)
                }
            }
        }
    }
    
    func initUIElements() {
        initBlurSuperview()
        initBlurview()
        initBlurSubview()
        initNavbar()
        initNavbarButtons()
        initTextview()
    }
    
    func initBlurSuperview() {
        blurSuperview.layer.cornerRadius = Constants.CornerRadius
        
        blurSuperview?.snuglyConstrain(to: baseview!)
    }
    
    func initBlurview() {
        blurview.snuglyConstrain(to: blurSuperview!)
    }
    
    func initBlurSubview() {
        blurSubview.snuglyConstrain(to: blurview!)
    }
    
    func initNavbar() {
        navbarTitle.title = getNavbarTitleName()
        navbar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: Constants.DarkGray]
        
        (_, _) = navbar.snuglyConstrain(to: blurSubview, leftAmount: 0, rightAmount: 0)
        let topConstraint = NSLayoutConstraint(item: navbar, attribute: .top, relatedBy: .equal, toItem: blurSubview, attribute: .top, multiplier: 1, constant: 0)
        let heightConstraint = NSLayoutConstraint(item: navbar, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: Constants.NavbarHeight)
        navbar.translatesAutoresizingMaskIntoConstraints = false
        blurSubview.addConstraints([topConstraint, heightConstraint])
    }
    
    func initNavbarButtons() {
        navbar.tintColor = Constants.TabBarButtonActiveColor
        initNavButtons()
        initRightLanguagePicker()
    }
    
    func initTextview() {
        (_, _) = textview.snuglyConstrain(to: blurSubview, leftAmount: Constants.LeftRightMarginInDefView, rightAmount: Constants.LeftRightMarginInDefView)
        (_, _) = textview.snuglyConstrain(to: blurSubview, toTop: navbar, toBottom: blurSubview, topAmount: 0, bottomAmount: Constants.BottomMarginInDefView)
    }
    
    func initNavButtons() {
        leftArrow.isEnabled = false
        rightArrow.isEnabled = false
    }
    
    func initRightLanguagePicker() {
        rightLanguageButton.title = shortenLanguage(title: langCodeToName(languages: getSupportedLangs(), matchCode: getRightSelectedLanguage())!)
        rightLanguagePicker.delegate = self
        rightLanguagePicker.dataSource = self
        let rowOfDefaultLang = getSupportedLangs().keys.sorted().index(of: langCodeToName(languages: getSupportedLangs(), matchCode: getRightSelectedLanguage())!)
        rightLanguagePicker.selectRow(rowOfDefaultLang!, inComponent: 0, animated: true)
        rightLanguagePicker.isHidden = true
        
        (_, _) = rightLanguagePicker.snuglyConstrain(to: blurSubview, leftAmount: 0, rightAmount: 0)
        (_, _) = rightLanguagePicker.snuglyConstrain(to: blurSubview, toTop: navbar, toBottom: blurSubview, topAmount: 0, bottomAmount: 0)
    }
    
    // Will probably want to overide this in subclasses
    func initContent() {
        updateViewContents(with: "<p>Lorem ipsummm</p>")
    }
    
    func initNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: .UIApplicationWillEnterForeground, object: nil)
    }
    
    // Probably want to override in subclasses
    func expandHook() {
    }
    
    // Probably want to override in subclasses
    func contractHook() {
    }
    
    // Might want to override in subclasses
    func hidePickerShowOriginalView() {
        rightLanguagePicker.isHidden = true
        textview.isHidden = false
    }
    
    // Should probably override this in subclasses
    func updateViewContents(with htmlStr: String?) {
        guard let htmlStr = htmlStr else {
            return
        }
        
        let extendedStr = htmlStr
        if let attrbStr = extendedStr.htmlToAttributedString {
            let mutableAttrbStr = NSMutableAttributedString(attributedString: attrbStr)
            textview.attributedText = mutableAttrbStr.trimmedAttributedString(set: .whitespacesAndNewlines)
        }
    }
    
    // Override in subclasses
    func getApiPath() -> String {
        return "health"
    }
    
    // Override in subclasses
    func getNavbarTitleName() -> String {
        return "Base \(Int(Double(arc4random()) / Double(UINT32_MAX) * 100.0))"
    }
    
    func langCodeToName(languages: [String: [String: String]], matchCode: String) -> String? {
        var match: String?
        for (humanReadable, codes) in languages {
            let code = codes["basic"] ?? ""
            if matchCode == code {
                if rightSelectedRegion != nil {
                    let region = codes["region"] ?? ""
                    if rightSelectedRegion == region {
                        match = humanReadable
                    }
                } else {
                    match = humanReadable
                }
            }
        }
        return match
    }
    
    // Should probably override this
    func persistenceKey() -> String? {
        return nil  // nil if we don't want to persist this
    }
    
    func getPersistableAttributedText() -> NSAttributedString {
        return textview.attributedText
    }
    
    func getPersistableText() -> String {
        return textview.text
    }
    
    // Override in subclasses
    func getRightSelectedLanguage() -> String {
        if rightSelectedLanguage == nil {
            rightSelectedLanguage = Constants.DefaultLanguage
        }
        return rightSelectedLanguage!
    }
    
    // Override in subclasses
    func getSupportedLangs() -> [String: [String: String]] {
        return Constants.DefaultSupportedLangs
    }
    
    func getJsonObj(iCloudHash: String, text: String) -> [String: Any] {
        return [
            "iCloudUserNameHash": iCloudHash,
            "searchText": text
        ]
    }
    
    // MARK: Transform input dictionary into form acceptable to jsonHandler
    func prepDictForJsonHandler(dict: [String: Any]) -> [String: Any]? {
        if let searchSuccess: Bool = Utilities.GetProp(named: "searchSuccess", from: dict), searchSuccess {
            return dict
        } else {
            return nil
        }
    }
    
    func refreshAux(dcData: Data?, t: String?) {
        
        // Get URL ready
        let paths = [Constants.AwsApiBaseURL, Constants.AwsApiStage, self.getApiPath()].filter { str in
            return str != ""
        }
        let url = URL(string: paths.joined(separator: "/"))!
        
        let sesh = URLSession(configuration: .default)
        var req = URLRequest(url: url)
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpMethod = "POST"
        
        var jsonObj = self.getJsonObj(iCloudHash: self.myDelegate.getICloudUserNameHash(), text: self.currentWord)
        if let dcData = dcData {
            jsonObj["deviceCheckToken"] = dcData.base64EncodedString()
        }
        if let t = t {
            jsonObj["t"] = t
        }
        let data = try! JSONSerialization.data(withJSONObject: jsonObj, options: [])
        
        req.httpBody = data
        var jsonObjToPrint = jsonObj
        jsonObjToPrint["deviceCheckToken"] = nil
        print("Calling \(url) in a definition view controller with \(jsonObjToPrint)")
        let task = sesh.dataTask(with: req, completionHandler: { (data, response, error) in
            if let data = data, let jsonData = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers),
                let jsonDictionary = jsonData as? [String: Any]  {
                
                DispatchQueue.main.async {
                    if let preppedJson = self.prepDictForJsonHandler(dict: jsonDictionary) {
                        if let t: String = Utilities.GetProp(named: "t", from: jsonDictionary) {
                            FlashcardCollections.EatT(t: t)
                        }
                        self.jsonHandler!(preppedJson)
                    } else {  // if failed, show explanation
                        // TODO
                    }
                }
            } else {
                self.cleanupAfterFailedRPC()
            }
        })
        task.resume()
    }
    
    // MARK: Call API endpoint and process its response for ONLY this definition view controller. Aggregate searches are performed in ViewController. This is called when e.g. the selected language is updated and we don't want to refresh the other two definition view controllers.
    func refresh() {
        
        if jsonHandler == nil {
            print("Error: jsonHandler hasn't been initialized yet")
            return
        }
        
        if let t = FlashcardCollections.DatT() {
            self.refreshAux(dcData: nil, t: t)
        } else if Constants.CurrDevice.isSupported {
            Constants.CurrDevice.generateToken { (dcData, error) in
                if let dcData = dcData {
                    DispatchQueue.main.sync {
                        self.refreshAux(dcData: dcData, t: nil)
                    }
                }
                if let error = error {
                    print("Error when generating a token:", error.localizedDescription)
                }
            }
        } else {
            print("Platform is not supported or you missing dat t")
        }
    }
    
    func cleanupAfterFailedRPC() {
        
        // Do exponential back-off
        guard retries < Constants.MaxRetries else {
            print("Hit max retries in translate. Reload screen to try again")
            return
        }
        let secondsToWait = Double(Utilities.Exp(2, retries))
        retries += 1
        
        DispatchQueue.main.async {
            Timer.scheduledTimer(withTimeInterval: secondsToWait, repeats: false) { _ in
                print("Waited \(secondsToWait) seconds. Retrying RPC in definition view controller.")
                self.refresh()
            }
        }
    }
    
    // MARK: Called from handler for link clicks in webview
    func textviewLinkClickHandler(url: URL) {  // override in some subclasses
        print("Clicked a link in the textview")
    }
    
    // Override in subclasses with multiple pickers
    func getRowCount(in pickerView: UIPickerView) -> Int{
        return getSupportedLangs().count
    }
    
    // Override in subclasses with multiple pickers
    func getNameFor(row: Int, in pickerView: UIPickerView) -> String? {
        return getSupportedLangs().keys.sorted()[row]
    }
    
    func shortenLanguage(title: String) -> String {
        let splitAroundLeftParen = title.split(separator: "(")
        var shortTitle = String(title)
        if splitAroundLeftParen.count > 1 {
            shortTitle = splitAroundLeftParen[0].trimmingCharacters(in: .whitespaces)
        }
        if shortTitle.count > DefinitionViewController.MaxLanguageTitleLength {
            let endIdx = shortTitle.index(shortTitle.startIndex, offsetBy: DefinitionViewController.MaxLanguageTitleLength)
            shortTitle = String(shortTitle[..<endIdx]) + "..."
        }
        return shortTitle
    }
    
    // MARK: Selected right language. Override in subclasses that have more than one language picker
    func didSelectRowHandler(row: Int, view pickerView: UIPickerView) {
        rightSelectedLanguage = getSupportedLangs()[getSupportedLangs().keys.sorted()[row]]?["basic"]
        let title = langCodeToName(languages: getSupportedLangs(), matchCode: getRightSelectedLanguage())!
        rightLanguageButton.title = shortenLanguage(title: title)
        hidePickerShowOriginalView()
        refresh()
    }
}

// MARK: - Button handlers and helpers
extension DefinitionViewController {
    
    @IBAction func handleSwipeUp(_ sender: UISwipeGestureRecognizer) {
        if !expanded {
            expandDefinitionViewFunc!()
        }
    }
    
    @IBAction func handleSwipeDown(_ sender: UISwipeGestureRecognizer) {
        if expanded {
            contractDefinitionViewFunc!()
        }
    }
    
    @IBAction func handleRightLanguageButton(_ sender: UIBarButtonItem) {
        if rightLanguagePicker.isHidden {
            textview.isHidden = true
            rightLanguagePicker.isHidden = false
        } else {
            textview.isHidden = false
            rightLanguagePicker.isHidden = true
        }
    }
}

// MARK: - Methods for language picker
extension DefinitionViewController: UIPickerViewDelegate, UIPickerViewDataSource {

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return getRowCount(in: pickerView)
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return getNameFor(row: row, in: pickerView)
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        didSelectRowHandler(row: row, view: pickerView)
    }
}

// MARK: - Javascript used to notify ButtonConsciousWebView that it should set navigation flags
extension DefinitionViewController: WKScriptMessageHandler {
    
    // MARK: Calls handler when entire URL changs
    func getConfigWithURLObserverOnTimer() -> WKWebViewConfiguration {
        let javascript = """
        function doFunc() {
            var currentURL = location.href;
            if (currentURL !== lastSeenURL) {
                lastSeenURL = currentURL;
                webkit.messageHandlers.hashchangeMessageHandler.postMessage(null);
            }
        }
        var lastSeenURL = location.href;
        setInterval(doFunc, 250);
        """
        let script = WKUserScript(source: javascript, injectionTime: WKUserScriptInjectionTime.atDocumentEnd, forMainFrameOnly: false)
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.add(self, name: "hashchangeMessageHandler")
        configuration.userContentController.addUserScript(script)
        return configuration
    }
    
    // MARK: Receives a message when a script thinks it's time to enable/disable nav buttons
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("There was a URL change! New URL is", webview.url ?? "")
        webview.setNavigationButtonEnableFlags()
    }
}

// MARK: - Handle links in the attributed text view
extension DefinitionViewController: UITextViewDelegate {

    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        textviewLinkClickHandler(url: URL)
        return false
    }
}
