//
//  ViewController.swift
//  Tapdefine
//
//  Created by Hamik on 6/21/18.
//  Copyright © 2018 Hamik. All rights reserved.
//

import AVFoundation
import CloudKit
import Photos
import UIKit

import CGPathIntersection
import FirebaseAnalytics

enum ApiUsageType {
    case scan, search
}

class ViewController: UIViewController {

    // General string constants
    static let DragToCropString = "Drag a box to scan a word or enter above"
    static let TryAgainString = "Try again"
    static let SavedCardTemplateString = "Saved card to {{deck-name}}"
    static let ManualEntryDefaultPlaceholder = "Enter a word"
    static let PhraseSelectionDoneButtonString = "Done"
    static let PhraseSelectionCancelButtonString = "Cancel"
    
    // Camera permissions strings
    static let RestrictedAccessMessageString = "Camera access is restricted - ask owner for access"
    static let JustDeniedCameraAccessMessageString = "No worries - tap button again to enable later"
    static let CameraPermissionDenialAlertTitleString = "Need Camera Access"
    static let CameraPermissionDenialLongActionPromptString = "Grant permission by opening system settings, scrolling to Dictpic, toggling camera, and reopening app"
    static let CameraPermissionDenialShortActionPromptString = "Open Dictpic permissions to grant access"
    static let GoToSettingsButtonString = "Open"
    static let OKButtonString = "Ok"
    static let PickAWordMessage = "Pick word then done"

    
    // Word search failure string constants
    static let CouldNotGenerateDCTokenMessageString = "Apple Device Check unavailable on platform"
    static let UnknownApiFailureString = "💩, something is wrong!"
    static let DeviceCheckFailureMessageString = "Device verification failed"
    static let InvalidCloudUserIDMessageString = "Must be logged into iCloud"
    static let GlobalUsageLimitExceededString = "Max {{interval}} {{usage-type}} count exceeded"
    static let GenericUsageLimitExceededString = "{{usage-type}} count exceeded"
    
    static let HourString = "hourly"
    static let DayString = "daily"
    static let WeekString = "weekly"
    static let MonthString = "monthly"
    static let YearString = "annual"
    static let Intervals = [
        "h": HourString,
        "d": DayString,
        "w": WeekString,
        "m": MonthString,
        "y": YearString
    ]
    static let SearchUsageString = "Search"
    static let ScanUsageString = "Scan"
    
    // Aggregate response codes
    static let CouldNotGenerateDCTokenCode = "noTokenFailure"
    static let DeviceCheckFailureCode = "deviceCheckFailure"
    static let InvalidICloudUserIDFailureCode = "invalidICloudUserID"
    static let ApiUsageThresholdExceededFailureCode = "thresholdExceeded"
    static let UnknownFailureCode = "unknown"
    static let FreeThresholdTypeCode = "free"
    static let GlobalThresholdTypeCode = "global"

    // General UI constants
    static let CropViewDefaultHeight = CGFloat(44)
    static let CropViewDefaultWidth = Constants.GoldenRatio * CropViewDefaultHeight
    static let CropViewScaleFactor = CGFloat(1)
    static let TopMarginModal = CGFloat(9.5) + Constants.ManualEntryTextFieldBottomMargin
    static let BottomMarginModal = TopMarginModal
    static let JpegQuality = CGFloat(0.5)  // needs to be in interval [0, 1]
    static let OcrPathMulti = "ocr/google/multi"
    static let MaxZoomValue = CGFloat(3)
    static let TimeToShowTestImage = 3.0
    static let DefinitionExpansionAnimationDuration = 0.3
    static let MiddleActivityIndicatorColor = Constants.TabBarButtonActiveColor
    static let PressedTopBarButtonColor = Constants.TabBarButtonActiveColor
    static let DefaultTopBarButtonColor = Constants.TabBarButtonInactiveColor
    static let CameraButtonRightMargin = -Constants.TopbarButtonSpacing - 2
    
    // Phrase Selection UI
    static let CropboxBorderColor = Constants.TabBarButtonActiveColor
    static let CropboxInteriorColor = CropboxBorderColor.withAlphaComponent(0.5)
    static let BoundedWordBorderColor = CropboxInteriorColor.cgColor
    static let BoundedWordInteriorColorNotChosen = UIColor.clear.cgColor
    static let BoundedWordInteriorColorChosen = CropboxInteriorColor.cgColor
    static let BoundedWordBorderWidth = CGFloat(2)
    static let HighlighterLineColor = Constants.TabBarButtonActiveColor.cgColor
    static let HighlighterLineOpacity: Float = 0.5
    static let SuperCropViewLeftRightMargin = CGFloat(0)
    static let SuperCropViewTopMargin = CGFloat(0)
    static let SuperCropViewBottomMargin = CGFloat(0)
    static let SnapMinLeftRightMargin = Constants.LeftRightMarginDefViewSpacing
    static let SnapMinTopMargin = PhraseSelectionButtonContainerHeight + PhraseSelectionButtonContainerTopMargin
    static let SnapMinBottomMargin = CGFloat(10)
    static let PhraseSelectionButtonContainerLeftRightMargin = SnapMinLeftRightMargin
    static let PhraseSelectionButtonContainerHeight = CGFloat(30)
    static let PhraseSelectionButtonContainerTopMargin = CGFloat(10)
    static let PhraseSelectionButtonColor = UIColor.white
    static let PhraseSelectionButtonLeftMargin = CGFloat(0)
    static let PhraseSelectionButtonRightMargin = CGFloat(0)
    static let PhraseSelectionButtonFont = Constants.TopBarButtonFont
    static let MessageTopBottomMargin = CGFloat(10)
    
    // Messages
    static let UpperMessageMinLeftRightMargin = CGFloat(20)
    static let UpperMessageLeftRightPadding = CGFloat(7.5)
    static let UpperMessageTopBottomPadding = CGFloat(7.5)
    static let UpperMessageLifetime = 2.5
    static let UpperMessageAnimationDuration = 0.3

    // Views
    @IBOutlet weak var parentView: UIView!
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var definitionView: UIView!
    @IBOutlet weak var snapView: UIImageView!
    var pageViewController: DefinitionPageViewController?

    // Top bar, including manual entry and buttons
    @IBOutlet weak var superTopBarView: UIVisualEffectView!
    @IBOutlet weak var topBarView: UIView!
    @IBOutlet weak var manualEntryView: UIView!
    @IBOutlet weak var manualEntryTextField: PaddedTextField!
    @IBOutlet weak var middleActivityView: UIActivityIndicatorView!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var flashlightButton: UIButton!
    @IBOutlet weak var cameraButton: UIButton!
    var lightBulbOn = false
    var expanded = false

    // Flashcard stuff
    @IBOutlet weak var superModalView: UIView!
    @IBOutlet weak var modalView: UIView!
    @IBOutlet weak var superCollectionsListView: UIView!
    var modalVisible = false
    var collectionsListView: CollectionsTableViewController?

    // Cropview stuff
    @IBOutlet weak var superCropView: UIView!
    @IBOutlet weak var cropView: UIView!
    var cropViewStart: CGPoint!
    var cropViewEnd: CGPoint!
    var cropViewLeftConstraint: NSLayoutConstraint!
    var cropViewRightConstraint: NSLayoutConstraint!
    var cropViewTopConstraint: NSLayoutConstraint!
    var cropViewBottomConstraint: NSLayoutConstraint!
    var cropViewWidthConstraint: NSLayoutConstraint!
    var cropViewHeightConstraint: NSLayoutConstraint!
    var cropViewCenterXConstraint: NSLayoutConstraint!
    var cropViewCenterYConstraint: NSLayoutConstraint!
    var tapSnapLocation: CGPoint!

    // Phrase selection
    var boundingPolygons: [[String: Any]] = []
    var selectingPhrase = false
    var baseSnappedImageWidth: CGFloat!
    var baseSnappedImageHeight: CGFloat!
    var snappedImage: UIImageView!
    var startedMovePanAt: CGPoint!
    var endedMovePanAt: CGPoint!
    var baseCropViewCenter: CGPoint!
    var panPath: UIBezierPath!
    var panPathShape: CAShapeLayer!
    var avgWordHeight = CGFloat(10)
    var phraseSelectionButtonsContainer: UIView!
    var cancelSelectionButton: UIButton!
    var doneWithSelectionButton: UIButton!

    // Video instance variables
    var captureSession: AVCaptureSession?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var capturePhotoOutput: AVCapturePhotoOutput?
    var lastZoomValue = CGFloat(1)
    
    // Contraints used in animations
    var definitionViewHeightConstraint: NSLayoutConstraint?
    var definitionViewTopConstraint: NSLayoutConstraint?
    
    // Message containers
    @IBOutlet weak var upperMessageContainer: UIView!
    var upperMessageVC: MessageViewController!
    var upperMessageWidthConstraint: NSLayoutConstraint!
    var upperMessageHeightConstraint: NSLayoutConstraint!

    // Miscellaneous
    var studyVC: StudyViewController?
    var keyboardOpen = false
    var iCloudUserID: String?
    var searchRetries = 0
    var ocrRetries = 0
    var tutorial: Tutorial?
    var cameraInitialized = false
    var cameraOn = false
    var backgroundGradient: UIView!
    var initTutorialAlreadyCalled = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // The order of these initialization functions is important
        initCredentials()
        initTopBar()
        prepCameraView()
        if hasCameraPermission() {
            finishInitializingCameraView()
        }
        initDefinitionView()
        initCropViewAndPhraseSelection()
        initModalView()
        initMessageContainers()
        initNotifications()
        
        // Miscellaneous
        studyVC = tabBarController?.viewControllers?[TabBarViewController.StudyTabTagAndIndex] as? StudyViewController
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func willEnterForeground() {
        print("Search view controller coming back into foreground")

        // We want to reset retries to 0 when there is a user action (foregrounding the app, in this case)
        searchRetries = 0
        ocrRetries = 0
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // We want to reset retries to 0 when there is a user action (swiping to the translate view, in this case)
        searchRetries = 0
        ocrRetries = 0
        
        initTutorial()
    }
    
    // Get reference to some sub view controllers
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let id = segue.identifier else {
            return
        }
        if id == "definitionViewSegue", let pvc = segue.destination as? DefinitionPageViewController {
            pageViewController = pvc
            pageViewController?.expandDefinitionViewFunc = expandDefinitionView
            pageViewController?.contractDefinitionViewFunc = contractDefinitionView
            pageViewController?.manualEntryUpdateFunc = updateManualEntryField
            pageViewController?.definitionVCDelegate = self
            pageViewController?.definitionVCDelegate = self
            pageViewController?.definitionPVCDelegate = self
        }
        if id == "addFlashcardSegue", let fc = segue.destination as? CustomNavigationController {
            fc.collectionsTableDelegate = self
        }
        if id == "upperMessageSegue", let umvc = segue.destination as? MessageViewController {
            upperMessageVC = umvc
            upperMessageVC.maxWidth = previewView.frame.width - 2 * ViewController.UpperMessageMinLeftRightMargin - 2 * ViewController.UpperMessageLeftRightPadding
            upperMessageVC.labelPadding = ViewController.UpperMessageLeftRightPadding
        }
    }
}

