//
//  ReminderViewController.swift
//  Tapdefine
//
//  Created by Hamik on 10/1/18.
//  Copyright © 2018 Hamik. All rights reserved.
//

import UIKit

protocol ReminderDelegate: ModalVCDelegate {
    func setPressed(forDate date: Date)
}

class ReminderViewController: ModalViewController {

    // MARK: - UI Constants
    static let TextLeftRightMargin = Constants.LeftRightMarginDefViewSpacing
    static let MarginUnderTopBarView = CGFloat(30)
    static let MarginUnderExplanatoryText = CGFloat(15)
    static let PickerMinuteInterval = 5
    
    // MARK: - Strings
    static let ReminderTitleString = "Reminder"
    static let ScheduleButtonTitleString = "Set"
    static let ExplanatoryText = """
    Studies show that spaced repetition is the best way to learn. Set a reminder to review your deck a day from now, repeating until you can breeze through your deck without mistakes. When that happens, schedule reminders that are progressively later to really cement the deck in your memory.
    """
    
    // Views and buttons
    var superReminderView: UIView!
    var topTextLabel: UILabel!
    var datePicker: UIDatePicker!
    var scheduleButton: UIButton!
    
    // Delegate
    var myReminderDelegate: ReminderDelegate!
    override var myDelegate: ModalVCDelegate! {
        get {
            return myReminderDelegate
        }
        set {
            myReminderDelegate = newValue as? ReminderDelegate
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Container view
        superReminderView = UIView()
        view.addSubview(superReminderView)
        superReminderView.backgroundColor = UIColor.clear
        (_, _) = superReminderView.snuglyConstrain(to: view, leftAmount: 0, rightAmount: 0)
        (_, _) = superReminderView.snuglyConstrain(to: view, toTop: topBarView, toBottom: view, topAmount: 0, bottomAmount: 0)
        
        // Date picker
        datePicker = UIDatePicker()
        superReminderView.addSubview(datePicker)
        let dpcxc = NSLayoutConstraint(item: datePicker, attribute: .centerX, relatedBy: .equal, toItem: superReminderView, attribute: .centerX, multiplier: 1, constant: 0)
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        superReminderView.addConstraints([dpcxc])
        datePicker.minimumDate = Date()
        datePicker.minuteInterval = ReminderViewController.PickerMinuteInterval
        
        // Explanatory text
        let desiredWidth = view.frame.width - 2 * ReminderViewController.TextLeftRightMargin
        let computedHeight = ReminderViewController.ExplanatoryText.heightForLabel(fontSize: Constants.StandardFontSize, labelWidth: desiredWidth)
        topTextLabel = UILabel()
        superReminderView.addSubview(topTextLabel)
        topTextLabel.numberOfLines = 0
        topTextLabel.lineBreakMode = .byWordWrapping
        topTextLabel.font = Constants.StandardFont
        topTextLabel.text = ReminderViewController.ExplanatoryText
        topTextLabel.sizeToFit()
        topTextLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topTextLabel.topAnchor.constraint(equalTo: topBarView.bottomAnchor, constant: ReminderViewController.MarginUnderTopBarView),
            topTextLabel.bottomAnchor.constraint(equalTo: datePicker.topAnchor, constant: -ReminderViewController.MarginUnderExplanatoryText),
            topTextLabel.heightAnchor.constraint(equalToConstant: computedHeight),
            topTextLabel.widthAnchor.constraint(equalToConstant: desiredWidth),
            topTextLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0)
        ])
        
        // Schedule button
        scheduleButton = UIButton(type: .system)  // system needed for tint
        topBarView.addSubview(scheduleButton)
        scheduleButton.addTarget(self, action: #selector(handleScheduleButton), for: .primaryActionTriggered)
        scheduleButton.setTitle(ReminderViewController.ScheduleButtonTitleString, for: .normal)
        scheduleButton.titleLabel?.font = Constants.TopBarButtonFont
        scheduleButton.tintColor = Constants.TopBarButtonColor
        scheduleButton.contentHorizontalAlignment = .right
        (_, _) = scheduleButton.snuglyConstrain(to: topBarView, toLeft: topBarTitleLabel, toRight: topBarView, leftAmount: Constants.TopButtonsSpacing, rightAmount: Constants.TopButtonsRightMargin)
        let tbsbyc = NSLayoutConstraint(item: scheduleButton, attribute: .centerY, relatedBy: .equal, toItem: topBarTitleLabel, attribute: .centerY, multiplier: 1, constant: 0)
        scheduleButton.translatesAutoresizingMaskIntoConstraints = false
        topBarView.addConstraints([tbsbyc])
    }
    
    override func getTitleString() -> String {
        return ReminderViewController.ReminderTitleString
    }
}

// MARK: - Handlers
extension ReminderViewController {

    @objc func handleScheduleButton() {
        
        // Ask for permission to send local notifications
        AppDelegate.NotificationCenter.requestAuthorization(options: AppDelegate.NotificationOptions) {
            (granted, error) in
            if !granted {
                print("Notifications permissions not granted")
            }
        }
        
        myReminderDelegate.setPressed(forDate: datePicker.date)
    }
}
