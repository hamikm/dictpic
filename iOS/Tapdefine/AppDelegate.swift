//
//  AppDelegate.swift
//  Tapdefine
//
//  Created by Hamik on 6/21/18.
//  Copyright © 2018 Hamik. All rights reserved.
//

import Firebase
import Siren
import UIKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    static let IsFirstLaunchKey = "isFirstLaunch"
    
    var window: UIWindow?
    
    // Notifications
    static var NotificationCenter = UNUserNotificationCenter.current()
    static let NotificationOptions: UNAuthorizationOptions = [.alert]

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        // Make all navbars translucent
        UINavigationBar.appearance().setBackgroundImage(UIImage(), for: .default)
        UINavigationBar.appearance().backgroundColor = UIColor.clear
        UINavigationBar.appearance().isTranslucent = true
        
        // Set notifications delegate. We ask for permissions in ReminderVC
        AppDelegate.NotificationCenter.delegate = self
        
        // Set up our ghetto user defaults database
        AppDelegate.SetIsFirstLaunch()
        FlashcardCollections.InitializeFlashcardCollections()
        
        // Initialize Firebase after (a future) transaction observer
        FirebaseApp.configure()
        
        // Set up Siren, which asks users to upgrade
        Siren.shared.patchUpdateAlertType = .option
        Siren.shared.minorUpdateAlertType = .option
        Siren.shared.majorUpdateAlertType = .force
        Siren.shared.showAlertAfterCurrentVersionHasBeenReleasedForDays = 2  // don't set to 0. There is Apple CDN bug
        Siren.shared.debugEnabled = true
        
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        Siren.shared.checkVersion(checkType: .daily)
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        Siren.shared.checkVersion(checkType: .immediately)
    }

    private func handleSharedDeck(url: URL) -> Bool {
        guard let collectionName = CollectionsTableViewController.ImportData(from: url) else {
            print("Couldn't import data")
            return false
        }
        
        guard let tabBarController = window?.rootViewController as? TabBarViewController else {
            print("rootViewController isn't a TabBarViewController for some reason...")
            return false
        }
        
        // Navigate to the shared deck that was just opened
        tabBarController.selectedIndex = TabBarViewController.StudyTabTagAndIndex
        let deckToOpen = collectionName
        tabBarController.studyVC?.loadDeck(named: deckToOpen, shouldCloseTopbar: true)
        if let pickDeckController = tabBarController.studyVC?.pickDeckControllerCast {
            pickDeckController.refreshViewController()
        }
        
        return true
    }
    
    private func handleSharedImage(url: URL) -> Bool {
        var sharedImage: UIImage?
        do {
            let imageData = try Data(contentsOf: url)
            sharedImage = UIImage(data: imageData)
        } catch {
            print("Error loading image: \(error)")
            return false
        }
        
        guard let tabBarController = window?.rootViewController as? TabBarViewController else {
            print("rootViewController isn't a TabBarViewController for some reason...")
            return false
        }
        
        // Navigate to the shared deck that was just opened
        tabBarController.selectedIndex = TabBarViewController.SearchTabTagAndIndex
        tabBarController.searchVC?.recognizeWords(fromShared: sharedImage!)
        
        return true
    }
    
    // MARK: handle shared decks
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {

        if "deck".contains(url.pathExtension.trimmingCharacters(in: .whitespaces).lowercased()) {
            return handleSharedDeck(url: url)
        } else {
            return handleSharedImage(url: url)
        }
    }
    
    static func IsFirstLaunchKeyExists() -> Bool {
        return UserDefaults.standard.object(forKey: AppDelegate.IsFirstLaunchKey) != nil
    }
    
    static func IsFirstLaunch() -> Bool {
        return UserDefaults.standard.bool(forKey: AppDelegate.IsFirstLaunchKey)
    }
    
    static func SetIsFirstLaunch() {
        // Set isFirstLaunch in User Defaults if it's the first launch ever
        if !IsFirstLaunchKeyExists() {
            UserDefaults.standard.set(true, forKey: AppDelegate.IsFirstLaunchKey)
            print("First launch ever")
        } else if IsFirstLaunch() {  // If second one, flip value to flase
            print("Second launch ever")
            UserDefaults.standard.set(false, forKey: AppDelegate.IsFirstLaunchKey)
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {

        guard let tabBarController = window?.rootViewController as? TabBarViewController else {
            print("rootViewController isn't a TabBarViewController for some reason...")
            return
        }
        
        tabBarController.selectedIndex = TabBarViewController.StudyTabTagAndIndex
        let deckToOpen = response.notification.request.content.categoryIdentifier
        tabBarController.studyVC?.loadDeck(named: deckToOpen, shouldCloseTopbar: true)
        
        completionHandler()
    }
}

extension String {
    
    static var CharsThatDoNotHaveToBeUrlEncoded: CharacterSet {
        var allowedWithoutEncoding = CharacterSet()
        allowedWithoutEncoding.insert(charactersIn: "-._~/?:()=")
        allowedWithoutEncoding = allowedWithoutEncoding.union(.alphanumerics)
        return allowedWithoutEncoding
    }
    
    var htmlToAttributedString: NSAttributedString? {
        guard let data = data(using: .utf8) else { return NSAttributedString() }
        do {
            return try NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding:String.Encoding.utf8.rawValue], documentAttributes: nil)
        } catch {
            return NSAttributedString()
        }
    }

    var htmlToString: String {
        return htmlToAttributedString?.string ?? ""
    }
    
    var stringByAddingPercentEncodingForRFC3986: String? {
        return self.addingPercentEncoding(withAllowedCharacters: String.CharsThatDoNotHaveToBeUrlEncoded)
    }
    
    // MARK: turns a long string into e.g. "long str..."
    func abbreviateWithDots(after index: Int) -> String {
        guard index < self.count else {
            return self
        }
        let idx = self.index(self.startIndex, offsetBy: index)
        return String(self[..<idx]) + "..."
    }
    
    func heightForLabel(fontSize: CGFloat, labelWidth: CGFloat) -> CGFloat {
        return heightForLabel(font: Constants.StandardFont(ofSize: fontSize), labelWidth: labelWidth)
    }
    
    func heightForLabel(font: UIFont?, labelWidth: CGFloat) -> CGFloat {
        guard let font = font else {
            print("Error: no font given")
            return CGFloat(0)
        }
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: labelWidth, height: CGFloat.greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.font = font
        label.text = self
        label.sizeToFit()
        return label.frame.height
    }
}

