//
//  CardView.swift
//  Tapdefine
//
//  Created by Hamik on 8/30/18.
//  Copyright © 2018 Hamik. All rights reserved.
//

import UIKit

protocol CardViewActionReceiver {
    mutating func saveCurrentFlashcard(withNewContent: NSAttributedString, withIndex cardIndex: Int)
    mutating func deleteCurrentFlashcard(withIndex cardIndex: Int)
    mutating func didBeginEditing()
    mutating func didEndEditing()
    func present(optionsVC: UIViewController, animated: Bool)
}

class CardView: UIView {
    
    // MARK: - HTML constants
    static let FrontStyle = """
    .word {
        font-weight: bolder;
        font-size: 19pt;
        text-align: center;
        color: #\(Constants.DarkGrayString);
    }
    .subtitle {
        font-size: 11pt;
        color: #\(Constants.LightestGrayString);
        text-align: center;
    }
    """
    static let Subtitle = "<div class=\"subtitle\">{{subtitle-text}}</div>"
    static let FrontBody = "<div class=\"word\">{{word}}</div><br>{{subtitle-lines}}"
    static let BackStyle = """
    .section-name {
        font-weight: bolder;
        font-size: 12pt;
        color: #\(Constants.DarkGrayString);
    }
    """
    static let BackSectionBody = "<div class=\"section-name\">§ {{name}}</div>"
    
    // MARK: - Text
    static let EditButtonTitleString = "Edit"
    static let EditButtonCancelTitleString = "Cancel"
    static let SaveButtonTitleString = "Save"
    static let DeleteButtonTitleString = "Delete"
    static let DeletionPrompt = "Permanently delete {{word}}?"
    static let TapToPeekText = "tap to flip"
    static let CardIndexTemplateString = "{{card-index}}"
    static let UnknownWordString = "Unknown word"
    
    // MARK: - UI Constants
    static let FrontFooterTopMargin = CGFloat(0)
    static let TitleDeltaY = CGFloat(10)
    static let FooterFontSize = CGFloat(15)
    static let FooterHeight = CGFloat(30)
    static let FooterLifetime = 2.0
    static let FooterAnimationDuration = 0.5
    static let FrontCardNumberSize = FooterFontSize
    static let FrontCardNumberTopMargin = CGFloat(15)
    static let FrontCardNumberLeftMargin = CGFloat(20)
    static let FrontCardNumberHeight = FooterHeight
    
    // MARK: - Front views
    var frontsideView: UIView!
    var frontCardNumberLabel: UILabel!
    var frontContent: UILabel!
    var frontFooter: UILabel!
    
    // MARK: - Back views
    var backsideView: UIView!
    var navbar: UINavigationBar!
    var navbarTitle: UINavigationItem!
    var saveButton: UIBarButtonItem!
    var editButton: UIBarButtonItem!
    var deleteButton: UIBarButtonItem!
    var backContent: UITextView!
    
    // MARK: - Miscellaneous
    var onFrontSide = true
    var word: String!
    var contents: [String: NSAttributedString]!
    var actionReceiver: CardViewActionReceiver?
    var popoverInEscrow: ConfirmationPopoverViewController?
    var footerTimer: Timer!
    var oldBackContentText: NSAttributedString?
    var cardIndex: Int!
    var deckName: String!
    var cardUuid: String!
    
    convenience init(contents: [String: NSAttributedString], actionReceiver: CardViewActionReceiver, cardIndex: Int, deckName: String!) {
        self.init(frame: CGRect.zero)
        self.word = (contents[FlashcardCollections.WordAttributeName] ?? NSAttributedString(string: CardView.UnknownWordString)).string
        self.contents = contents
        self.cardIndex = cardIndex
        self.showFront()
        self.setFrontText()
        self.setBackText()
        self.actionReceiver = actionReceiver
        self.cardUuid = contents["uuid"]!.string
        self.deckName = deckName
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func setFooterDisappearanceTimer() {
        footerTimer = Timer.scheduledTimer(withTimeInterval: CardView.FooterLifetime, repeats: false) { _ in
            UIView.animate(withDuration: CardView.FooterAnimationDuration, animations: {
                self.frontFooter.alpha = 0
            }, completion: { _ in
                self.frontFooter.isHidden = true
                self.footerTimer?.invalidate()
                self.footerTimer = nil
            })
        }
    }
    
    private func commonInit() {
        
        // Parent view
        self.layer.cornerRadius = Constants.CornerRadius
        self.clipsToBounds = true
        self.addBorder(ofColor: Constants.LightestGray)
        
        // Tap to flip gesture
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTapToFlip(_:)))
        self.addGestureRecognizer(tap)
        self.isUserInteractionEnabled = true
        
        // Frontside view
        frontsideView = UIView()
        self.addSubview(frontsideView)
        