// MARK: - set up subview constraints and perform other initializations
extension ViewController {
    
    // MARK: Get user's hashed iCloud username, which is the same across all his devices for this app. It's a sign-in proxy for us that we use to track # of searches
    func initCredentials() {
        iCloudUserIDAsync { (recordID: CKRecordID?, error: NSError?) in
            if let userID = recordID?.recordName {
                print("Received iCloudID \(userID)")
                self.iCloudUserID = userID
            } else {
                print("Fetched iCloudID was nil")
            }
        }
    }
    
    func iCloudUserIDAsync(complete: @escaping (_ instance: CKRecordID?, _ error: NSError?) -> ()) {
        let container = CKContainer.default()
        container.fetchUserRecordID() {
            recordID, error in
            if error != nil {
                print(error!.localizedDescription)
                complete(nil, error as NSError?)
            } else {
                complete(recordID, nil)
            }
        }
    }
    
    // MARK: Set constraints and basic properties of camera view but don't fully access it
    func prepCameraView() {
        
        previewView.snuglyConstrain(to: parentView)
        snapView.snuglyConstrain(to: parentView)
        previewView.layer.backgroundColor = UIColor.clear.cgColor
        snapView.isHidden = true
        snapView.contentMode = UIViewContentMode.scaleAspectFit
        
        // Background gradient view
        backgroundGradient = UIView()
        backgroundGradient.backgroundColor = UIColor.clear
        parentView.addSubview(backgroundGradient)
        backgroundGradient.snuglyConstrain(to: parentView)
        parentView.sendSubview(toBack: backgroundGradient)
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = view.bounds
        gradientLayer.colors = [
            Constants.BackgroundGradientStartColor.cgColor,
            Constants.BackgroundGradientEndColor.cgColor
        ]
        backgroundGradient.layer.addSublayer(gradientLayer)
    }
    
