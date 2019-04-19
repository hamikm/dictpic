//
//  StudyViewController.swift
//  Tapdefine
//
//  Created by Hamik on 8/25/18.
//  Copyright © 2018 Hamik. All rights reserved.
//

import UIKit
import Koloda
import UserNotifications

class StudyViewController: UIViewController {
    
    // MARK: - Deck title
    static let DeckTitleTopMargin = Constants.ButtonBottomMargin + CGFloat(5)
    static let DeckTitleTextColor = UIColor.white
    static let DeckTitleFontSize = CGFloat(18)
    static let DeckTitleHeight = DeckTitleFontSize * CGFloat(1.2)
    static let DeckTitleLeftRightMargin = MiddleButtonsLeftMargin
    
    // MARK: - Middle buttons
    static let MiddleButtonsBottomMargin = Constants.ButtonBottomMargin
    static let MiddleButtonsRightMargin = Constants.ButtonRightMargin + CGFloat(10)
    static let MiddleButtonsLeftMargin = MiddleButtonsRightMargin + CGFloat(4)
    static let MiddleButtonsSpacingSmall = Constants.MiddleButtonSpacing
    static let MiddleButtonHeightSmall = CGFloat(40)
    static let MiddleButtonHeightLarge = CGFloat(80)
    static let MiddleButtonUnpressedColor = UIColor.white
    static let MiddleButtonPressedColor = Constants.BottomHillyBackgroundTeal

    // MARKS: - Congrats
    static let CongratsButtonYOffset = SwipeButtonsYOffset
    static let CongratsButtonSpacing = MiddleButtonHeightLarge * 2
    static let CongratsButtonLabelFontSize = SwipeButtonsLabelFontSize
    static let CongratsButtonLabelTopMargin = SwipeButtonsLabelTopMargin
    static let CongratsButtonLabelHeight = SwipeButtonsLabelHeight
    static let ColorOfLabelUnderBigBackAllButton = UIColor.white
    static let ColorOfLabelUnderReminderButton = UIColor.white
    
    // MARK: - Swipe left/right buttons
    static let SwipeButtonsYOffset = -CGFloat(15)
    static let SwipeButtonsLabelFontSize = CGFloat(15)
    static let SwipeButtonsLabelHeight = SwipeButtonsLabelFontSize
    static let SwipeButtonsLabelTopMargin = CGFloat(0)
    static let ColorOfLabelUnderRecycleButton = UIColor.white
    static let ColorOfLabelUnderCheckmarkButton = UIColor.white
    static let ButtonJumpAmount = CGFloat(15)
    static let ButtonJumpDuration = 0.1
    static let LargeButtonDeltaScaleFactor = CGFloat(1 / 3 / 1.5)
    
    // MARK: - Refresh button
    static let RefreshButtonYOffset = SwipeButtonsYOffset
    static let RefreshLabelFontSize = SwipeButtonsLabelFontSize
    static let RefreshLabelHeight = SwipeButtonsLabelFontSize
    static let RefreshLabelTopMargin = SwipeButtonsLabelTopMargin
    static let ColorOfLabelUnderRefreshButton = UIColor.white
    
    // MARK: - Flashcard
    static let FlashcardLeftMargin = Constants.LeftRightMarginDefViewSpacing
    static let FlashcardRightMargin = Constants.LeftRightMarginDefViewSpacing
    static let FlashcardYOffset = Constants.ManualEntryHeight / 2
    static let FlashcardkeyboardVisibleTopMargin = DominatingViewTopMargin
    static let FlashcardKeyboardVisibleBottomMargin = DominatingViewBottomMargin
    static let NumVisibleFlashcards = 3
    static let HeightOfVisiblePartOfCardStack = CGFloat(10)
    static let DragAnimationDuration = DragSpeed.fast
    
    // MARK: - Fixed middle view
    static let FixedMiddleViewBorderColor = Constants.LightestGray
    static let FixedMiddleLabelTextColor = UIColor.white
    static let FixedMiddleLabelFontSize = DeckTitleFontSize
    
    // MARK: - Deck picker/add card
    static let DominatingViewLeftMargin = Constants.LeftRightMarginDefViewSpacing
    static let DominatingViewRightMargin = Constants.LeftRightMarginDefViewSpacing
    static let DominatingViewTopMargin = Constants.DefViewTopMargin
    static let DominatingViewBottomMargin = DominatingViewTopMargin
    static let DominatingViewKeyboardVisibleBottomMargin = DominatingViewBottomMargin
    
    // MARK: - Strings
    static let PickDeckButtonDefaultTitle = "Open"
    static let DecksString = "Open Deck"
    static let NewDeckString = "New Deck"
    static let AddButtonString = "Add"
    static let LabelUnderRecycleButtonTemplateString = "{{num-left}} in deck"
    static let LabelUnderCheckmarkButtonTemplateString = "{{num-done}} learned"
    static let CongratsString = "Learned all cards"
    static let ReachedEndOfDeckString = "Reached end of deck"
    static let NoDeckChosenString = ""
    static let RefreshLabelText = "Go to start"
    static let BigBackAllButtonLabelString = "Start over"
    static let ReminderButtonLabelString = "Review reminder"
    static let FixedMiddleLabelAddCardString = "No cards yet"
    static let ReviewNotificationTitleString = "Review {{deck-title}}"
    static let NotificationDefaultDeckTitle = "your deck"
    static let ReviewNotificationContentString = "Last reviewed {{days}} days ago"
    
    // MARK: - Time constants
    static let TopSlideAnimationTimeInterval = 0.25
    static let LeftSlideAnimationTimeInterval = 0.15
    static let ConfettiDuration = 5.0
    
    // MARK: - Miscellaneous
    static let UserDefinedCardStyle = """
        .text {
            font-size: 11pt;
        }
    """

    // Topbar
    @IBOutlet weak var topbarSuperFxView: UIVisualEffectView!
    @IBOutlet weak var topBarView: UIView!
    @IBOutlet weak var topBarButtonRowView: UIView!
    @IBOutlet weak var pickDeckButton: UIButton!
    @IBOutlet weak var middleTitle: UILabel!
    @IBOutlet weak var newDeckButton: UIButton!
   
    // Background views
    var backgroundGradient: UIView!
    var confettiView: SAConfettiView!
    var confettiTimer: Timer?

    // Middle buttons
    @IBOutlet weak var shuffleButton: UIButton!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var backOneButton: UIButton!
    @IBOutlet weak var backAllButton: UIButton!
    @IBOutlet weak var lowerButtonsContainer: UIView!
    @IBOutlet weak var recycleButton: UIButton!
    @IBOutlet weak var checkmarkButton: UIButton!
    var deckTitleLabel: UILabel!
    var labelUnderRecycleButton: UILabel!
    var recycleButtonYOffsetConstraint: NSLayoutConstraint!
    var labelUnderCheckmarkButton: UILabel!
    var checkmarkButtonYOffsetConstraint: NSLayoutConstraint!
    var middleButtonsHidden = true
    
    // Refresh
    @IBOutlet weak var refreshButton: UIButton!
    var labelUnderRefreshButton: UILabel!
    
    // Congrats
    @IBOutlet weak var bigBackAllButton: UIButton!
    @IBOutlet weak var reminderButton: UIButton!
    var labelUnderBigBackAllButton: UILabel!
    var labelUnderReminderButton: UILabel!

    // Topbar modal
    @IBOutlet weak var superFxTopbarModalView: UIVisualEffectView!
    @IBOutlet weak var fxTopbarModalView: UIView!
    @IBOutlet weak var topbarModalContainerView: UIView!
    @IBOutlet weak var topbarModalNavbar: UINavigationBar!
    @IBOutlet weak var topbarModalNavbarTitle: UINavigationItem!
    @IBOutlet weak var topbarModalAddButton: UIBarButtonItem!
    @IBOutlet weak var topbarModalCancelButton: UIBarButtonItem!
    var superFxTopbarModalTopConstraint: NSLayoutConstraint!
    var superFxTopbarModalBottomConstraint: NSLayoutConstraint!
    var collectionsListView: CollectionsTableViewController?
    var pickDeckController: UIViewController!
    var pickDeckControllerCast: StudyCollectionsTableViewController!
    var newDeckController: UIViewController!
    var newDeckControllerCast: StudyNewCollectionTableViewController!
    var keyboardDismissalCompletionFunc: (() -> Void)? = nil
    
    // Scoreboard
    var numDown = 0
    var numToGo = 0
    
    // Flashcard
    @IBOutlet weak var kolodaView: KolodaView!
    var currentDeck: [[String: NSAttributedString]]?
    var learnedPile: [[String: NSAttributedString]]?
    var currentDeckName: String?
    var flashcardYConstraint: NSLayoutConstraint!
    var flashcardHeightConstraint: NSLayoutConstraint!
    var flashcardTopConstraint: NSLayoutConstraint!
    var flashcardBottomConstraint: NSLayoutConstraint!
    
    // Fixed middle view
    var fixedMiddleView: UIView!  // goes exactly where kolodaView does, but doesn't move. Used for relative constraints and decks with no cards
    var fixedMiddleLabel: UILabel!
    var fixedMiddleLastBorder: CAShapeLayer? = nil
    
