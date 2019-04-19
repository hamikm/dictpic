//
//  Constants.swift
//  Tapdefine
//
//  Created by Hamik on 6/28/18.
//  Copyright © 2018 Hamik. All rights reserved.
//

import DeviceCheck
import UIKit

class Constants: NSObject {
    
    static let DefaultWord = "terrier"
    
    // MARK: - General colors
    static let TabBarButtonInactiveColor = UIColor(rgb: 0x9f9e9c)
    static let TabBarButtonActiveColor = UIColor(rgb: 0x4286f4)
    static let DarkGray = UIColor(rgb: 0x303030)
    static let LightGray = UIColor(rgb: 0x777777)
    static let LightestGray = UIColor(rgb: 0xcccccc)
    static let NavbarBorderGray = UIColor(rgb: 0x8a8a8a)
    static let BottomHillyBackgroundTeal = UIColor(rgb: 0xa1f6fd)
    static let DarkGrayString = "303030"
    static let LightGrayString = "777777"
    static let LightestGrayString = "cccccc"
    static let BatteryGreen = UIColor(rgb: 0x4bd963)
    static let NeutralBackgroundColor = UIColor(rgb: 0xfbfbfb)
    static let PressedButtonColor = UIColor(rgb: 0xaabbc8)
    static let BackgroundGradientStartColor = UIColor(rgb: 0x4286f4)
    static let BackgroundGradientEndColor = UIColor(rgb: 0x3b5889)
    static let LogoTeal1 = UIColor(rgb: 0x73e0fa)
    static let LogoTeal2 = UIColor(rgb: 0xc9f7fe)
    static let LogoTeal3 = UIColor(rgb: 0xf1fcfe)
    
    // MARK: - Definition view
    static let MinSpacingBetweenDefViewAndEntryBox = CGFloat(20)
    static let LeftRightMarginDefViewSpacing = CGFloat(20)
    static let DefViewTopMargin = CGFloat(15)
    static let LeftRightMarginInDefView = CGFloat(5)
    static let BottomMarginInDefView = CGFloat(5)
    static let PageFooterHeight = CGFloat(37)  // automatically set - this is for reference
    
    // MARK: - Separator line
    static let SeparatorLeftRightMargin = CGFloat(5)
    static let SeparatorTopBottomMargin = SeparatorLeftRightMargin
    static let SeparatorViewWidth = CGFloat(1)
    
    // MARK: - Miscellaneous UI
    static let GoldenRatio = CGFloat(1.6)  // 3 x 5 index card size :-)
    static let CornerRadius = CGFloat(5.0)
    static let NavbarHeight = CGFloat(44)
    static let TableCellHeight = CGFloat(44)
    static let DefaultFontSize = CGFloat(15)
    
    // MARK: - Manual entry view
    static let ManualEntryTopMargin = CGFloat(0)
    static let ManualEntryLeftMargin = CGFloat(0)
    static let ManualEntryRightMargin = -CGFloat(0)
    static let ManualEntryHeight = ManualEntryTextFieldHeight + ManualEntryTextFieldTopMargin + ManualEntryTextFieldBottomMargin
    
    // MARK: - Manual entry text field
    static let ManualEntryTextFieldHeight = CGFloat(30)
    static let ManualEntryTextFieldLeftMargin = CGFloat(10)
    static let ManualEntryTextFieldTopMargin = CGFloat(5)
    static let ManualEntryTextFieldBottomMargin = CGFloat(10)
    static let ManualEntryTextFieldLeftPadding = CGFloat(10)
    static let ManualEntryTextFieldRightPadding = CGFloat(10)
    static let ManualEntryTextFieldTextColor = UIColor(white: 1, alpha: 0.5)
    static let RightPaddingActivityView = CGFloat(10)
    
    // MARK: - Top bar and middle buttons and titles
    static let ButtonHeight = CGFloat(20)
    static let ButtonBottomMargin = ManualEntryTextFieldBottomMargin + (ManualEntryTextFieldHeight - ButtonHeight) / 2
    static let MiddleButtonSpacing = CGFloat(15)
    static let TopbarButtonSpacing = CGFloat(8)
    static let ButtonRightMargin = ManualEntryTextFieldLeftMargin - CGFloat(1)
    static let TopBottomBarColor = UIColor.white
    static let TopButtonsLeftMargin = CGFloat(15)
    static let TopButtonsRightMargin = CGFloat(15)
    static let TopBottonsTopMargin = ManualEntryTopMargin + CGFloat(5)
    static let TopButtonsBottomMargin = ButtonBottomMargin - CGFloat(5)
    static let TopButtonsSpacing = MiddleButtonSpacing
    static let TopBarTitleFont = UIFont.systemFont(ofSize: 17.0, weight: .semibold)
    static let TopBarButtonFont = UIFont.systemFont(ofSize: 17.0)
    static let TopBarTitleColor = DarkGray
    static let TopBarButtonColor = TabBarButtonActiveColor
    static let CancelXButtonScaleFactor = CGFloat(0.55)
    static let CancelXButtonSize = ManualEntryTextFieldHeight * CancelXButtonScaleFactor
    
    // MARK: - Language constants
    static let DefaultLanguage = "en"
    static let DefaultSupportedLangs = [
        "English" : ["basic": "en"],
        "Spanish": ["basic": "es"],
    ]
    
    // MARK: - API URLs
    static let AwsApiBaseURL = "https://f4iwoev1v3.execute-api.us-east-1.amazonaws.com"
    static let AwsApiStage = "prod"  // or "dev"
    static let AggregatedSearchApiPath = "search"

    // MARK: - HTML constants
    static let ContentTemplate = """
    <html>
        <style>
            * {
                color: #\(DarkGrayString);
                font-family: "\(UIFont.systemFont(ofSize: 17.0).fontName)";
            }
            {{more-style}}
        </style>

        <body>{{body}}</body>
    <html>
    """
    
    // MARK: - Networking
    static let MaxRetries = 2
    
    // MARK: - Fonts
    static let StandardFontSize = CGFloat(13.0)
    static let StandardFont = UIFont(name: UIFont.systemFont(ofSize: 17.0).fontName, size: StandardFontSize)
    static func StandardFont(ofSize fontSize: CGFloat) -> UIFont? {
        return UIFont(name: UIFont.systemFont(ofSize: 17.0).fontName, size: fontSize)
    }
    
    // Miscellaneous
    static let CurrDevice = DCDevice.current
}
