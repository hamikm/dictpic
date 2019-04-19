//
//  MessageViewController.swift
//  Tapdefine
//
//  Created by Hamik on 11/15/18.
//  Copyright © 2018 Hamik. All rights reserved.
//

import UIKit

class MessageViewController: UIViewController {

    static let MessageTextColor = Constants.DarkGray
    static let MessageFontSize = CGFloat(15)
    
    // Views
    var blurView: UIVisualEffectView!
    var blurSubview: UIView!
    var label: UILabel!
    var message: String?
    
    // Miscellaneous
    var timer: Timer?
    var maxWidth: CGFloat!
    var labelLeftConstraint: NSLayoutConstraint!
    var labelRightConstraint: NSLayoutConstraint!
    var labelPadding: CGFloat!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.clear

        blurView = UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))
        view.addSubview(blurView)
        blurView.snuglyConstrain(to: view)
        
        blurSubview = UIView()
        blurSubview.backgroundColor = UIColor.clear
        blurView.contentView.addSubview(blurSubview)
        blurSubview.snuglyConstrain(to: blurView)

        label = UILabel()
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.font = label.font.withSize(MessageViewController.MessageFontSize)
        label.textAlignment = .center
        label.textColor = MessageViewController.MessageTextColor
        label.backgroundColor = UIColor.clear
        blurSubview.addSubview(label)
        (_, _) = label.snuglyConstrain(to: blurSubview, topAmount: 0, bottomAmount: 0)
        (labelLeftConstraint, labelRightConstraint) = label.snuglyConstrain(to: blurSubview, leftAmount: 0, rightAmount: 0)
    }
    
    // MARK: get width and height for a UILabel with the given text. If width is larger than max allowed width, returns a non-zero height
    private func getRequiredDimensions(for text: String) -> (CGFloat, CGFloat) {

        let dummySingleLineLabel = UILabel()
        dummySingleLineLabel.text = text
        dummySingleLineLabel.numberOfLines = 1
        dummySingleLineLabel.font = dummySingleLineLabel.font.withSize(MessageViewController.MessageFontSize)
        dummySingleLineLabel.textAlignment = .center
        dummySingleLineLabel.sizeToFit()
        let singleLineWidth = dummySingleLineLabel.frame.width
        let computedHeight = text.heightForLabel(font: label.font.withSize(MessageViewController.MessageFontSize), labelWidth: maxWidth)
        return (singleLineWidth > maxWidth ? maxWidth : singleLineWidth, computedHeight)
    }
    
    // MARK: set message to given string and return required dimensions
    func setMessage(to message: String) -> (CGFloat, CGFloat) {

        let (width, height) = getRequiredDimensions(for: message)
        self.message = message
        label.text = message
        labelLeftConstraint?.constant = labelPadding!
        labelRightConstraint?.constant = -labelPadding!
        blurSubview.setNeedsLayout()
        blurSubview.layoutIfNeeded()
        return (width, height)
    }
}