    // Modal view controllers
    var addCardViewController: AddCardViewController!
    var reminderViewController: ReminderViewController!
    
    // Miscellaneous
    @IBOutlet weak var parentView: UIView!
    @IBOutlet weak var studySuperView: UIView!
    var keyboardOpen: Bool = false
    var searchVC: ViewController?
    var finishedInitializing = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initStudySuperView()
        initTopBar()
        initMiddle()
        initTopbarModal()
        initNotifications()
        initBackground()

        hideAllMiddleButtonsAndLabels()
        
        // Miscellaneous
        searchVC = tabBarController?.viewControllers?[TabBarViewController.SearchTabTagAndIndex] as? ViewController
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func willEnterForeground() {
        print("Study view controller coming back into foreground")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        finishedInitializing = true
    }
    
    // Get reference to some sub view controllers
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let id = segue.identifier else {
            return
        }
        if id == "addCardSegue", let advc = segue.destination as? AddCardViewController {
            addCardViewController = advc
            addCardViewController.myDelegate = self
        }
        if id == "reminderSegue", let rvc = segue.destination as? ReminderViewController {
            reminderViewController = rvc
            reminderViewController.myDelegate = self
        }
    }
}

// MARK: - initializations
extension StudyViewController {
    
    private func initStudySuperView() {

        studySuperView.backgroundColor = UIColor.clear

        (_, _) = studySuperView.snuglyConstrain(to: parentView, leftAmount: 0, rightAmount: 0)
        // .bottom causes overlap with tab bar, thus .bottomMargin
        let bc = NSLayoutConstraint(item: studySuperView, attribute: .bottom, relatedBy: .equal, toItem: parentView, attribute: .bottomMargin, multiplier: 1.0, constant: 0)
        let tc = NSLayoutConstraint(item: studySuperView, attribute: .top, relatedBy: .equal, toItem: parentView, attribute: .top, multiplier: 1.0, constant: 0)
        studySuperView.translatesAutoresizingMaskIntoConstraints = false
        parentView.addConstraints([tc, bc])
    }
    
    private func initBackground() {
        
        // Confetti view
        confettiView = SAConfettiView(frame: studySuperView.bounds)
        studySuperView.addSubview(confettiView)
        studySuperView.bringSubview(toFront: confettiView)
        studySuperView.bringSubview(toFront: topbarSuperFxView)
        studySuperView.bringSubview(toFront: topBarButtonRowView)
        (_, _) = confettiView.snuglyConstrain(to: studySuperView, leftAmount: 0, rightAmount: 0)
        (_, _) = confettiView.snuglyConstrain(to: studySuperView, toTop: topBarView, toBottom: studySuperView, topAmount: 0, bottomAmount: 0)
        confettiView.isUserInteractionEnabled = false
        
        // Background gradient view
        backgroundGradient = UIView()
        backgroundGradient.backgroundColor = UIColor.clear
        view.addSubview(backgroundGradient)
        backgroundGradient.snuglyConstrain(to: view)
        view.sendSubview(toBack: backgroundGradient)
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = view.bounds
        gradientLayer.colors = [
            Constants.BackgroundGradientStartColor.cgColor,
            Constants.BackgroundGradientEndColor.cgColor
        ]
        backgroundGradient.layer.addSublayer(gradientLayer)
    }
    
    private func initTopBar() {
        
        // Fx superview
        (_, _) = topbarSuperFxView.snuglyConstrain(to: studySuperView, leftAmount: 0, rightAmount: 0)
        let tbtc = NSLayoutConstraint(item: topbarSuperFxView, attribute: .top, relatedBy: .equal, toItem: studySuperView, attribute: .top, multiplier: 1, constant: 0)
        let tbbc = NSLayoutConstraint(item: topbarSuperFxView, attribute: .bottom, relatedBy: .equal, toItem: topBarButtonRowView, attribute: .bottom, multiplier: 1, constant: 0)
        topBarView.translatesAutoresizingMaskIntoConstraints = false
        studySuperView.addConstraints([tbtc, tbbc])
        
        // Top bar
        topBarView.backgroundColor = UIColor.clear
        topBarView.snuglyConstrain(to: topbarSuperFxView)
        
        initTopBarButtonRow()
        bringTopBarToFront()
    }
    
    private func bringTopBarToFront() {
        studySuperView.bringSubview(toFront: topbarSuperFxView)
        studySuperView.bringSubview(toFront: topBarButtonRowView)
    }
    