        // Frontside content
        frontContent = UILabel()
        frontsideView.addSubview(frontContent)
        frontContent.lineBreakMode = .byWordWrapping
        frontContent.numberOfLines = 0
        
        // Front card number
        frontCardNumberLabel = UILabel()
        frontCardNumberLabel.isHidden = true
        frontsideView.addSubview(frontCardNumberLabel)
        frontCardNumberLabel.textColor = Constants.LightestGray
        frontCardNumberLabel.font = frontCardNumberLabel.font.withSize(CardView.FrontCardNumberSize)
        frontsideView.bringSubview(toFront: frontCardNumberLabel)
        
        // Front footer
        frontFooter = UILabel()
        frontsideView.addSubview(frontFooter)
        frontFooter.textColor = Constants.LightestGray
        frontFooter.font = frontFooter.font.withSize(CardView.FooterFontSize)
        frontFooter.text = CardView.TapToPeekText
        
        // Backside view
        backsideView = UIView()
        self.addSubview(backsideView)
        
        // Navbar
        navbar = UINavigationBar()
        navbarTitle = UINavigationItem(title: "")
        navbar.setItems([navbarTitle], animated: false)
        navbar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: Constants.DarkGray]
        backsideView.addSubview(navbar)
        
        // Left navbar buttons
        deleteButton = UIBarButtonItem(title: CardView.DeleteButtonTitleString, style: .plain, target: self, action: #selector(self.handleDeleteButton))
        deleteButton.tintColor = Constants.TabBarButtonActiveColor
        navbarTitle.leftBarButtonItem = deleteButton
        
        // Right navbar buttons
        saveButton = UIBarButtonItem(title: CardView.SaveButtonTitleString, style: .plain, target: self, action: #selector(self.handleSaveButton))
        editButton = UIBarButtonItem(title: CardView.EditButtonTitleString, style: .plain, target: self, action: #selector(self.handleEditButton))
        navbarTitle.rightBarButtonItems = [editButton, saveButton]
        saveButton.isEnabled = false
        editButton.isEnabled = true
        saveButton.tintColor = Constants.TabBarButtonActiveColor
        editButton.tintColor = Constants.TabBarButtonActiveColor
        
        // Backside content
        backContent = UITextView()
        backsideView.addSubview(backContent)
        backContent.isEditable = false
        backContent.isSelectable = true
        backContent.backgroundColor = UIColor.clear
        backContent.linkTextAttributes = [NSAttributedStringKey.underlineColor.rawValue: UIColor.clear]
        
        // Play audio links
        backContent.delegate = self
    }
    
    override func updateConstraints() {
        
        // Front card number
        frontCardNumberLabel.snuglyConstrain(to: frontsideView, leftAmount: CardView.FrontCardNumberLeftMargin, topAmount: CardView.FrontCardNumberTopMargin)
        let fcnhc = NSLayoutConstraint(item: frontCardNumberLabel, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: CardView.FrontCardNumberHeight)
        frontCardNumberLabel.translatesAutoresizingMaskIntoConstraints = false
        frontsideView.addConstraints([fcnhc])
        
        // Front content
        let fccxc = NSLayoutConstraint(item: frontContent, attribute: .centerX, relatedBy: .equal, toItem: frontsideView, attribute: .centerX, multiplier: 1, constant: 0)
        let fccyc = NSLayoutConstraint(item: frontContent, attribute: .centerY, relatedBy: .equal, toItem: frontsideView, attribute: .centerY, multiplier: 1, constant: -CardView.TitleDeltaY)
        frontContent.translatesAutoresizingMaskIntoConstraints = false
        frontsideView.addConstraints([fccxc, fccyc])
        
        // Front footer
        frontsideView.snuglyConstrain(to: self)
        frontFooter.centerView(to: frontsideView, x: true, y: false)
        let ffhc = NSLayoutConstraint(item: frontFooter, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: CardView.FooterHeight)
        let fftc = NSLayoutConstraint(item: frontFooter, attribute: .top, relatedBy: .equal, toItem: frontContent, attribute: .bottom, multiplier: 1, constant: CardView.FrontFooterTopMargin)
        frontFooter.translatesAutoresizingMaskIntoConstraints = false
        frontsideView.addConstraints([ffhc, fftc])
        
        // Backside
        backsideView.snuglyConstrain(to: self)
        
        // Navbar
        (_, _) = navbar.snuglyConstrain(to: backsideView, leftAmount: 0, rightAmount: 0)
        let nbtc = NSLayoutConstraint(item: navbar, attribute: .top, relatedBy: .equal, toItem: backsideView, attribute: .top, multiplier: 1, constant: 0)
        let nbhc = NSLayoutConstraint(item: navbar, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: Constants.NavbarHeight)
        navbar.translatesAutoresizingMaskIntoConstraints = false
        backsideView.addConstraints([nbtc, nbhc])
        
        // Backside content
        (_, _) = backContent.snuglyConstrain(to: backsideView, leftAmount: Constants.LeftRightMarginInDefView, rightAmount: Constants.LeftRightMarginInDefView)
        (_, _) = backContent.snuglyConstrain(to: backsideView, toTop: navbar, toBottom: backsideView, topAmount: 0, bottomAmount: Constants.BottomMarginInDefView)
        
        super.updateConstraints()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        // Start even long definitions at top
        backContent.setContentOffset(.zero, animated: false)
    }
}

// MARK: initialization
extension CardView {
    
    func updateIndex() {
        guard let newCardIndex = FlashcardCollections.IndexOfCard(with: cardUuid, in: deckName) else {
            print("Couldn't find new index of card \(word ?? "unknown word")")
            return
        }
        cardIndex = newCardIndex
        frontCardNumberLabel.text = CardView.CardIndexTemplateString.replacingOccurrences(of: "{{card-index}}", with: String(cardIndex + 1))
        frontCardNumberLabel.isHidden = false
    }

    private func generateHtmlForSubtitle() -> String {
        return [CardView.TapToPeekText].map({ subtitle in
            return CardView.Subtitle.replacingOccurrences(of: "{{subtitle-text}}", with: subtitle)
        }).joined(separator: "")
    }
    
    func setFrontText() {
        var htmlDoc = Constants.ContentTemplate.replacingOccurrences(of: "{{more-style}}", with: CardView.FrontStyle)
        var htmlBody = CardView.FrontBody
        let htmlSubtitles = ""

        htmlBody = htmlBody.replacingOccurrences(of: "{{word}}", with: word).replacingOccurrences(of: "{{subtitle-lines}}", with: htmlSubtitles)
        htmlDoc = htmlDoc.replacingOccurrences(of: "{{body}}", with: htmlBody)

        if let attrbStr = htmlDoc.htmlToAttributedString {
            let mutableAttrbStr = NSMutableAttributedString(attributedString: attrbStr)
            let trimmed = mutableAttrbStr.trimmedAttributedString(set: .whitespacesAndNewlines)
            frontContent.attributedText = trimmed
        }
        
        frontCardNumberLabel.text = CardView.CardIndexTemplateString.replacingOccurrences(of: "{{card-index}}", with: String(cardIndex + 1))
    }

    private func getSectionNameAttributedString(name: String) -> NSMutableAttributedString {
        var htmlDoc = Constants.ContentTemplate.replacingOccurrences(of: "{{more-style}}", with: CardView.BackStyle)
        var htmlBody = CardView.BackSectionBody

        htmlBody = htmlBody.replacingOccurrences(of: "{{name}}", with: name)
        htmlDoc = htmlDoc.replacingOccurrences(of: "{{body}}", with: htmlBody)

        return NSMutableAttributedString(attributedString: htmlDoc.htmlToAttributedString!).trimmedAttributedString(set: .whitespacesAndNewlines)
    }

    private func setBackTextAux(rtn: NSMutableAttributedString, sectionName: String, contents: NSAttributedString) {
        let eol = NSAttributedString(string: "\n")
        rtn.append(getSectionNameAttributedString(name: sectionName))
        rtn.append(eol)
        rtn.append(eol)
        rtn.append(NSMutableAttributedString(attributedString: contents).trimmedAttributedString(set: .whitespacesAndNewlines))
        rtn.append(eol)
        rtn.append(eol)
    }
    
    func setBackText() {
        let rtn = NSMutableAttributedString()
        
        // If the user edited contents previously or made a new card from scratch, show that content
        if let userSuppliedContents = contents[FlashcardCollections.UserSuppliedContentsAttributeName] {
            rtn.append(userSuppliedContents)
        } else {  // otherwise construct flashcard contents from definition, wikipedia article, and translation
            let defPartMutable = contents[FlashcardCollections.DefinitionAttributeName] ?? NSMutableAttributedString(string: "No definition found 💔")
            setBackTextAux(rtn: rtn, sectionName: "Definition", contents: defPartMutable)
            
            let wikiPartMutable = contents[FlashcardCollections.WikipediaAttributeName] ?? NSMutableAttributedString(string: "No article found 😿")
            setBackTextAux(rtn: rtn, sectionName: "Wikipedia", contents: wikiPartMutable)
            
            let transPartMutable = contents[FlashcardCollections.TranslationAttributeName] ?? NSMutableAttributedString(string: "No translation found 😦")
            setBackTextAux(rtn: rtn, sectionName: "Translation", contents: transPartMutable)
        }

        backContent.attributedText = rtn.trimmedAttributedString(set: .whitespacesAndNewlines)
    }
    
    func showFront() {
        onFrontSide = true
        backsideView.isHidden = true
        frontsideView.isHidden = false
    }

    func showBack() {
        onFrontSide = false
        backsideView.isHidden = false
        frontsideView.isHidden = true
    }
}

// MARK: - Tap and button handlers
extension CardView {
    
    @objc func handleTapToFlip(_ sender: UITapGestureRecognizer) {
        if onFrontSide {
            showBack()
        } else {  // will only flip if the tap is on the navbar, since backContent is selectable
            if !backContent.isEditable {
                showFront()
            }
        }
    }

    @objc func handleDeleteButton() {
        popoverInEscrow = confirmationPopover()
    }
    
    @objc func handleEditButton() {
        if backContent.isEditable {  // toggling back to non-editing mode
            backContent.attributedText = oldBackContentText
            editButton.title = CardView.EditButtonTitleString
            actionReceiver?.didEndEditing()
            backContent.isEditable = false
            saveButton.isEnabled = false
            deleteButton.isEnabled = true
            closeKeyboard()
        } else {  // toggling to edit mode
            oldBackContentText = backContent.attributedText
            editButton.title = CardView.EditButtonCancelTitleString
            actionReceiver?.didBeginEditing()
            backContent.isEditable = true
            saveButton.isEnabled = true
            deleteButton.isEnabled = false
            backContent.becomeFirstResponder()
        }
    }
    
    @objc func handleSaveButton() {
        editButton.title = CardView.EditButtonTitleString
        actionReceiver?.didEndEditing()
        saveButton.isEnabled = false
        backContent.isEditable = false
        deleteButton.isEnabled = true
        actionReceiver?.saveCurrentFlashcard(withNewContent: backContent.attributedText, withIndex: cardIndex)
    }
    
    // MARK: Display a popover that asks for deletion confirmation
    func confirmationPopover() -> ConfirmationPopoverViewController? {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let optionsVC = storyboard.instantiateViewController(
            withIdentifier: "confirmDeleteCardViewController") as? ConfirmationPopoverViewController else {
                print("Error getting the confirmation popover")
                return nil
        }
        
        // Set basic popover properties
        optionsVC.modalPresentationStyle = .popover
        optionsVC.popoverPresentationController?.delegate = self
        optionsVC.popoverPresentationController?.sourceView = self
        
        // Set the popover's anchor (the arrow that points to where the popover came from)
        let sourceRect = navbar.frame
        optionsVC.popoverPresentationController?.sourceRect = sourceRect
        
        // Set size
        let containerWidth = self.frame.width
        let popoverWidth = containerWidth - 2 * Constants.LeftRightMarginDefViewSpacing
        let popoverHeight = CGFloat(100)
        optionsVC.preferredContentSize = CGSize(width: popoverWidth, height: popoverHeight)
        
        // Set popover content properties
        optionsVC.usedWidth = popoverWidth
        optionsVC.usedHeight = popoverHeight
        optionsVC.callerRef = self
        
        optionsVC.prompt = CardView.DeletionPrompt.replacingOccurrences(of: "{{word}}", with: word)
        optionsVC.popoverType = .delete
        
        // Present the view controller (in a popover)
        actionReceiver!.present(optionsVC: optionsVC, animated: true)
        return optionsVC
    }
    
    func closeKeyboard() {
        self.endEditing(true)  // closes keyboard
    }
    
    func textviewLinkClickHandler(url: URL) {
        let (linkType, _) = LinkType.Get(from: url.absoluteString.removingPercentEncoding)
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
        default:
            print("Currently unsupported link type \(linkType!)")
        }
    }
}

// MARK: - This is necessary to get the popover to display in the desired compact size
extension CardView: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
}

// MARK: - Handlers for ok and cancel button presses in popover
extension CardView: DisplaysConfirmationPopover {
    func cancelHandler(for popoverType: PopoverType) {
        guard let popoverInEscrow = popoverInEscrow else {
            print("popoverInEscrow was never set. Probably missing some ConfirmationPopoverViewController inits")
            return
        }
        popoverInEscrow.dismiss(animated: true, completion: nil)
    }
    
    func okHandler(for popoverType: PopoverType) {
        guard let popoverInEscrow = popoverInEscrow else {
            print("popoverInEscrow was never set. Probably missing some ConfirmationPopoverViewController inits")
            return
        }
        
        switch popoverType {
        case .select:
            print("Select popover type is undefined in Koloda view")
        case .delete:  // delete this flashcard
            actionReceiver?.deleteCurrentFlashcard(withIndex: cardIndex)
        }
        popoverInEscrow.dismiss(animated: true, completion: nil)
    }
}

// MARK: - Handle links in the attributed text view
extension CardView: UITextViewDelegate {
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        textviewLinkClickHandler(url: URL)
        return false
    }
}
