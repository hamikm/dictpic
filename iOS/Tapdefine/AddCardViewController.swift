//
//  AddCardViewController.swift
//  Tapdefine
//
//  Created by Hamik on 9/9/18.
//  Copyright © 2018 Hamik. All rights reserved.
//

import UIKit

protocol AddCardDelegate: ModalVCDelegate {
    func addPressed()
}

enum AddCardErrorType {
    case needWord, needDefinition, needToChooseDeck
}

class AddCardViewController: ModalViewController {

    static let AddCardTitleString = "New Card"
    
    // UI constants
    static let LabelLeftMargin = CGFloat(16)
    static let TopLabelTopMargin = CGFloat(10)
    static let SpaceAboveTopLine = CGFloat(5.88)
    static let BottomLabelTopMargin = CGFloat(40)
    static let FieldLeftSpacing = CGFloat(10)
    static let FieldRightSpacing = CGFloat(10)
    static let TextViewBottomMargin = CGFloat(48)
    static let FieldHeight = Constants.TableCellHeight
    static let WordFieldTopBottomMargin = CGFloat(0)
    static let DefinitionTextViewTopBottomMargin = CGFloat(12.3)
    static let SeparatorLeftRightMargin = CGFloat(0)
    static let ErrorMessageTopMargin = CGFloat(6.86)

    // Text constants
    static let LabelFont = Constants.StandardFont
    static let WordLabelString = "FRONT"
    static let DefinitionLabelString = "BACK"
    static let AddButtonString = "Add"
    static let WordFieldPlaceholder = ""
    static let NeedWordErrorString = "Need to enter a word"
    static let NeedDefinitionErrorString = "Need to enter a definition"
    static let NeedToChooseDeckErrorString = "Need to choose a deck first"

    // Other views
    @IBOutlet weak var parentView: UIView!
    @IBOutlet weak var subParentView: UIView!
    var topBarAddButton: UIButton!
    var subParentBottomConstraint: NSLayoutConstraint!
    
    // Word part
    @IBOutlet weak var wordLabel: UILabel!
    @IBOutlet weak var wordField: UITextField!
    
    // Definition part
    @IBOutlet weak var definitionLabel: UILabel!
    @IBOutlet weak var definitionTextView: UITextView!
    
    // Error message label
    var errorMessageLabel: UILabel!
    var errorType: AddCardErrorType! {
        didSet {
            switch errorType! {
            case .needWord:
                errorMessageLabel.text = AddCardViewController.NeedWordErrorString
            case .needDefinition:
                errorMessageLabel.text = AddCardViewController.NeedDefinitionErrorString
            case .needToChooseDeck:
                errorMessageLabel.text = AddCardViewController.NeedToChooseDeckErrorString
            }
            errorMessageLabel.isHidden = false
        }
    }
    
    // Delegate
    var myAddCardDelegate: AddCardDelegate!
    override var myDelegate: ModalVCDelegate! {
        get {
            return myAddCardDelegate
        }
        set {
            myAddCardDelegate = newValue as? AddCardDelegate
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add button
        topBarAddButton = UIButton(type: .system)  // system needed for tint
        topBarView.addSubview(topBarAddButton)
        topBarAddButton.addTarget(self, action: #selector(handleAddButton), for: .primaryActionTriggered)
        topBarAddButton.setTitle(AddCardViewController.AddButtonString, for: .normal)
        topBarAddButton.titleLabel?.font = Constants.TopBarButtonFont
        topBarAddButton.tintColor = Constants.TopBarButtonColor
        topBarAddButton.contentHorizontalAlignment = .right
        (_, _) = topBarAddButton.snuglyConstrain(to: topBarView, toLeft: topBarTitleLabel, toRight: topBarView, leftAmount: Constants.TopButtonsSpacing, rightAmount: Constants.TopButtonsRightMargin)
        let tbabyc = NSLayoutConstraint(item: topBarAddButton, attribute: .centerY, relatedBy: .equal, toItem: topBarTitleLabel, attribute: .centerY, multiplier: 1, constant: 0)
        topBarAddButton.translatesAutoresizingMaskIntoConstraints = false
        topBarView.addConstraints([tbabyc])

        // Sub parent view (resized when keyboard is opened)
        subParentView.backgroundColor = UIColor.clear
        subParentView.translatesAutoresizingMaskIntoConstraints = false
        let guide = view.safeAreaLayoutGuide
        subParentBottomConstraint = subParentView.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: 0)
        NSLayoutConstraint.activate([
            subParentView.topAnchor.constraint(equalTo: topBarView.bottomAnchor, constant: 0),
            subParentBottomConstraint,
            subParentView.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 0),
            subParentView.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: 0)
        ])
        