extension NSMutableAttributedString {
    
    func trimmedAttributedString(set: CharacterSet) -> NSMutableAttributedString {
        
        let invertedSet = set.inverted
        
        var range = (string as NSString).rangeOfCharacter(from: invertedSet)
        let loc = range.length > 0 ? range.location : 0
        
        range = (string as NSString).rangeOfCharacter(
            from: invertedSet, options: .backwards)
        let len = (range.length > 0 ? NSMaxRange(range) : string.count) - loc
        
        let r = self.attributedSubstring(from: NSMakeRange(loc, len))
        return NSMutableAttributedString(attributedString: r)
    }
}

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(rgb: Int) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF
        )
    }
}

extension UIView {
    
    // All sides
    func snuglyConstrain(to: UIView) {
        (_, _) = snuglyConstrain(to: to, leftAmount: 0, rightAmount: 0)
        (_, _) = snuglyConstrain(to: to, topAmount: 0, bottomAmount: 0)
    }

    // Left right
    func snuglyConstrain(to: UIView, leftAmount: CGFloat = 0, rightAmount: CGFloat = 0) -> (NSLayoutConstraint?, NSLayoutConstraint?) {
        return snuglyConstrain(to: to, toLeft: to, toRight: to, leftAmount: leftAmount, rightAmount: rightAmount)
    }
    