    func hasCameraPermission() -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
        case .authorized:
            return true
        default:
            return false
        }
    }
    
    func startCamera(forceContract: Bool) {
        let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)

        switch status {
        case .authorized:
            finishInitializingCameraView(forceContract: forceContract)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: AVMediaType.video) { granted in
                if granted {
                    self.finishInitializingCameraView(forceContract: forceContract)
                }
                else {
                    self.cameraOn = false
                    DispatchQueue.main.async {
                        if let tutorial = self.tutorial {
                            tutorial.pause()
                        }
                        self.cameraButton.tintColor = ViewController.DefaultTopBarButtonColor
                        self.expandDefinitionView()
                        self.fadeUpperMessageIn(with: ViewController.JustDeniedCameraAccessMessageString)
                    }
                }
            }
        case .denied:
            handleCameraPermissionDenial()
            cameraOn = false
            cameraButton.tintColor = ViewController.DefaultTopBarButtonColor
            
            DispatchQueue.main.async {
                if !forceContract {
                    self.expandDefinitionView()
                }
            }
        case .restricted:
            cameraOn = false
            cameraButton.tintColor = ViewController.DefaultTopBarButtonColor
            DispatchQueue.main.async {
                if !forceContract {
                    self.expandDefinitionView()
                }
                self.fadeUpperMessageIn(with: ViewController.RestrictedAccessMessageString)
            }
        }
    }
    
    func handleCameraPermissionDenial() {
        DispatchQueue.main.async {
            
            // Set default values for alert text and action button text
            var alertText = ViewController.CameraPermissionDenialLongActionPromptString
            var alertButtonActionString = ViewController.OKButtonString
            var goAction = UIAlertAction(title: alertButtonActionString, style: .default, handler: nil)
            var cancelAction: UIAlertAction? = UIAlertAction(title: "Cancel", style: .cancel) { (action: UIAlertAction!) in
                print("Cancel button tapped");
            }
            
            // If this iOS version can jump straight to settings, great! Choose appropriate alert and action button copy. Also keep the cancel action
            if UIApplication.shared.canOpenURL(URL(string: UIApplicationOpenSettingsURLString)!) {
                alertText = ViewController.CameraPermissionDenialShortActionPromptString
                alertButtonActionString = ViewController.GoToSettingsButtonString
                goAction = UIAlertAction(title: alertButtonActionString, style: .default, handler: { (alert: UIAlertAction!) -> Void in
                    UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!, options: [:], completionHandler: nil)
                    // If user grants permission and navigates back, SIGKILL is sent to app. If doesn't grant, nothing changes. So don't need completion handler here to e.g. set tint color of button, set cameraOn to true, or contract definition view
                })
            } else {  // if we can't jump straight to settings, keep the default "long action" values for alert text and action button text. Do not add cancel button
                cancelAction = nil
            }
            
            // Create alert
            let alert = UIAlertController(title: ViewController.CameraPermissionDenialAlertTitleString, message: alertText, preferredStyle: .alert)
            alert.addAction(goAction)
            if let cancelAction = cancelAction {
                alert.addAction(cancelAction)
            }
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    // MARK: Finish setting up the camera view. This will trigger system camera permissions request
    func finishInitializingCameraView(forceContract: Bool = false) {
        
        // Set up video preview
        let captureDevice = AVCaptureDevice.default(for: .video)
        if captureDevice != nil {
            DispatchQueue.main.async {
                do {
                    let input = try AVCaptureDeviceInput(device: captureDevice!)
                    self.captureSession = AVCaptureSession()
                    self.captureSession?.addInput(input)
                    self.videoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession!)
                    self.videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
                    self.videoPreviewLayer?.frame = self.view.layer.bounds
                    self.previewView.layer.addSublayer(self.videoPreviewLayer!)
                    self.captureSession?.startRunning()
                    self.capturePhotoOutput = AVCapturePhotoOutput()
                    self.capturePhotoOutput?.isHighResolutionCaptureEnabled = true
                    self.captureSession?.addOutput(self.capturePhotoOutput!)
                    
                    // Make sure subviews z-indices are in correct order
                    self.previewView.bringSubview(toFront: self.superTopBarView)
                    self.previewView.bringSubview(toFront: self.manualEntryView)
                    self.previewView.bringSubview(toFront: self.definitionView)
                    self.previewView.bringSubview(toFront: self.superCropView)
                    self.previewView.bringSubview(toFront: self.superModalView)
                    self.previewView.bringSubview(toFront: self.upperMessageContainer)
                    
                    // Miscellaneous initialization
                    self.cameraInitialized = true
                    self.cameraOn = true
                    self.cameraButton.tintColor = ViewController.PressedTopBarButtonColor
                    if forceContract {
                        self.contractDefinitionView()
                    }
                    if let tutorial = self.tutorial {
                        _ = tutorial.completed(action: .cameraEnabled)
                    }
                } catch {
                    print(error)
                }
            }
        } else {
            print("Camera permission not granted. Will ask again next time camera is toggled")
        }
    }
    
    func initTopBar() {
        
        initManualEntryBar()

        // Blurred top bar (stick it at the very top of the screen)
        (_, _) = superTopBarView.snuglyConstrain(to: previewView, leftAmount: 0, rightAmount: 0)
        let tbtc = NSLayoutConstraint(item: superTopBarView, attribute: .top, relatedBy: .equal, toItem: previewView, attribute: .top, multiplier: 1, constant: 0)
        let tbbc = NSLayoutConstraint(item: superTopBarView, attribute: .bottom, relatedBy: .equal, toItem: manualEntryView, attribute: .bottom, multiplier: 1, constant: 0)
        superTopBarView.translatesAutoresizingMaskIntoConstraints = false
        previewView.addConstraints([tbtc, tbbc])
        
        // Its nested view
        topBarView.snuglyConstrain(to: superTopBarView)
        topBarView.backgroundColor = UIColor.clear
        
        // Z indices
        previewView.bringSubview(toFront: superTopBarView)
        previewView.bringSubview(toFront: manualEntryView)
    }
    
    func initManualEntryBar() {
        
        // Manual entry bar container view
        manualEntryView.backgroundColor = UIColor.clear
        manualEntryView.translatesAutoresizingMaskIntoConstraints = false
        let guide = previewView.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            manualEntryView.topAnchor.constraint(equalTo: guide.topAnchor, constant: Constants.ManualEntryTopMargin),
            manualEntryView.heightAnchor.constraint(equalToConstant: Constants.ManualEntryHeight),
            manualEntryView.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: Constants.ManualEntryLeftMargin),
            manualEntryView.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: Constants.ManualEntryRightMargin)
        ])
        
        initButtons()
        
        // Manual entry text field
        manualEntryTextField.padding = UIEdgeInsets(top: 0, left: Constants.ManualEntryTextFieldLeftPadding, bottom: 0, right: Constants.ManualEntryTextFieldRightPadding)
        manualEntryTextField.layer.cornerRadius = Constants.CornerRadius
        manualEntryTextField.backgroundColor = Constants.ManualEntryTextFieldTextColor
        manualEntryTextField.text = Constants.DefaultWord
        manualEntryTextField.placeholder = ViewController.ManualEntryDefaultPlaceholder
        manualEntryTextField.returnKeyType = .search
        manualEntryTextField.clearButtonMode = .whileEditing
        (_, _) = manualEntryTextField.snuglyConstrain(to: manualEntryView, toLeft: manualEntryView, toRight: saveButton, leftAmount: Constants.ManualEntryTextFieldLeftMargin, rightAmount: Constants.TopbarButtonSpacing - 2)
        (_, _) = manualEntryTextField.snuglyConstrain(to: manualEntryView, topAmount: Constants.ManualEntryTextFieldTopMargin, bottomAmount: Constants.ManualEntryTextFieldBottomMargin)
    }
    
    func initButtons() {
        
        // Toggle camera button
        cameraButton.initPictureButton(in: manualEntryView, imageName: "cameraThin", withColor: Constants.TabBarButtonInactiveColor, width: Constants.ManualEntryTextFieldHeight, height: Constants.ManualEntryTextFieldHeight)
        let crc = NSLayoutConstraint(item: cameraButton, attribute: .right, relatedBy: .equal, toItem: manualEntryView, attribute: .right, multiplier: 1, constant: ViewController.CameraButtonRightMargin)
        let ccyc = NSLayoutConstraint(item: cameraButton, attribute: .centerY, relatedBy: .equal, toItem: manualEntryTextField, attribute: .centerY, multiplier: 1, constant: -0.5)
        cameraButton.translatesAutoresizingMaskIntoConstraints = false
        manualEntryView.addConstraints([crc, ccyc])
        
        // Toggle flashlight button
        flashlightButton.initPictureButton(in: manualEntryView, imageName: "lightbulb", withColor: Constants.TabBarButtonInactiveColor, width: Constants.ManualEntryTextFieldHeight, height: Constants.ManualEntryTextFieldHeight)
        let tfrc = NSLayoutConstraint(item: flashlightButton, attribute: .right, relatedBy: .equal, toItem: cameraButton, attribute: .left, multiplier: 1, constant: -Constants.TopbarButtonSpacing + 5.125)
        let tfyc = NSLayoutConstraint(item: flashlightButton, attribute: .centerY, relatedBy: .equal, toItem: manualEntryTextField, attribute: .centerY, multiplier: 1, constant: -0.625)
        flashlightButton.translatesAutoresizingMaskIntoConstraints = false
        manualEntryView.addConstraints([tfrc, tfyc])
        
        // Handle constraints for the save flashcard button
        saveButton.initPictureButton(in: manualEntryView, imageName: "bookmark", withColor: Constants.TabBarButtonInactiveColor, width: Constants.ManualEntryTextFieldHeight, height: Constants.ManualEntryTextFieldHeight)
        let sbrc = NSLayoutConstraint(item: saveButton, attribute: .right, relatedBy: .equal, toItem: flashlightButton, attribute: .left, multiplier: 1, constant: -Constants.TopbarButtonSpacing + 9)
        let sbyc = NSLayoutConstraint(item: saveButton, attribute: .centerY, relatedBy: .equal, toItem: manualEntryTextField, attribute: .centerY, multiplier: 1, constant: 0)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        manualEntryView.addConstraints([sbrc, sbyc])
    }
    
    func initDefinitionView() {
        
        previewView.bringSubview(toFront: definitionView)
        (_, _) = definitionView.snuglyConstrain(to: previewView, leftAmount: Constants.LeftRightMarginDefViewSpacing, rightAmount: Constants.LeftRightMarginDefViewSpacing)
        let bottomConstraint = NSLayoutConstraint(item: definitionView, attribute: .bottomMargin, relatedBy: .equal, toItem: previewView, attribute: .bottomMargin, multiplier: 1.0, constant: 0)
        let defViewWidth = UIScreen.main.bounds.width - 2 * Constants.LeftRightMarginDefViewSpacing
        let defViewHeight = defViewWidth / Constants.GoldenRatio + Constants.PageFooterHeight
        
        // Store constaints that are toggled later for expansion/contraction of definition view
        definitionViewTopConstraint = NSLayoutConstraint(item: definitionView, attribute: .top, relatedBy: .equal, toItem: topBarView, attribute: .bottom, multiplier: 1.0, constant: Constants.DefViewTopMargin)
        definitionViewHeightConstraint = NSLayoutConstraint(item: definitionView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: defViewHeight)
        
        // If tutorial is off and no camera permission given, start in expanded view state
        definitionView.translatesAutoresizingMaskIntoConstraints = false
        previewView.addConstraints([bottomConstraint])
        if !hasCameraPermission() && !shouldResumeTutorial() {
            previewView.addConstraints([definitionViewTopConstraint!])
            expanded = true
            pageViewController?.expanded = true
        } else {  // otherwise start in the default contracted state
            previewView.addConstraints([definitionViewHeightConstraint!])
            expanded = false
            pageViewController?.expanded = false
        }

        previewView.setNeedsLayout()
        previewView.layoutIfNeeded()
    }
    
    func initCropViewAndPhraseSelection() {

        // Make the container crop view invisible but span from definition box to manual entry
        previewView.bringSubview(toFront: superCropView)
        (_, _) = superCropView.snuglyConstrain(to: previewView, toTop: topBarView, toBottom: definitionView, topAmount: ViewController.SuperCropViewTopMargin, bottomAmount: ViewController.SuperCropViewBottomMargin)
        (_, _) = superCropView.snuglyConstrain(to: previewView, leftAmount: ViewController.SuperCropViewLeftRightMargin, rightAmount: ViewController.SuperCropViewLeftRightMargin)
        previewView.setNeedsLayout()
        previewView.layoutIfNeeded()
        superCropView.backgroundColor = UIColor(white: 1, alpha: 0)
        
        // Handle constraints for the crop view nested in the spacing container view. The constraints constants used here are unimportant because the cropview is hidden
        cropView.backgroundColor = UIColor(white: 1, alpha: 0.5)
        cropView.layer.cornerRadius = Constants.CornerRadius
        cropView.clipsToBounds = true
        cropView.isHidden = true
        cropView.addBorder(ofColor: ViewController.CropboxBorderColor)
        cropView.backgroundColor = ViewController.CropboxInteriorColor
        (cropViewLeftConstraint, cropViewRightConstraint) = cropView.snuglyConstrain(to: superCropView, leftAmount: 0, rightAmount: 0)
        (cropViewTopConstraint, cropViewBottomConstraint) = cropView.snuglyConstrain(to: superCropView, topAmount: 0, bottomAmount: 0)
        superCropView.removeConstraints([cropViewLeftConstraint, cropViewRightConstraint, cropViewTopConstraint, cropViewBottomConstraint])
        (cropViewWidthConstraint, cropViewHeightConstraint) = cropView.dimensionContraints(to: superCropView, width: 0, height: 0)
        cropViewCenterXConstraint = NSLayoutConstraint(item: cropView, attribute: .centerX, relatedBy: .equal, toItem: superCropView, attribute: .centerX, multiplier: 1, constant: 0)
        cropViewCenterYConstraint = NSLayoutConstraint(item: cropView, attribute: .centerY, relatedBy: .equal, toItem: superCropView, attribute: .centerY, multiplier: 1, constant: 0)
        superCropView.setNeedsLayout()
        superCropView.layoutIfNeeded()
        
        // Activity view, which is in middle of crop-able area
        middleActivityView.activityIndicatorViewStyle = .whiteLarge
        middleActivityView.color = ViewController.MiddleActivityIndicatorColor
        middleActivityView.centerView(to: superCropView)
        middleActivityView.isHidden = true
        superCropView.bringSubview(toFront: middleActivityView)

        // Make sure snap won't cover other stuff when it's dragged
        previewView.bringSubview(toFront: definitionView)
        previewView.bringSubview(toFront: superTopBarView)
        previewView.bringSubview(toFront: manualEntryView)
        
        // Phrase selection button container
        phraseSelectionButtonsContainer = UIView()
        superCropView.addSubview(phraseSelectionButtonsContainer)
        phraseSelectionButtonsContainer.backgroundColor = UIColor.clear
        (_, _) = phraseSelectionButtonsContainer.snuglyConstrain(to: superCropView, leftAmount: ViewController.PhraseSelectionButtonContainerLeftRightMargin, rightAmount: ViewController.PhraseSelectionButtonContainerLeftRightMargin)
        let psbctc = NSLayoutConstraint(item: phraseSelectionButtonsContainer, attribute: .top, relatedBy: .equal, toItem: superCropView, attribute: .top, multiplier: 1, constant: ViewController.PhraseSelectionButtonContainerTopMargin)
        let psbchc = NSLayoutConstraint(item: phraseSelectionButtonsContainer, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: ViewController.PhraseSelectionButtonContainerHeight)
        phraseSelectionButtonsContainer.translatesAutoresizingMaskIntoConstraints = false
        superCropView.addConstraints([psbctc, psbchc])
        
        // Cancel selection button
        cancelSelectionButton = UIButton()
        cancelSelectionButton.isHidden = true
        phraseSelectionButtonsContainer.addSubview(cancelSelectionButton)
        cancelSelectionButton.initPictureButton(in: phraseSelectionButtonsContainer, imageName: "bigTimes", withColor: ViewController.PhraseSelectionButtonColor, width: Constants.CancelXButtonSize, height: Constants.CancelXButtonSize)
        cancelSelectionButton.addTarget(self, action: #selector(handleCancelSelectionButton), for: .primaryActionTriggered)
        cancelSelectionButton.tintColor = ViewController.PhraseSelectionButtonColor
        let tablc = NSLayoutConstraint(item: cancelSelectionButton, attribute: .left, relatedBy: .equal, toItem: phraseSelectionButtonsContainer, attribute: .left, multiplier: 1, constant: ViewController.PhraseSelectionButtonLeftMargin)
        let tabcyc = NSLayoutConstraint(item: cancelSelectionButton, attribute: .centerY, relatedBy: .equal, toItem: phraseSelectionButtonsContainer, attribute: .centerY, multiplier: 1, constant: 0)
        cancelSelectionButton.translatesAutoresizingMaskIntoConstraints = false
        phraseSelectionButtonsContainer.addConstraints([tablc, tabcyc])
        
        // Done button
        doneWithSelectionButton = UIButton(type: .system)  // system needed for tint
        doneWithSelectionButton.isHidden = true
        phraseSelectionButtonsContainer.addSubview(doneWithSelectionButton)
        doneWithSelectionButton.addTarget(self, action: #selector(handleDoneWithSelectionButton), for: .primaryActionTriggered)
        doneWithSelectionButton.setTitle(ViewController.PhraseSelectionDoneButtonString, for: .normal)
        doneWithSelectionButton.titleLabel?.font = ViewController.PhraseSelectionButtonFont
        doneWithSelectionButton.tintColor = ViewController.PhraseSelectionButtonColor
        let dwsbrc = NSLayoutConstraint(item: doneWithSelectionButton, attribute: .right, relatedBy: .equal, toItem: phraseSelectionButtonsContainer, attribute: .right, multiplier: 1, constant: ViewController.PhraseSelectionButtonRightMargin)
        let dwsbcyc = NSLayoutConstraint(item: doneWithSelectionButton, attribute: .centerY, relatedBy: .equal, toItem: phraseSelectionButtonsContainer, attribute: .centerY, multiplier: 1, constant: 0)
        doneWithSelectionButton.translatesAutoresizingMaskIntoConstraints = false
        phraseSelectionButtonsContainer.addConstraints([dwsbrc, dwsbcyc])
    }
    
    func initModalView() {

        // Handle modal container constraints
        previewView.bringSubview(toFront: superModalView)
        superModalView.isHidden = true
        (_, _) = superModalView.snuglyConstrain(to: previewView, leftAmount: Constants.LeftRightMarginDefViewSpacing, rightAmount: Constants.LeftRightMarginDefViewSpacing)
        (_, _) = superModalView.snuglyConstrain(to: previewView, toTop: topBarView, toBottom: definitionView, topAmount: ViewController.TopMarginModal, bottomAmount: ViewController.BottomMarginModal)
        superModalView.layer.cornerRadius = Constants.CornerRadius
        superModalView.clipsToBounds = true
        previewView.setNeedsLayout()
        previewView.layoutIfNeeded()
        
        // Handle constraints for the modal nested in the container view
        modalView.snuglyConstrain(to: superModalView)
        modalView.backgroundColor = UIColor(white: 1, alpha: 0)
        modalView.clipsToBounds = true
        
        // Handle constraints for collections table view controller
        superCollectionsListView.snuglyConstrain(to: modalView)
        superCollectionsListView.backgroundColor = UIColor.clear
    }
    
    func initMessageContainers() {

        // Upper message container
        upperMessageContainer.backgroundColor = UIColor.clear
        upperMessageContainer.clipsToBounds = true
        upperMessageContainer.layer.cornerRadius = Constants.CornerRadius
        (upperMessageWidthConstraint, upperMessageHeightConstraint) = upperMessageContainer.dimensionContraints(to: previewView, width: 0, height: 0)  // will be reset in fadeUpperMessageIn()
        let umctc = NSLayoutConstraint(item: upperMessageContainer, attribute: .top, relatedBy: .equal, toItem: topBarView, attribute: .bottom, multiplier: 1, constant: ViewController.MessageTopBottomMargin)
        let umccxc = NSLayoutConstraint(item: upperMessageContainer, attribute: .centerX, relatedBy: .equal, toItem: previewView, attribute: .centerX, multiplier: 1, constant: 0)
        upperMessageContainer.translatesAutoresizingMaskIntoConstraints = false
        previewView.addConstraints([umctc, umccxc])
        upperMessageContainer.isHidden = true
        previewView.bringSubview(toFront: upperMessageContainer)
    }
    
    // MARK: Change contraints to give the definition view an "expanding" animation
    func expandDefinitionView() {
        
        // Don't allow expansions if the save to flashcard modal is visible or if selecting phrase
        if modalVisible || selectingPhrase {
            return
        }
        
        definitionViewTopConstraint!.constant = getDefinitionViewTopConstraintConstantBasedOnVisibleMessages()
        
        if let tutorial = tutorial {
            _ = tutorial.completed(action: .swipeUpToExpand)
        }

        // Set expanded to true in page view controller and all its pages
        expanded = true
        pageViewController?.expanded = true
        
        // Handle view constraints
        previewView.removeConstraint(definitionViewHeightConstraint!)
        previewView.addConstraint(definitionViewTopConstraint!)

        UIView.animate(withDuration: ViewController.DefinitionExpansionAnimationDuration, animations: {
            self.previewView.layoutIfNeeded()
        })
    }
    
    // MARK: Change contraints to give the definition view a "contracting" animation
    func contractDefinitionView() {
        
        // Set expanded to false in page view controller and all its pages
        expanded = false
        pageViewController?.expanded = false
        
        // Handle view constraints
        previewView.removeConstraint(definitionViewTopConstraint!)
        previewView.addConstraint(definitionViewHeightConstraint!)

        UIView.animate(withDuration: ViewController.DefinitionExpansionAnimationDuration, animations: {
            self.previewView.layoutIfNeeded()
        })
    }
    
    func initNotifications() {
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardNotification(notification:)), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: .UIApplicationWillEnterForeground, object: nil)
    }
    
    // MARK: start tutorial if either (1) first launch or (2) tutorial interrupted by turning off camera, leaving app, or denying camera permission
    func shouldResumeTutorial() -> Bool {
        return !FlashcardCollections.IsDoneWithTutorial()
    }
    
    func initTutorial() {
        if !initTutorialAlreadyCalled && shouldResumeTutorial() {
            tutorial = Tutorial()
            tutorial?.delegate = self
            tutorial?.resume()
            initTutorialAlreadyCalled = true
        }
    }
}