    private func initTopBarButtonRow() {

        // Top bar button row view. Put it just under safe area's top
        topBarButtonRowView.backgroundColor = UIColor.clear
        topBarButtonRowView.translatesAutoresizingMaskIntoConstraints = false
        let guide = studySuperView.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            topBarButtonRowView.topAnchor.constraint(equalTo: guide.topAnchor, constant: Constants.ManualEntryTopMargin),
            topBarButtonRowView.heightAnchor.constraint(equalToConstant: Constants.ManualEntryHeight),
            topBarButtonRowView.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: Constants.ManualEntryLeftMargin),
            topBarButtonRowView.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: Constants.ManualEntryRightMargin)
        ])
        
        // Title
        middleTitle.textColor = Constants.TopBarTitleColor
        middleTitle.font = Constants.TopBarTitleFont
        (_, _) = middleTitle.snuglyConstrain(to: topBarButtonRowView, topAmount: Constants.ManualEntryTextFieldTopMargin, bottomAmount: Constants.ManualEntryTextFieldBottomMargin)
        let mtcxc = NSLayoutConstraint(item: middleTitle, attribute: .centerX, relatedBy: .equal, toItem: topBarButtonRowView, attribute: .centerX, multiplier: 1, constant: 0)
        middleTitle.translatesAutoresizingMaskIntoConstraints = false
        topBarButtonRowView.addConstraints([mtcxc])
        
        // New deck
        newDeckButton.tintColor = Constants.TopBarButtonColor
        (_, _) = newDeckButton.snuglyConstrain(to: topBarButtonRowView, toLeft: middleTitle, toRight: topBarButtonRowView, leftAmount: Constants.TopButtonsSpacing, rightAmount: Constants.TopButtonsRightMargin)
        let ndbcyc = NSLayoutConstraint(item: newDeckButton, attribute: .centerY, relatedBy: .equal, toItem: middleTitle, attribute: .centerY, multiplier: 1, constant: 0)
        newDeckButton.translatesAutoresizingMaskIntoConstraints = false
        topBarButtonRowView.addConstraints([ndbcyc])
        
        // Pick deck button
        pickDeckButton.tintColor = Constants.TopBarButtonColor
        pickDeckButton.setTitle(StudyViewController.PickDeckButtonDefaultTitle, for: .normal)
        (_, _) = pickDeckButton.snuglyConstrain(to: topBarButtonRowView, toLeft: topBarButtonRowView, toRight: middleTitle, leftAmount: Constants.TopButtonsLeftMargin, rightAmount: Constants.TopButtonsSpacing)
        let pdbcyc = NSLayoutConstraint(item: pickDeckButton, attribute: .centerY, relatedBy: .equal, toItem: middleTitle, attribute: .centerY, multiplier: 1, constant: 0)
        pickDeckButton.translatesAutoresizingMaskIntoConstraints = false
        topBarButtonRowView.addConstraints([pdbcyc])
    }
    
    private func initMiddle() {
        initDeckTitle()
        initSwipeButtons()
        initRefreshScreen()
        initCongratsScreen()
        initKolodaView()
        initRowOfButtonsNearTop()
    }
    
    private func initDeckTitle() {

        // Deck title properties
        deckTitleLabel = UILabel()
        deckTitleLabel.textAlignment = .left
        deckTitleLabel.textColor = StudyViewController.DeckTitleTextColor
        deckTitleLabel.font = deckTitleLabel.font.withSize(StudyViewController.DeckTitleFontSize)
        deckTitleLabel.isUserInteractionEnabled = false
        
        // Deck title constraints
        studySuperView.addSubview(deckTitleLabel)
        (_, _) = deckTitleLabel.snuglyConstrain(to: studySuperView, leftAmount: StudyViewController.DeckTitleLeftRightMargin, rightAmount: StudyViewController.DeckTitleLeftRightMargin)
        let dtltc = NSLayoutConstraint(item: deckTitleLabel, attribute: .top, relatedBy: .equal, toItem: topBarView, attribute: .bottom, multiplier: 1, constant: StudyViewController.DeckTitleTopMargin)
        let dtlhc = NSLayoutConstraint(item: deckTitleLabel, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: StudyViewController.DeckTitleHeight)
        deckTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        studySuperView.addConstraints([dtltc, dtlhc])
    }
    
    private func initRowOfButtonsNearTop() {
        
        // Add button (rightmost)
        addButton.initPictureButton(in: studySuperView, imageName: "add", withColor: StudyViewController.MiddleButtonUnpressedColor, width: StudyViewController.MiddleButtonHeightSmall, height: StudyViewController.MiddleButtonHeightSmall)
        (_, _) = addButton.snuglyConstrain(to: studySuperView, toRight: studySuperView, toBottom: fixedMiddleView, rightAmount: StudyViewController.MiddleButtonsRightMargin, bottomAmount: StudyViewController.MiddleButtonsBottomMargin)
        
        // Shuffle button (just left of add button)
        shuffleButton.initPictureButton(in: studySuperView, imageName: "shuffle", withColor: StudyViewController.MiddleButtonUnpressedColor, width: StudyViewController.MiddleButtonHeightSmall, height: StudyViewController.MiddleButtonHeightSmall)
        (_, _) = shuffleButton.snuglyConstrain(to: studySuperView, toRight: addButton, toBottom: fixedMiddleView, rightAmount: StudyViewController.MiddleButtonsSpacingSmall, bottomAmount: StudyViewController.MiddleButtonsBottomMargin)
        
        // Undo all button
        backAllButton.initPictureButton(in: studySuperView, imageName: "backAll", withColor: StudyViewController.MiddleButtonUnpressedColor, width: StudyViewController.MiddleButtonHeightSmall, height: StudyViewController.MiddleButtonHeightSmall)
        (_, _) = backAllButton.snuglyConstrain(to: studySuperView, toLeft: studySuperView, toBottom: fixedMiddleView, leftAmount: StudyViewController.MiddleButtonsLeftMargin, bottomAmount: StudyViewController.MiddleButtonsBottomMargin)
        
        // Undo all button
        backOneButton.initPictureButton(in: studySuperView, imageName: "backOne", withColor: StudyViewController.MiddleButtonUnpressedColor, width: StudyViewController.MiddleButtonHeightSmall, height: StudyViewController.MiddleButtonHeightSmall)
        (_, _) = backOneButton.snuglyConstrain(to: studySuperView, toLeft: backAllButton, toBottom: fixedMiddleView, leftAmount: StudyViewController.MiddleButtonsSpacingSmall, bottomAmount: StudyViewController.MiddleButtonsBottomMargin)
    }
    
    private func initSwipeButtons() {
        
        // Reycle and checkmark buttons container
        lowerButtonsContainer.backgroundColor = UIColor.clear
        (_, _) = lowerButtonsContainer.snuglyConstrain(to: studySuperView, leftAmount: 0, rightAmount: 0)
        (_, _) = lowerButtonsContainer.snuglyConstrain(to: studySuperView, toTop: kolodaView, toBottom: studySuperView, topAmount: 0, bottomAmount: 0)
        
        let deltaX = (UIScreen.main.bounds.width - StudyViewController.FlashcardLeftMargin - StudyViewController.FlashcardRightMargin) * StudyViewController.LargeButtonDeltaScaleFactor
        
        // Recyle "X" button (for left swipes)
        recycleButton.initPictureButton(in: studySuperView, imageName: "bigTimes", withColor: StudyViewController.MiddleButtonUnpressedColor, width: StudyViewController.MiddleButtonHeightLarge, height: StudyViewController.MiddleButtonHeightLarge)
        let rbxc = NSLayoutConstraint(item: recycleButton, attribute: .centerX, relatedBy: .equal, toItem: lowerButtonsContainer, attribute: .centerX, multiplier: 1, constant: -deltaX)
        recycleButtonYOffsetConstraint = NSLayoutConstraint(item: recycleButton, attribute: .centerY, relatedBy: .equal, toItem: lowerButtonsContainer, attribute: .centerY, multiplier: 1, constant: StudyViewController.SwipeButtonsYOffset)
        recycleButton.translatesAutoresizingMaskIntoConstraints = false
        lowerButtonsContainer.addConstraints([rbxc, recycleButtonYOffsetConstraint])
        labelUnderRecycleButton = recycleButton.initPictureButtonLabel(in: studySuperView, textColor: StudyViewController.ColorOfLabelUnderRecycleButton, fontSize: StudyViewController.SwipeButtonsLabelFontSize, topMargin: StudyViewController.SwipeButtonsLabelTopMargin, labelHeight: StudyViewController.SwipeButtonsLabelHeight)
        
        // Checkmark button (for right swipes)
        checkmarkButton.initPictureButton(in: studySuperView, imageName: "checkmark", withColor: StudyViewController.MiddleButtonUnpressedColor, width: StudyViewController.MiddleButtonHeightLarge, height: StudyViewController.MiddleButtonHeightLarge)
        checkmarkButton.centerView(to: lowerButtonsContainer, x: false, y: true)
        let cmbxc = NSLayoutConstraint(item: checkmarkButton, attribute: .centerX, relatedBy: .equal, toItem: lowerButtonsContainer, attribute: .centerX, multiplier: 1, constant: deltaX)
        checkmarkButtonYOffsetConstraint = NSLayoutConstraint(item: checkmarkButton, attribute: .centerY, relatedBy: .equal, toItem: lowerButtonsContainer, attribute: .centerY, multiplier: 1, constant: StudyViewController.SwipeButtonsYOffset)
        checkmarkButton.translatesAutoresizingMaskIntoConstraints = false
        lowerButtonsContainer.addConstraints([cmbxc, checkmarkButtonYOffsetConstraint])
        labelUnderCheckmarkButton = checkmarkButton.initPictureButtonLabel(in: studySuperView, textColor: StudyViewController.ColorOfLabelUnderCheckmarkButton, fontSize: StudyViewController.SwipeButtonsLabelFontSize, topMargin: StudyViewController.SwipeButtonsLabelTopMargin, labelHeight: StudyViewController.SwipeButtonsLabelHeight)
    }
    
    private func initRefreshScreen() {

        // Refresh button
        refreshButton.initPictureButton(in: studySuperView, imageName: "refresh", withColor: StudyViewController.MiddleButtonUnpressedColor, width: StudyViewController.MiddleButtonHeightLarge, height: StudyViewController.MiddleButtonHeightLarge)
        refreshButton.centerView(to: lowerButtonsContainer, x: true, y: false)
        let rfbyc = NSLayoutConstraint(item: refreshButton, attribute: .centerY, relatedBy: .equal, toItem: lowerButtonsContainer, attribute: .centerY, multiplier: 1, constant: StudyViewController.RefreshButtonYOffset)
        refreshButton.translatesAutoresizingMaskIntoConstraints = false
        lowerButtonsContainer.addConstraints([rfbyc])
        labelUnderRefreshButton = refreshButton.initPictureButtonLabel(in: lowerButtonsContainer, textColor: StudyViewController.ColorOfLabelUnderRefreshButton, fontSize: StudyViewController.RefreshLabelFontSize, topMargin: StudyViewController.RefreshLabelTopMargin, labelHeight: StudyViewController.RefreshLabelHeight)
        labelUnderRefreshButton.text = StudyViewController.RefreshLabelText
    }
    
    private func initCongratsScreen() {
        
        let deltaX = (UIScreen.main.bounds.width - StudyViewController.FlashcardLeftMargin - StudyViewController.FlashcardRightMargin) * StudyViewController.LargeButtonDeltaScaleFactor
        
        // "Start over" button to put all cards back in study deck from learned
        bigBackAllButton.initPictureButton(in: studySuperView, imageName: "bigBackAll", withColor: StudyViewController.MiddleButtonUnpressedColor, width: StudyViewController.MiddleButtonHeightLarge, height: StudyViewController.MiddleButtonHeightLarge)
        let bbabxc = NSLayoutConstraint(item: bigBackAllButton, attribute: .centerX, relatedBy: .equal, toItem: lowerButtonsContainer, attribute: .centerX, multiplier: 1, constant: -deltaX)
        let bbabyc = NSLayoutConstraint(item: bigBackAllButton, attribute: .centerY, relatedBy: .equal, toItem: lowerButtonsContainer, attribute: .centerY, multiplier: 1, constant: StudyViewController.CongratsButtonYOffset)
        bigBackAllButton.translatesAutoresizingMaskIntoConstraints = false
        lowerButtonsContainer.addConstraints([bbabxc, bbabyc])
        labelUnderBigBackAllButton = bigBackAllButton.initPictureButtonLabel(in: lowerButtonsContainer, textColor: StudyViewController.ColorOfLabelUnderBigBackAllButton, fontSize: StudyViewController.CongratsButtonLabelFontSize, topMargin: StudyViewController.CongratsButtonLabelTopMargin, labelHeight: StudyViewController.CongratsButtonLabelHeight)
        labelUnderBigBackAllButton.text = StudyViewController.BigBackAllButtonLabelString
        
        // Reminder button to schedule a notification to review deck
        reminderButton.initPictureButton(in: studySuperView, imageName: "alarm", withColor: StudyViewController.MiddleButtonUnpressedColor, width: StudyViewController.MiddleButtonHeightLarge, height: StudyViewController.MiddleButtonHeightLarge)
        let rmbxc = NSLayoutConstraint(item: reminderButton, attribute: .centerX, relatedBy: .equal, toItem: lowerButtonsContainer, attribute: .centerX, multiplier: 1, constant: deltaX)
        let rmbyc = NSLayoutConstraint(item: reminderButton, attribute: .centerY, relatedBy: .equal, toItem: lowerButtonsContainer, attribute: .centerY, multiplier: 1, constant: StudyViewController.CongratsButtonYOffset)
        reminderButton.translatesAutoresizingMaskIntoConstraints = false
        lowerButtonsContainer.addConstraints([rmbxc, rmbyc])
        labelUnderReminderButton = reminderButton.initPictureButtonLabel(in: lowerButtonsContainer, textColor: StudyViewController.ColorOfLabelUnderReminderButton, fontSize: StudyViewController.CongratsButtonLabelFontSize, topMargin: StudyViewController.CongratsButtonLabelTopMargin, labelHeight: StudyViewController.CongratsButtonLabelHeight)
        labelUnderReminderButton.text = StudyViewController.ReminderButtonLabelString
    }
    
    func initTopbarModal() {
        
        // FX container
        superFxTopbarModalView.isHidden = true
        superFxTopbarModalView.layer.cornerRadius = Constants.CornerRadius
        superFxTopbarModalView.clipsToBounds = true
        (_, _, superFxTopbarModalTopConstraint, superFxTopbarModalBottomConstraint) = dominateStage(theSuperView: superFxTopbarModalView)
        superFxTopbarModalTopConstraint.constant -= studySuperView.frame.height
        superFxTopbarModalBottomConstraint.constant -= studySuperView.frame.height
        
        // FX view
        fxTopbarModalView.backgroundColor = UIColor.clear
        fxTopbarModalView.snuglyConstrain(to: superFxTopbarModalView)
        
        // Container view
        topbarModalNavbar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: Constants.DarkGray]
        (_, _) = topbarModalNavbar.snuglyConstrain(to: fxTopbarModalView, leftAmount: 0, rightAmount: 0)
        let cdnbtc = NSLayoutConstraint(item: topbarModalNavbar, attribute: .top, relatedBy: .equal, toItem: fxTopbarModalView, attribute: .top, multiplier: 1, constant: 0)
        let cdnbhc = NSLayoutConstraint(item: topbarModalNavbar, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: Constants.NavbarHeight)
        topbarModalNavbar.translatesAutoresizingMaskIntoConstraints = false
        fxTopbarModalView.addConstraints([cdnbtc, cdnbhc])
        topbarModalContainerView.backgroundColor = UIColor.clear
        (_, _) = topbarModalContainerView.snuglyConstrain(to: fxTopbarModalView, leftAmount: 0, rightAmount: 0)
        (_, _) = topbarModalContainerView.snuglyConstrain(to: fxTopbarModalView, toTop: topbarModalNavbar, toBottom: fxTopbarModalView, topAmount: 0, bottomAmount: 0)
        
        // Pick deck view controller
        pickDeckController = storyboard!.instantiateViewController(withIdentifier: "studyCollectionsTableViewController")
        addChildViewController(pickDeckController)
        pickDeckController.view.translatesAutoresizingMaskIntoConstraints = false
        topbarModalContainerView.addSubview(pickDeckController.view)
        pickDeckController.view.snuglyConstrain(to: topbarModalContainerView)
        if let sctvc = pickDeckController as? StudyCollectionsTableViewController {
            sctvc.collectionsTableDelegate = self
            pickDeckControllerCast = sctvc
        }
        
        // New deck view controller
        newDeckController = storyboard!.instantiateViewController(withIdentifier: "studyNewCollectionsTableViewController")
        addChildViewController(newDeckController)
        newDeckController.view.translatesAutoresizingMaskIntoConstraints = false
        topbarModalContainerView.addSubview(newDeckController.view)
        newDeckController.view.snuglyConstrain(to: topbarModalContainerView)
        if let snctvc = newDeckController as? StudyNewCollectionTableViewController {
            newDeckControllerCast = snctvc
        }
        
        // Set navbar button colors
        topbarModalCancelButton.tintColor = Constants.TabBarButtonActiveColor
        topbarModalAddButton.tintColor = Constants.TabBarButtonActiveColor
        
        // Show deck picker, since user needs to select a deck upon entry in study mode
        let collectionsCount = FlashcardCollections.GetCollectionNames()?.count ?? 0
        if collectionsCount > 0 {
            showChooseDeckModal(animate: false)
        } else {
            showNewDeckModal(animate: false)
        }
    }
    
    private func initKolodaView() {
        
        // Flashcard container view properties
        kolodaView.dataSource = self
        kolodaView.delegate = self
        kolodaView.isLoop = false
        kolodaView.countOfVisibleCards = StudyViewController.NumVisibleFlashcards
        kolodaView.isHidden = true
        kolodaView.backgroundColor = UIColor.clear

        // Flashcard container view constaints
        (_, _, flashcardHeightConstraint, flashcardYConstraint) = positionInMiddle(theSuperView: kolodaView)
        flashcardTopConstraint = NSLayoutConstraint(item: kolodaView, attribute: .top, relatedBy: .equal, toItem: topBarView, attribute: .bottom, multiplier: 1, constant: StudyViewController.FlashcardkeyboardVisibleTopMargin)
        flashcardBottomConstraint = NSLayoutConstraint(item: kolodaView, attribute: .bottom, relatedBy: .equal, toItem: studySuperView, attribute: .bottom, multiplier: 1, constant: -StudyViewController.FlashcardKeyboardVisibleBottomMargin)
        
        // Fixed middle view
        fixedMiddleView = UIView()
        fixedMiddleView.layer.cornerRadius = Constants.CornerRadius
        fixedMiddleView.backgroundColor = UIColor.clear
        fixedMiddleView.isUserInteractionEnabled = false
        studySuperView.addSubview(fixedMiddleView)
        studySuperView.sendSubview(toBack: fixedMiddleView)
        hideFixedMiddleView()
        (_, _, _, _) = positionInMiddle(theSuperView: fixedMiddleView)
        
        // Label inside fixedMiddleView
        fixedMiddleLabel = UILabel()
        fixedMiddleLabel.textAlignment = .center
        fixedMiddleLabel.textColor = StudyViewController.FixedMiddleLabelTextColor
        fixedMiddleLabel.font = fixedMiddleLabel.font.withSize(StudyViewController.FixedMiddleLabelFontSize)
        fixedMiddleLabel.lineBreakMode = .byWordWrapping
        fixedMiddleLabel.numberOfLines = 0
        fixedMiddleLabel.isUserInteractionEnabled = false
        fixedMiddleView.addSubview(fixedMiddleLabel)
        fixedMiddleLabel.centerView(to: fixedMiddleView)
        (_, _) = fixedMiddleLabel.snuglyConstrain(to: fixedMiddleView, leftAmount: 0, rightAmount: 0)
    }
    
    private func initNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardNotification(notification:)), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: .UIApplicationWillEnterForeground, object: nil)
    }
}