    func snuglyConstrain(to: UIView, toLeft: UIView, toRight: UIView, leftAmount: CGFloat, rightAmount: CGFloat) -> (NSLayoutConstraint?, NSLayoutConstraint?) {
        let nestLeft = to == toLeft
        let nestRight = to == toRight
        let leftConstraint = NSLayoutConstraint(item: self, attribute: .left, relatedBy: .equal, toItem: nestLeft ? to : toLeft, attribute: nestLeft ? .left : .right, multiplier: 1, constant: leftAmount)
        let rightConstraint = NSLayoutConstraint(item: self, attribute: .right, relatedBy: .equal, toItem: nestRight ? to : toRight, attribute: nestRight ? .right : .left, multiplier: 1, constant: -rightAmount)
        self.translatesAutoresizingMaskIntoConstraints = false
        to.addConstraints([leftConstraint, rightConstraint])
        return (leftConstraint, rightConstraint)
    }
    
    // Top bottom
    func snuglyConstrain(to: UIView, topAmount: CGFloat, bottomAmount: CGFloat) -> (NSLayoutConstraint?, NSLayoutConstraint?) {
        return snuglyConstrain(to: to, toTop: to, toBottom: to, topAmount: topAmount, bottomAmount: bottomAmount)
    }
    
    func snuglyConstrain(to: UIView, toTop: UIView, toBottom: UIView, topAmount: CGFloat, bottomAmount: CGFloat) -> (NSLayoutConstraint?, NSLayoutConstraint?) {
        let nestedTop = to == toTop
        let nestedBottom = to == toBottom
        let topConstraint = NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: nestedTop ? to : toTop, attribute: nestedTop ? .top : .bottom, multiplier: 1, constant: topAmount)
        let bottomConstraint = NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: nestedBottom ? to : toBottom, attribute: nestedBottom ? .bottom : .top, multiplier: 1, constant: -bottomAmount)
        self.translatesAutoresizingMaskIntoConstraints = false
        to.addConstraints([topConstraint, bottomConstraint])
        return (topConstraint, bottomConstraint)
    }
    
    // Top left
    func snuglyConstrain(to: UIView, leftAmount: CGFloat, topAmount: CGFloat) {
        snuglyConstrain(to: to, toLeft: to, toTop: to, leftAmount: leftAmount, topAmount: topAmount)
    }
    
    func snuglyConstrain(to: UIView, toLeft: UIView, toTop: UIView, leftAmount: CGFloat, topAmount: CGFloat) {
        let nestLeft = to == toLeft
        let nestTop = to == toTop
        let leftConstraint = NSLayoutConstraint(item: self, attribute: .left, relatedBy: .equal, toItem: nestLeft ? to : toLeft, attribute: nestLeft ? .left : .right, multiplier: 1, constant: leftAmount)
        let topConstraint = NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: nestTop ? to : toTop, attribute: nestTop ? .top : .bottom, multiplier: 1, constant: topAmount)
        self.translatesAutoresizingMaskIntoConstraints = false
        to.addConstraints([leftConstraint, topConstraint])
    }
    
    // Top right
    func snuglyConstrain(to: UIView, topAmount: CGFloat, rightAmount: CGFloat) {
        snuglyConstrain(to: to, toTop: to, toRight: to, topAmount: topAmount, rightAmount: rightAmount)
    }
    
    func snuglyConstrain(to: UIView, toTop: UIView, toRight: UIView, topAmount: CGFloat, rightAmount: CGFloat) {
        let nestTop = to == toTop
        let nestRight = to == toRight
        let topConstraint = NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: nestTop ? to : toTop, attribute: nestTop ? .top : .bottom, multiplier: 1, constant: topAmount)
        let rightConstraint = NSLayoutConstraint(item: self, attribute: .right, relatedBy: .equal, toItem: nestRight ? to : toRight, attribute: nestRight ? .right : .left, multiplier: 1, constant: -rightAmount)
        self.translatesAutoresizingMaskIntoConstraints = false
        to.addConstraints([topConstraint, rightConstraint])
    }
    
    // Bottom left
    func snuglyConstrain(to: UIView, leftAmount: CGFloat, bottomAmount: CGFloat) -> (NSLayoutConstraint?, NSLayoutConstraint?) {
        return snuglyConstrain(to: to, toLeft: to, toBottom: to, leftAmount: leftAmount, bottomAmount: bottomAmount)
    }
    
    func snuglyConstrain(to: UIView, toLeft: UIView, toBottom: UIView, leftAmount: CGFloat, bottomAmount: CGFloat) -> (NSLayoutConstraint?, NSLayoutConstraint?) {
        let nestLeft = to == toLeft
        let nestBottom = to == toBottom
        let leftConstraint = NSLayoutConstraint(item: self, attribute: .left, relatedBy: .equal, toItem: nestLeft ? to : toLeft, attribute: nestLeft ? .left : .right, multiplier: 1, constant: leftAmount)
        let bottomConstraint = NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: nestBottom ? to : toBottom, attribute: nestBottom ? .bottom : .top, multiplier: 1, constant: -bottomAmount)
        self.translatesAutoresizingMaskIntoConstraints = false
        to.addConstraints([leftConstraint, bottomConstraint])
        return (leftConstraint, bottomConstraint)
    }
    
    // Bottom right
    func snuglyConstrain(to: UIView, rightAmount: CGFloat, bottomAmount: CGFloat) -> (NSLayoutConstraint?, NSLayoutConstraint?) {
        return snuglyConstrain(to: to, toRight: to, toBottom: to, rightAmount: rightAmount, bottomAmount: bottomAmount)
    }
    
    func snuglyConstrain(to: UIView, toRight: UIView, toBottom: UIView, rightAmount: CGFloat, bottomAmount: CGFloat) -> (NSLayoutConstraint?, NSLayoutConstraint?) {
        let nestRight = to == toRight
        let nestBottom = to == toBottom
        let rightConstraint = NSLayoutConstraint(item: self, attribute: .right, relatedBy: .equal, toItem: nestRight ? to : toRight, attribute: nestRight ? .right : .left, multiplier: 1, constant: -rightAmount)
        let bottomConstraint = NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: nestBottom ? to : toBottom, attribute: nestBottom ? .bottom : .top, multiplier: 1, constant: -bottomAmount)
        self.translatesAutoresizingMaskIntoConstraints = false
        to.addConstraints([rightConstraint, bottomConstraint])
        return (rightConstraint, bottomConstraint)
    }
    
    func dimensionContraints(to: UIView, width: CGFloat, height: CGFloat) -> (NSLayoutConstraint?, NSLayoutConstraint?) {
        let widthConstraint = NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: width)
        let heightConstraint = NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: height)
        self.translatesAutoresizingMaskIntoConstraints = false
        to.addConstraints([widthConstraint, heightConstraint])
        return (widthConstraint, heightConstraint)
    }
    
    func centerView(to: UIView, x: Bool = true, y: Bool = true) {
        if x {
            let centerXConstraint = NSLayoutConstraint(item: self, attribute: .centerX, relatedBy: .equal, toItem: to, attribute: .centerX, multiplier: 1, constant: 0)
            self.translatesAutoresizingMaskIntoConstraints = false
            to.addConstraints([centerXConstraint])
        }
        if y {
            let centerYConstraint = NSLayoutConstraint(item: self, attribute: .centerY, relatedBy: .equal, toItem: to, attribute: .centerY, multiplier: 1, constant: 0)
            self.translatesAutoresizingMaskIntoConstraints = false
            to.addConstraints([centerYConstraint])
        }
    }
    
    func addDashedBorder(lastBorder: CAShapeLayer?, ofColor color: UIColor, dashLength: NSNumber, dashSpacing: NSNumber, cornerRadius: CGFloat) -> CAShapeLayer {
        if let lastBorder = lastBorder {
            lastBorder.removeFromSuperlayer()
        }
        
        let shapeLayer: CAShapeLayer = CAShapeLayer()
        let frameSize = self.frame.size
        let shapeRect = CGRect(x: 1, y: 1, width: frameSize.width - 2, height: frameSize.height - 2)
        
        shapeLayer.bounds = shapeRect
        shapeLayer.position = CGPoint(x: frameSize.width / 2, y: frameSize.height / 2)
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = color.cgColor
        shapeLayer.lineWidth = 1
        shapeLayer.lineJoin = kCALineJoinRound
        shapeLayer.lineDashPattern = [dashLength, dashSpacing]
        shapeLayer.path = UIBezierPath(roundedRect: shapeRect, cornerRadius: cornerRadius).cgPath
        
        self.layer.addSublayer(shapeLayer)
        return shapeLayer
    }
    
    // MARK: Adds a border of a given color. Useful for testing
    func addBorder(ofColor: UIColor, ofWidth: CGFloat = CGFloat(1)) {
        layer.borderColor = ofColor.cgColor
        layer.borderWidth = ofWidth
    }
}

