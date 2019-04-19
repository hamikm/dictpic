//
//  ModalViewController.swift
//  Tapdefine
//
//  Created by Hamik on 10/1/18.
//  Copyright © 2018 Hamik. All rights reserved.
//

import UIKit

protocol ModalVCDelegate {
    func closePressed()
}

class ModalViewController: UIViewController {

    // UI Constants
    static let BackgroundColor = Constants.NeutralBackgroundColor
    static let TopBarBackgroundColor = UIColor.clear
    
    // Strings
    static let TitleString = "Modal"
    
    // Navbar
    var topBarView: UIView!
    var topBarCancelButton: UIButton!
    var topBarTitleLabel: UILabel!
    
    // Miscellaneous
    var myDelegate: ModalVCDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initBackground()
        initTopBar()
    }
    
    func getTitleString() -> String {
        return ModalViewController.TitleString
    }
}

// MARK: - Initializations
extension ModalViewController {
    
    private func initBackground() {
        view.backgroundColor = ModalViewController.BackgroundColor
    }
    
    private func initTopBar() {

        // Top bar
        topBarView = UIView()
        topBarView.backgroundColor = ModalViewController.TopBarBackgroundColor
        view.addSubview(topBarView)
        topBarView.translatesAutoresizingMaskIntoConstraints = false
        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            topBarView.topAnchor.constraint(equalTo: guide.topAnchor, constant: Constants.ManualEntryTopMargin),
            topBarView.heightAnchor.constraint(equalToConstant: Constants.ManualEntryHeight),
            topBarView.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: Constants.ManualEntryLeftMargin),
            topBarView.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: Constants.ManualEntryRightMargin)
        ])
        
        // Title
        topBarTitleLabel = UILabel()
        topBarView.addSubview(topBarTitleLabel)
        topBarTitleLabel.text = getTitleString()
        topBarTitleLabel.textAlignment = .center
        topBarTitleLabel.font = Constants.TopBarTitleFont
        topBarTitleLabel.textColor = Constants.TopBarTitleColor
        
        (_, _) = topBarTitleLabel.snuglyConstrain(to: topBarView, topAmount: Constants.TopBottonsTopMargin, bottomAmount: Constants.TopButtonsBottomMargin)
        let tbtlxc = NSLayoutConstraint(item: topBarTitleLabel, attribute: .centerX, relatedBy: .equal, toItem: topBarView, attribute: .centerX, multiplier: 1, constant: 0)
        topBarTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        topBarView.addConstraints([tbtlxc])
        
        // Close button
        topBarCancelButton = UIButton()
        topBarView.addSubview(topBarCancelButton)
        topBarCancelButton.initPictureButton(in: topBarView, imageName: "bigTimes", withColor: Constants.TabBarButtonActiveColor, width: Constants.CancelXButtonSize, height: Constants.CancelXButtonSize)
        topBarCancelButton.addTarget(self, action: #selector(handleCancelButton), for: .primaryActionTriggered)
        let tbcblc = NSLayoutConstraint(item: topBarCancelButton, attribute: .left, relatedBy: .equal, toItem: topBarView, attribute: .left, multiplier: 1, constant: Constants.TopButtonsLeftMargin)
        let tbcbyc = NSLayoutConstraint(item: topBarCancelButton, attribute: .centerY, relatedBy: .equal, toItem: topBarTitleLabel, attribute: .centerY, multiplier: 1, constant: 0)
        topBarCancelButton.translatesAutoresizingMaskIntoConstraints = false
        topBarView.addConstraints([tbcbyc, tbcblc])
    }
}

// MARK: - Handlers
extension ModalViewController {
    
    @objc func handleCancelButton() {
        myDelegate.closePressed()
    }
}