// MARK: - Capture photos and do OCR
extension ViewController : AVCapturePhotoCaptureDelegate {

    private func cgPoint(from pt: [String: Int], scaledBy factor: CGFloat) -> CGPoint {
        let x = CGFloat(pt["x"] ?? 0) * factor
        let y = CGFloat(pt["y"] ?? 0) * factor
        return CGPoint(x: x, y: y)
    }
    
    private func startSelectingPhraseMode() {
        
        videoPreviewLayer?.isHidden = true
        cropView.addBorder(ofColor: UIColor.clear)
        superCropView.isHidden = false
        cropView.isHidden = false
        selectingPhrase = true
        // lastZoomValue set in show(img:)
        boundingPolygons = []
    }
    
    private func stopSelectingPhraseMode() {
        
        // Get the cropView ready for cropping again instead of showing a crop-snap
        cropView.isHidden = true
        cropView.addBorder(ofColor: ViewController.CropboxBorderColor)
        superCropView.removeConstraints([cropViewWidthConstraint, cropViewHeightConstraint, cropViewCenterXConstraint, cropViewCenterYConstraint])
        superCropView.addConstraints([cropViewLeftConstraint, cropViewRightConstraint, cropViewTopConstraint, cropViewBottomConstraint])
        
        // Remove bounding polygons from cropView
        for wordObj in boundingPolygons {
            if let shape = wordObj["shape"] as? CAShapeLayer {
                shape.removeFromSuperlayer()
            }
        }
        boundingPolygons = []
        
        // Remove crop-snap from cropView
        snappedImage.removeFromSuperview()
        snappedImage = nil
        
        // Return the video feed to normal zoom
        lastZoomValue = CGFloat(1)
        zoomVideo(zoomValue: lastZoomValue)
        
        // Reset miscellaneous variables
        videoPreviewLayer?.isHidden = false
        selectingPhrase = false
        boundingPolygons = []
        baseSnappedImageWidth = nil
        baseSnappedImageHeight = nil
        avgWordHeight = CGFloat(10)  // just a reasonable default value
        cancelSelectionButton.isHidden = true
        doneWithSelectionButton.isHidden = true
    }
    
    // MARK: Returns path connecting given vertices and minimum edge length
    private func bezierFrom(vertices: [[String: Int]], scaledBy scaleFactor: CGFloat) -> (UIBezierPath, CGFloat) {
        var minEdgeLength = CGFloat.greatestFiniteMagnitude
        let bezier = UIBezierPath()
        bezier.move(to: cgPoint(from: vertices[0], scaledBy: scaleFactor))
        for i in 1..<vertices.count {
            let prevVertex = cgPoint(from: vertices[i - 1], scaledBy: scaleFactor)
            let currVertex = cgPoint(from: vertices[i], scaledBy: scaleFactor)
            let lineLength = sqrt(pow(currVertex.x - prevVertex.x, 2) + pow(currVertex.y - prevVertex.y, 2))
            if lineLength < minEdgeLength {
                minEdgeLength = lineLength
            }
            
            bezier.addLine(to: currVertex)
        }
        bezier.close()
        return (bezier, minEdgeLength)
    }
    
    func recognizeWords(fromShared img: UIImage) {
        
        if isExpanded() {
            contractDefinitionView()
        }
        
        let maxHeight = superCropView.frame.height - ViewController.SnapMinTopMargin - ViewController.SnapMinBottomMargin
        let maxWidth = superCropView.frame.width - 2 * ViewController.SnapMinLeftRightMargin

        let imgWidth = CGFloat(img.cgImage!.width)
        let imgHeight = CGFloat(img.cgImage!.height)
        var widthToUse: CGFloat?
        var heightToUse: CGFloat?
        
        if imgHeight > imgWidth {
            heightToUse = maxHeight
            widthToUse = heightToUse! * (imgWidth / imgHeight)
        } else {
            widthToUse = maxWidth
            heightToUse = widthToUse! * (imgHeight / imgWidth)
        }

        superCropView.removeConstraints([cropViewWidthConstraint, cropViewHeightConstraint, cropViewCenterXConstraint, cropViewCenterYConstraint, cropViewLeftConstraint, cropViewRightConstraint, cropViewTopConstraint, cropViewBottomConstraint])
        superCropView.addConstraints([cropViewWidthConstraint, cropViewHeightConstraint, cropViewCenterXConstraint, cropViewCenterYConstraint])
        cropViewCenterXConstraint.constant = CGFloat(0)
        cropViewCenterYConstraint.constant = (ViewController.SnapMinTopMargin - ViewController.SnapMinBottomMargin) / 2
        cropViewHeightConstraint.constant = heightToUse!
        cropViewWidthConstraint.constant = widthToUse!
        lastZoomValue = CGFloat(1)
        
        let upright = img.imageOrientation == .up || img.imageOrientation == .down || img.imageOrientation == .upMirrored || img.imageOrientation == .downMirrored
        
        recognizeWords(from: img, rotated: !upright)
    }
    
    private func processOcrResponse(jsonArray: [[String: Any]], rotated: Bool, cgImage: CGImage, img: UIImage) {

        guard jsonArray.count > 0 else {
            print("No words in multi-OCR response")
            self.fadeUpperMessageIn(with: ViewController.TryAgainString)
            return
        }
        
        var atLeastOneWorked = false
        self.startSelectingPhraseMode()
        let scaleFactor =  (rotated ? CGFloat(self.cropView.frame.width) : CGFloat(self.cropView.frame.height)) / CGFloat(cgImage.height)
        var sumWordHeights = CGFloat(0)
        var numWords = CGFloat(0)
        for wordResp in jsonArray {
            if let word: String = Utilities.GetProp(named: "description", from: wordResp), let boundingPoly: [String: Any] = Utilities.GetProp(named: "boundingPoly", from: wordResp), let vertices: [[String: Int]] = Utilities.GetProp(named: "vertices", from: boundingPoly), vertices.count > 0 {
                
                atLeastOneWorked = true
                let (bezier, wordHeight) = self.bezierFrom(vertices: vertices, scaledBy: scaleFactor)
                sumWordHeights += wordHeight
                numWords += 1
                
                var currWordObj = [String: Any]()
                currWordObj["word"] = word
                
                // Generate a shape for the current bounding polygon. Add it to cropView
                let shape = CAShapeLayer()
                shape.lineWidth = ViewController.BoundedWordBorderWidth
                shape.lineJoin = kCALineJoinRound
                shape.strokeColor = ViewController.BoundedWordBorderColor
                shape.fillColor = ViewController.BoundedWordInteriorColorNotChosen
                shape.path = bezier.cgPath
                currWordObj["shape"] = shape
                currWordObj["vertices"] = vertices
                currWordObj["chosen"] = false
                currWordObj["pxToPtScaleFactor"] = scaleFactor
                self.boundingPolygons.append(currWordObj)
            }
        }
        
        guard atLeastOneWorked else {
            print("No words found")
            self.fadeUpperMessageIn(with: ViewController.TryAgainString)
            print("None of the words had bounding polygons and text")
            return
        }
        
        self.avgWordHeight = sumWordHeights / numWords
        self.show(img: img)
    }
    