extension UIImage {
    func correctlyOrientedImage() -> UIImage? {

        if self.imageOrientation == UIImageOrientation.up {
            return self
        }

        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        self.draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        let normalizedImage: UIImage? = UIGraphicsGetImageFromCurrentImageContext() ?? nil
        UIGraphicsEndImageContext()
        
        return normalizedImage
    }
}

extension UIPageViewController {
    
    func goToPreviousPage(animated: Bool = false) -> Bool {
        guard let currentViewController = self.viewControllers?.first else { return false }
        guard let previousViewController = dataSource?.pageViewController(self, viewControllerBefore: currentViewController) else { return false }
        setViewControllers([previousViewController], direction: .reverse, animated: animated, completion: nil)
        return true
    }
    
    func goToStartPage(animated: Bool = false) {
        while goToPreviousPage(animated: animated) {
        }
    }
}

extension Double {
    static func RandInUnitInterval() -> Double {
        return Double(arc4random()) / Double(UINT32_MAX)
    }
}

extension Int {
    static func RandInInterval(_ a: Int, _ b: Int) -> Int {
        let smaller = Double(a < b ? a : b)
        let larger = Double(a >= b ? a : b)
        return Int(smaller + (larger - smaller) * Double.RandInUnitInterval())
    }
}

extension CGFloat {
    func approximatelyEquals(other: CGFloat, epsilon: CGFloat = 0.01) -> Bool {
        return (self - other > -epsilon) && (self - other < epsilon)
    }
}