// MARK: - Screen togglers (hide/show)
extension StudyViewController {

    // MARK: hide all middle buttons and labels
    private func hideAllMiddleButtonsAndLabels() {
        middleButtonsHidden = true
        hideRowOfButtonsNearTop()
        hideSwipeLeftRightButtons()
        hideRefreshScreen()
        hideCongratsScreen()
    }
    
    // MARK: show all middle buttons and labels except refresh button and congrats buttons
    private func showFlashcardStudyScreen() {
        hideRefreshScreen()
        hideCongratsScreen()
        
        middleButtonsHidden = false
        showRowOfButtonsNearTop()
        showSwipeLeftRightButtons()
    }
    
    private func showRefreshScreen() {
        hideAllMiddleButtonsAndLabels()
        fixedMiddleLabel.text = StudyViewController.ReachedEndOfDeckString
        showFixedMiddleView()
        showRefreshButton()
        Timer.scheduledTimer(withTimeInterval: StudyViewController.DragAnimationDuration.rawValue, repeats: false) { _ in
            self.kolodaView.isHidden = true
        }
    }
    
    private func hideRefreshScreen() {
        hideFixedMiddleView()
        hideRefreshButton()
    }
    
    private func showCongratsScreen() {
        if let _ = confettiTimer {
            self.confettiTimer?.invalidate()
            self.confettiView.stopConfetti()
            self.confettiTimer = nil
        }
        confettiView.startConfetti()
        confettiTimer = Timer.scheduledTimer(withTimeInterval: StudyViewController.ConfettiDuration, repeats: false) { (_) in
            self.confettiView.stopConfetti()
            self.confettiTimer = nil
        }

        hideAllMiddleButtonsAndLabels()
        fixedMiddleLabel.text = StudyViewController.CongratsString
        showFixedMiddleView()
        setCongratsButtons(invisible: false)
        Timer.scheduledTimer(withTimeInterval: StudyViewController.DragAnimationDuration.rawValue, repeats: false) { _ in
            self.kolodaView.isHidden = true
        }
    }
    
    private func hideCongratsScreen() {
        hideFixedMiddleView()
        hideCongratsButtons()
    }
    
    private func hideFixedMiddleView() {
        fixedMiddleView.isHidden = true
    }
    
    private func showFixedMiddleView() {
        fixedMiddleView.isHidden = false
        fixedMiddleLastBorder = fixedMiddleView.addDashedBorder(lastBorder: fixedMiddleLastBorder, ofColor: StudyViewController.FixedMiddleViewBorderColor, dashLength: 7, dashSpacing: 5, cornerRadius: Constants.CornerRadius)
    }
    