    func recognizeWordsAux(from img: UIImage, rotated: Bool, cgImage: CGImage, orientedImg: UIImage, dcData: Data?, t: String?) {

        // Get URL ready
        let paths = [Constants.AwsApiBaseURL, Constants.AwsApiStage, ViewController.OcrPathMulti].filter { str in
            return str != ""
        }
        let url = URL(string: paths.joined(separator: "/"))!
        
        // Get request ready
        let sesh = URLSession(configuration: .default)
        var req = URLRequest(url: url)
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpMethod = "POST"
        let imgBase64 = UIImageJPEGRepresentation(orientedImg, ViewController.JpegQuality)?.base64EncodedString()
        var jsonObj: [String: Any] = [
            "image": imgBase64 ?? "null",
            "iCloudUserNameHash": self.iCloudUserID ?? ""
        ]
        if let dcData = dcData {
            jsonObj["deviceCheckToken"] = dcData.base64EncodedString()
        }
        if let t = t {
            jsonObj["t"] = t
        }
        let data = try! JSONSerialization.data(withJSONObject: jsonObj, options: [])
        req.httpBody = data
        
        // Call the OCR endpoint
        self.middleActivityView.isHidden = false
        self.middleActivityView.startAnimating()
        print("Calling OCR endpoint at", req.url ?? "NIL", "for iCloud user", self.iCloudUserID ?? "")
        _ = sesh.dataTask(with: req, completionHandler: { (data, response, error) in
            
            DispatchQueue.main.async {
                if let _ = response, let data = data, let jsonData = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers), let jsonDictionary = jsonData as? [String: Any], let ocrSuccess: Bool = Utilities.GetProp(named: "ocrSuccess", from: jsonDictionary) {
                    
                    // OCR was successful and we got a results array!
                    if ocrSuccess, let jsonArray: [[String: Any]] = Utilities.GetProp(named: "results", from: jsonDictionary) {
                        if let t: String = Utilities.GetProp(named: "t", from: jsonDictionary) {
                            FlashcardCollections.EatT(t: t)
                        }
                        self.processOcrResponse(jsonArray: jsonArray, rotated: rotated, cgImage: cgImage, img: img)
                    } else if !ocrSuccess, let failureReason: [String: Any] = Utilities.GetProp(named: "failureReason", from: jsonDictionary) {
                        // OCR failed but at least we got a failure reason
                        print("Failed to complete OCR. Showing reason", failureReason)
                        self.handleMeteredApiFailure(because: failureReason, usageType: .scan)
                    } else {  // Didn't get enough info from response
                        print("Missing results or failureReason")
                        self.handleMeteredApiFailure(because: ["reason": ViewController.UnknownFailureCode], usageType: .scan)
                    }
                    self.middleActivityView.isHidden = true
                    self.middleActivityView.stopAnimating()
                } else {
                    print("Error:", error ?? "")
                    if let data = data {
                        print(NSString.init(data: data, encoding: String.Encoding.utf8.rawValue) ?? "")
                    }
                    self.cleanupAfterFailedOcrRpc(img: img, rotated: rotated)
                }
            }
        }).resume()
    }
    
    func recognizeWords(from img: UIImage, rotated: Bool = true) {
        
        guard let cgImage = img.cgImage, let orientedImg = img.correctlyOrientedImage() else {
            print("Error: unable to get/orient image before recognizing words")
            return
        }
        
        if let t = FlashcardCollections.DatT() {
            self.recognizeWordsAux(from: img, rotated: rotated, cgImage: cgImage, orientedImg: orientedImg, dcData: nil, t: t)
        } else if Constants.CurrDevice.isSupported {
            Constants.CurrDevice.generateToken { (dcData, error) in
                if let dcData = dcData {
                    DispatchQueue.main.sync {
                        self.recognizeWordsAux(from: img, rotated: rotated, cgImage: cgImage, orientedImg: orientedImg, dcData: dcData, t: nil)
                    }
                }
                if let error = error {
                    print("Error when generating a token:", error.localizedDescription)
                    self.handleMeteredApiFailure(because: ["reason": ViewController.CouldNotGenerateDCTokenCode], usageType: .scan)
                }
            }
        } else {
            print("Platform is not supported or you missing dat t")
            self.handleMeteredApiFailure(because: ["reason": ViewController.CouldNotGenerateDCTokenCode], usageType: .scan)
        }
    }
    
    private func drawImage(image: UIImage) -> UIImage {
        let imageSize = image.size
        let scale: CGFloat = 0
        UIGraphicsBeginImageContextWithOptions(imageSize, false, scale)
        image.draw(at: CGPoint(x: 0, y: 0))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
    
    // MARK: Show resized, fitted image
    private func showSnap(img: UIImage) {
        previewView.isHidden = true
        snapView.image = drawImage(image: img)
        snapView.isHidden = false
        Timer.scheduledTimer(withTimeInterval: ViewController.TimeToShowTestImage, repeats: false) { _ in
            self.snapView.isHidden = true
            self.previewView.isHidden = false
        }
    }
    
    // MARK: Show resized, fitted image
    private func show(img: UIImage) {

        snappedImage = UIImageView()
        snappedImage.image = img
        cropView.addSubview(snappedImage)
        snappedImage.snuglyConstrain(to: cropView)
        baseSnappedImageWidth = CGFloat(cropView.frame.width)
        baseSnappedImageHeight = CGFloat(cropView.frame.height)

        // Put the resulting image in the center of the screen
        cropViewCenterXConstraint.constant = CGFloat(0)
        cropViewCenterYConstraint.constant = (ViewController.SnapMinTopMargin - ViewController.SnapMinBottomMargin) / 2
        superCropView.removeConstraints([cropViewLeftConstraint, cropViewRightConstraint, cropViewTopConstraint, cropViewBottomConstraint])
        superCropView.addConstraints([cropViewWidthConstraint, cropViewHeightConstraint, cropViewCenterXConstraint, cropViewCenterYConstraint])
        
        // Compute zoom value needed to fit in screen w/o changing aspect ratio
        let maxWidth = superCropView.frame.width - 2 * ViewController.SnapMinLeftRightMargin
        let maxHeight = superCropView.frame.height - ViewController.SnapMinTopMargin - ViewController.SnapMinBottomMargin
        let zoomHorizontal = maxWidth / baseSnappedImageWidth
        let zoomVertical = maxHeight / baseSnappedImageHeight
        let zoomValue = min(min(zoomHorizontal, zoomVertical), ViewController.MaxZoomValue)
        cropViewWidthConstraint.constant = baseSnappedImageWidth * zoomValue
        cropViewHeightConstraint.constant = baseSnappedImageHeight * zoomValue
        lastZoomValue = zoomValue
        
        // Show the phrase selection butons
        cancelSelectionButton.isHidden = false
        doneWithSelectionButton.isHidden = false
        
        // Show the bounding polygons
        scaleSnapAndBoundingPolygons(zoomValue: zoomValue)
        for wordObj in boundingPolygons {
            if let shape = wordObj["shape"] as? CAShapeLayer {
                cropView.layer.addSublayer(shape)
            }
        }
        superCropView.setNeedsLayout()
        superCropView.layoutIfNeeded()
        
        if let tutorial = tutorial {
            _ = tutorial.completed(action: .successfulOcrDrag)
        }
    }
    
    // MARK: Blink the camerea view to give user impression photo was actually taken
    private func blinkCameraView() {
        videoPreviewLayer?.isHidden = true
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in
            self.videoPreviewLayer?.isHidden = false
        }
    }
    
    // MARK: Called when OS finishes processing photo
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil else {
            print("There was an error capturing photo: \(String(describing: error))")
            return
        }
        guard let cgImageRef = photo.cgImageRepresentation() else {
            print("Could not get CGImage")
            return
        }
        guard let videoWidth = previewView?.frame.maxX, let videoHeight = previewView?.frame.maxY else {
            print("Could not get image dimensions")
            return
        }
        
        let usedSettings = photo.resolvedSettings.photoDimensions
        let imgWidthPx = CGFloat(usedSettings.height)
        let imgHeightPx = CGFloat(usedSettings.width)
        let ptToPxScaleFactor = CGFloat(imgHeightPx) / videoHeight

        // Transform pan coordinates from their superview's coordinates to the "global" previewView coordinates
        let startInGlobalCoords = previewView.convert(cropViewStart, from: superCropView)
        let endInGlobalCoords = previewView.convert(cropViewEnd, from: superCropView)
        
        // Sometimes cropbox is made by panning down-right, other times it's made by panning down-left, up-right, or up-left
        var left = min(startInGlobalCoords.x, endInGlobalCoords.x)  // in pts
        var right = max(startInGlobalCoords.x, endInGlobalCoords.x)
        var top = min(startInGlobalCoords.y, endInGlobalCoords.y)
        var bottom = max(startInGlobalCoords.y, endInGlobalCoords.y)
        
        // Tranform coordinates in zoomed space to unzoomed space. The captured image is always the same whether or not the user zoomed
        if lastZoomValue > 1 {
            left = (left - videoWidth / 2) / lastZoomValue + videoWidth / 2
            right = (right - videoWidth / 2) / lastZoomValue + videoWidth / 2
            top = (top - videoHeight / 2) / lastZoomValue + videoHeight / 2
            bottom = (bottom - videoHeight / 2) / lastZoomValue + videoHeight / 2
        }

        // Expand the cropbox a little in case the camera moved slightly when the user released the cropbox to snap a photo
        var width = right - left
        var height = bottom - top
        let widthAdjustment = width * (ViewController.CropViewScaleFactor - 1) / 2
        let heightAdjustment = height * (ViewController.CropViewScaleFactor - 1) / 2
        left -= widthAdjustment  // still in pts
        right += widthAdjustment
        top -= heightAdjustment
        bottom += heightAdjustment
        
        // Transform from pts space to pixel space. NB, some phones (like iPhone X) have super skinny displays, so the left and right sides of the captured image are clipped when the video mode is .resizeAspectFill
        width = (right - left) * ptToPxScaleFactor
        height = (bottom - top) * ptToPxScaleFactor
        let visibleVideoWidthPx = previewView.frame.width * ptToPxScaleFactor
        let pxNotVisibleToEachSide = (imgWidthPx - visibleVideoWidthPx) / 2
        left = left * ptToPxScaleFactor + pxNotVisibleToEachSide  // now in px
        right = left + width
        top *= ptToPxScaleFactor
        bottom = top + height
        
        // Crop the captured image
        let cropOrigin = CGPoint(x: imgWidthPx - left - width, y: top)
        let cropDim = CGPoint(x: width, y: height)
        let horizontalOrientationCropbox = CGRect(x: cropOrigin.y, y: cropOrigin.x, width: cropDim.y, height: cropDim.x)
        let croppedImg = UIImage(cgImage: cgImageRef.takeUnretainedValue().cropping(to: horizontalOrientationCropbox)!, scale: 1.0, orientation: .right)

        // Extract tapped word from image and update current word
        ocrRetries = 0
        recognizeWords(from: croppedImg)
    }
}

// MARK: - Handle gestures
extension ViewController {
    