extension UIButton {
    func initPictureButton(in containingView: UIView, imageName: String, withColor buttonColor: UIColor, width: CGFloat, height: CGFloat) {
        (_, _) = dimensionContraints(to: containingView, width: width, height: height)
        setTitle("", for: .normal)
        setImage(UIImage(named: imageName)?.withRenderingMode(.alwaysTemplate), for: .normal)
        tintColor = buttonColor
        imageView?.contentMode = UIViewContentMode.scaleAspectFill
    }
    
    func initPictureButtonLabel(in superviewContainer: UIView, textColor: UIColor, fontSize: CGFloat, topMargin: CGFloat, labelHeight: CGFloat) -> UILabel {
        let label = UILabel()
        label.textColor = textColor
        label.font = label.font.withSize(fontSize)
        superviewContainer.addSubview(label)
        let lubcc = NSLayoutConstraint(item: label, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0)
        let lubtc = NSLayoutConstraint(item: label, attribute: .top, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: topMargin)
        let lubhc = NSLayoutConstraint(item: label, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: labelHeight)
        label.translatesAutoresizingMaskIntoConstraints = false
        superviewContainer.addConstraints([lubcc, lubtc, lubhc])
        return label
    }
}

class PaddedTextField: UITextField {
    
    var padding = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    
    override open func textRect(forBounds bounds: CGRect) -> CGRect {
        return UIEdgeInsetsInsetRect(bounds, padding)
    }
    
    override open func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return UIEdgeInsetsInsetRect(bounds, padding)
    }
    
    override open func editingRect(forBounds bounds: CGRect) -> CGRect {
        return UIEdgeInsetsInsetRect(bounds, padding)
    }
}

extension Date {
    
    static func - (lhs: Date, rhs: Date) -> TimeInterval {
        return lhs.timeIntervalSinceReferenceDate - rhs.timeIntervalSinceReferenceDate
    }
}

extension TimeInterval {
    
    func toDays() -> Int {
        return Int(((self / (3600 * 24)) + 0.5))
    }
}

extension UITabBar {
    func getUIViewForTabAt(index: Int) -> UIView? {
        var views = self.subviews.compactMap { return $0 is UIControl ? $0 : nil }
        views.sort { $0.frame.origin.x < $1.frame.origin.x }
        return views[safe: index]
    }
}

extension Collection {
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