    private func hideCongratsButtons() { setCongratsButtons(invisible: true) }
    private func showCongratsButtons() { setCongratsButtons(invisible: false) }
    private func setCongratsButtons(invisible: Bool) {
        bigBackAllButton.isHidden = invisible
        labelUnderBigBackAllButton.isHidden = invisible
        reminderButton.isHidden = invisible
        labelUnderReminderButton.isHidden = invisible
    }
    
    private func hideSwipeLeftRightButtons() { setSwipeButtons(invisible: true) }
    private func showSwipeLeftRightButtons() { setSwipeButtons(invisible: false) }
    private func setSwipeButtons(invisible: Bool) {
        recycleButton.isHidden = invisible
        labelUnderRecycleButton.isHidden = invisible
        checkmarkButton.isHidden = invisible
        labelUnderCheckmarkButton.isHidden = invisible
    }
    
    private func hideRowOfButtonsNearTop() { setButtonRowNearTop(invisible: true) }
    private func showRowOfButtonsNearTop() { setButtonRowNearTop(invisible: false) }
    private func setButtonRowNearTop(invisible: Bool) {
        backAllButton.isHidden = invisible
        backOneButton.isHidden = invisible
        shuffleButton.isHidden = invisible
        addButton.isHidden = invisible
    }
    
    private func hideRefreshButton() { setRefreshButton(invisible: true) }
    private func showRefreshButton() { setRefreshButton(invisible: false) }
    private func setRefreshButton(invisible: Bool) {
        refreshButton.isHidden = invisible
        labelUnderRefreshButton.isHidden = invisible
    }
    
    private func isFixedMiddleViewScreenActive() -> Bool {
        return isRefreshScreenActive() || isCongratsScreenActive() || isNoCardsYetScreenActive()
    }
    
    private func isRefreshScreenActive() -> Bool {
        guard let currentDeck = currentDeck else {
            return false
        }
        return currentDeck.count > 0 && currentDeck.count <= kolodaView.currentCardIndex
    }
    
    private func isCongratsScreenActive() -> Bool {
        guard let currentDeck = currentDeck, let learnedPile = learnedPile else {
            return false
        }
        return currentDeck.count == 0 && learnedPile.count > 0
    }
    
    private func isNoCardsYetScreenActive() -> Bool {
        guard let currentDeck = currentDeck, let learnedPile = learnedPile else {
            return false
        }
        return currentDeck.count == 0 && learnedPile.count == 0
    }
}

// MARK: - Initialization utility functions
extension StudyViewController {
    
    private func positionInMiddle(theSuperView: UIView) -> (NSLayoutConstraint?, NSLayoutConstraint?, NSLayoutConstraint?, NSLayoutConstraint?) {

        let defViewWidth = UIScreen.main.bounds.width - 2 * Constants.LeftRightMarginDefViewSpacing
        let defViewHeight = defViewWidth / Constants.GoldenRatio + StudyViewController.HeightOfVisiblePartOfCardStack

        let (lc, rc) = theSuperView.snuglyConstrain(to: studySuperView, leftAmount: StudyViewController.FlashcardLeftMargin, rightAmount: StudyViewController.FlashcardRightMargin)
        let hc = NSLayoutConstraint(item: theSuperView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: defViewHeight)
        let yc = NSLayoutConstraint(item: theSuperView, attribute: .centerY, relatedBy: .equal, toItem: studySuperView, attribute: .centerY, multiplier: 1, constant: StudyViewController.FlashcardYOffset)
        theSuperView.translatesAutoresizingMaskIntoConstraints = false
        studySuperView.addConstraints([hc, yc])
        
        return (lc, rc, hc, yc)
    }
    
    private func dominateStage(theSuperView: UIView) -> (NSLayoutConstraint?, NSLayoutConstraint?, NSLayoutConstraint?, NSLayoutConstraint?) {
        
        let (lc, rc) = theSuperView.snuglyConstrain(to: studySuperView, leftAmount: StudyViewController.DominatingViewLeftMargin, rightAmount: StudyViewController.DominatingViewRightMargin)
        let (tc, bc) = theSuperView.snuglyConstrain(to: studySuperView, toTop: topBarView, toBottom: studySuperView, topAmount: StudyViewController.DominatingViewTopMargin, bottomAmount: StudyViewController.DominatingViewBottomMargin)
        
        return (lc, rc, tc, bc)
    }
}

// MARK: - Top bar button handlers
extension StudyViewController {
    
    private func slideTopbarModalIn(animate: Bool = true) {
        superFxTopbarModalView.isHidden = false
        studySuperView.bringSubview(toFront: superFxTopbarModalView)
        bringTopBarToFront()
        superFxTopbarModalTopConstraint.constant = StudyViewController.DominatingViewTopMargin
        superFxTopbarModalBottomConstraint.constant = -StudyViewController.DominatingViewBottomMargin
        if animate {
            UIView.animate(withDuration: StudyViewController.TopSlideAnimationTimeInterval) {
                self.hideFixedMiddleView()
                self.studySuperView.layoutIfNeeded()
            }
        } else {
            studySuperView.layoutIfNeeded()
        }
    }
    
    private func slideTopbarModalOut(postCompetionFunc: (() -> ())? = nil) {
        collectionsListView?.deselectRow()
        superFxTopbarModalTopConstraint.constant += studySuperView.frame.height
        superFxTopbarModalBottomConstraint.constant += studySuperView.frame.height
        UIView.animate(withDuration: StudyViewController.TopSlideAnimationTimeInterval, animations: {
            if self.isFixedMiddleViewScreenActive() {
                self.showFixedMiddleView()
            }
            self.studySuperView.layoutIfNeeded()
        }) { (_) in
            self.topbarModalCancelButton.isEnabled = true
            self.superFxTopbarModalView.isHidden = true
            self.superFxTopbarModalTopConstraint.constant -= 2 * self.studySuperView.frame.height
            self.superFxTopbarModalBottomConstraint.constant -= 2 * self.studySuperView.frame.height
            if let postCompetionFunc = postCompetionFunc {
                self.studySuperView.layoutIfNeeded()
                postCompetionFunc()  // always animate slide outs
            }
        }
    }
    
    @IBAction func handleTopbarModalCancelButton(_ sender: UIBarButtonItem) {
        if !newDeckController.view.isHidden {
            if keyboardOpen {
                keyboardDismissalCompletionFunc = {
                    self.slideTopbarModalOut()
                }
                newDeckController.view.endEditing(true)
            } else {
                slideTopbarModalOut()
            }
        } else {
            slideTopbarModalOut()
        }
    }
    
    // MARK: Make a new deck
    @IBAction func handleTopbarModalAddButton(_ sender: UIBarButtonItem) {
        if let deckName = newDeckControllerCast.createNewDeck() {
            if keyboardOpen {
                keyboardDismissalCompletionFunc = {
                    self.loadDeck(named: deckName)
                }
                newDeckController.view.endEditing(true)
            } else {
                loadDeck(named: deckName)
            }
            pickDeckControllerCast.refreshViewController()
        }
    }
    
    private func showChooseDeckModal(animate: Bool) {
        topbarModalAddButton.title = ""
        topbarModalAddButton.isEnabled = false
        topbarModalNavbarTitle.title = StudyViewController.DecksString
        newDeckController.view.isHidden = true
        pickDeckController.view.isHidden = false
        slideTopbarModalIn(animate: animate)
    }
    
    private func pickDeckButtonHandler() {
    
        // If whole modal is hidden, show the modal
        if superFxTopbarModalView.isHidden {
            showChooseDeckModal(animate: true)
        } else {  // If the modal is showing...
            
            // ...and it's for a new deck, slide it out then back in with choose deck one
            if !newDeckController.view.isHidden {
                if keyboardOpen {
                    keyboardDismissalCompletionFunc = {
                        self.slideTopbarModalOut(postCompetionFunc: {
                            self.showChooseDeckModal(animate: true)
                        })
                    }
                    newDeckController.view.endEditing(true)
                } else {
                    slideTopbarModalOut(postCompetionFunc: {
                        self.showChooseDeckModal(animate: true)
                    })
                }
            } else {  // If choose deck controller is alreadly visible, just slide it out
                slideTopbarModalOut()
            }
        }
    }
    
    @IBAction func handlePickDeckButton(_ sender: UIButton, forEvent event: UIEvent) {
        pickDeckButtonHandler()
    }
    
    private func showNewDeckModal(animate: Bool = true) {
        topbarModalAddButton.title = StudyViewController.AddButtonString
        topbarModalAddButton.isEnabled = true
        topbarModalNavbarTitle.title = StudyViewController.NewDeckString
        pickDeckController.view.isHidden = true
        newDeckControllerCast.resetEverything()
        newDeckController.view.isHidden = false
        slideTopbarModalIn(animate: animate)
        newDeckControllerCast.popKeyboardAndStartEditing()
    }
    
