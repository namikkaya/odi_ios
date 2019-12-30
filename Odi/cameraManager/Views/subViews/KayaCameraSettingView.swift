//
//  KayaCameraSettingView.swift
//  videoMuteSystem_hub
//
//  Created by Nok Danışmanlık on 15.11.2019.
//  Copyright © 2019 brokoly. All rights reserved.
//

import UIKit


protocol KayaCameraSettingViewDelegate:class {
    /// iso yani ışık ayarı 0-1 arası değer gönderir.
    func KayaCameraSettingView_changeISO(value:Float?)
    /// white balance ayarları tempeture ve tint beraber gelir
    func KayaCameraSettingView_changeWB(tempetureValue:Float?, tintValue:Float?)
    /// setting sayfasının açılıp kapanmasına göre bilgi gönderir
    func KayaCameraSettingView_openSettingPage(status:Bool?)
    /// iso otomatik veya manuel olduğu zaman tetiklenir.
    func KayaCameraSettingView_ISO_AUTO_STATUS(status:Bool)
    /// whitebalance otomatik veya manuel olduğu zaman
    func KayaCameraSettingView_WB_AUTO_STATUS(status:Bool)
}

extension KayaCameraSettingViewDelegate {
    /// iso yani ışık ayarı 0-1 arası değer gönderir.
    func KayaCameraSettingView_changeISO(value:Float?) { }
    /// white balance ayarları tempeture ve tint beraber gelir
    func KayaCameraSettingView_changeWB(tempetureValue:Float?, tintValue:Float?) { }
    /// setting sayfasının açılıp kapanmasına göre bilgi gönderir
    func KayaCameraSettingView_openSettingPage(status:Bool?) {}
    /// iso otomatik veya manuel olduğu zaman tetiklenir.
    func KayaCameraSettingView_ISO_AUTO_STATUS(status:Bool) {}
    /// whitebalance otomatik veya manuel olduğu zaman
    func KayaCameraSettingView_WB_AUTO_STATUS(status:Bool) {}
}


@IBDesignable
class KayaCameraSettingView: UIView {
    
//    MARK: - External Set Data
    
    private var WBHiddenStatus:Bool? = false
    var WBHidden:Bool? {
        set{
            WBHiddenStatus = newValue
            guard let value = newValue else { return }
            whiteBalanceButton.isHidden = value
            whiteBalanceContentContainer.isHidden = value
            palletteButton.isHidden = value
            palletteContentContainer.isHidden = value
        }get{
            return WBHiddenStatus
        }
    }
    
    private var ISOHiddenStatus:Bool? = false
    var ISOHidden:Bool? {
        set {
            ISOHiddenStatus = newValue
            guard let value = newValue else { return }
            lightButton.isHidden = value
            lightContentContainer.isHidden = value
        }get {
            return ISOHiddenStatus
        }
    }
    
    private var lightHolder:Float?
    /// ISO / ışık ayarı set edilecek
    var setLight: Float? {
        set {
            lightHolder = newValue
        }get {
            return lightHolder
        }
    }
    
    private var whiteBalanceHolder:Float?
    /// beyazlık ayarları set edilir
    var setWhiteBalance:Float? {
        set {
            whiteBalanceHolder = newValue
        }get {
            return whiteBalanceHolder
        }
    }
    
    private var setPalletteHolder:Float?
    /// Ton /  tint ayarları set edilir
    var setPallette:Float? {
        set {
            setPalletteHolder = newValue
        }get {
            return setPalletteHolder
        }
    }
    
//    MARK: - constant
    let slideButtonAnimationDuration:Double = 0.2
    
//    MARK: ENUM
    enum SettingPageStatus {
        case Open
        case Close
    }
    
    enum OpenSettingSlideStatus {
        case light
        case whiteBalance
        case pallette
    }
    
//    MARK: - Delegate
    weak var setDelegate:KayaCameraSettingViewDelegate?
    
//    MARK: - Kurucu objeler
    private var view:UIView!
    private var nibName:String = "KayaCameraSettingView"
    
//    MARK: - Object
    
    @IBOutlet var lightButton: UIButton!
    @IBOutlet var whiteBalanceButton: UIButton!
    @IBOutlet var palletteButton: UIButton!
    
    @IBOutlet var lightContentContainer: UIView!
    @IBOutlet var whiteBalanceContentContainer: UIView!
    @IBOutlet var palletteContentContainer: UIView!
    @IBOutlet var lightContentView: UIView!
    @IBOutlet var whiteBlanceContentView: UIView!
    @IBOutlet var palletteContentView: UIView!
    
