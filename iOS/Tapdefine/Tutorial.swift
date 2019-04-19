//
//  Tutorial.swift
//  Tapdefine
//
//  Created by Hamik on 11/14/18.
//  Copyright © 2018 Hamik. All rights reserved.
//

import AMPopTip
import Foundation

// MARK: - Action type that dismisses current tutorial message
enum TutorialAction {
    case cameraEnabled, successfulOcrDrag, singleHighlight, searching, swipeRightToWiki, manualEntry, swipeUpToExpand, swipeRightToTranslation, multipleHighlight, flashcardsTap
}

protocol TutorialDelegate {
    func isCameraOn() -> Bool
    func getParent() -> UIView
    func frameForCameraButton() -> CGRect
    func frameForCroppingAndSnappingArea() -> CGRect
    func frameForSelectionArea() -> CGRect
    func frameForDefinitionViewContent() -> (CGRect, CGFloat)
    func frameForManualEntryBar() -> (CGRect, CGFloat)
    func frameForDefinitionView() -> (CGRect, CGFloat)
    func frameForBottomOfDefinitionView(delta: CGFloat?) -> (CGRect, CGFloat)
    func frameForStudyTabBarItem() -> CGRect
}

class Tutorial {
    
    static let ManualEntryWord = "puppy"
    static let PluralManualEntryWord = "puppies"
    static let DefaultBubbleColor = Constants.TabBarButtonActiveColor
    static let BubbleBorderColor = Constants.LightestGray
    static let BubbleBorderWidth = CGFloat(0)
    static let TextColor = UIColor.white
    
    var lastPopTip: PopTip?
    var steps: [[String: Any]]!
    var stepNumber = -1 {
        didSet {
            if stepNumber >= 0 && stepNumber < steps.count {
                saveState()
            }
        }
    }
    var delegate: TutorialDelegate! {
        didSet {
            initSteps()
        }
    }
    
    init() {}
    
    func initSteps() {
        steps = [  // Point at camera button
            [
                "message": "Welcome! Tap camera to start.",
                "action": TutorialAction.cameraEnabled,
                "frameHandler": delegate.frameForCameraButton,
                "direction": PopTipDirection.down,
                "maxWidth": 200,
                "bubbleColor": Constants.LogoTeal2,
                "textColor": UIColor.black
                // Point at cropping area (top of lower message container)
            ],
            [
                "message": "Point at nearby words and drag a box around them to scan.",
                "action": TutorialAction.successfulOcrDrag,
                "maxWidth": 250,
                "frameHandler": delegate.frameForCroppingAndSnappingArea,
                "direction": PopTipDirection.down
                // Point at cropping area (top of lower message container)
            ],
            [
                "message": "Tap a word then tap done to search. Pinch-zoom or move with two fingers if needed.",
                "action": TutorialAction.singleHighlight,
                "chastisingMessage": "Pick 1 word. Try 2+ words later",
                "maxWidth": 250,
                "frameHandler": delegate.frameForSelectionArea,
                "direction": PopTipDirection.up,
                "bubbleColor": Constants.LogoTeal2,
                "textColor": UIColor.black,
                "skipIfFirst": true
                // Point at definition view (the navbar)
            ],
            [
                "message": "Search results are below. Swipe left/right for Wikipedia and translations. Swipe up on title bar to expand.",
                "action": TutorialAction.swipeUpToExpand,
                "frameHandler": delegate.frameForDefinitionView,
                "direction": PopTipDirection.up
                // Done
            ]
        ]
    }
    
    func isDone() -> Bool {
        if stepNumber >= 0 && stepNumber < steps.count {
            return false
        }
        return true
    }
    
    private func getStepIndices(for action: TutorialAction) -> [Int] {
        var indices: [Int] = []
        for (idx, step) in steps.enumerated() {
            if let currAction = step["action"] as? TutorialAction, currAction == action {
                indices.append(idx)
            }
        }
        return indices
    }
    
    func completed(action: TutorialAction) -> Bool {
        if getStepIndices(for: action).contains(stepNumber) {
            stepNumber += 1
            if isDone() {
                stepNumber = -1
                lastPopTip?.hide()
                FlashcardCollections.DoneWithTutorial()
            } else {
                showCurrentMessageAsPopTip()
            }
            return true
        }
        return false
    }
    