        // Word label
        wordLabel.text = AddCardViewController.WordLabelString
        wordLabel.font = AddCardViewController.LabelFont
        wordLabel.textColor = Constants.LightGray
        wordLabel.snuglyConstrain(to: subParentView, toLeft: subParentView, toTop: subParentView, leftAmount: AddCardViewController.LabelLeftMargin, topAmount: AddCardViewController.TopLabelTopMargin)
        
        // Word field
        let lineAboveWordField = LineView.MakeLine(in: subParentView, under: wordLabel, space: AddCardViewController.SpaceAboveTopLine, leftMargin: AddCardViewController.SeparatorLeftRightMargin, rightMargin: AddCardViewController.SeparatorLeftRightMargin)
        wordField.backgroundColor = UIColor.clear
        wordField.textColor = Constants.DarkGray
        wordField.borderStyle = .none
        (_, _) = wordField.snuglyConstrain(to: subParentView, leftAmount: AddCardViewController.FieldLeftSpacing, rightAmount: AddCardViewController.FieldRightSpacing)
        let wftc = NSLayoutConstraint(item: wordField, attribute: .top, relatedBy: .equal, toItem: lineAboveWordField, attribute: .bottom, multiplier: 1, constant: AddCardViewController.WordFieldTopBottomMargin)
        let wfhc = NSLayoutConstraint(item: wordField, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: AddCardViewController.FieldHeight)
        wordField.translatesAutoresizingMaskIntoConstraints = false
        subParentView.addConstraints([wftc, wfhc])
        let lineBelowWordField = LineView.MakeLine(in: subParentView, under: wordField, space: AddCardViewController.WordFieldTopBottomMargin, leftMargin: AddCardViewController.SeparatorLeftRightMargin, rightMargin: AddCardViewController.SeparatorLeftRightMargin)
        
        // Definition label
        definitionLabel.text = AddCardViewController.DefinitionLabelString
        definitionLabel.font = AddCardViewController.LabelFont
        definitionLabel.textColor = Constants.LightGray
        definitionLabel.snuglyConstrain(to: subParentView, toLeft: subParentView, toTop: lineBelowWordField, leftAmount: AddCardViewController.LabelLeftMargin, topAmount: AddCardViewController.BottomLabelTopMargin)
        
        // Definition text view
        let lineAboveDefinitionTextView = LineView.MakeLine(in: subParentView, under: definitionLabel, space: AddCardViewController.SpaceAboveTopLine, leftMargin: AddCardViewController.SeparatorLeftRightMargin, rightMargin: AddCardViewController.SeparatorLeftRightMargin)
        definitionTextView.text = ""
        definitionTextView.backgroundColor = UIColor.clear
        definitionTextView.textColor = Constants.DarkGray
        (_, _) = definitionTextView.snuglyConstrain(to: subParentView, leftAmount: AddCardViewController.FieldLeftSpacing, rightAmount: AddCardViewController.FieldLeftSpacing)
        (_, _) = definitionTextView.snuglyConstrain(to: subParentView, toTop: lineAboveDefinitionTextView, toBottom: subParentView, topAmount: AddCardViewController.DefinitionTextViewTopBottomMargin, bottomAmount: AddCardViewController.TextViewBottomMargin)
        let lineBelowDefinitionTextView = LineView.MakeLine(in: subParentView, under: definitionTextView, space: AddCardViewController.DefinitionTextViewTopBottomMargin, leftMargin: AddCardViewController.SeparatorLeftRightMargin, rightMargin: AddCardViewController.SeparatorLeftRightMargin)
        definitionTextView.textContainerInset = .zero
        definitionTextView.textContainer.lineFragmentPadding = 0
        