    @IBOutlet var lightAutoButton: kayaToogleButton!
    @IBOutlet var whiteBalanceAutoButton: kayaToogleButton!
    @IBOutlet var palletteAutoButton: kayaToogleButton!
    
    @IBOutlet var lightSlider: UISlider!
    @IBOutlet var whiteBalanceSlider: UISlider!
    @IBOutlet var palletteSlider: UISlider!
    
    /// otomatik ışık ayarı değiştirildiğinde
    var lightAutoStatus:Bool = true {
        didSet {
            if lightAutoStatus {
                lightAutoButton.isEnabled = false
                lightAutoButton.activeButton(bool: true)
            }else {
                lightAutoButton.isEnabled = true
                lightAutoButton.activeButton(bool: false)
            }
            setDelegate?.KayaCameraSettingView_ISO_AUTO_STATUS(status: lightAutoStatus)
        }
    }
    
    /// otomatik whitebalance ayarı değiştirildiğinde
    var whiteBalanceAutoStatus:Bool = true {
        didSet {
            if whiteBalanceAutoStatus {
                whiteBalanceAutoButton.isEnabled = false
                whiteBalanceAutoButton.activeButton(bool: true)
            }else {
                whiteBalanceAutoButton.isEnabled = true
                whiteBalanceAutoButton.activeButton(bool: false)
            }
            setDelegate?.KayaCameraSettingView_WB_AUTO_STATUS(status: whiteBalanceAutoStatus)
        }
    }
    
    /// pallette ayarı değiştirildiğinde
    var palletteAutoStatus:Bool = true {
        didSet {
            if palletteAutoStatus {
                palletteAutoButton.isEnabled = false
                palletteAutoButton.activeButton(bool: true)
            }else {
                palletteAutoButton.isEnabled = true
                palletteAutoButton.activeButton(bool: false)
            }
            setDelegate?.KayaCameraSettingView_WB_AUTO_STATUS(status: palletteAutoStatus)
        }
    }
    
    var palletteButtonPositionHolder:CGRect?
    var whiteBalanceButtonPositionHolder:CGRect?
    var lightButtonPositionHolder:CGRect?
    
    var lightContentViewPositionHolder:CGRect?
    var whiteBalanceContentViewPositionHolder:CGRect?
    var palletteContentViewPositionHolder:CGRect?
    
    private var isSettingPageStatusHolder:SettingPageStatus = .Close
    var isSettingPageStatus:SettingPageStatus {
        get {
            return isSettingPageStatusHolder
        }
    }
    
    private var openSlideHolder:OpenSettingSlideStatus?
    