    private func getCurrent(prop: String) -> Any? {
        guard !isDone() else {
            print("Already done with tutorial")
            return nil
        }
        guard let value = steps[stepNumber][prop] else {
            return nil
        }
        return value
    }
    
    // Show a "poptip" that points at the given frame and containing the current tutorial mesasge
    func showCurrentMessageAsPopTip() {

        lastPopTip?.hide()

        let popTip = PopTip()
        popTip.entranceAnimation = .scale
        popTip.actionAnimation = .bounce(2)
        popTip.shouldDismissOnTap = true
        popTip.shouldDismissOnTapOutside = false
        popTip.shouldDismissOnSwipeOutside = false
        popTip.cornerRadius = Constants.CornerRadius
        popTip.edgeMargin = CGFloat(5)
        popTip.borderColor = Tutorial.BubbleBorderColor
        popTip.borderWidth = Tutorial.BubbleBorderWidth

        if let bubbleColor = getCurrent(prop: "bubbleColor") as? UIColor {
            popTip.bubbleColor = bubbleColor
        } else {
             popTip.bubbleColor = Tutorial.DefaultBubbleColor
        }
        
        if let textColor = getCurrent(prop: "textColor") as? UIColor {
            popTip.textColor = textColor
        } else {
            popTip.textColor = Tutorial.TextColor
        }
        
        let msg = getCurrent(prop: "message") as! String
        let parentView = delegate.getParent()
        let direction = getCurrent(prop: "direction") as! PopTipDirection
        var width = CGFloat(200)
        var frame = CGRect(x: 0, y: 0, width: 0, height: 0)

        // If both maxWidth and delta are given, handler should have signature (delta: CGFloat?) -> CGRect, since it doesn't have to return a width
        if let delta = getCurrent(prop: "delta") as? Int, let widthProp = getCurrent(prop: "maxWidth") as? Int, let handler = getCurrent(prop: "frameHandler") as? ((CGFloat?) -> CGRect) {
            frame = handler(CGFloat(delta))
            width = CGFloat(widthProp)
        }
        
        // If delta is given but not maxWidth, handler should have signature (delta: CGFloat?) -> (CGRect, CGFloat), since it needs to return a width
        else if let delta = getCurrent(prop: "delta") as? Int, let handler = getCurrent(prop: "frameHandler") as? ((CGFloat?) -> (CGRect, CGFloat)) {
            (frame, width) = handler(CGFloat(delta))
        }
        
        // If delta is not given but maxWidth is, handler should have signature (() -> CGRect), since it doesn't take a delta and doesn't need to return a width
        else if let widthProp = getCurrent(prop: "maxWidth") as? Int, let handler = getCurrent(prop: "frameHandler") as? (() -> CGRect) {
            frame = handler()
            width = CGFloat(widthProp)
        }
        
        // If neither delta nor maxWidth are given, handler should have signature () -> (CGRect, CGFloat), since no delta for arg and maxWidth is needed
        else if let handler = getCurrent(prop: "frameHandler") as? (() -> (CGRect, CGFloat)) {
            (frame, width) = handler()
        }
        
        else {
            print("Something went wrong at step \(stepNumber). Could not find correct frame handler")
            return
        }
        
        popTip.show(text: msg, direction: direction, maxWidth: width, in: parentView, from: frame)
        lastPopTip = popTip
    }
    
    // MARK: get last tutorial state out of user defaults and start there
    func resume() {
        stepNumber = FlashcardCollections.GetTutorialState()
        
        // If user doesn't give camera permissions, then gives them, then reopens app, skip the first message, since they've already acted upon it
        if stepNumber == 0, delegate.isCameraOn() {
            stepNumber += 1
        }
        
        // If we resumed onto a message that should be skipped if it's the first one, skip it
        if let skipMe = getCurrent(prop: "skipIfFirst") as? Bool, skipMe {
            stepNumber += 1
        }
        
        showCurrentMessageAsPopTip()
    }
    
    func pause() {
        lastPopTip?.hide()
    }
    
    func saveState() {
        FlashcardCollections.SaveTutorialState(step: stepNumber)
    }
    
    func nextExpectedTutorialAction() -> TutorialAction? {
        guard !isDone() else {
            return nil
        }
        return steps[stepNumber]["action"] as? TutorialAction
    }
    
    func getChastisingMessage() -> String? {
        guard !isDone() else {
            return nil
        }
        return steps[stepNumber]["chastisingMessage"] as? String
    }
}
