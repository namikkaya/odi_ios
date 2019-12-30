//
//  cameraView.swift
//  videoMuteSystem_hub
//
//  Created by namikkaya on 13.11.2019.
//  Copyright © 2019 brokoly. All rights reserved.
//

import UIKit
import AVFoundation
import AMPopTip

enum RecordStatus {
    case start
    case stop
}

enum UIDesing {
    case Ready
    case CountDown
    case Recording
    case Stop
    case Setting
}

protocol KayaCameraViewDelegate:class {
    /// close buttona basılıp sayfanın kapanacağı eğer kayıtta video var ise siler
    func KayaCameraViewDelegate_CloseButtonEvent()
    /// video çıktısı veren protocol
    func KayaCameraViewDelegate_VideoOutPutExport(outputURL: URL?, originalImage: UIImage?, thumbnail: UIImage?)
    /// gallerybuttonuna tıklandığında galerinin açılması gerektiğini haber verir
    func KayaCameraViewDelegate_OpenGallery()
    /// İşlem durumunu belirtir
    func KayaCameraViewdelegate_RecordStatus(recordStatus:RecordStatus)
    /// camera position
    func KayaCameraViewDelegate_ChangeCamera(cameraPosition:CameraPosition?)
    
    /// inhput error
    
    func KayaCameraViewDelegate_Error()
}

extension KayaCameraViewDelegate {
    /// close buttona basılıp sayfanın kapanacağı eğer kayıtta video var ise siler
    func KayaCameraViewDelegate_CloseButtonEvent() { }
    /// video çıktısı veren protocol
    func KayaCameraViewDelegate_VideoOutPutExport(outputURL: URL?, originalImage: UIImage?, thumbnail: UIImage?){}
    /// gallerybuttonuna tıklandığında galerinin açılması gerektiğini haber verir
    func KayaCameraViewDelegate_OpenGallery() {}
    /// İşlem durumunu belirtir
    func KayaCameraViewdelegate_RecordStatus(recordStatus:RecordStatus) {}
    /// camera position
    func KayaCameraViewDelegate_ChangeCamera(cameraPosition:CameraPosition?){}
    
    func KayaCameraViewDelegate_Error(){}
}

