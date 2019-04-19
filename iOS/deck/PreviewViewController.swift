//
//  PreviewViewController.swift
//  deck
//
//  Created by Hamik on 11/6/18.
//  Copyright © 2018 Hamik. All rights reserved.
//

import UIKit
import QuickLook

class PreviewViewController: UIViewController, QLPreviewingController {

    static let NeutralBackgroundColor = UIColor(rgb: 0xfbfbfb)
    static let LightestGray = UIColor(rgb: 0xcccccc)
    static let GradientStartColor = UIColor(rgb: 0x4286f4)
    static let GradientEndColor = UIColor(rgb: 0x373B44)
    static let DarkGray = UIColor(rgb: 0x303030)
    static let HelperString = "Tap share then \"Copy to Dictpic\""
    static let TitleString = "Dictpic Deck File"

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view from its nib.
    }
        
    func preparePreviewOfSearchableItem(identifier: String, queryString: String?, completionHandler handler: @escaping (Error?) -> Void) {
        // Perform any setup necessary in order to prepare the view.
        
        // Call the completion handler so Quick Look knows that the preview is fully loaded.
        // Quick Look will display a loading spinner while the completion handler is not called.
        handler(nil)
    }
    
    /*
     * Implement this method if you support previewing files.
     * Add the supported content types to the QLSupportedContentTypes array in the Info.plist of the extension.
     */
    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        
        guard let uncastCollectionInfo = NSDictionary(contentsOf: url), let collectionInfo = uncastCollectionInfo as? [String: Any], let collectionName = collectionInfo["collectionName"] as? String else {
            print("Could not import from", url)
            return
        }
        
        // Flashcard deck
        let topFlashcardView = flashcardBox(in: view, multiple: CGFloat(0.9), yOffset: CGFloat(-25), cardAbove: nil)
        let middleFlashcardView = flashcardBox(in: view, multiple: CGFloat(0.86), yOffset: CGFloat(4), cardAbove: topFlashcardView)
        let bottomFlashcardView = flashcardBox(in: view, multiple: CGFloat(0.82), yOffset: CGFloat(4), cardAbove: middleFlashcardView)
        view.sendSubviewToBack(topFlashcardView)
        view.sendSubviewToBack(middleFlashcardView)
        view.sendSubviewToBack(bottomFlashcardView)
        
        // Dictpic deck file
        let title = UILabel()
        topFlashcardView.addSubview(title)
        title.backgroundColor = UIColor.clear
        title.font = UIFont.systemFont(ofSize: 25.0, weight: .bold)
        title.text = PreviewViewController.TitleString
        title.textColor = PreviewViewController.DarkGray
        title.textAlignment = .center
        let txc = NSLayoutConstraint(item: title, attribute: .centerX, relatedBy: .equal, toItem: topFlashcardView, attribute: .centerX, multiplier: 1, constant: 0)
        let tyc = NSLayoutConstraint(item: title, attribute: .centerY, relatedBy: .equal, toItem: topFlashcardView, attribute: .centerY, multiplier: 1, constant: CGFloat(-15))
        let tlc = NSLayoutConstraint(item: title, attribute: .left, relatedBy: .equal, toItem: topFlashcardView, attribute: .left, multiplier: 1, constant: CGFloat(10))
        let trc = NSLayoutConstraint(item: title, attribute: .right, relatedBy: .equal, toItem: topFlashcardView, attribute: .right, multiplier: 1, constant: CGFloat(-10))
        title.translatesAutoresizingMaskIntoConstraints = false
        topFlashcardView.addConstraints([txc, tyc, tlc, trc])
        
        // Title of deck (subtitle)
        let deckTitle = UILabel()
        topFlashcardView.addSubview(deckTitle)
        deckTitle.backgroundColor = UIColor.clear
        deckTitle.font = UIFont.systemFont(ofSize: 15.0, weight: .regular)
        deckTitle.text = collectionName
        deckTitle.textColor = PreviewViewController.LightestGray
        deckTitle.textAlignment = .center
        let dtxc = NSLayoutConstraint(item: deckTitle, attribute: .centerX, relatedBy: .equal, toItem: topFlashcardView, attribute: .centerX, multiplier: 1, constant: 0)
        let dttc = NSLayoutConstraint(item: deckTitle, attribute: .top, relatedBy: .equal, toItem: title, attribute: .bottom, multiplier: 1, constant: CGFloat(5))
        let dtlc = NSLayoutConstraint(item: deckTitle, attribute: .left, relatedBy: .equal, toItem: topFlashcardView, attribute: .left, multiplier: 1, constant: CGFloat(20))
        let dtrc = NSLayoutConstraint(item: deckTitle, attribute: .right, relatedBy: .equal, toItem: topFlashcardView, attribute: .right, multiplier: 1, constant: CGFloat(-20))
        deckTitle.translatesAutoresizingMaskIntoConstraints = false
        topFlashcardView.addConstraints([dtxc, dttc, dtlc, dtrc])
        
        // Background gradient view
        let backgroundGradient = UIView()
        view.addSubview(backgroundGradient)
        backgroundGradient.backgroundColor = UIColor.clear
        let bgvlc = NSLayoutConstraint(item: backgroundGradient, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1, constant: 0)
        let bgvrc = NSLayoutConstraint(item: backgroundGradient, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1, constant: 0)
        let bgvtc = NSLayoutConstraint(item: backgroundGradient, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 0)
        let bgvbc = NSLayoutConstraint(item: backgroundGradient, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0)
        backgroundGradient.translatesAutoresizingMaskIntoConstraints = false
        view.addConstraints([bgvlc, bgvrc, bgvtc, bgvbc])
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = view.bounds
        gradientLayer.colors = [
            PreviewViewController.GradientStartColor.cgColor,
            PreviewViewController.GradientEndColor.cgColor
        ]
        backgroundGradient.layer.addSublayer(gradientLayer)
        view.sendSubviewToBack(backgroundGradient)
        
        // Explainer text
        let helperText = UILabel()
        view.addSubview(helperText)
        helperText.backgroundColor = UIColor.clear
        helperText.font = UIFont.systemFont(ofSize: 17.0, weight: .ultraLight)
        helperText.textColor = UIColor.white
        helperText.textAlignment = .center
        helperText.text = PreviewViewController.HelperString
        helperText.translatesAutoresizingMaskIntoConstraints = false
        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            helperText.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: CGFloat(-10)),
            helperText.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: CGFloat(0)),
            helperText.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: CGFloat(0))
        ])

        handler(nil)
    }
    
    private func flashcardBox(in containerView: UIView, multiple: CGFloat, yOffset: CGFloat, cardAbove: UIView?) -> UIView {
        let flashcardView = UIView()
        containerView.addSubview(flashcardView)
        flashcardView.backgroundColor = PreviewViewController.NeutralBackgroundColor
        flashcardView.layer.cornerRadius = 5.0
        flashcardView.layer.borderColor =
            PreviewViewController.LightestGray.cgColor
        flashcardView.layer.borderWidth = 1.0
        let fvwc = NSLayoutConstraint(item: flashcardView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: view.frame.width * multiple)
        let fvhc = NSLayoutConstraint(item: flashcardView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: fvwc.constant / CGFloat(1.6))  // golden ratio ish
        let fvxc = NSLayoutConstraint(item: flashcardView, attribute: .centerX, relatedBy: .equal, toItem: containerView, attribute: .centerX, multiplier: 1, constant: 0)
        var fvvc: NSLayoutConstraint?
        if let cardAbove = cardAbove {
            fvvc = NSLayoutConstraint(item: flashcardView, attribute: .bottom, relatedBy: .equal, toItem: cardAbove, attribute: .bottom, multiplier: 1, constant: yOffset)
        } else {
            fvvc = NSLayoutConstraint(item: flashcardView, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1, constant: yOffset)
        }
        flashcardView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addConstraints([fvwc, fvhc, fvxc, fvvc!])
        return flashcardView
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