    private func newDeckButtonHandler() {
        
        // If hidden, just show modal
        if superFxTopbarModalView.isHidden {
            showNewDeckModal()
        } else {  // If it's showing...
            
            // ...and new deck controller is visible, slide modal out
            if !newDeckController.view.isHidden {
                if keyboardOpen {
                    keyboardDismissalCompletionFunc = {
                        self.slideTopbarModalOut()
                    }
                    newDeckController.view.endEditing(true)
                } else {
                    slideTopbarModalOut()
                }
            } else {  // If choose deck controller is visible, slide it out then slide in the new deck one
                slideTopbarModalOut(postCompetionFunc: {
                    self.showNewDeckModal(animate: true)
                })
            }
        }
    }
    
    @IBAction func handleNewDeckButton(_ sender: UIButton, forEvent event: UIEvent) {
        newDeckButtonHandler()
    }
    
    private func updateCurrentCardDisplayedIndex() {
        let currentCard = kolodaView.viewForCard(at: kolodaView.currentCardIndex) as? CardView
        currentCard?.updateIndex()
    }
    
    private func reloadFlashcards() {
        kolodaView.reloadData()
        kolodaView.resetCurrentCardIndex()
        updateCurrentCardDisplayedIndex()
    }
}

// MARK: - Middle button handlers
extension StudyViewController {

    @IBAction func handleShuffleButton(_ sender: UIButton, forEvent event: UIEvent) {
        guard let deckName = currentDeckName else {
            print("Deck name is nil")
            return
        }
        if let usedDeckName = FlashcardCollections.ShuffleCollection(named: deckName) {
            kolodaView.isHidden = true
            loadDeck(named: usedDeckName, shouldCloseTopbar: false)
        }
    }
    
    private func backOneHandler() {
        print("Pressed back one button")
        
        guard let _ = learnedPile, learnedPile!.count > 0 else {
            print("Nothing in learned pile to undo")
            return
        }
        
        guard let currentDeckName = currentDeckName else {
            print("No deck chosen right now, so can't undo")
            return
        }
        
        // If we moved a card from learned back into the deck, reset local state variables, update score board
        if let _ = FlashcardCollections.UnlearnedLastFlashcard(in: currentDeckName) {
            
            let previousDeckSize = currentDeck?.count
            currentDeck = FlashcardCollections.GetCollection(named: currentDeckName)
            
            guard let currentDeck = currentDeck else {
                print("Couldn't find deck we just updated with undo...")
                return
            }
            
            learnedPile = FlashcardCollections.GetLearnedCollection(named: currentDeckName)
            
            if previousDeckSize == 0 {
                showFlashcardStudyScreen()
                reloadFlashcards()
                kolodaView.isHidden = false
            } else {
                kolodaView.insertCardAtIndexRange(Range(NSRange(location: currentDeck.count - 1, length: 1))!)
            }
            
            updateNumCardsLeftAndDone()
            
            bounceButton(withConstraint: recycleButtonYOffsetConstraint)
            bounceButton(withConstraint: checkmarkButtonYOffsetConstraint)
        }
    }
    
    @IBAction func handleBackOneButton(_ sender: UIButton, forEvent event: UIEvent) {
        backOneHandler()
    }
    
    private func backAllHandler() {
        print("Pressed back all button")
        
        guard let _ = learnedPile, learnedPile!.count > 0 else {
            print("Nothing in learned pile to undo")
            return
        }
        
        guard let currentDeckName = currentDeckName else {
            print("No deck chosen right now, so can't undo")
            return
        }
        
        // If we moved all cards from learned back into the deck, reset local state variables, update score board
        currentDeck = FlashcardCollections.UnlearnedAllFlashcards(in: currentDeckName)
        
        guard let currentDeck = currentDeck else {
            print("Couldn't find deck we just updated with undo...")
            return
        }

        showFlashcardStudyScreen()
        
        let oldLearnedPileSize = learnedPile?.count ?? 0
        learnedPile = nil
        updateNumCardsLeftAndDone()
        
        // If went from congrats screen to deck
        if oldLearnedPileSize == currentDeck.count {
            reloadFlashcards()
            kolodaView.isHidden = false
        } else {  // if hit backAll before all cards were learned
            kolodaView.insertCardAtIndexRange(Range(NSRange(location: currentDeck.count - oldLearnedPileSize, length: oldLearnedPileSize))!)
        }
        
        bounceButton(withConstraint: recycleButtonYOffsetConstraint)
        bounceButton(withConstraint: checkmarkButtonYOffsetConstraint)
    }
    
    @IBAction func handleBackAllButton(_ sender: UIButton, forEvent event: UIEvent) {
        backAllHandler()
    }
    
    @IBAction func handleRecycleButton(_ sender: UIButton, forEvent event: UIEvent) {
        kolodaView.swipe(.left, force: true)
    }
    
    @IBAction func handleCheckmarkButton(_ sender: UIButton, forEvent event: UIEvent) {
        kolodaView.swipe(.right, force: true)
    }
    
    @IBAction func handleRefreshButton(_ sender: UIButton, forEvent event: UIEvent) {
        kolodaView.resetCurrentCardIndex()
        updateCurrentCardDisplayedIndex()
        showFlashcardStudyScreen()
        kolodaView.isHidden = false
        bounceButton(withConstraint: recycleButtonYOffsetConstraint)
        bounceButton(withConstraint: checkmarkButtonYOffsetConstraint)
    }
    
    @IBAction func handleBigBackAllButton(_ sender: UIButton, forEvent event: UIEvent) {
        backAllHandler()
    }
}

// MARK: - Miscellaneous
extension StudyViewController {
    
    func setDeckTitle(to title: String) {
        deckTitleLabel.text = title
    }
    
    private func updateNumCardsLeftAndDone() {
        let learnedCount = self.learnedPile?.count ?? 0
        let remainingCount = self.currentDeck?.count ?? 0

        labelUnderRecycleButton.text = StudyViewController.LabelUnderRecycleButtonTemplateString.replacingOccurrences(of: "{{num-left}}", with: String(remainingCount))
        labelUnderCheckmarkButton.text = StudyViewController.LabelUnderCheckmarkButtonTemplateString.replacingOccurrences(of: "{{num-done}}", with: String(learnedCount))
    }
    
    private func collectionWasPicked(name: String) {
        deckTitleLabel.isHidden = false  // likely set elsewhere, but just to sure
        
        if isNoCardsYetScreenActive() {
            hideAllMiddleButtonsAndLabels()
            kolodaView.isHidden = true
            addButton.isHidden = false
            fixedMiddleLabel.text = StudyViewController.FixedMiddleLabelAddCardString
            showFixedMiddleView()
        } else if isCongratsScreenActive() {
            backAllHandler()
        } else {
            showFlashcardStudyScreen()
            reloadFlashcards()
            kolodaView.isHidden = false
            studySuperView.bringSubview(toFront: kolodaView)
            updateNumCardsLeftAndDone()
        }
    }
    
    private func kolodaViewIsVisible() -> Bool {
        return !kolodaView.isHidden && superFxTopbarModalView.isHidden
    }
    