@IBDesignable
class KayaCameraView: UIView,
KayaCameraManagerDelegate,
KayaCameraSettingViewDelegate,
KayaMediaManagerDelegate,
KayaCountDownDelegate
{
    
    
    let TAG:String = "KayaCameraView:"
    
//    MARK: - External
    private var subtitleDataHolder:[KayaSubtitleModel]? = []
    
    /**
     Usage: Altyazı bilgilerini tutar
     - Parameter Set: KayaSubtitleModel
     - Parameter Get: KayaSubtitleModel
     */
    var subtitleData:[KayaSubtitleModel]? {
        set {
            subtitleDataHolder = newValue
            camMediaManager?.subtitleData = subtitleData // media menager için de gönderiliyor
        }get{
            return subtitleDataHolder
        }
    }
//    MARK: - Designable
    
    /// record button göbek rengi
    @IBInspectable
    var recordButtonColor:UIColor = UIColor.red {
        didSet{
            recordButton.recordButtonColor = recordButtonColor
        }
    }
    
    @IBInspectable
    var setting:UIColor = UIColor.red {
        didSet{
            recordButton.recordButtonColor = recordButtonColor
        }
    }
    
    @IBInspectable
    var mySelfSubtitleColor:UIColor = UIColor.blue {
        didSet{
            
        }
    }
    
    @IBInspectable
    var speakerSubtitleColor:UIColor = UIColor.red {
        didSet {
            
        }
    }
    
    
    private var galleryStatusHolder:Bool = false
    
    var galleryStatus:Bool {
        set {
            galleryStatusHolder = newValue
        }get {
            return galleryStatusHolder
        }
    }
    
    /**
     Usage: Galeriyi açmak için bu değişkene bir thumb image ataması yapılması gerekiyor. Eğer nil gönderilirs akapatılır
     - Parameter galleryImage:  thumbnail alır
     - Returns:
     */
    var galleryImage:UIImage? = nil {
        didSet {
            if galleryImage != nil {
                galleryButton.image = galleryImage
                galleryButton.contentMode = .scaleAspectFill
                galleryButton.layer.cornerRadius = 5
                galleryButton.layer.masksToBounds = true
                galleryButton.isHidden = false
                galleryStatus = true
            }else {
                galleryStatus = false
                galleryButton.isHidden = true
            }
        }
    }
    

    private var WBButtonHiddenStatus:Bool = false
    /**
        Usage:  white balance ayarlarının button görünümü
    */
    @IBInspectable var WBButtonHidden:Bool {
        set {
            WBButtonHiddenStatus = newValue
            settingView.WBHidden = newValue
        }get {
            return WBButtonHiddenStatus
        }
    }
    
    private var ISOButtonHiddeStatus:Bool = false
    /**
     Usage: Işık ayarlarını kontrol düğmesinin açık / kapalı oluşu
     */
    @IBInspectable var ISOButtonHidden:Bool {
        set {
            ISOButtonHiddeStatus = newValue
            settingView.ISOHidden = newValue
        }get {
            return ISOButtonHiddeStatus
        }
    }
    
    private var contextHolder:UIViewController?
    /// Context uiviewController
    var context:UIViewController? {
        set {
            contextHolder = newValue
        }get {
            return contextHolder
        }
    }
    
    private var currentStepStatus:UIDesing = .Ready
    
    private var recordStatusHolder:RecordStatus = .stop
    
//    MARK: - KAYNAK View
    public var view:UIView!
    private var nibName:String = "KayaCameraView"
    
//    MARK: - OBJECT
    @IBOutlet var previewView: UIView!
    @IBOutlet var contentContainer: UIView!
    @IBOutlet var bottomViewContentContainer: UIView!
    @IBOutlet var settingView: KayaCameraSettingView!
    @IBOutlet var verticalSubtitleContainer: KayaKaraokeViewManager!
    @IBOutlet var horizontalSubtitleContainer: KayaKaraokeViewManager!
    @IBOutlet var countDown: KayaCountDown!
    
    
//    -- button
    @IBOutlet var changeButton: UIButton!
    @IBOutlet var recordButton: KayaRecordButton!
    @IBOutlet var settingButton: UIButton!
    @IBOutlet var textButton: KayaTextButton!
    @IBOutlet var soundButton: KayaSoundButton!
    @IBOutlet var nextButton: UIButton!
    @IBOutlet var galleryButton: UIImageView!
    @IBOutlet var timeSlider: KayaSlider!
    @IBOutlet var closeButton: UIButton!
    
    
//    MARK: - CLASS
    //managers
    var camManager: KayaCameraManager?
    var camMediaManager: KayaMediaManager?
    var camFileManager: KayaFileManager?
    
//    MARK: - Variable Holder
    
    
    /// View içinde ki hareketleri haber veren delegate
    weak var setDelegate:KayaCameraViewDelegate?
    
    private var currentVideoOrientationHolder:AVCaptureVideoOrientation?
    var currentVideoOrientation: AVCaptureVideoOrientation? {
        set {
            currentVideoOrientationHolder = newValue
        }get {
            return currentVideoOrientationHolder
        }
    }
    
    var cameraPositionHolder:CameraPosition? = CameraPosition.FRONT
    
    // - Front Camera Auto Holder
    private var front_ISO_AutoHolder:Bool = true
    private var front_WB_AutoHolder:Bool = true
    
    private var back_ISO_AutoHolder:Bool = true
    private var back_WB_AutoHolder:Bool = true
    
    // - Kamera değiştirme iconu dönüşü
    private var isFlipped:Bool = false
    
    private var currentInterfaceOrientationMaskHolder:UIInterfaceOrientationMask = UIInterfaceOrientationMask.landscapeRight
    /// Ekran yönünü tutar
    var currentInterfaceMaskOrientation:UIInterfaceOrientationMask {
        set {
            currentInterfaceOrientationMaskHolder = newValue
        }get {
            return currentInterfaceOrientationMaskHolder
        }
    }
    
    private var currentInterfaceOrientationHolder:UIInterfaceOrientation = UIInterfaceOrientation.landscapeRight
    /// ekran yönünü tutar
    var currentInterfaceOrientation:UIInterfaceOrientation {
        set {
            currentInterfaceOrientationHolder = newValue
        }get {
            return currentInterfaceOrientationHolder
        }
    }
    
//    MARK: - KAYNAK CODE
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func didClose() {
        recordButton.isHidden = true
        print("didClose")
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        print("\(self.TAG): didMoveToWindow:")
        DispatchQueue.main.async {
            self.previewView?.frame = self.view.bounds
        }
    }
    
    func setup(){
        print("namik : setup")
        view = loadViewFromNib()
        view.frame = bounds
        view.autoresizingMask = [UIView.AutoresizingMask.flexibleWidth,
                                 UIView.AutoresizingMask.flexibleHeight]
        addSubview(view)
        
        
        timeSlider.setThumbImage(UIImage(), for: UIControl.State.normal)
        
        
        // initalize function
        settingView.setDelegate = self
        cameraFileManager()
        cameraConfiguration()
        rotated()
        mediaConfiguration()
        countDownConfiguration()
        uiConfiguration()
        addListener()
        rotated()
        
        UISetDesing = .Ready
    }
    
    
    func loadViewFromNib()-> UIView {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: nibName, bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
        return view
    }
    
    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        guard let camM = camManager else { return }
        guard let mediaM = camMediaManager else { return }
        
        camM.layerUpdate(of: previewView)
        
        DispatchQueue.main.async {
            self.previewView?.frame = self.view.bounds
        }
        
        camM.updateRotateVideo()
        
        mediaM.setDesing(orientation: KayaMediaManager.orientation.Horizontal)
        //currentVideoOrientation = AVCaptureVideoOrientation.landscapeLeft
        update_bottomViewContentContainer_gradientBackgronud()
        //recordButtonPosition(orientation: .landscapeLeft)
        //settingView.layer.zPosition = 5*/
    }
    
    deinit {
        releaseView()
        if recordButtonTimer != nil {
            recordButtonTimer?.invalidate()
            recordButtonTimer = nil
        }
    }
    
    // view temizliği
    func releaseView() {
        removeListener()
    }
    
    fileprivate func uiConfiguration() {
        galleryButton.layer.cornerRadius = 5
        galleryButton.layer.masksToBounds = true
        galleryButton.isUserInteractionEnabled = true
    
        let galleryTap = UITapGestureRecognizer(target: self, action: #selector(self.gallreyHandleTap(_:)))
        self.galleryButton.addGestureRecognizer(galleryTap)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        self.contentContainer.addGestureRecognizer(tap)
        
        let tapBottom = UITapGestureRecognizer(target: self, action: #selector(self.emptyTap(_:)))
        self.bottomViewContentContainer.addGestureRecognizer(tapBottom)
        
        update_bottomViewContentContainer_gradientBackgronud()
    }
    
    ///Usage:  Bottom view deki arkaplanda ki gradient rengi ayarlar ve ekran kadar uzatır
    fileprivate func update_bottomViewContentContainer_gradientBackgronud() {
        bottomViewContentContainer.clearGradientBackground()
        bottomViewContentContainer.setGradientBackground(colorOne: UIColor.black.withAlphaComponent(0.8),
                                                         colorTwo: UIColor.black.withAlphaComponent(0.5))
    }
    
    @objc func gallreyHandleTap(_ sender: UITapGestureRecognizer? = nil) {
        setDelegate?.KayaCameraViewDelegate_OpenGallery()
    }
    
    @objc func emptyTap(_ sender: UITapGestureRecognizer? = nil) {
        
    }
    
    
    var focusSq:cameraFocusShape?
    @objc func handleTap(_ sender: UITapGestureRecognizer? = nil) {
        if focusSq != nil {
            focusSq?.clearMySelf()
            focusSq = nil
        }
        if recordButton.isRecording { // record başladıysa focus özelliği işletme
            return
        }
        let touchPoint = sender!.location(in: self.view)
        focusSq = cameraFocusShape(point: touchPoint, view: contentContainer)
        guard let cam = camManager else { return }
        cam.focusAndExpose(point: touchPoint)
        settingView.lightAutoStatus = false
        settingView.whiteBalanceAutoStatus = false
        settingView.palletteAutoStatus = false
    }
    
//    MARK: - Camera Configuration & Setting
    
    private func cameraConfiguration() {
        camManager = KayaCameraManager(preview: previewView)
        camManager?.setDelegate = self
        camManager?.autoIso()
        cameraChangeConfiguration()
    }
    
    private func cameraFileManager() {
        camFileManager = KayaFileManager()
    }
    
    private func mediaConfiguration() {
        camMediaManager = KayaMediaManager(horizontal: horizontalSubtitleContainer, vertical: verticalSubtitleContainer, slider: timeSlider)
        camMediaManager?.setDelegate = self
    }
    
    private func countDownConfiguration() {
        countDown.setDelegate = self
    }
    
    internal func cameraSettingConfiguration(iso:Float?, whiteBalance:AVCaptureDevice.WhiteBalanceTemperatureAndTintValues?) {
        settingView.set_ISO_current_Position(position: iso)
        settingView.set_whiteBalance_current_Position(temperature: whiteBalance?.temperature, tint: whiteBalance?.tint)
        
        if cameraPositionHolder == CameraPosition.FRONT {
            settingView.set_Auto_ISO_STATUS(status: front_ISO_AutoHolder)
            settingView.set_Auto_WB_Status(status: front_WB_AutoHolder)
        }else {
            settingView.set_Auto_ISO_STATUS(status: back_ISO_AutoHolder)
            settingView.set_Auto_WB_Status(status: back_WB_AutoHolder)
        }
    }
    
    /**
     
     Usage: Kamera değiştiğinde veya ilk açılırken kamera cihazından alınan bilgileri setting ayarlarına da haber verir. iso kamera ön veya arka da değiştiği zaman limitleri değişir. bunun için güncelleme şarttır.
     
     - Returns: No return value
     
     */
    private func cameraChangeConfiguration() {
        print("namik cameraChangeConfiguration")
        guard let camM = camManager else { return }
        let maxIso = camM.isoMaxValue
        let minIso = camM.isoMinValue
        camM.autoIso()
        settingView.set_ISO_limit(min: minIso, max: maxIso)
    }
    
    
//    MARK: - Button Event
    @IBAction func recordButtonEvent(_ sender: Any) {
        if (recordButton.isRecording) {
            startRecording()
        }else {
            stopRecording()
        }
    }
    
    fileprivate func startRecording() {
        UISetDesing = .CountDown
        recordStatusUpdate(status: RecordStatus.start)
        countDown.begin()
    }
    
    fileprivate func stopRecording() {
        guard let cam = camManager, let mediaMan = camMediaManager else { return }
        cam.stopRecordEvent()
        mediaMan.finish()
        self.recordButton.isUserInteractionEnabled = false
        UISetDesing = .Ready
        recordStatusUpdate(status: RecordStatus.stop)
    }
    
    
    @IBAction func changeCamera(_ sender: Any) {
        guard let camM = camManager else { return }
        camM.changeCamera()
        if (isFlipped) {
            DispatchQueue.main.async {
                
                UIView.transition(with: self.changeButton,
                                  duration: 0.5,
                                  options: UIView.AnimationOptions.transitionFlipFromRight,
                                  animations: {
                    
                }) { (act) in
                    self.isFlipped = false
                }
                
                UIView.transition(with: self.previewView,
                                  duration: 0.5,
                                  options: UIView.AnimationOptions.transitionFlipFromRight,
                                  animations: {
                    
                }) { (act) in
                    
                }
            }
        }else {
            DispatchQueue.main.async {
                UIView.transition(with: self.changeButton,
                                  duration: 0.5,
                                  options: UIView.AnimationOptions.transitionFlipFromLeft,
                                  animations: {
                    
                }) { (act) in
                    self.isFlipped = true
                }
                
                UIView.transition(with: self.previewView,
                                  duration: 0.5,
                                  options: UIView.AnimationOptions.transitionFlipFromLeft,
                                  animations: {
                                   
                }) { (act) in
                    self.isFlipped = true
                }
                
            }
        }
        
        
    }
    
    @IBAction func settingButtonEvent(_ sender: Any) {
        if settingView.isSettingPageStatus == .Close {
            settingView.settingPageShow(on: KayaCameraSettingView.SettingPageStatus.Open)
        }else {
            settingView.settingPageShow(on: KayaCameraSettingView.SettingPageStatus.Close)
        }
    }
    
    @IBAction func closeButtonEvent(_ sender: Any) {
        countDown.stopCountDown()
        setDelegate?.KayaCameraViewDelegate_CloseButtonEvent()
    }
    
    @IBAction func textButtonEvent(_ sender: Any) {
        guard let camMediaMan = camMediaManager else { return }
        camMediaMan.isHiddenSubtitle = textButton.isOn
    }
    
    @IBAction func soundButtonEvent(_ sender: Any) {
        guard let camMediaMan = camMediaManager else { return }
        camMediaMan.isVolumeStatus = soundButton.isOn
    }
    
    @IBAction func nextButtonEvent(_ sender: Any) {
        guard let camMediaMan = camMediaManager else { return }
        camMediaMan.nextDialog()
    }
    
    
//    MARK: - Trigger operation
    
    /**
     Usage: Uygulamada record işleminin başlatılmak istediğini haber verir.
     - Returns: No return value
     */
    func recordStatusUpdate(status:RecordStatus) {
        setDelegate?.KayaCameraViewdelegate_RecordStatus(recordStatus: status)
        switch status {
        case RecordStatus.start:
            recordStatusHolder = .start
            break
        case RecordStatus.stop:
            recordStatusHolder = .stop
            break
        }
    }
    
    
    
    
//    MARK: - UI change
    
    /// UIDesing enum üzerinden atamasının yapılması gerekiyor
    private var UISetDesing:UIDesing = UIDesing.Ready {
        didSet{
            switch UISetDesing {
            case .Ready:
                currentStepStatus = .Ready
                self.ReadyDesing()
                break
            case .Recording:
                currentStepStatus = .Recording
                self.RecordingDesing()
                break
            case .Stop:
                currentStepStatus = .Stop
                self.StopDesing()
                break
            case .Setting:
                currentStepStatus = .Setting
                self.SettingDesing()
                break
            case .CountDown:
                currentStepStatus = .CountDown
                self.CountDownDesing()
                break
            }
        }
    }
    
    var recordButtonTimer:Timer?

    @objc func startButtonTimer(){
        if recordButtonTimer != nil {
            recordButtonTimer?.invalidate()
            recordButtonTimer = nil
        }
        self.recordButton.isUserInteractionEnabled = true
    }
    
    private func ReadyDesing() {
        DispatchQueue.main.async {
            self.settingButton.alpha = 1
            self.settingButton.isUserInteractionEnabled = true
            
            self.changeButton.alpha = 1
            self.changeButton.isUserInteractionEnabled = true
            
            self.soundButton.alpha = 1
            self.soundButton.isHidden = false
            self.soundButton.isUserInteractionEnabled = true
            self.closeButton.isHidden = false
            
            if self.recordButtonTimer != nil {
                self.recordButtonTimer?.invalidate()
                self.recordButtonTimer = nil
            }
            
            self.recordButtonTimer = Timer.scheduledTimer(timeInterval: 1.5,
                                                          target: self,
                                                          selector: #selector(self.startButtonTimer),
                                                          userInfo: nil,
                                                          repeats: false)
            
            
            self.nextButton.isHidden = true
            if self.galleryStatus {
                self.galleryButton.isHidden = false
            }else {
                self.galleryButton.isHidden = true
            }
        }
    }
    
    private func CountDownDesing() {
        DispatchQueue.main.async {
            self.settingButton.alpha = 0.5
            self.settingButton.isUserInteractionEnabled = false
            
            self.changeButton.alpha = 0.5
            self.changeButton.isUserInteractionEnabled = false
            
            self.soundButton.alpha = 0.5
            self.soundButton.isUserInteractionEnabled = false
            self.soundButton.isHidden = false
            self.closeButton.isHidden = false
            
            self.recordButton.isUserInteractionEnabled = false
            
            self.nextButton.isHidden = true
            
            if self.galleryStatus {
                self.galleryButton.isHidden = true
            }else {
                self.galleryButton.isHidden = true
            }
        }
    }
    
    private func RecordingDesing() {
        DispatchQueue.main.async {
            self.settingButton.alpha = 1
            self.settingButton.isHidden = true
            self.settingButton.isUserInteractionEnabled = true
            
            self.changeButton.alpha = 1
            self.changeButton.isHidden = true
            self.changeButton.isUserInteractionEnabled = true
            
            self.soundButton.alpha = 1
            self.soundButton.isHidden = true
            self.soundButton.isUserInteractionEnabled = true
            self.closeButton.isHidden = true
            
            self.recordButton.isUserInteractionEnabled = true
            if self.galleryStatus {
                self.galleryButton.isHidden = true
            }else {
                self.galleryButton.isHidden = true
                
            }
        }
    }
    
    private func StopDesing() {
        DispatchQueue.main.async {
            self.settingButton.alpha = 1
            self.settingButton.isHidden = false
            self.settingButton.isUserInteractionEnabled = true
            
            self.changeButton.alpha = 1
            self.changeButton.isHidden = false
            self.changeButton.isUserInteractionEnabled = true
            
            self.soundButton.alpha = 1
            self.soundButton.isHidden = false
            self.soundButton.isUserInteractionEnabled = true
            self.closeButton.isHidden = false
            
            self.recordButton.isUserInteractionEnabled = true
            
            self.nextButton.isHidden = true
            if self.galleryStatus {
                self.galleryButton.isHidden = false
            }else {
                self.galleryButton.isHidden = true
                
            }
        }
    }
    
    func layerUpdate(of _view:UIView) {
        DispatchQueue.main.async {
            self.view.frame = _view.bounds
        }
    }
    
    private func SettingDesing() {
        DispatchQueue.main.async {
            
        }
    }
    
    var openSettingView = false {
        didSet {
            if openSettingView {
                self.recordButton.isUserInteractionEnabled = false
                self.changeButton.isUserInteractionEnabled = false
                UIView.animate(withDuration: 0.3) {
                    self.recordButton.alpha = 0.3
                    self.changeButton.alpha = 0.3
                }
            }else {
                self.recordButton.isUserInteractionEnabled = true
                self.changeButton.isUserInteractionEnabled = true
                UIView.animate(withDuration: 0.3) {
                    self.recordButton.alpha = 1
                    self.changeButton.alpha = 1
                }
            }
        }
    }
    
//    MARK: - Listener
    private func addListener() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.rotated),
                                               name: UIDevice.orientationDidChangeNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.appBackground),
                                               name: NSNotification.Name.KAYA_CAMERA_NOTIFICATION.APP_WILL_BACKGROUND,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.appActive),
                                               name: NSNotification.Name.KAYA_CAMERA_NOTIFICATION.APP_ACTIVE,
                                               object: nil)
    }
    
    private func removeListener() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func appBackground() {
        recordStatusUpdate(status: RecordStatus.stop)
        self.stopRecording()
        
    }
    
    @objc func appActive() {
        
    }
    
    @objc func rotated() {
        if recordButton.isRecording {
            return
        }
        
        guard let camM = camManager else { return }
        guard let mediaM = camMediaManager else { return }
        
        switch UIDevice.current.orientation {
        case .portrait:
            currentInterfaceOrientation = .portrait
            currentInterfaceMaskOrientation = .portrait
            camM.currentVideoOrientation = AVCaptureVideoOrientation.landscapeLeft
            mediaM.setDesing(orientation: KayaMediaManager.orientation.Vertical)
            currentVideoOrientation = AVCaptureVideoOrientation.portrait
            update_bottomViewContentContainer_gradientBackgronud()
            recordButtonPosition(orientation: .landscapeRight)
            settingView.layer.zPosition = 5
            print("\(self.TAG): cameraPos: portrait")
            break
        case .landscapeRight:
            currentInterfaceOrientation = .landscapeLeft
            currentInterfaceMaskOrientation = .landscapeLeft
            camM.currentVideoOrientation = AVCaptureVideoOrientation.landscapeRight
            mediaM.setDesing(orientation: KayaMediaManager.orientation.Horizontal)
            currentVideoOrientation = AVCaptureVideoOrientation.landscapeRight
            update_bottomViewContentContainer_gradientBackgronud()
            recordButtonPosition(orientation: .landscapeRight)
            settingView.layer.zPosition = 5
            print("\(self.TAG): cameraPos: right")
            break
        case .landscapeLeft:
            currentInterfaceOrientation = .landscapeRight
            currentInterfaceMaskOrientation = .landscapeRight
            mediaM.setDesing(orientation: KayaMediaManager.orientation.Horizontal)
            camM.currentVideoOrientation = AVCaptureVideoOrientation.landscapeLeft
            currentVideoOrientation = AVCaptureVideoOrientation.landscapeLeft
            update_bottomViewContentContainer_gradientBackgronud()
            recordButtonPosition(orientation: .landscapeLeft)
            settingView.layer.zPosition = 5
            print("\(self.TAG): cameraPos: landscapeLeft \(self.view.frame.width) - \(self.view.frame.height)")
            
            if !toolTipStartStatus && !UserPrefences.getCameraFirstLook()!{
                toolTipStart()
                UserPrefences.setCameraFirstLook(value: true)
            }
            break
        default:
            //Daha önce belirtilmiş bir yön yok ve yön kurallar dışında ise dik konumda başlattır.
            if currentVideoOrientation == nil {
               currentInterfaceOrientation = .landscapeLeft
                currentInterfaceMaskOrientation = .landscapeLeft
                camM.currentVideoOrientation = AVCaptureVideoOrientation.landscapeRight
                mediaM.setDesing(orientation: KayaMediaManager.orientation.Horizontal)
                currentVideoOrientation = AVCaptureVideoOrientation.landscapeRight
                update_bottomViewContentContainer_gradientBackgronud()
                recordButtonPosition(orientation: .landscapeRight)
                settingView.layer.zPosition = 5
            }
            print("\(self.TAG): cameraPos: default")
            break
        }
    }
    
    private func recordButtonPosition(orientation:  UIDeviceOrientation?) {
        guard let orientation = orientation else { return }
        switch orientation {
        case .portrait:
            recordButtonPositionHolder = .portrait
            recordButtonPortraitPosition()
            print("\(self.TAG): cameraPos:  recordButtonPosition : portrait")
            break
        case .landscapeRight:
            recordButtonPositionHolder = .landscapeRight
            recordButtonLandScapePosition()
            print("\(self.TAG): cameraPos:  recordButtonPosition : landscapeRight")
            break
        case .landscapeLeft:
            recordButtonPositionHolder = .landscapeLeft
            recordButtonLandScapePosition()
            print("\(self.TAG): cameraPos:  recordButtonPosition : landscapeLeft")
            break
        default:
            //Daha önce belirtilmiş bir yön yok ve yön kurallar dışında ise dik konumda başlattır.
            if currentVideoOrientation == nil {
                recordButtonLandScapePosition()
            }
            print("\(self.TAG): cameraPos:  recordButtonPosition : default")
            break
        }
        
    }
    
    var recordButtonPositionHolder:UIDeviceOrientation?
    private func recordButtonLandScapePosition() {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.2) {
                print("namik recordButtonLandScapePosition")
                self.recordButton.frame = CGRect(x: (self.contentContainer.frame.size.width - self.recordButton.frame.width) - 16,
                                                 y: (self.contentContainer.frame.size.height-self.recordButton.frame.size.height) / 2,
                                                 width: self.recordButton.frame.size.width,
                                                 height: self.recordButton.frame.size.height)
                self.setNeedsDisplay()
                self.setNeedsLayout()
            }
        }
    }
    
    private func recordButtonPortraitPosition() {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.2) {
                print("namik recordButtonPortraitPosition")
                self.recordButton.frame = CGRect(x: (self.contentContainer.frame.size.width - self.recordButton.frame.width) / 2,
                                                 y: (self.contentContainer.frame.size.height - self.recordButton.frame.size.height) - 16,
                                                 width: self.recordButton.frame.size.width,
                                                 height: self.recordButton.frame.size.height)
                self.setNeedsDisplay()
                self.setNeedsLayout()
            }
        }
    }
    