    private func zoomVideo(zoomValue: CGFloat) {
        videoPreviewLayer?.setAffineTransform(CGAffineTransform(scaleX: zoomValue, y: zoomValue))
    }
    
    private func zoomVideoPinch(sender: UIPinchGestureRecognizer) {
        let zoomValue = min(max(sender.scale * lastZoomValue, 1), ViewController.MaxZoomValue)
        
        switch sender.state {
        case .began:
            print("Began video pinch", lastZoomValue)
        case .changed:
            
            if keyboardOpen {
                return
            }
            
            zoomVideo(zoomValue: zoomValue)
        case .ended:
            
            if keyboardOpen {
                view.endEditing(true)
                return
            }
            
            lastZoomValue = zoomValue
            
            print("Ended video pinch", lastZoomValue)
        default:
            print("Unexpected video pinch state")
        }
    }
    
    private func scaleSnapAndBoundingPolygons(zoomValue: CGFloat) {
        cropViewWidthConstraint.constant = baseSnappedImageWidth * zoomValue
        cropViewHeightConstraint.constant = baseSnappedImageHeight * zoomValue
        
        for i in 0..<boundingPolygons.count {
            var wordObj = boundingPolygons[i]
            if let shape = wordObj["shape"] as? CAShapeLayer, let vertices = wordObj["vertices"] as? [[String: Int]], let origScaleFactor = wordObj["pxToPtScaleFactor"] as? CGFloat {
                let (bezier, _) = self.bezierFrom(vertices: vertices, scaledBy: origScaleFactor * zoomValue)
                shape.path = bezier.cgPath
            }
        }
    }
    
    private func zoomSnapPinch(sender: UIPinchGestureRecognizer) {
        let zoomValue = min(max(sender.scale * lastZoomValue, 1), ViewController.MaxZoomValue)
        
        switch sender.state {
        case .began:
            print("Began snap pinch", lastZoomValue)
        case .changed:
            
            if keyboardOpen {
                return
            }
            
            scaleSnapAndBoundingPolygons(zoomValue: zoomValue)
        case .ended:
            
            if keyboardOpen {
                view.endEditing(true)
                return
            }
            
            lastZoomValue = zoomValue
            print("Ended snap pinch", lastZoomValue)
        default:
            print("Unexpected snap pinch state")
        }
        
        // Move the image if the user moves pinch around
        let midpointOfFingers = sender.location(in: superCropView)
        moveSnapPan(to: midpointOfFingers, state: sender.state)
    }
    
    @IBAction func handlePinchZoom(_ sender: UIPinchGestureRecognizer) {
        
        if selectingPhrase {
            zoomSnapPinch(sender: sender)
        } else {
            zoomVideoPinch(sender: sender)
        }
    }
    
    private func croppingPan(sender: UIPanGestureRecognizer) {
        let currentLocation = sender.location(in: superCropView)
        if sender.state == .began {
            
            if keyboardOpen {
                return
            }
            
            cropViewStart = currentLocation
            superCropView.removeConstraints([cropViewWidthConstraint, cropViewHeightConstraint, cropViewCenterXConstraint, cropViewCenterYConstraint])
            superCropView.addConstraints([cropViewLeftConstraint, cropViewRightConstraint, cropViewTopConstraint, cropViewBottomConstraint])
        } else if sender.state == .changed {
            
            if keyboardOpen {
                return
            }
            
            cropViewLeftConstraint.constant = min(cropViewStart.x, currentLocation.x)
            cropViewRightConstraint.constant = -(superCropView.frame.width - max(cropViewStart.x, currentLocation.x))
            cropViewTopConstraint.constant = min(cropViewStart.y, currentLocation.y)
            cropViewBottomConstraint.constant = -(superCropView.frame.height - max(cropViewStart.y, currentLocation.y))
            cropView.setNeedsLayout()
            cropView.layoutIfNeeded()
            cropView.isHidden = false
        } else if sender.state == .ended {
            
            if keyboardOpen {
                view.endEditing(true)
                return
            }
            
            cropViewEnd = currentLocation
            
            let photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
            photoSettings.isAutoStillImageStabilizationEnabled = true
            photoSettings.isHighResolutionPhotoEnabled = true
            photoSettings.flashMode = .off
            photoSettings.isAutoDualCameraFusionEnabled = true
            
            cropView.isHidden = true
            capturePhotoOutput?.capturePhoto(with: photoSettings, delegate: self)
        } else {
            print("Shouldn't be in croppingPan in another state...")
        }
    }
    
    private func selectWordsPan(sender: UIPanGestureRecognizer) {
        let currentLocation = sender.location(in: cropView)

        if sender.state == .began {
            
            if keyboardOpen {
                return
            }
            
            panPath = UIBezierPath()
            panPath.move(to: currentLocation)
            
            // Initialize the highlighter
            panPathShape = CAShapeLayer()
            cropView.layer.addSublayer(panPathShape)
            panPathShape.lineWidth = avgWordHeight * lastZoomValue
            panPathShape.lineJoin = kCALineJoinRound
            panPathShape.opacity = ViewController.HighlighterLineOpacity
            panPathShape.fillColor = UIColor.clear.cgColor
            panPathShape.strokeColor = ViewController.HighlighterLineColor
            panPathShape.path = panPath.cgPath
        } else if sender.state == .changed {
            
            if keyboardOpen {
                return
            }
            
            panPath.addLine(to: currentLocation)
            panPathShape.path = panPath.cgPath
            
            for i in 0..<boundingPolygons.count {
                var wordObj = boundingPolygons[i]
                if let shape = wordObj["shape"] as? CAShapeLayer, let shapePath = shape.path, panPath.cgPath.intersects(path: shapePath) {
    
                    boundingPolygons[i]["chosen"] = true
                    shape.fillColor = ViewController.BoundedWordInteriorColorChosen
                }
            }
        } else if sender.state == .ended {
            
            if keyboardOpen {
                view.endEditing(true)
                return
            }
            
            panPathShape.removeFromSuperlayer()
        } else {
            print("Shouldn't be in selectingWordsPan in another state...")
        }
    }
    
    @IBAction func handlePan(_ sender: UIPanGestureRecognizer) {
        
        // Don't allow panning when the definition view is expanded, save modal is open, or camera is off
        guard !isExpanded() && !modalVisible && cameraOn else {
            return
        }
        
        if selectingPhrase {
            selectWordsPan(sender: sender)
        } else {
            croppingPan(sender: sender)
        }
    }
    
    private func moveSnapPan(to currentLocation: CGPoint, state: UIGestureRecognizer.State) {

        if state == .began {
            print("Beginning move pan")
            if keyboardOpen {
                return
            } else if selectingPhrase {
                startedMovePanAt = currentLocation
                baseCropViewCenter = CGPoint(x: cropViewCenterXConstraint.constant, y: cropViewCenterYConstraint.constant)
            }
        } else if state == .changed {
            
            if keyboardOpen {
                return
            } else if selectingPhrase {
                let deltaX = currentLocation.x - startedMovePanAt.x
                let deltaY = currentLocation.y - startedMovePanAt.y
                cropViewCenterXConstraint.constant = baseCropViewCenter.x + deltaX
                cropViewCenterYConstraint.constant = baseCropViewCenter.y + deltaY
            }
        } else if state == .ended {

            print("Ending move pan")
            if keyboardOpen {
                view.endEditing(true)
                return
            }
            // otherwise done
        } else {
            print("Shouldn't be in selectingWordsPan in another state...")
        }
    }
    
    @IBAction func handleTwoFingerPan(_ sender: UIPanGestureRecognizer) {
        guard !isExpanded() && !modalVisible else {
            print("Can't two-finger pan right now")
            return
        }
        moveSnapPan(to: sender.location(in: superCropView), state: sender.state)
    }
    
    @IBAction func handleBackgroundTap(_ sender: UITapGestureRecognizer) {

        // If we're editing the manual entry text field, then cancel the edit and hide keyboard
        if keyboardOpen && superModalView.isHidden {
            view.endEditing(true)
        }
        
        // If user is taps on background, he presumably doesn't know how to drag to drop yet. Display an explainer status messagee
        else if !isExpanded() && !keyboardOpen && superModalView.isHidden && !selectingPhrase && cameraOn {
            print("--> handling tap-snap")
            tapSnapLocation = sender.location(in: superCropView)
            // TODO left off here
        }
        
        // If we're selecting a phrase, then toggle the correct bounding polygon and add it to pending word search
        else if selectingPhrase, boundingPolygons.count > 0 {
            let tapLocation = sender.location(in: cropView)
            for i in 0..<boundingPolygons.count {
                var wordObj = boundingPolygons[i]
                let wasChosen = wordObj["chosen"] as! Bool
                if let shape = wordObj["shape"] as? CAShapeLayer, shape.path?.contains(tapLocation) ?? false {
                    boundingPolygons[i]["chosen"] = !wasChosen
                    if !wasChosen {  // if it was just chosen
                        shape.fillColor = ViewController.BoundedWordInteriorColorChosen
                    } else {  // if it was just unchosen
                        shape.fillColor = ViewController.BoundedWordInteriorColorNotChosen
                    }
                }
            }
        }
    }
}

// MARK: - Word search
extension ViewController {