    @objc func keyboardNotification(notification: NSNotification) {

        // Let AddViewController handle its own keyboard notifications
        guard addCardViewController == nil else {
            return
        }
        
        if let userInfo = notification.userInfo, let keyboardFrameBegin = (userInfo[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue, let keyboardFrameEnd = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            
            // Get edge and animation info from notification
            let beginningKeyboardEdgeY = keyboardFrameBegin.origin.y
            let endingKeyboardEdgeY = keyboardFrameEnd.origin.y
            let duration: TimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
            let animationCurveRawNSN = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber
            let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIViewAnimationOptions.curveEaseInOut.rawValue
            let animationCurve: UIViewAnimationOptions = UIViewAnimationOptions(rawValue: animationCurveRaw)
            
            // If this notification doesn't open or close keyboard, exit
            guard !beginningKeyboardEdgeY.approximatelyEquals(other: endingKeyboardEdgeY) else {
                return
            }

            // If keyboard isn't opening, closing, or changing, then exit
            if endingKeyboardEdgeY.approximatelyEquals(other: UIScreen.main.bounds.height) {
                keyboardOpen = false
                
                // Koloda view: swap out top/bottom constrains for height and Y ones
                studySuperView.removeConstraints([flashcardTopConstraint, flashcardBottomConstraint])
                kolodaView.translatesAutoresizingMaskIntoConstraints = false
                studySuperView.addConstraints([flashcardHeightConstraint, flashcardYConstraint])
                
                // Deck picker view
                superFxTopbarModalBottomConstraint.constant = -StudyViewController.DominatingViewKeyboardVisibleBottomMargin
                
                UIView.animate(withDuration: duration, delay: 0.0, options: animationCurve, animations: { self.view.layoutIfNeeded() }, completion: { _ in
                    self.deckTitleLabel.isHidden = false
                    if let kdf = self.keyboardDismissalCompletionFunc {
                        kdf()
                        self.keyboardDismissalCompletionFunc = nil
                    }
                })
            } else {  // Otherwise it's just resizing, so modify constraints as necessary
                keyboardOpen = true
                
                // Put edge into local (studySuperView) coordinates
                let tabBarHeight = tabBarController?.tabBar.frame.size.height ?? CGFloat(80)  // 80 is best guess tabbar height
                let globalSuperviewHeight = UIScreen.main.bounds.size.height
                let localSuperviewHeight = studySuperView.frame.size.height
                let edgeDistFromBottomGlobal = globalSuperviewHeight - endingKeyboardEdgeY
                let edgeDistFromTabBarGlobal = edgeDistFromBottomGlobal - tabBarHeight
                let edgeFractionLocal = edgeDistFromTabBarGlobal / (globalSuperviewHeight - tabBarHeight)
                let edgeDistFromBottomLocal = edgeFractionLocal * localSuperviewHeight
                
                // Prevent views from being blocked by keyboard. Views that might be edited should be resized and/or moved. Views that can't be edited should be hidden
                deckTitleLabel.isHidden = true
                
                // Flashcards: (1) move the koloda view so it's nestled under topbar and (2) adjust bottom edge to make room for keyboard
                studySuperView.removeConstraints([flashcardHeightConstraint, flashcardYConstraint])
                flashcardBottomConstraint.constant = -(edgeDistFromBottomLocal + StudyViewController.FlashcardKeyboardVisibleBottomMargin)
                kolodaView.translatesAutoresizingMaskIntoConstraints = false
                studySuperView.addConstraints([flashcardTopConstraint, flashcardBottomConstraint])
                
                // Deck picker view: lift bottom edge
                superFxTopbarModalBottomConstraint.constant = -(edgeDistFromBottomLocal + StudyViewController.DominatingViewKeyboardVisibleBottomMargin)
                
                UIView.animate(withDuration: duration, delay: 0.0, options: animationCurve, animations: { self.view.layoutIfNeeded() }, completion: nil)
            }
        }
    }
    
    // MARK: this code is executed when the study tab is selected. Not sure if it's before or after its views appear - we just use it see if we should show the new deck modal or the choose deck one
    func comingFromAnotherTab() {
        
        guard finishedInitializing else {
            return
        }
        
        if studyModeIsBlank() {
            
            let collectionsCount = FlashcardCollections.GetCollectionNames()?.count ?? 0
            
            // If the new deck or choose deck controller is open
            if !superFxTopbarModalView.isHidden {
                
                // If the new deck controller is open
                if pickDeckController.view.isHidden {
                    
                    // If we should show deck picker, toggle it
                    if collectionsCount > 0 {
                        pickDeckButtonHandler()
                    } else {  // If we should show new deck controller...
                        // ...do nothing
                    }
                } else {  // If the choose deck controller is open
                    
                    // If we should show deck picker...
                    if collectionsCount > 0 {
                        // ...do nothing
                    } else {  // If we should show new deck controller, toggle it
                        newDeckButtonHandler()
                    }
                }
            } else {  // If the screen is entirely blank, don't worry about double toggles
                if collectionsCount > 0 {
                    pickDeckButtonHandler()
                } else {
                    newDeckButtonHandler()
                }
            }
        }
    }
}

// MARK: - Koloda (tinder) view delegate functions
extension StudyViewController: KolodaViewDelegate {

    // MARK: Make a button (e.g. swipe left or right ones) bounce up once
    private func bounceButton(withConstraint constraint: NSLayoutConstraint) {
        constraint.constant -= StudyViewController.ButtonJumpAmount
        UIView.animate(withDuration: StudyViewController.ButtonJumpDuration / 2, delay: 0.0, options: .curveEaseOut, animations: {
            self.studySuperView.setNeedsLayout()
            self.studySuperView.layoutIfNeeded()
        }) { (_) in
            constraint.constant += StudyViewController.ButtonJumpAmount
            UIView.animate(withDuration: StudyViewController.ButtonJumpDuration / 2, delay: 0.0, options: .curveEaseIn, animations: {
                self.studySuperView.setNeedsLayout()
                self.studySuperView.layoutIfNeeded()
            })
        }
    }
    
    private func swipedLeft(onLastCardInSeries isLastCard: Bool, deckName: String) {
        if isLastCard {
            showRefreshScreen()
        } else {  // animate the recycle button
            bounceButton(withConstraint: recycleButtonYOffsetConstraint)
            let currentCard = kolodaView.viewForCard(at: kolodaView.currentCardIndex) as? CardView
            currentCard?.updateIndex()
        }
    }
    
    private func swipedRight(index: Int, word: String, deckName: String, onLastCardInSeries isLastCard: Bool, onLastRemainingCard isLastRemainingCard: Bool) {
        
        // If user swipes right, remove from deck into "learned" pile
        FlashcardCollections.LearnedFlashcard(at: index, in: deckName)
        self.currentDeck = FlashcardCollections.GetCollection(named: deckName)
        self.learnedPile = FlashcardCollections.GetLearnedCollection(named: deckName)
        kolodaView.removeCardInIndexRange(Range(NSRange(location: index, length: 1))!, animated: false)

        updateNumCardsLeftAndDone()
        
        if isLastRemainingCard {
            showCongratsScreen()
        } else if isLastCard {
            showRefreshScreen()
        } else {  // animate the refresh button
            bounceButton(withConstraint: checkmarkButtonYOffsetConstraint)
            let currentCard = kolodaView.viewForCard(at: kolodaView.currentCardIndex) as? CardView
            currentCard?.updateIndex()
        }
    }

    func koloda(_ koloda: KolodaView, didSwipeCardAt index: Int, in direction: SwipeResultDirection) {
        
        guard let currentDeckName = currentDeckName, let currentDeck = currentDeck else {
            print("Basic stuff is nil")
            return
        }
        
        guard index >= 0, index < currentDeck.count else {
            print("Indices into deck messed up", index)
            return
        }

        var currentCard = currentDeck[index]
        guard let wordOnCurrentCard = currentCard[FlashcardCollections.WordAttributeName]?.string else {
            print("Word missing")
            return
        }
        
        switch direction {
        case .left:
            swipedLeft(onLastCardInSeries: index == currentDeck.count - 1, deckName: currentDeckName)
        case .right:
            swipedRight(index: index, word: wordOnCurrentCard, deckName: currentDeckName, onLastCardInSeries: index == currentDeck.count - 1, onLastRemainingCard: currentDeck.count == 1)
        default:
            print("Unsupported swipe direction")
        }
    }
    
    func kolodaSwipeThresholdRatioMargin(_ koloda: KolodaView) -> CGFloat? {
        return 0.4
    }
    
    func kolodaShouldTransparentizeNextCard(_ koloda: KolodaView) -> Bool {
        return false
    }
}

// MARK: - Koloda (tinder) view data source functions
extension StudyViewController: KolodaViewDataSource {
    func kolodaNumberOfCards(_ koloda:KolodaView) -> Int {
        return currentDeck?.count ?? 0
    }
    
    func kolodaSpeedThatCardShouldDrag(_ koloda: KolodaView) -> DragSpeed {
        return StudyViewController.DragAnimationDuration
    }
    
    func koloda(_ koloda: KolodaView, viewForCardAt index: Int) -> UIView {

        guard let deckName = currentDeckName, let currentDeck = currentDeck else {
            print("Deck or deck name is nil...")
            return UIView()
        }
        
        guard index >= 0, index < currentDeck.count else {
            print("Index \(index) out of bounds in currentDeck. Current index is \(koloda.currentCardIndex)")
            return UIView()
        }

        let currentCardContents = currentDeck[index]
        let currentFlashcard = CardView(contents: currentCardContents, actionReceiver: self, cardIndex: index, deckName: deckName)
        currentFlashcard.backgroundColor = UIColor.white

        return currentFlashcard
    }
}

// MARK: - An individual flashcard's actions, like save and delete
extension StudyViewController: CardViewActionReceiver {

    func saveCurrentFlashcard(withNewContent contents: NSAttributedString, withIndex cardIndex: Int) {
        guard let currentDeckName = currentDeckName, let currentDeck = currentDeck else {
            print("Deck or deck name is nil")
            return
        }
        let underlyingIndex = cardIndex
        guard underlyingIndex >= 0, underlyingIndex < currentDeck.count else {
            print("Current koloda index out of bounds")
            return
        }
        
        guard let updatedCard = FlashcardCollections.AddAttributeToFlashcard(in: currentDeckName, at: underlyingIndex, named: FlashcardCollections.UserSuppliedContentsAttributeName, containing: contents) else {
            print("Couldn't update card contents")
            return
        }

        self.currentDeck![underlyingIndex] = updatedCard
    }
    
    func present(optionsVC: UIViewController, animated: Bool) {
        self.present(optionsVC, animated: animated)
    }
    