//    MARK: -  VIEW  - KayaCameraSettingView DELEGATE
    
    func KayaCameraManagerDelegate_Error() {
        setDelegate?.KayaCameraViewDelegate_Error()
    }
    
    func KayaCameraSettingView_changeISO(value: Float?) {
        guard let cam = camManager else { return  }
        guard let val = value else { return }
        cam.setIsoValue = val
    }
    
    func KayaCameraSettingView_changeWB(tempetureValue: Float?, tintValue: Float?) {
        guard let cam = camManager else { return  }
        guard let tempe = tempetureValue, let tint = tintValue else { return }
        cam.setWhiteBalanceValue(tempeture: tempe, tint: tint)
    }
    
    func KayaCameraSettingView_openSettingPage(status: Bool?) {
        guard let status = status else { return }
        openSettingView = status
    }
    
    func KayaCameraSettingView_WB_AUTO_STATUS(status: Bool) {
        guard let cam = camManager else { return }
        switch cameraPositionHolder {
        case .FRONT:
            front_WB_AutoHolder = status
            if (status) {
                cam.autoModeForCameraWhiteBalance()
            }
            break
        case .BACK:
            back_WB_AutoHolder = status
            if (status) {
                cam.autoModeForCameraWhiteBalance()
            }
            break
        default:
            break
        }
    }
    
    func KayaCameraSettingView_ISO_AUTO_STATUS(status: Bool) {
        guard let cam = camManager else { return }
        switch cameraPositionHolder {
        case .FRONT:
            front_ISO_AutoHolder = status
            if (status) {
                cam.autoIso()
            }
            break
        case .BACK:
            back_ISO_AutoHolder = status
            if (status) {
                cam.autoIso()
            }
            break
        default:
            break
        }
    }
    
