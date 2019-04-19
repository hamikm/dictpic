//
//  ConfirmationPopoverViewController.swift
//  Tapdefine
//
//  Created by Hamik on 8/24/18.
//  Copyright © 2018 Hamik. All rights reserved.
//

import UIKit

protocol DisplaysConfirmationPopover {
    mutating func cancelHandler(for: PopoverType)
    mutating func okHandler(for: PopoverType)
}

enum PopoverType {
    case select, delete
}

// MARK: - Presents a confirmation dialog for cell selection or deletion
class ConfirmationPopoverViewController: UIViewController {
    
    static let DeleteButtonColor = UIColor.red
    static let RightButtonColor = Constants.TabBarButtonActiveColor
    
    @IBOutlet weak var confirmationParentView: UIView!
    @IBOutlet weak var promptLabel: UILabel!
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!

    // MARK: - properties
    var usedWidth: CGFloat?
    var usedHeight: CGFloat?
    var prompt: String?
    var popoverType: PopoverType?
    var callerRef: DisplaysConfirmationPopover?
    var selectionName: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let containerWidth = usedWidth, let containerHeight = usedHeight, let popoverType = popoverType, let prompt = prompt else {
            print ("Error: need to set popover props before loading")
            return
        }

        // Colors for buttons
        leftButton.tintColor = Constants.TabBarButtonActiveColor
        rightButton.tintColor = Constants.TabBarButtonActiveColor
        
        // Handle constraints for the prompt
        promptLabel.text = prompt
        promptLabel.textAlignment = .center
        promptLabel.textColor = Constants.LightGray
        promptLabel.font = promptLabel.font.withSize(Constants.DefaultFontSize)
        let lcxc = NSLayoutConstraint(item: promptLabel, attribute: .centerX, relatedBy: .equal, toItem: confirmationParentView, attribute: .centerX, multiplier: 1, constant: 0)
        let lcyc = NSLayoutConstraint(item: promptLabel, attribute: .centerY, relatedBy: .equal, toItem: confirmationParentView, attribute: .centerY, multiplier: 1, constant: -containerHeight / 4)
        promptLabel.translatesAutoresizingMaskIntoConstraints = false
        confirmationParentView.addConstraints([lcxc, lcyc])
        
        // Set button text and colors
        switch popoverType {
        case .delete:
            leftButton.setTitle("Delete", for: .normal)
            leftButton.tintColor = ConfirmationPopoverViewController.DeleteButtonColor
            rightButton.setTitle("Cancel", for: .normal)
            rightButton.tintColor = ConfirmationPopoverViewController.RightButtonColor
        case .select:
            leftButton.setTitle("Cancel", for: .normal)
            rightButton.setTitle("OK", for: .normal)
            rightButton.tintColor = ConfirmationPopoverViewController.RightButtonColor
        }

        // Make a horizontal line under the prompt
        let horizontalLine = LineView()
        horizontalLine.vertical = false
        horizontalLine.backgroundColor = UIColor.clear
        confirmationParentView.addSubview(horizontalLine)
        (_, _) = horizontalLine.snuglyConstrain(to: confirmationParentView, leftAmount: Constants.SeparatorLeftRightMargin, rightAmount: Constants.SeparatorLeftRightMargin)
        let hlcyc = NSLayoutConstraint(item: horizontalLine, attribute: .centerY, relatedBy: .equal, toItem: confirmationParentView, attribute: .centerY, multiplier: 1, constant: 0)
        let hlhc = NSLayoutConstraint(item: horizontalLine, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: Constants.SeparatorViewWidth)
        horizontalLine.translatesAutoresizingMaskIntoConstraints = false
        confirmationParentView.addConstraints([hlcyc, hlhc])
        
        // Find button offset from center
        let w = max(leftButton.frame.width, rightButton.frame.width)
        let c = containerWidth
        let offset = (c - 2 * w) / 3 / 2 + (w / 2)
        
        // Set left button constraints
        let lbcxc = NSLayoutConstraint(item: leftButton, attribute: .centerX, relatedBy: .equal, toItem: confirmationParentView, attribute: .centerX, multiplier: 1, constant: -offset)
        let lbcyc = NSLayoutConstraint(item: leftButton, attribute: .centerY, relatedBy: .equal, toItem: confirmationParentView, attribute: .centerY, multiplier: 1, constant: containerHeight / 4)
        leftButton.translatesAutoresizingMaskIntoConstraints = false
        confirmationParentView.addConstraints([lbcxc, lbcyc])
        
        // Set right button constraints
        let rbcxc = NSLayoutConstraint(item: rightButton, attribute: .centerX, relatedBy: .equal, toItem: confirmationParentView, attribute: .centerX, multiplier: 1, constant: offset)
        let rbcyc = NSLayoutConstraint(item: rightButton, attribute: .centerY, relatedBy: .equal, toItem: confirmationParentView, attribute: .centerY, multiplier: 1, constant: containerHeight / 4)
        rightButton.translatesAutoresizingMaskIntoConstraints = false
        confirmationParentView.addConstraints([rbcxc, rbcyc])
    }
}

// MARK: - Handlers for buttons
extension ConfirmationPopoverViewController {
    @IBAction func handleRightButton(_ sender: UIButton) {
        guard let popoverType = popoverType, var callerRef = callerRef else {
            print ("Error: need to set popover props before loading")
            return
        }
        switch popoverType {
        case .select:
            callerRef.okHandler(for: .select)
        case .delete:
            callerRef.cancelHandler(for: .delete)
        }
    }
    
    @IBAction func handleLeftButton(_ sender: UIButton) {
        guard let popoverType = popoverType, var callerRef = callerRef else {
            print ("Error: need to set popover props before loading")
            return
        }
        switch popoverType {
        case .select:
            callerRef.cancelHandler(for: .select)
        case .delete:
            callerRef.okHandler(for: .delete)
        }
    }
}