    private var animationStatus:Bool = false
    
    
//    MARK: - initalize operation
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup(){
        view = loadViewFromNib()
        view.frame = bounds
        view.autoresizingMask = [UIView.AutoresizingMask.flexibleWidth,
                                 UIView.AutoresizingMask.flexibleHeight]
        addSubview(view)
        
        view.layer.masksToBounds = true
        
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(touchSelfView))
        self.addGestureRecognizer(gestureRecognizer)
        
        
        let gestureRecognizerWBCV = UITapGestureRecognizer(target: self, action: #selector(emptyTouchContainer))
        whiteBlanceContentView.addGestureRecognizer(gestureRecognizerWBCV)
        
        let gestureRecognizerlight = UITapGestureRecognizer(target: self, action: #selector(emptyTouchContainer))
        lightContentView.addGestureRecognizer(gestureRecognizerlight)
        
        let gestureRecognizerPall = UITapGestureRecognizer(target: self, action: #selector(emptyTouchContainer))
        palletteContentView.addGestureRecognizer(gestureRecognizerPall)
        
        
        
        // açık ama kullanıma kapalı şekilde başlat. otomatik ayarda.
        lightAutoButton.isEnabled = false
        whiteBalanceAutoButton.isEnabled = false
        palletteAutoButton.isEnabled = false
        
        UIConfiguration()
    }
    
    @objc func emptyTouchContainer() {
        
    }
    
    @objc func touchSelfView() {
        closeAnimation()
    }
    
    func loadViewFromNib()-> UIView {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: nibName, bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
        return view
    }
    
//    MARK: - configuration
    fileprivate func UIConfiguration() {
        self.isHidden = true
        DispatchQueue.main.async {
            self.palletteButton.layer.cornerRadius = self.palletteButton.frame.size.width / 2
            self.whiteBalanceButton.layer.cornerRadius = self.palletteButton.frame.size.width / 2
            self.lightButton.layer.cornerRadius = self.palletteButton.frame.size.width / 2
            
            self.lightContentView.layer.cornerRadius = self.lightContentView.frame.size.height/2
            self.whiteBlanceContentView.layer.cornerRadius = self.whiteBlanceContentView.frame.size.height/2
            self.palletteContentView.layer.cornerRadius = self.palletteContentView.frame.size.height/2
            self.lightContentContainer.layer.cornerRadius = self.lightContentContainer.frame.size.height/2
            self.whiteBalanceContentContainer.layer.cornerRadius = self.whiteBalanceContentContainer.frame.size.height/2
            self.palletteContentContainer.layer.cornerRadius = self.palletteContentContainer.frame.size.height/2
        }
        self.lightContentContainer.clipsToBounds = true
        self.whiteBalanceContentContainer.clipsToBounds = true
        self.palletteContentContainer.clipsToBounds = true
        
        palletteButtonPositionHolder = palletteButton.bounds
        whiteBalanceButtonPositionHolder = whiteBalanceButton.bounds
        lightButtonPositionHolder = lightButton.bounds
        
        lightContentViewPositionHolder = lightContentView.bounds
        whiteBalanceContentViewPositionHolder = whiteBlanceContentView.bounds
        palletteContentViewPositionHolder = palletteContentView.bounds
        
        UIView.animate(withDuration: 0) {
            self.lightButton.transform = CGAffineTransform(translationX: self.lightButton.bounds.origin.x,
                                                           y: self.frame.size.height - self.lightButton.frame.origin.y)
            self.whiteBalanceButton.transform = CGAffineTransform(translationX: self.whiteBalanceButton.bounds.origin.x,
                                                                  y: self.frame.size.height - self.whiteBalanceButton.frame.origin.y)
            self.palletteButton.transform = CGAffineTransform(translationX: self.palletteButton.bounds.origin.x,
                                                                  y: self.frame.size.height - self.palletteButton.frame.origin.y)
            
            self.lightContentView.transform = CGAffineTransform(translationX: self.lightContentView.frame.size.width, y: 0)
            self.whiteBlanceContentView.transform = CGAffineTransform(translationX: self.whiteBlanceContentView.frame.size.width, y: 0)
            self.palletteContentView.transform = CGAffineTransform(translationX: self.palletteContentView.frame.size.width, y: 0)
            self.view.layoutIfNeeded()
        }
    }
    
//    MARK: - Slider
    
    // max ve minimum değerler arasında set edilir.
    
    /**
     Usage: ISO kamera özelliğine göre max ve min iso değerlerini slider için alır
     - Parameter min: iso minimum değer
     - Parameter max: iso maximum değer
     - Returns: No return value
     */
    func set_ISO_limit (min:Float?, max:Float?) {
        guard let min = min, let max = max else { return }
        lightSlider.maximumValue = max
        lightSlider.minimumValue = min
    }
    
    /**
     Usage: Kameranın anlık ISO değerini slider için set eder
     - Parameter position: değer
     - Returns: No return value
     */
    func set_ISO_current_Position (position:Float?) {
        guard let position = position else { return }
        lightSlider.setValue(position, animated: true)
    }
    
    /**
     Usage: White balance ayarlarını slider için set eder
     - Parameter temperature:  ışık değeri
     - Parameter tint:  ışık sıcaklığı
     - Returns: No return value
     */
    func set_whiteBalance_current_Position(temperature:Float?, tint:Float?) {
        guard let temperature = temperature, let tint = tint else { return }
        whiteBalanceSlider.setValue(temperature, animated: true)
        palletteSlider.setValue(tint, animated: true)
    }
    
    /**
    Usage: Iso ayarları otomatik veya manuel ise Auto button için değer alır
    - Parameter status:  iso otomatik veya değel true/ false
    - Returns: No return value
    */
    func set_Auto_ISO_STATUS (status: Bool?) {
        guard let status = status else { return }
        lightAutoButton.activeButton(bool: status)
    }
    /**
    Usage: whitebalance ayarları otomatik veya manuel ise Auto button için değer alır
    - Parameter status:  wb otomatik veya değel true/ false
    - Returns: No return value
    */
    func set_Auto_WB_Status (status:Bool?) {
        guard let status = status else { return }
        whiteBalanceAutoButton.activeButton(bool: status)
        palletteAutoButton.activeButton(bool: status)
    }
    
    @IBAction func lightSliderEvent(_ sender: UISlider) {
        let sliderValue = sender.value
        setLight = sliderValue
        
        if lightAutoStatus {
            lightAutoStatus = false
        }
        setDelegate?.KayaCameraSettingView_changeISO(value: sliderValue)
    }
    
    @IBAction func whiteBalanceSliderEvent(_ sender: UISlider) {
        let sliderValue = sender.value
        let tempeture = sliderValue
        let tint = palletteSlider.value
        
        if whiteBalanceAutoStatus {
            whiteBalanceAutoStatus = false
            palletteAutoStatus = false
        }
        
        setDelegate?.KayaCameraSettingView_changeWB(tempetureValue: tempeture, tintValue: tint)
    }
    
    @IBAction func palletteSliderEvent(_ sender: UISlider) {
        let sliderValue = sender.value
        let tempeture = whiteBalanceSlider.value
        let tint = sliderValue
        
        if palletteAutoStatus {
            whiteBalanceAutoStatus = false
            palletteAutoStatus = false
        }
        
        setDelegate?.KayaCameraSettingView_changeWB(tempetureValue: tempeture, tintValue: tint)
    }
    
//    MARK: - Button Event Trigger
    @IBAction func lightAutoButtonEvent(_ sender: Any) {
        lightAutoStatus = true
    }
    
    @IBAction func whiteBalanceAutoButtonEvent(_ sender: Any) {
        whiteBalanceAutoStatus = true
        palletteAutoStatus = true
    }
    
    @IBAction func palletteAutoButtonEvent(_ sender: Any) {
        palletteAutoStatus = true
        whiteBalanceAutoStatus = true
    }
    
    @IBAction func palletteButtonEvent(_ sender: Any) {
        if openSlideHolder == KayaCameraSettingView.OpenSettingSlideStatus.pallette {
            slideButtonAnimation(status: false, objectStatus: KayaCameraSettingView.OpenSettingSlideStatus.pallette)
        }else {
            slideButtonAnimation(status: true, objectStatus: KayaCameraSettingView.OpenSettingSlideStatus.pallette)
        }
    }
    
    @IBAction func whiteBallanceButtonEvent(_ sender: Any) {
        if openSlideHolder == KayaCameraSettingView.OpenSettingSlideStatus.whiteBalance {
            slideButtonAnimation(status: false, objectStatus: KayaCameraSettingView.OpenSettingSlideStatus.whiteBalance)
        }else {
            slideButtonAnimation(status: true, objectStatus: KayaCameraSettingView.OpenSettingSlideStatus.whiteBalance)
        }
    }
    
    @IBAction func lightButtonEvent(_ sender: Any) {
        if openSlideHolder == KayaCameraSettingView.OpenSettingSlideStatus.light {
            slideButtonAnimation(status: false, objectStatus: KayaCameraSettingView.OpenSettingSlideStatus.light)
        }else {
            slideButtonAnimation(status: true, objectStatus: KayaCameraSettingView.OpenSettingSlideStatus.light)
        }
    }
    
    private func slideButtonAnimation(status:Bool, objectStatus: OpenSettingSlideStatus) {
        // eğer açık başka bir slide var ise onu kapatır
        if (openSlideHolder != nil) {
            switch openSlideHolder {
            case .light:
                slideButtonClose(object: lightContentView)
                break
            case .pallette:
                slideButtonClose(object: palletteContentView)
                break
            case .whiteBalance:
                slideButtonClose(object: whiteBlanceContentView)
                break
            case .none:
                
                break
            }
        }
        
        switch objectStatus {
        case .light:
            if status {
                slideButtonOpen(object: lightContentView, defaultPosition: lightContentViewPositionHolder!)
                openSlideHolder = objectStatus
                
            }else {
                slideButtonClose(object: lightContentView)
                openSlideHolder = nil
            }
            break
        case .pallette:
            if status {
                slideButtonOpen(object: palletteContentView, defaultPosition: palletteContentViewPositionHolder!)
                openSlideHolder = objectStatus
            }else {
                slideButtonClose(object: palletteContentView)
                openSlideHolder = nil
            }
            break
        case .whiteBalance:
            if status {
                slideButtonOpen(object: whiteBlanceContentView, defaultPosition: whiteBalanceContentViewPositionHolder!)
                openSlideHolder = objectStatus
            }else {
                slideButtonClose(object: whiteBlanceContentView)
                openSlideHolder = nil
            }
            break
        }
    }
    
    private func slideButtonOpen(object:UIView, defaultPosition: CGRect){
        setSlideButtonImage(object: object, status: true)
        UIView.animate(withDuration: slideButtonAnimationDuration, delay: 0, options: [.curveEaseInOut], animations: {
            object.transform = CGAffineTransform(translationX: (defaultPosition.origin.x), y: (defaultPosition.origin.y))
            self.view.layoutIfNeeded()
        }) { (act) in
            
        }
    }
    
    private func slideButtonClose(object:UIView, finishCloseAnimationStatus:Bool = false) {
        setSlideButtonImage(object: object, status: false)
        UIView.animate(withDuration: slideButtonAnimationDuration, delay: 0, options: [.curveEaseInOut], animations: {
            object.transform = CGAffineTransform(translationX: object.frame.size.width, y: object.frame.origin.y)
            self.view.layoutIfNeeded()
        }) { (act) in
            if finishCloseAnimationStatus {
                self.finishCloseAnimation()
            }
        }
    }
    
    private func setSlideButtonImage(object:UIView, status:Bool) {
        switch object {
        case lightContentView:
            if status {
                lightButton.setImage(UIImage(named: "light_yellow"), for: UIControl.State.normal)
            }else {
                lightButton.setImage(UIImage(named: "light"), for: UIControl.State.normal)
            }
            break
        case whiteBlanceContentView:
            if status {
                whiteBalanceButton.setImage(UIImage(named: "whiteBalance_yellow"), for: UIControl.State.normal)
            }else {
                whiteBalanceButton.setImage(UIImage(named: "whiteBalance"), for: UIControl.State.normal)
            }
            break
        case palletteContentView:
            if status {
                palletteButton.setImage(UIImage(named: "palllette_yellow"), for: UIControl.State.normal)
            }else {
                palletteButton.setImage(UIImage(named: "pallette"), for: UIControl.State.normal)
            }
            break
        default:
            
            break
        }
    }
    
    private func buttonSetIcon(selected:Bool, objectStatus: OpenSettingSlideStatus) {
        switch objectStatus {
        case .light:
            if selected {
                
            }else {
                
            }
            break
        case .pallette:
            if selected {
                
            }else {
                
            }
            break
        case .whiteBalance:
            if selected {
                
            }else {
                
            }
            break
        }
    }
    
//    MARK: - Open Status
    
    func settingPageShow(on status: SettingPageStatus){
        switch status {
        case .Open:
            openAnimation()
            break
        case .Close:
            closeAnimation()
            break
        }
    }
    
    fileprivate func openAnimation() {
        if animationStatus {
            return
        }
        self.isHidden = false
        animationStatus = true
        isSettingPageStatusHolder = .Open
        
        if let wbHidden = WBHidden {
            if !wbHidden {
                UIView.animate(withDuration: 0.4, delay: 0, options: [.curveEaseInOut], animations: {
                    self.lightButton.transform = CGAffineTransform(translationX: self.lightButton.bounds.origin.x,
                    y: (self.lightButtonPositionHolder?.origin.y)!)
                    self.view.layoutIfNeeded()
                }) { (act) in
                    self.animationStatus = false
                    self.setDelegate?.KayaCameraSettingView_openSettingPage(status: true)
                }
                
                UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut], animations: {
                    self.whiteBalanceButton.transform = CGAffineTransform(translationX: self.whiteBalanceButton.bounds.origin.x,
                    y: (self.whiteBalanceButtonPositionHolder?.origin.y)!)
                    self.view.layoutIfNeeded()
                }) { (act) in
                    
                }
                
                UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseInOut], animations: {
                    self.palletteButton.transform = CGAffineTransform(translationX: self.palletteButton.bounds.origin.x,
                    y: (self.palletteButtonPositionHolder?.origin.y)!)
                    self.view.layoutIfNeeded()
                }) { (act) in
                    
                }
            }else {
                //print("setting wbHidden : true \(self.palletteButtonPositionHolder?.origin.y)")
                UIView.animate(withDuration: 0.4, delay: 0, options: [.curveEaseInOut], animations: {
                    self.lightButton.transform = CGAffineTransform(translationX: self.lightButton.bounds.origin.x, y: 100)
                    self.lightContentContainer.transform = CGAffineTransform(translationX: self.lightContentContainer.bounds.origin.x, y: 100)
                    self.view.layoutIfNeeded()
                }) { (act) in
                    self.animationStatus = false
                    self.setDelegate?.KayaCameraSettingView_openSettingPage(status: true)
                }
            }
        }
    }
    
    fileprivate func closeAnimation() {
        // ilk aşamada açık button slide var ise onu kapatır
        if (openSlideHolder != nil) {
            switch openSlideHolder {
            case .light:
                slideButtonClose(object: lightContentView, finishCloseAnimationStatus: true)
                break
            case .pallette:
                slideButtonClose(object: palletteContentView, finishCloseAnimationStatus: true)
                break
            case .whiteBalance:
                slideButtonClose(object: whiteBlanceContentView, finishCloseAnimationStatus: true)
                break
            case .none:
                
                break
            }
        }else {
            finishCloseAnimation()
        }
    }
    
    fileprivate func finishCloseAnimation() {
        openSlideHolder = nil
        if animationStatus {
            return
        }
        animationStatus = true
        isSettingPageStatusHolder = .Close
        
        if !WBHidden! {
            
            UIView.animate(withDuration: 0.4,
                           delay: 0,
                           options: [.curveEaseInOut],
                           animations: {
                self.lightButton.transform = CGAffineTransform(translationX: self.lightButton.bounds.origin.x,
                                                               y: self.frame.size.height - self.lightButton.frame.origin.y)
                self.view.layoutIfNeeded()
            }) { (act) in
                self.animationStatus = false
                self.isHidden = true
                self.setDelegate?.KayaCameraSettingView_openSettingPage(status: false)
            }
            
            UIView.animate(withDuration: 0.3,
                           delay: 0.07,
                           options: [.curveEaseInOut],
                           animations: {
                self.whiteBalanceButton.transform = CGAffineTransform(translationX: self.whiteBalanceButton.bounds.origin.x,
                                                                      y: self.frame.size.height - self.whiteBalanceButton.frame.origin.y)
                self.view.layoutIfNeeded()
            }) { (act) in
                
            }
            
            UIView.animate(withDuration: 0.4,
                           delay: 0.08,
                           options: [.curveEaseInOut],
                           animations: {
                self.palletteButton.transform = CGAffineTransform(translationX: self.palletteButton.bounds.origin.x,
                                                                  y: self.frame.size.height - self.palletteButton.frame.origin.y)
                self.view.layoutIfNeeded()
            }) { (act) in
                
            }
            
        }else {
            
            UIView.animate(withDuration: 0.4,
                           delay: 0,
                           options: [.curveEaseInOut],
                           animations: {
                self.lightButton.transform = CGAffineTransform(translationX: self.lightButton.bounds.origin.x,
                                                               y: self.frame.size.height - self.lightButton.frame.origin.y)
                self.view.layoutIfNeeded()
            }) { (act) in
                self.animationStatus = false
                self.isHidden = true
                self.setDelegate?.KayaCameraSettingView_openSettingPage(status: false)
            }
        }
        
        
        // eski
        /*
        UIView.animate(withDuration: 0.4,
                       delay: 0,
                       options: [.curveEaseInOut],
                       animations: {
            self.lightButton.transform = CGAffineTransform(translationX: self.lightButton.bounds.origin.x,
                                                           y: self.frame.size.height - self.lightButton.frame.origin.y)
            self.view.layoutIfNeeded()
        }) { (act) in
            self.animationStatus = false
            self.isHidden = true
            self.setDelegate?.KayaCameraSettingView_openSettingPage(status: false)
        }
        
        UIView.animate(withDuration: 0.3,
                       delay: 0.07,
                       options: [.curveEaseInOut],
                       animations: {
            self.whiteBalanceButton.transform = CGAffineTransform(translationX: self.whiteBalanceButton.bounds.origin.x,
                                                                  y: self.frame.size.height - self.whiteBalanceButton.frame.origin.y)
            self.view.layoutIfNeeded()
        }) { (act) in
            
        }
        
        UIView.animate(withDuration: 0.4,
                       delay: 0.08,
                       options: [.curveEaseInOut],
                       animations: {
            self.palletteButton.transform = CGAffineTransform(translationX: self.palletteButton.bounds.origin.x,
                                                              y: self.frame.size.height - self.palletteButton.frame.origin.y)
            self.view.layoutIfNeeded()
        }) { (act) in
            
        }
 */
    }
    
}