//    MARK: - KayaCameraManager
    
    func KayaCameraManagerDelegate_ChangeCamera(cameraPosition: CameraPosition?,
                                                getCurrentIsoValue:Float?,
                                                getWhiteBalanceVaules: AVCaptureDevice.WhiteBalanceTemperatureAndTintValues?) {
        //cameraChangeConfiguration()
        cameraPositionHolder = cameraPosition
        cameraSettingConfiguration(iso: getCurrentIsoValue,
                                   whiteBalance: getWhiteBalanceVaules)
        
        setDelegate?.KayaCameraViewDelegate_ChangeCamera(cameraPosition:cameraPosition)
    }
    
    func KayaCameraManagerDelegate_VideoRecordStatus(status: VIDEO_RECORD_STATUS) {
        switch status {
        case .READY:
            //KayaAppUtility.lockOrientation(UIInterfaceOrientationMask.allButUpsideDown)
            changeButton.isHidden = false
            settingButton.isHidden = false
            soundButton.isHidden = false
            break
        case .FINISH:
            changeButton.isHidden = false
            settingButton.isHidden = false
            soundButton.isHidden = false
            nextButton.isHidden = true
            break
        case .RECORDING:
            settingButton.isHidden = true
            changeButton.isHidden = true
            soundButton.isHidden = true
            break
        default:
            changeButton.isHidden = false
            settingButton.isHidden = false
            soundButton.isHidden = false
            break
        }
    }
    
    func KayaCameraManagerDelegate_VideoOutPutExport(outputURL: URL?, originalImage: UIImage?, thumbnail: UIImage?) {
        //KayaAppUtility.lockOrientation(UIInterfaceOrientationMask.allButUpsideDown)
        UISetDesing = .Ready
        setDelegate?.KayaCameraViewDelegate_VideoOutPutExport(outputURL: outputURL, originalImage: originalImage, thumbnail: thumbnail)
    }
    
    