    func deleteCurrentFlashcard(withIndex cardIndex: Int) {
        guard let currentDeckName = currentDeckName, let currentDeck = currentDeck else {
            print("Deck or deck name is nil")
            return
        }
        let underlyingIndex = cardIndex
        let kolodaIndex = kolodaView.currentCardIndex
        guard underlyingIndex >= 0, underlyingIndex < currentDeck.count, kolodaIndex >= 0, kolodaIndex < currentDeck.count else {
            print("Current koloda index out of bounds")
            return
        }
        
        var removedLastCardInSeries = false
        if kolodaIndex == currentDeck.count - 1 {
            removedLastCardInSeries = true
        }
        
        var removedLastRemainingCard = false
        if currentDeck.count == 1 {
            removedLastRemainingCard = true
        }
        
        let _ = FlashcardCollections.RemoveFlashcard(at: underlyingIndex, in: currentDeckName)
        self.currentDeck = FlashcardCollections.GetCollection(named: currentDeckName)
        kolodaView.removeCardInIndexRange(Range(NSRange(location: kolodaIndex, length: 1))!, animated: true)
        
        if removedLastRemainingCard {
            let learnedPileSize = learnedPile?.count ?? 0
            if learnedPileSize > 0 {  // If there are some learned cards, let user rewind
                showCongratsScreen()
            } else {  // If there are no cards at all, present add card view
                hideAllMiddleButtonsAndLabels()
                addButton.isHidden = false
                fixedMiddleLabel.text = StudyViewController.FixedMiddleLabelAddCardString
                showFixedMiddleView()
            }
        } else if removedLastCardInSeries {
            showRefreshScreen()
        } else {  // more cards left
            let currentCard = kolodaView.viewForCard(at: kolodaView.currentCardIndex) as? CardView
            currentCard?.updateIndex()
        }

        updateNumCardsLeftAndDone()
    }
    
    func didBeginEditing() {
        pickDeckButton.isEnabled = false
        newDeckButton.isEnabled = false
    }
    
    func didEndEditing() {
        view.endEditing(true)
        pickDeckButton.isEnabled = true
        newDeckButton.isEnabled = true
    }
}

extension StudyViewController: AddCardDelegate {

    private func cardWasAddedToCurrentDeck(to deck: String) {
        guard let newDeck = FlashcardCollections.GetCollection(named: deck) else {
            print("Error: could not get deck to which card was added")
            return
        }

        if middleButtonsHidden {
            showFlashcardStudyScreen()
        }
        self.currentDeck = newDeck  // refresh currenDeck, since a card was added elsewhere
        if newDeck.count == 1 {  // open deck if it was the first card
            collectionWasPicked(name: deck)
        } else {
            kolodaView.insertCardAtIndexRange(Range(NSRange(location: newDeck.count - 1, length: 1))!)
        }
        updateNumCardsLeftAndDone()
    }
    
    func addPressed() {

        // Check edge cases and display error messages if necessary
        guard let currentDeckName = currentDeckName else {
            addCardViewController.errorType = .needToChooseDeck
            view.endEditing(true)
            return
        }
        guard let word = addCardViewController.wordField.text, word.count > 0 else {
            addCardViewController.errorType = .needWord
            view.endEditing(true)
            return
        }
        guard let definition = addCardViewController.definitionTextView.text, definition.count > 0 else {
            addCardViewController.errorType = .needDefinition
            view.endEditing(true)
            return
        }
        
        // Create attributed string for definition from HTML
        let additionalStyle = StudyViewController.UserDefinedCardStyle
        let bodyTemplate = "<span class=\"text\">{{text}}</span>"
        let htmlDefinition = Constants.ContentTemplate.replacingOccurrences(of: "{{more-style}}", with: additionalStyle).replacingOccurrences(of: "{{body}}", with: bodyTemplate.replacingOccurrences(of: "{{text}}", with: definition))
        let attrbDefinition = htmlDefinition.htmlToAttributedString
        
        // Put word and definition into a contents dict, then add the card to the current deck
        let contents = [
            FlashcardCollections.WordAttributeName: NSAttributedString(string: word),
            FlashcardCollections.UserSuppliedContentsAttributeName: attrbDefinition!
        ]
        _ = FlashcardCollections.AddFlashcard(to: currentDeckName, containing: contents)
        
        // Close add card modal
        if let _ = addCardViewController {
            addCardViewController = nil
        }
        dismiss(animated: true)
        
        // Update the current koloda deck so user doesn't have to repick this deck to see the new card
        guard let currentDeck = FlashcardCollections.GetCollection(named: currentDeckName) else {
            print("Error: could not get current deck after adding a card")
            return
        }
        
        if middleButtonsHidden {
            showFlashcardStudyScreen()
        }
        
        self.currentDeck = currentDeck
        if currentDeck.count == 1 {
            collectionWasPicked(name: currentDeckName)
        } else {
            kolodaView.insertCardAtIndexRange(Range(NSRange(location: currentDeck.count - 1, length: 1))!)
        }
        updateNumCardsLeftAndDone()
    }
}

extension StudyViewController: CollectionsTableViewControllerDelegate {

    func loadDeck(named collectionName: String, shouldCloseTopbar: Bool = true) {
        
        // Load flashcards
        currentDeck = FlashcardCollections.GetCollection(named: collectionName)
        learnedPile = FlashcardCollections.GetLearnedCollection(named: collectionName)
        guard let _ = currentDeck else {
            print("No Deck", collectionName)
            return
        }
        
        currentDeckName = collectionName
        setDeckTitle(to: collectionName)
        
        if shouldCloseTopbar {
            if isNoCardsYetScreenActive() {
                slideTopbarModalOut(postCompetionFunc: {
                    // If desired, bring up add card modal here
                })
            } else {
                slideTopbarModalOut()
            }
        }
        
        collectionWasPicked(name: collectionName)
    }
    
    func performPostCloseAction(for row: Int) {
        guard let collectionName = FlashcardCollections.GetCollectionName(at: row) else {
            setDeckTitle(to: StudyViewController.NoDeckChosenString)
            return
        }
        loadDeck(named: collectionName)
    }
    
    func toggleTableViewModal() {
        // Done in performPostCloseAction to chain animations
    }
    
    func getCurrentWord() -> String? {
        return nil
    }
    
    func getPersistableDict() -> [String : NSAttributedString]? {
        return nil
    }
    
    func setCollectionsListView(view: CollectionsTableViewController?) {
        collectionsListView = view
    }
    
    private func resetStudyMode() {
        currentDeck = nil
        learnedPile = nil
        currentDeckName = nil
        kolodaView.isHidden = true
        deckTitleLabel.isHidden = true
        deckTitleLabel.text = StudyViewController.NoDeckChosenString
        hideAllMiddleButtonsAndLabels()
    }
    
    private func studyModeIsBlank() -> Bool {
        return currentDeck == nil && currentDeckName == nil && kolodaView.isHidden
    }
    
    func didDelete(deck: String?, passDataToOtherTab: Bool) {
        guard let deckName = deck else {
            print("No deck name given")
            return
        }
        
        if let cdn = currentDeckName, cdn == deckName {
            resetStudyMode()
        }
        
        // Let other tab know we deleted this deck, so it can update the table
        if passDataToOtherTab {
            searchVC?.didDelete(deck: deck, passDataToOtherTab: false)
        } else {  // Only reload collections table data if this was called from the other tab, since table data has already been reloaded when passDataToOtherTab == true
            collectionsListView?.tableView.reloadData()
        }
    }
    
    // MARK: called from search mode when a card is saved
    func didSelect(deck: String?, passDataToOtherTab: Bool) {
        guard let deckName = deck else {
            print("No deck name given")
            return
        }
        
        // If a card was added in the search view to the current deck, reload it
        if let cdn = currentDeckName, cdn == deckName, !passDataToOtherTab {
            cardWasAddedToCurrentDeck(to: deckName)
        }
    }
}

extension StudyViewController: ModalVCDelegate {

    func closePressed() {
        
        // If the reminders modal is closing
        if let _ = reminderViewController {
            reminderViewController = nil
        } else if let _ = addCardViewController {
            addCardViewController = nil
        } else {
            print("closePressed was invoked in an unknown modal view controller")
        }
        
        dismiss(animated: true)
    }
}

extension StudyViewController: ReminderDelegate {

    func setPressed(forDate date: Date) {

        // Properties
        var timeDelta = date - Date()
        if timeDelta <= 0.0 {
            timeDelta = 1.0
        }
        let daysInFuture = timeDelta.toDays()
        let notificationContent = UNMutableNotificationContent()
        let cleanedDeckTitle = deckTitleLabel.text?.trimmingCharacters(in: .whitespaces) ?? StudyViewController.NotificationDefaultDeckTitle
        notificationContent.title = StudyViewController.ReviewNotificationTitleString.replacingOccurrences(of: "{{deck-title}}", with: cleanedDeckTitle)
        notificationContent.body = StudyViewController.ReviewNotificationContentString.replacingOccurrences(of: "{{days}}", with: String(daysInFuture))
        notificationContent.sound = UNNotificationSound.default()
        notificationContent.categoryIdentifier = cleanedDeckTitle
        
        // Trigger
        let notificationTrigger = UNTimeIntervalNotificationTrigger(timeInterval: timeDelta, repeats: false)
        
        // Set up notification
        let identifier = "\(cleanedDeckTitle) \(date)"
        let request = UNNotificationRequest(identifier: identifier, content: notificationContent, trigger: notificationTrigger)
        AppDelegate.NotificationCenter.add(request, withCompletionHandler: { (error) in
            if let error = error {
                print("Couldn't create notification \(identifier). \(error)")
            }
        })
        
        dismiss(animated: true)
    }
}