        // Error message label
        errorMessageLabel = UILabel()
        errorMessageLabel.font = AddCardViewController.LabelFont
        errorMessageLabel.textColor = Constants.LightGray
        errorMessageLabel.textAlignment = .left
        subParentView.addSubview(errorMessageLabel)
        errorMessageLabel.snuglyConstrain(to: subParentView, toLeft: subParentView, toTop: lineBelowDefinitionTextView, leftAmount: AddCardViewController.LabelLeftMargin, topAmount: AddCardViewController.ErrorMessageTopMargin)
        errorMessageLabel.isHidden = true
        
        initNotifications()
    }
    
    private func initNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardNotification(notification:)), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
    }
    
    override func getTitleString() -> String {
        return AddCardViewController.AddCardTitleString
    }
    
    @objc func keyboardNotification(notification: NSNotification) {
        
        if let userInfo = notification.userInfo, let keyboardFrameBegin = (userInfo[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue, let keyboardFrameEnd = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            
            // Get edge and animation info from notification
            let beginningKeyboardEdgeY = keyboardFrameBegin.origin.y
            let endingKeyboardEdgeY = keyboardFrameEnd.origin.y
            let duration: TimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
            let animationCurveRawNSN = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber
            let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIViewAnimationOptions.curveEaseInOut.rawValue
            let animationCurve: UIViewAnimationOptions = UIViewAnimationOptions(rawValue: animationCurveRaw)
            
            // If keyboard isn't opening, closing, or changing, then exit
            guard !beginningKeyboardEdgeY.approximatelyEquals(other: endingKeyboardEdgeY) else {
                return
            }
            
            // If the keyboard is closing, undo constraint changes
            if endingKeyboardEdgeY.approximatelyEquals(other: UIScreen.main.bounds.height) {
                
                subParentBottomConstraint.constant = 0
                
                UIView.animate(withDuration: duration, delay: 0.0, options: animationCurve, animations: { self.view.layoutIfNeeded() }, completion: nil)
            } else {  // Otherwise it's just resizing, so modify constraints as necessary
                
                // Put edge into local (studySuperView) coordinates
                let unsafeBottomAreaHeight = view.safeAreaInsets.bottom
                let globalSuperviewHeight = UIScreen.main.bounds.size.height
                let localSuperviewHeight = view.frame.size.height
                let edgeDistFromBottomGlobal = globalSuperviewHeight - endingKeyboardEdgeY
                let edgeDistFromTabBarGlobal = edgeDistFromBottomGlobal - unsafeBottomAreaHeight
                let edgeFractionLocal = edgeDistFromTabBarGlobal / (globalSuperviewHeight - unsafeBottomAreaHeight)
                let edgeDistFromBottomLocal = edgeFractionLocal * localSuperviewHeight
                
                subParentBottomConstraint.constant = -edgeDistFromBottomLocal
                
                UIView.animate(withDuration: duration, delay: 0.0, options: animationCurve, animations: { self.view.layoutIfNeeded() }, completion: nil)
            }
        }
    }
    
    @objc override func handleCancelButton() {
        view.endEditing(true)  // endEditing here so that keyboard closing notification isn't handled in StudyViewController
        super.handleCancelButton()
    }
}

extension AddCardViewController {

    @objc func handleAddButton() {
        view.endEditing(true)  // endEditing here so that keyboard closing notification isn't handled in StudyViewController
        myAddCardDelegate.addPressed()
    }
}