//    MARK: - KayaMediaManagerDelegate
    
    func KayaMediaManagerDelegate_finish() {
        guard let cam = camManager else { return }
        cam.stopRecordEvent()
        recordButton.activeButton(bool: false)
    }
    
    func KayaMediaManagerDelegate_NextButtonHidden(status: Bool) {
        nextButton.isHidden = status
    }
    
//    MARK: - KayaCountDownDelegate
    
    func KayaCountDownComplete() {
        guard let cam = camManager, let mediaMan = camMediaManager else { return }
        cam.startRecordEvent()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
            cam.startRecordEvent()
        })
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
            mediaMan.start()
        })
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: {
            self.UISetDesing = .Recording
        })
        
    }
    
    func KayaCountDownStart() {
        
    }
    
//    MARK: - FileManager fonksiyonları
    
    /// temp klasörünü temizler
    func clearTempFolder() {
        camFileManager?.clearTemp()
    }
//    MARK: - TOOLTIP
    var popTip:PopTip?
    var toolTipTimer:Timer?
    var toolTipArray:[toolTipModel] = []
    var toolTipCounter:Int = 0
    var toolTipStartStatus:Bool = false // bir kere başladıysa tekrar başlatmaması için gerekli
    private func toolTipStart() {
        toolTipStartStatus = true
        let subtitleToolTip = toolTipModel(toolTipText: "Altyazıyı kapatıp, açabilirsin",
                                           toolTipObject: textButton,
                                           direction: .right)
        
        let soundToolTip = toolTipModel(toolTipText: "Dış sesi kapatıp, açabilirsin",
                                        toolTipObject: soundButton,
                                        direction: .right)
        
        
        toolTipArray.append(subtitleToolTip)
        toolTipArray.append(soundToolTip)
       
        openToolTip()
        toolTipTimer = Timer.scheduledTimer(timeInterval: 5,
                                            target: self,
                                            selector: #selector(toolTipTimerEvent),
                                            userInfo: nil,
                                            repeats: true)
    }
    
    private func openToolTip() {
        if (toolTipCounter == toolTipArray.count) {
            if (toolTipTimer != nil) {
                toolTipTimer?.invalidate()
                toolTipTimer = nil
            }
            if popTip != nil {
                popTip?.hide()
                popTip = nil
            }
            return
        }
        
        if popTip != nil {
            popTip?.hide()
            popTip = nil
        }
        
        let object = toolTipArray[toolTipCounter].toolTipObject as? UIView
        popTip = PopTip()
        
        popTip!.bubbleColor = UIColor.black
        //popTip!.shouldDismissOnTap = true
        popTip!.actionAnimation = .bounce(16)
        popTip!.font = UIFont.systemFont(ofSize: 18, weight: UIFont.Weight.regular)//UIFont(name: "Avenir-Medium", size: 12)!
        popTip!.show(text: toolTipArray[toolTipCounter].toolTipText!,
                    direction: PopTipDirection.right,
                    maxWidth: 320,
                    in: bottomViewContentContainer,
                    from: object!.frame,
                    duration: 4)
       
        popTip!.tapHandler = { popTip in
            if (self.toolTipTimer != nil) {
                self.toolTipTimer?.invalidate()
                self.toolTipTimer = nil
            }
            if self.popTip != nil {
                self.popTip?.hide()
                self.popTip = nil
            }
            self.toolTipTimer = Timer.scheduledTimer(timeInterval: 5,
            target: self,
            selector: #selector(self.toolTipTimerEvent),
            userInfo: nil,
            repeats: true)
            self.openToolTip()
        }
        
        toolTipCounter += 1
    }
    
    private func toolTipFinish() {
        if (self.toolTipTimer != nil) {
            self.toolTipTimer?.invalidate()
            self.toolTipTimer = nil
        }
        if self.popTip != nil {
            self.popTip?.hide()
            self.popTip = nil
        }
    }
    
    @objc func toolTipTimerEvent() {
        openToolTip()
    }
    
}