    func updateManualEntryField(text: String?, placeholder: Bool = false) {
        guard var text = text else {
            print("Nil string in manual entry text field")
            manualEntryTextField.text = nil
            manualEntryTextField.placeholder = "Enter word or tap"
            return
        }
        
        if !placeholder {
            // Remove punctuation and newlines from beginning and end of string. NB, composition of trims isn't commutative
            text = text.trimmingCharacters(in: .punctuationCharacters).trimmingCharacters(in: .whitespacesAndNewlines)
            text = text.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: .punctuationCharacters)
            manualEntryTextField.text = text
            
            // Log that a definition/wikipedia/translation search attempt is happening
            Analytics.logEvent(AnalyticsEventSearch, parameters: [
                AnalyticsParameterSearchTerm: text
            ])
            
            // Pass the word along to all definition view controllers
            pageViewController?.currentWord = text
            
            // Perform search
            searchRetries = 0
            performAggregatedSearch(for: text)
        } else {
            manualEntryTextField.text = nil
            manualEntryTextField.placeholder = text
        }
    }
    
    @IBAction func handeEnterInManualEntry(_ sender: PaddedTextField, forEvent event: UIEvent) {
        print("Manual entry finished")
        view.endEditing(true)
        
        var text = sender.text
        if let tutorial = tutorial, tutorial.completed(action: .manualEntry) {
            text = Tutorial.ManualEntryWord  // force the word "puppy" on the user in case they get cute
        }
        
        updateManualEntryField(text: text)
    }
    
    func performAggregateSearchAux(for text: String, dcData: Data?, t: String?) {
        
        // Get URL ready
        let paths = [Constants.AwsApiBaseURL, Constants.AwsApiStage, Constants.AggregatedSearchApiPath].filter { str in
            return str != ""
        }
        let url = URL(string: paths.joined(separator: "/"))!
        
        // Get request ready
        let sesh = URLSession(configuration: .default)
        var req = URLRequest(url: url)
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpMethod = "POST"
        var jsonObj = self.pageViewController?.someAggregatedSearchParams() ?? [:]
        jsonObj["iCloudUserNameHash"] = self.iCloudUserID ?? ""
        jsonObj["searchText"] = text
        jsonObj["endpoints"] = ["definition", "wikipediaIntro", "translation"]
        let jsonToPrint = jsonObj
        if let dcData = dcData {
            jsonObj["deviceCheckToken"] = dcData.base64EncodedString()
        }
        if let t = t {
            jsonObj["t"] = t
        }
        let data = try! JSONSerialization.data(withJSONObject: jsonObj, options: [])
        req.httpBody = data
        
        // Call the search endpoint
        self.middleActivityView.isHidden = false
        self.middleActivityView.startAnimating()
        print("Calling aggregate search endpoint at", req.url ?? "NIL", "with", jsonToPrint)
        _ = sesh.dataTask(with: req, completionHandler: { (data, response, error) in
            
            DispatchQueue.main.async {
                if let _ = response, let data = data, let jsonData = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers),
                    let jsonDictionary = jsonData as? [String: Any], let searchSuccess: Bool = Utilities.GetProp(named: "searchSuccess", from: jsonDictionary)  {
                    
                    // If successful, fan out responses to definition view controllers
                    if searchSuccess {
                        if let t: String = Utilities.GetProp(named: "t", from: jsonDictionary) {
                            FlashcardCollections.EatT(t: t)
                        }
                        self.pageViewController?.fanOutDefinitionSearch(response: jsonDictionary)
                    } else if !searchSuccess, let failureReason: [String: Any] = Utilities.GetProp(named: "failureReason", from: jsonDictionary) {
                        // If failed but we at least have a reason, show message
                        print("Aggregated search failed. Displaying status message showing reason", failureReason)
                        self.handleMeteredApiFailure(because: failureReason, usageType: .search)
                    } else {
                        print("Missing failure reason in aggregate search")
                        self.handleMeteredApiFailure(because: ["reason": ViewController.UnknownFailureCode], usageType: .search)
                    }
                } else {
                    print("Error:", error ?? "")
                    if let data = data {
                        print(NSString.init(data: data, encoding: String.Encoding.utf8.rawValue) ?? "")
                    }
                    self.cleanupAfterFailedSearchRPC(for: text)
                }
                self.middleActivityView.isHidden = true
                self.middleActivityView.stopAnimating()
            }
        }).resume()
    }
    
    func performAggregatedSearch(for text: String) {

        if let t = FlashcardCollections.DatT() {
            self.performAggregateSearchAux(for: text, dcData: nil, t: t)
        } else if Constants.CurrDevice.isSupported {
            Constants.CurrDevice.generateToken { (dcData, error) in
                if let dcData = dcData {
                    DispatchQueue.main.sync {
                        self.performAggregateSearchAux(for: text, dcData: dcData, t: nil)
                    }
                }
                if let error = error {
                    print("Error when generating a token:", error.localizedDescription)
                    self.handleMeteredApiFailure(because: ["reason": ViewController.CouldNotGenerateDCTokenCode], usageType: .search)
                }
            }
        } else {
            print("Platform is not supported or you missing dat t")
            handleMeteredApiFailure(because: ["reason": ViewController.CouldNotGenerateDCTokenCode], usageType: .search)
        }
    }
    
    func cleanupAfterFailedSearchRPC(for text: String) {
        
        // Do exponential back-off
        guard searchRetries < Constants.MaxRetries else {
            print("Hit max search retries")
            self.handleMeteredApiFailure(because: ["reason": ViewController.UnknownFailureCode], usageType: .search)
            return
        }
        let secondsToWait = Double(Utilities.Exp(2, searchRetries))
        searchRetries += 1
        
        DispatchQueue.main.async {
            Timer.scheduledTimer(withTimeInterval: secondsToWait, repeats: false) { _ in
                print("Waited \(secondsToWait) seconds. Retrying RPC in aggregated search")
                self.performAggregatedSearch(for: text)
            }
        }
    }
    
    func cleanupAfterFailedOcrRpc(img: UIImage, rotated: Bool) {
        
        // Do exponential back-off
        guard ocrRetries < Constants.MaxRetries else {
            print("Hit max OCR retries")
            self.handleMeteredApiFailure(because: ["reason": ViewController.UnknownFailureCode], usageType: .scan)
            self.middleActivityView.isHidden = true
            self.middleActivityView.stopAnimating()
            return
        }
        let secondsToWait = Double(Utilities.Exp(2, ocrRetries))
        ocrRetries += 1
        
        DispatchQueue.main.async {
            Timer.scheduledTimer(withTimeInterval: secondsToWait, repeats: false) { _ in
                print("Waited \(secondsToWait) seconds. Retrying RPC in aggregated search")
                self.recognizeWords(from: img, rotated: rotated)
            }
        }
    }
    
    // MARK: Show a brief status message explaining why the search failed.
    func handleMeteredApiFailure(because failureDescription: [String: Any], usageType: ApiUsageType) {
        // Format of failure reason is { reason: String, qualifiers: { thresholdType: String, level: String}}
        if let reason: String = Utilities.GetProp(named: "reason", from: failureDescription) {
            switch reason {
            case ViewController.UnknownFailureCode:
                fadeUpperMessageIn(with: ViewController.UnknownApiFailureString)
            case ViewController.CouldNotGenerateDCTokenCode:
                fadeUpperMessageIn(with: ViewController.CouldNotGenerateDCTokenMessageString)
            case ViewController.DeviceCheckFailureCode:
                fadeUpperMessageIn(with: ViewController.DeviceCheckFailureMessageString)
            case ViewController.InvalidICloudUserIDFailureCode:
                fadeUpperMessageIn(with: ViewController.InvalidCloudUserIDMessageString)
            case ViewController.ApiUsageThresholdExceededFailureCode:
                if let qualifiers: [String: Any] = Utilities.GetProp(named: "qualifiers", from: failureDescription), let thresholdType: String = Utilities.GetProp(named: "thresholdType", from: qualifiers), let level: String = Utilities.GetProp(named: "level", from: qualifiers), let levelLongForm = ViewController.Intervals[level] {
                    
                    switch thresholdType {
                    case ViewController.FreeThresholdTypeCode:
                        print("This is just a placeholder. Free threshold doesn't exist on the backend yet")
                    case ViewController.GlobalThresholdTypeCode:
                        let statusMessage = ViewController.GlobalUsageLimitExceededString.replacingOccurrences(of: "{{interval}}", with: levelLongForm).replacingOccurrences(of: "{{usage-type}}", with: (usageType == .search ? ViewController.SearchUsageString.lowercased() : ViewController.ScanUsageString.lowercased()))
                        fadeUpperMessageIn(with: statusMessage)
                    default:
                        print("Unsupported threshold type \(thresholdType)")
                    }
                } else {
                    let statusMessage = ViewController.GenericUsageLimitExceededString.replacingOccurrences(of: "{{usage-type}}", with: (usageType == .search ? ViewController.SearchUsageString : ViewController.ScanUsageString))
                    fadeUpperMessageIn(with: statusMessage)
                }
            default:
                print("Unknown reason \(reason) for aggregated search failure")
            }
        }
    }
}

// MARK: Flashlight handlers
extension ViewController {
    
    @IBAction func handleFlashlightButton(_ sender: UIButton, forEvent event: UIEvent) {
        lightBulbOn = !lightBulbOn
        if lightBulbOn {
            flashlightButton.tintColor = ViewController.PressedTopBarButtonColor
        } else {
            flashlightButton.tintColor = ViewController.DefaultTopBarButtonColor
        }
        toggleTorch(on: lightBulbOn)
    }

    func toggleTorch(on: Bool) {
        guard let device = AVCaptureDevice.default(for: AVMediaType.video)
            else {return}
        
        if device.hasTorch {
            do {
                try device.lockForConfiguration()
                
                if on == true {
                    device.torchMode = .on
                } else {
                    device.torchMode = .off
                }
                
                device.unlockForConfiguration()
            } catch {
                print("Torch could not be used")
            }
        } else {
            print("Torch is not available")
        }
    }
}

// MARK: - Make flashcard stuff
extension ViewController {

    func openAddToFlashcardCollectionModal() {
        if isExpanded() {
            contractDefinitionView()
        }
        superModalView.isHidden = false
        modalVisible = true
    }
    
    func closeAddToFlashcardCollectionModal() {
        superModalView.isHidden = true
        modalVisible = false
        view.endEditing(true)
    }
    
    func toggleModal() {
        if modalVisible {
            collectionsListView?.deselectRow()
            closeAddToFlashcardCollectionModal()
        } else {
            openAddToFlashcardCollectionModal()
        }
    }
    
    @IBAction func handleSaveButton(_ sender: UIButton, forEvent event: UIEvent) {
        toggleTableViewModal()
    }
    
    @IBAction func handleCameraButton(_ sender: UIButton, forEvent event: UIEvent) {
        if !cameraInitialized {
            startCamera(forceContract: true)
        } else {  // if camera initialization is finished
            if cameraOn {  // then switch off
                videoPreviewLayer?.isHidden = true
                cameraOn = false
                cameraButton.tintColor = ViewController.DefaultTopBarButtonColor
                expandDefinitionView()
            } else {  // if it's off, then switch it on
                videoPreviewLayer?.isHidden = false
                cameraOn = true
                cameraButton.tintColor = ViewController.PressedTopBarButtonColor
                contractDefinitionView()
            }
        }
    }
}

// MARK: - Miscellaneous
extension ViewController {

    @objc func keyboardNotification(notification: NSNotification) {
        
        if let userInfo = notification.userInfo, let keyboardFrameBegin = (userInfo[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue, let keyboardFrameEnd = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            
            // Get edge and animation info from notification
            let beginningKeyboardEdgeY = keyboardFrameBegin.origin.y
            let endingKeyboardEdgeY = keyboardFrameEnd.origin.y
            
            // One could get keyboard animation duration and curve here if needed for constraint animations

            // If this notification doesn't open or close keyboard, exit
            guard !beginningKeyboardEdgeY.approximatelyEquals(other: endingKeyboardEdgeY) else {
                return
            }
            
            // If keyboard is opening
            if beginningKeyboardEdgeY > endingKeyboardEdgeY {
                keyboardOpen = true
            } else {  // if the keyboard is closing
                keyboardOpen = false
            }
        }
    }
    
    @objc func handleCancelSelectionButton() {

        // Don't let users cancel selection mode when the tutorial is active
        if let tutorial = tutorial, let _ = tutorial.getChastisingMessage() {
            fadeUpperMessageIn(with: ViewController.PickAWordMessage)
            return
        }

        stopSelectingPhraseMode()
    }
    
    @objc func handleDoneWithSelectionButton() {
        
        var wordsChosen: [String] = []
        
        for i in 0..<boundingPolygons.count {
            let wordObj = boundingPolygons[i]
            if let chosen = wordObj["chosen"] as? Bool, chosen, let word = wordObj["word"] as? String {
                wordsChosen.append(word)
            }
        }
        
        // Handle tutorial stuff
        if let tutorial = tutorial {
            
            // Force the user to select exactly one word if in single highlight tutorial step
            if tutorial.nextExpectedTutorialAction() == .singleHighlight, wordsChosen.count != 1, let chastisingMessage = tutorial.getChastisingMessage() {
                fadeUpperMessageIn(with: chastisingMessage)
                return
            } else if tutorial.nextExpectedTutorialAction() == .multipleHighlight, wordsChosen.count <= 1, let chastisingMessage = tutorial.getChastisingMessage() {
                // force them to choose more than one word if in multi highlight step
                fadeUpperMessageIn(with: chastisingMessage)
                return
            }

            // Otherwise
            if wordsChosen.count == 1 {
                _ = tutorial.completed(action: .singleHighlight)
            } else if wordsChosen.count > 1 {
                _ = tutorial.completed(action: .multipleHighlight)
            }
        }
        
        updateManualEntryField(text: wordsChosen.joined(separator: " "))
        stopSelectingPhraseMode()
    }
    
    private func fadeUpperMessageOut() {
        upperMessageVC.timer = Timer.scheduledTimer(withTimeInterval: ViewController.UpperMessageLifetime, repeats: false) { _ in
            UIView.animate(withDuration: ViewController.UpperMessageAnimationDuration, animations: {
                self.upperMessageContainer.alpha = 0
            }, completion: { _ in
                self.upperMessageContainer.isHidden = true
                self.upperMessageVC.timer?.invalidate()
                self.upperMessageVC.timer = nil
                UIView.animate(withDuration: ViewController.UpperMessageAnimationDuration, animations: {
                    self.definitionViewTopConstraint!.constant = self.getDefinitionViewTopConstraintConstantBasedOnVisibleMessages()
                    self.previewView.setNeedsLayout()
                    self.previewView.layoutIfNeeded()
                })
            })
        }
    }
    
    private func fadeUpperMessageIn(with message: String?) {
        
        guard let message = message else {
            return
        }

        // If we're about to or currently animating message fade out, stop
        upperMessageVC.timer?.invalidate()
        upperMessageVC.view.layer.removeAllAnimations()
        
        // Set up new message
        upperMessageContainer.isHidden = true
        let (newWidth, newHeight) = upperMessageVC.setMessage(to: message)
        upperMessageWidthConstraint.constant = newWidth + 2 * ViewController.UpperMessageLeftRightPadding
        upperMessageHeightConstraint.constant = newHeight + 2 * ViewController.UpperMessageTopBottomPadding
        upperMessageContainer.isHidden = false
        definitionViewTopConstraint!.constant = getDefinitionViewTopConstraintConstantBasedOnVisibleMessages()
        previewView.setNeedsLayout()
        previewView.layoutIfNeeded()
        
        // Show message
        upperMessageContainer.alpha = 1
        fadeUpperMessageOut()
    }
    
    func getDefinitionViewTopConstraintConstantBasedOnVisibleMessages() -> CGFloat {
        var rtn = Constants.DefViewTopMargin
        if !upperMessageContainer.isHidden {
            rtn = upperMessageHeightConstraint.constant + 2 * ViewController.MessageTopBottomMargin
        }
        return rtn
    }
}

// MARK: - Functions that return frames for UI elements pointed out by tutorial
extension ViewController: TutorialDelegate {

    func isCameraOn() -> Bool {
        return cameraOn
    }
    
    func getParent() -> UIView {
        return previewView
    }

    func frameForCameraButton() -> CGRect {

        let heightTopBarView = superTopBarView.frame.height
        let distFromRight = abs(Constants.ManualEntryRightMargin) + abs(ViewController.CameraButtonRightMargin) + cameraButton.frame.width
        return CGRect(x: previewView.frame.width - distFromRight, y: heightTopBarView - Constants.ManualEntryTextFieldBottomMargin - 1, width:  cameraButton.frame.width, height: 0)
    }
    
    func frameForCroppingAndSnappingArea() -> CGRect {
        let heightTopBarView = superTopBarView.frame.height
        let superCropViewHeight = superCropView.frame.height
        let superCropViewWidth = superCropView.frame.width
        return CGRect(x: 0, y: heightTopBarView + superCropViewHeight - 60, width: superCropViewWidth, height: 0)
    }
    
    func frameForSelectionArea() -> CGRect {
        let heightTopBarView = superTopBarView.frame.height
        let superCropViewHeight = superCropView.frame.height
        let cropViewHeight = cropView.frame.height
        let cropViewWidth = cropView.frame.width
        let cropViewYDelta = (ViewController.SnapMinTopMargin - ViewController.SnapMinBottomMargin) / 2
        let spaceAboveCropView = superCropViewHeight / 2 + cropViewYDelta - cropViewHeight / 2
        let cropViewLeftMargin = (previewView.frame.width - cropViewWidth) / 2
        return CGRect(x: cropViewLeftMargin, y: heightTopBarView + spaceAboveCropView, width: cropViewWidth, height: 0)
    }
    
    func frameForDefinitionViewContent() -> (CGRect, CGFloat) {
        let heightTopBarView = superTopBarView.frame.height
        let superCropViewHeight = superCropView.frame.height
        let defViewWidth = definitionView.frame.width
        let defViewNavbarHeight = pageViewController?.getDefinitionViewNavbarHeight() ?? Constants.NavbarHeight
        return (CGRect(x: Constants.LeftRightMarginDefViewSpacing, y: heightTopBarView + superCropViewHeight + defViewNavbarHeight + 5, width: defViewWidth, height: 0), definitionView.frame.width - 2 * Constants.LeftRightMarginInDefView)
    }
    
    func frameForManualEntryBar() -> (CGRect, CGFloat) {
        let heightTopBarView = superTopBarView.frame.height
        let widthManualEntryTextField = manualEntryTextField.frame.width
        return (CGRect(x: Constants.ManualEntryTextFieldLeftMargin, y: heightTopBarView - Constants.ManualEntryTextFieldBottomMargin, width: widthManualEntryTextField, height: 0), manualEntryTextField.frame.width)
    }
    
    func frameForDefinitionView() -> (CGRect, CGFloat) {
        let heightTopBarView = superTopBarView.frame.height
        let superCropViewHeight = superCropView.frame.height
        let defViewWidth = definitionView.frame.width
        return (CGRect(x: Constants.LeftRightMarginDefViewSpacing, y: heightTopBarView + superCropViewHeight + 5, width: defViewWidth, height: 0), definitionView.frame.width - 2 * Constants.LeftRightMarginInDefView)
    }
    
    func frameForBottomOfDefinitionView(delta: CGFloat? = nil) -> (CGRect, CGFloat) {
        let heightTabBarView = (tabBarController?.tabBar.frame.height)!
        let heightTransparentBottomPageView = (pageViewController?.getHeightOfTransparentPagingPart())!
        let screenHeight = UIScreen.main.bounds.height
        let defViewWidth = definitionView.frame.width
        var additionalDelta = CGFloat(0)
        if let delta = delta {
            additionalDelta = delta
        }
        return (CGRect(x: Constants.LeftRightMarginDefViewSpacing, y: screenHeight - heightTabBarView - heightTransparentBottomPageView - 5 - additionalDelta, width: defViewWidth, height: 0), definitionView.frame.width - 4 * Constants.LeftRightMarginInDefView)
    }
    
    func frameForStudyTabBarItem() -> CGRect {
        if let tabBarItemView = tabBarController?.tabBar.getUIViewForTabAt(index: TabBarViewController.StudyTabTagAndIndex) {
            return previewView.convert(tabBarItemView.bounds, from: tabBarItemView)
        } else {
            let heightTabBarView = (tabBarController?.tabBar.frame.height)!
            let twoThirdsScreenWidth = UIScreen.main.bounds.width / 3 * 2
            let topOfTabBar = UIScreen.main.bounds.height - heightTabBarView
            return CGRect(x: twoThirdsScreenWidth, y: topOfTabBar, width: 1, height: 0)
        }
    }
}

extension ViewController: CollectionsTableViewControllerDelegate {

    func performPostCloseAction(for row: Int) {
    }
    
    func toggleTableViewModal() {
        toggleModal()
    }
    
    func getCurrentWord() -> String? {
        return pageViewController?.currentWord
    }
    
    func getPersistableDict() -> [String : NSAttributedString]? {
        return pageViewController?.getPersistableDict()
    }
    
    func setCollectionsListView(view: CollectionsTableViewController?) {
        collectionsListView = view
    }
    
    func didDelete(deck: String?, passDataToOtherTab: Bool) {
        guard let deckName = deck else {
            print("No deck name given")
            return
        }
        
        // Let other tab know we deleted this deck, so it can remove deck and buttons from screen
        if passDataToOtherTab {
            studyVC?.didDelete(deck: deckName, passDataToOtherTab: false)
        } else {  // Only reload collections table data if this was called from the other tab, since table data has already been reloaded when passDataToOtherTab == true
            collectionsListView?.tableView.reloadData()
        }
    }
    
    func didSelect(deck: String?, passDataToOtherTab: Bool) {
        guard let deckName = deck else {
            print("No deck name given")
            return
        }
        
        fadeUpperMessageIn(with: ViewController.SavedCardTemplateString.replacingOccurrences(of: "{{deck-name}}", with: deckName))
        
        // Let other tab know we added a card to this deck, so it can reload the deck if necessary
        if passDataToOtherTab {
            studyVC?.didSelect(deck: deckName, passDataToOtherTab: false)
        }
    }
}

extension ViewController: DefinitionViewControllerDelegate {
    func getICloudUserNameHash() -> String {
        return iCloudUserID ?? ""
    }
}

extension ViewController: DefinitionPageViewControllerDelegate {
    
    func vanillaVCSelected() {}
    
    func wikipediaVCSelected() {
        if let tutorial = tutorial {
            _ = tutorial.completed(action: .swipeRightToWiki)
        }
    }
    
    func translationVCSelected() {
        if let tutorial = tutorial {
            _ = tutorial.completed(action: .swipeRightToTranslation)
        }
    }
    
    func isExpanded() -> Bool {
        if (pageViewController?.expanded)! != expanded {
            print("Error: definition page view controller and search view controller have different ideas about whether definition view is expanded. Making it contracted")
            contractDefinitionView()
            return false
        }
        return expanded
    }
}
