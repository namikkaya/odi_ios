//
//  kayaCameraManager.swift
//  videoMuteSystem_hub
//
//  Created by namikkaya on 13.11.2019.
//  Copyright © 2019 brokoly. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import Photos

enum VIDEO_RECORD_STATUS {
    /// hazırlanıyor
    case PREPARE
    /// HAZIR
    case READY
    /// KAYDEDİYOR
    case RECORDING
    /// KAYDETME BİTTİ
    case FINISH
    /// HATA
    case ERROR
}

protocol KayaCameraManagerDelegate:class {
    /**
    Usage: Kamera ön veya arka olarak değiştirildiğinde tetiklenir.
    
    - Parameter cameraPosition: ön veya arka kamera yı belirtir
    - Parameter getCurrentIsoValue: anlık iso değeri
    - Parameter getCurrentIsoValue: anlık  whitebalance tempeteru ve tint // renk ve sıcaklığı
    
    - Returns: No return value
    
    */
    func KayaCameraManagerDelegate_ChangeCamera(cameraPosition:CameraPosition?,
                                                getCurrentIsoValue:Float?,
                                                getWhiteBalanceVaules: AVCaptureDevice.WhiteBalanceTemperatureAndTintValues?)
    
    /**
     Usage: Video Record durumlarını belirtir.
     - Parameter status:  VIDEO_RECORD_STATUS:
     - Returns:
     */

    func KayaCameraManagerDelegate_VideoRecordStatus(status:VIDEO_RECORD_STATUS)
    
    /**
     Usage: Kaydedilen videonun çıkış yolu
     - Parameter outputURL:  video çıkış
     - Parameter originalImage: Video boyutu kadar image
     - Parameter thumbnail: küçük image
     */
    func KayaCameraManagerDelegate_VideoOutPutExport(outputURL:URL?, originalImage:UIImage?, thumbnail:UIImage?)
    
    /**
     Usage: Alınan hatanın kullanıcıya iletilmesi
     
    */
    func KayaCameraManagerDelegate_Error()
    
}

extension KayaCameraManagerDelegate {
    /**
     Usage: Kamera ön veya arka olarak değiştirildiğinde tetiklenir.
     
     - Parameter cameraPosition: ön veya arka kamera yı belirtir
     - Parameter getCurrentIsoValue: anlık iso değeri
     - Parameter getCurrentIsoValue: anlık  whitebalance tempeteru ve tint // renk ve sıcaklığı
     - Returns: No return value
     */
    func KayaCameraManagerDelegate_ChangeCamera(cameraPosition:CameraPosition?,
                                                getCurrentIsoValue:Float?,
                                                getWhiteBalanceVaules: AVCaptureDevice.WhiteBalanceTemperatureAndTintValues?){}
    
    /**
     Usage: Video Record durumlarını belirtir.
     - Parameter status:  VIDEO_RECORD_STATUS:
     - Returns:
     */
    func KayaCameraManagerDelegate_VideoRecordStatus(status:VIDEO_RECORD_STATUS) {}
    
    /**
     Usage: Kaydedilen videonun çıkış yolu
     - Parameter outputURL:  video çıkış
     */
    func KayaCameraManagerDelegate_VideoOutPutExport(outputURL:URL?, originalImage:UIImage?, thumbnail:UIImage?) {}
    
    /**
     Usage: Alınan hatanın kullanıcıya iletilmesi
    */
    func KayaCameraManagerDelegate_Error() {}
}

/// Ön veya Arka kamera ayarlar
enum CameraPosition {
    case FRONT
    case BACK
}

class KayaCameraManager: NSObject, AVCaptureFileOutputRecordingDelegate {

    let TAG:String = "KayaCameraManager:"
    weak var setDelegate:KayaCameraManagerDelegate?

    
//    MARK: - Object
    internal var previewView:UIView?
    
//    MARK: - variable Holder
    var waitTimer:Timer?
    var timerCounter:Int = 0
    
    /// video rotate ayarlarını tutar
    var currentVideoOrientation: AVCaptureVideoOrientation? {
        set {
            currentVideoOrientationHolder = newValue
            updateRotateVideo() // -> ::extensions
        }get {
            return currentVideoOrientationHolder
        }
    }
    
    var holderPoint:CGPoint?
    var myBalanceTimer:Timer?
//    - output
    internal var outputURL:URL?
    internal let movieOutput = AVCaptureMovieFileOutput()
    
//    MARK: - Class
    internal var captureSession:AVCaptureSession?
    internal var CameraPositionHolder:CameraPosition = .FRONT
    private var activeInput: AVCaptureDeviceInput?
    internal var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    internal var captureConnection:AVCaptureConnection?
    private var activeAudioInput: AVCaptureDeviceInput?
    
    private var currentVideoOrientationHolder: AVCaptureVideoOrientation? = AVCaptureVideoOrientation.landscapeLeft
    
    
//    -- init
    
    override init() {
        super.init()
    }
    
    func layerUpdate(of view:UIView) {
        DispatchQueue.main.async {
            self.previewView?.frame = view.bounds
        }
    }
    
    fileprivate func setCategory () {
        //let audioSession = AVAudioSession.sharedInstance()
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playAndRecord, options: [.mixWithOthers, .allowBluetooth, .defaultToSpeaker])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            NSLog("ERROR: CANNOT PLAY MUSIC IN BACKGROUND. Message from code: \"\(error)\"")
        }
    }
    
    init(preview previewView:UIView) {
        super.init()
        self.previewView = previewView
        cameraManagerConfiguration()
        //customRecordingConfig()
    }
    
    deinit {
        if waitTimer != nil {
            waitTimer?.invalidate()
            waitTimer = nil
        }
        
        if myBalanceTimer != nil {
            myBalanceTimer?.invalidate()
            myBalanceTimer = nil
        }
    }
    
    private func cameraManagerConfiguration() {
        cameraConfiguration()
        recordConfiguration()
        deviceConfiguration()
        audioConfiguration()
        configurationOutputURL() // url yolunu ayarlar
        self.startSession()
        startWaitTimer()
        setCategory()
        currentVideoOrientation = AVCaptureVideoOrientation.landscapeLeft
    }
    
    private func cameraConfiguration() {
        captureSession = AVCaptureSession()
        captureSession?.automaticallyConfiguresApplicationAudioSession = false
        let captureDevice:AVCaptureDevice? = getDevice(position: CameraPositionHolder)
        inputConfiguration(captureDevice: captureDevice)
    }
    
    private func inputConfiguration(captureDevice:AVCaptureDevice?) {
        self.getInputDevive(captureDevice: captureDevice) { (status:Bool?, input:AVCaptureDeviceInput?) in
            if let status = status {
                if status {
                    if let input = input {
                        activeInput = input
                        
                        if let session = captureSession, let orientation = convertOrientation(), let pView = self.previewView{
                            session.sessionPreset = AVCaptureSession.Preset.high
                            
                            if session.canAddInput(input) {
                                session.addInput(input)
                            }
                            
                            self.videoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
                            
                            if let pLayer = self.videoPreviewLayer {
                                pLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
                                pLayer.connection?.videoOrientation = AVCaptureVideoOrientation.landscapeRight//orientation
                                
                                
                                pLayer.frame = pView.frame
                                pView.layer.addSublayer(pLayer)
                                pView.setNeedsDisplay()
                            }
                                
                            if session.canAddOutput(movieOutput) {
                                session.addOutput(movieOutput)
                            }
                        }
                    }
                }else {
                    setDelegate?.KayaCameraManagerDelegate_Error()
                }
            }
        }
    }
    
    private func audioConfiguration() {
        if (activeAudioInput != nil) {
            if let session = captureSession {
                session.removeInput(activeAudioInput!)
            }
        }
        
        let microphone = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInMicrophone, for: AVMediaType.audio, position: AVCaptureDevice.Position.unspecified)
        
        self.getAudioInputDevice(captureDevice: microphone) { (status:Bool?, input:AVCaptureDeviceInput?) in
            if let status = status {
                if status {
                    if let input = input {
                        activeAudioInput = input
                        if let session = captureSession {
                            if session.canAddInput(input) {
                                session.addInput(input)
                            }
                        }
                        captureSession?.automaticallyConfiguresApplicationAudioSession = false
                    }
                }
            }
        }
    }
    
    
    private func recordConfiguration() {
        captureConnection = movieOutput.connection(with: AVMediaType.video)
        
        
        if let captureConnection = captureConnection {
            if (captureConnection.isVideoOrientationSupported) {
               if let orientation = convertOrientation() {
                    if CameraPositionHolder == .FRONT {
                        captureConnection.videoOrientation = .landscapeRight
                        print("Ön kamera: Ön kamera sağa ayarlı")
                    }else {
                        captureConnection.videoOrientation = orientation
                    }
                }
            }
            
            if (captureConnection.isVideoStabilizationSupported) {
                captureConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationMode.auto
            }
            
            if captureConnection.isVideoMirroringSupported {
                if CameraPositionHolder == CameraPosition.FRONT {
                    captureConnection.isVideoMirrored = true
                }else {
                    captureConnection.isVideoMirrored = false
                }
            }
            
        }
    }
    
    internal func resetRecordConfiguration() {
        captureConnection = nil
        recordConfiguration()
        captureSession?.automaticallyConfiguresApplicationAudioSession = false
    }
    
    /// cameranın özelliklerinin izin verdiklerine karar veren fonksiyon
    private func deviceConfiguration() {
        if let activeInput = activeInput {
            let device = activeInput.device
            
            if (device.isSmoothAutoFocusSupported) {
                do {
                    try device.lockForConfiguration()
                    device.isSmoothAutoFocusEnabled = false
                    device.unlockForConfiguration()
                } catch {
                    print("\(self.TAG): Error setting configuration:  \(error)")
                }
            }
            
            if (device.isFocusModeSupported(AVCaptureDevice.FocusMode.continuousAutoFocus)) {
                do {
                    try device.lockForConfiguration()
                    device.isSmoothAutoFocusEnabled = false
                    device.unlockForConfiguration()
                } catch {
                     print("\(self.TAG): Error setting configuration:  \(error)")
                }
            }
            
        }
    }
    
    /// video çıktı  dosyalarının ayarlandığı fonksiyon
    private func configurationOutputURL() {
        if let myFolder = KayaTempFolder() {
            let videoTempName = "\(Date().currentDayString()).mp4"
            outputURL = myFolder.appendingPathComponent(videoTempName)
        }
    }
    
    /**
     Usage: Kamera durumuna göre ayna efektinin uygulanıp uygulanmayacağı kararını verir.
     
     - Parameter NoParameter: no parameter
     
     - Returns: No return value
     */
    func changeCamera() {
        print("changeCamera Çağırıldı")
        // arka veya ön kamera pozisyon tutucusu değiştirilir.
        if (CameraPositionHolder == .FRONT) {
            CameraPositionHolder = .BACK
        }else {
            CameraPositionHolder = .FRONT
        }
        
        if let session = captureSession {
            session.beginConfiguration()
            
            if let inputs = session.inputs as? [AVCaptureDeviceInput] {
                for input in inputs {
                    session.removeInput(input)
                }
            }
        }
        
        let captureDevice:AVCaptureDevice? = getDevice(position: CameraPositionHolder)
        if let captureDevice = captureDevice {
           self.getInputDevive(captureDevice: captureDevice) { (status: Bool?, input:AVCaptureDeviceInput?) in
               if let status = status {
                   if status {
                       if let input = input {
                           if let captureSession = captureSession {
                                captureSession.addInput(input)
                                activeInput = input
                            
                                self.resetRecordConfiguration()
                                // kamera yönü değiştiğinde ayna efektinin uygulanıp uygulanmayacağı
                                if let captureConnection = captureConnection {
                                    if captureConnection.isVideoMirroringSupported {
                                        if CameraPositionHolder == CameraPosition.FRONT {
                                            captureConnection.isVideoMirrored = true
                                        }else {
                                            captureConnection.isVideoMirrored = false
                                        }
                                    }
                                }
                                //captureSession.automaticallyConfiguresApplicationAudioSession = false
                                //captureSession.commitConfiguration()
                                //startWaitTimer()
                            
                                // --
                                let microphone = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInMicrophone, for: AVMediaType.audio, position: AVCaptureDevice.Position.unspecified)
                                
                                self.getAudioInputDevice(captureDevice: microphone) { (status:Bool?, input:AVCaptureDeviceInput?) in
                                    if let status = status {
                                        if status {
                                            if let input = input {
                                                activeAudioInput = input
                                                
                                                if captureSession.canAddInput(input) {
                                                    captureSession.addInput(input)
                                                }
                                                
                                                captureSession.commitConfiguration()
                                                startWaitTimer()
                                            }
                                        }
                                    }
                                }
                                // -
                           }
                       }
                   }
               }
           }
            
            
        }
    
        
    }
    
    fileprivate func startWaitTimer() {
        stopWaitTimer()
        /// kameranın gecikmeli olarak bilgileri veriyor...
        waitTimer = Timer.scheduledTimer(timeInterval: 0.3,
                                         target: self,
                                         selector: #selector(delegateTrigger(t:)),
                                         userInfo: nil,
                                         repeats: true)
    }
    
    fileprivate func stopWaitTimer() {
        if (waitTimer != nil) {
            waitTimer?.invalidate()
            waitTimer = nil
            timerCounter = 0
        }
    }
    
    @objc func delegateTrigger(t:Timer?) {
        setDelegate?.KayaCameraManagerDelegate_ChangeCamera(cameraPosition: CameraPositionHolder,
                                                            getCurrentIsoValue: isoCurrentValue,
                                                            getWhiteBalanceVaules: getWhiteBalanceValues())
        timerCounter += 1
        if (timerCounter >= 15) {
            stopWaitTimer()
        }
    }
    
    
//    MARK: - Root class triggering operations
    internal func startRecordEvent() {
       
        guard let outputURL = outputURL else { return print("RECORD BAŞLATMA PROBLEMİ")}
        movieOutput.movieFragmentInterval = CMTime.invalid
        movieOutput.startRecording(to: outputURL, recordingDelegate: self)
        setDelegate?.KayaCameraManagerDelegate_VideoRecordStatus(status: VIDEO_RECORD_STATUS.RECORDING)
    }
    
    /**
     Usage:  Record durdurur.  fileOutput tetiklenir ve buna bağlı olarak KayaCameraManagerDelegate_VideoOutPutExport delegate tetiklenir. Event tetikler ve çıktı alınan dosyayı döndürür.
     */
    internal func stopRecordEvent() {
        if movieOutput.isRecording == true {
            movieOutput.stopRecording()
        }
    }
    
//    MARK: - Record Delegate
    
    // record işlemi bitirildiğinde tetiklenir...
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        setDelegate?.KayaCameraManagerDelegate_VideoRecordStatus(status: VIDEO_RECORD_STATUS.FINISH)
        if (error != nil) {
            
            print("HATA fileOutput f: \(error!.localizedDescription)")
            setDelegate?.KayaCameraManagerDelegate_VideoRecordStatus(status: VIDEO_RECORD_STATUS.ERROR)
            
        } else {
            guard let videoRecorded = outputURL else { return }
            let originalImage:UIImage? = thumbnailImageFor(fileUrl: videoRecorded)
            let thumbnail:UIImage? = resizeImage(image: originalImage, targetSize: CGSize(width: 120, height: 120))
            setDelegate?.KayaCameraManagerDelegate_VideoOutPutExport(outputURL: videoRecorded,
                                                                     originalImage: originalImage,
                                                                     thumbnail: thumbnail)
        }
    }
    
    func thumbnailImageFor(fileUrl:URL) -> UIImage? {
        let video = AVURLAsset(url: fileUrl, options: [:])
        let assetImgGenerate = AVAssetImageGenerator(asset: video)
        assetImgGenerate.appliesPreferredTrackTransform = true
        
        let videoDuration:CMTime = video.duration
        //let durationInSeconds:Float64 = CMTimeGetSeconds(videoDuration)
        
        let numerator = Int64(1)
        let denominator = videoDuration.timescale
        let time = CMTimeMake(value: numerator, timescale: denominator)
        
        do {
            let img = try assetImgGenerate.copyCGImage(at: time, actualTime: nil)
            let thumbnail = UIImage(cgImage: img)
            return thumbnail
        } catch {
            print(error)
            return nil
        }
    }
    
    func resizeImage(image: UIImage?, targetSize: CGSize) -> UIImage? {
        guard let image = image else { return nil }
        let size = image.size

        let widthRatio  = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height

        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }

        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage!
    }
    
    
    
//    MARK: - Camera Ayarları ----------------------------------------------------------------------------------------------
    func focusAndExpose(point:CGPoint) {
        //setAutoSettingAndManuel()
        setManuelSettingFix()
        
        let devicePointSet = self.videoPreviewLayer!.captureDevicePointConverted(fromLayerPoint: point)
        holderPoint = devicePointSet
        self.focusWithMode(.continuousAutoFocus,
                           exposeWithMode: .continuousAutoExposure,
                           atDevicePoint: devicePointSet,
                           monitorSubjectAreaChange: true)
        
        myBalanceTimer = Timer.scheduledTimer(timeInterval: 2,
                                              target: self,
                                              selector: #selector(balanceTimerEvent(timer:)),
                                              userInfo: nil,
                                              repeats: false)
    }
    
    @objc func balanceTimerEvent(timer:Timer?) {
        if (myBalanceTimer != nil) {
            myBalanceTimer?.invalidate()
            myBalanceTimer = nil
        }
        self.focusWithMode(.continuousAutoFocus,
                           exposeWithMode: .locked,
                           atDevicePoint: self.holderPoint!,
                           monitorSubjectAreaChange: true)
        print("focus kitlendi")
    }
    
//     --- FOCUS
    private func focusWithMode(_ focusMode: AVCaptureDevice.FocusMode, exposeWithMode exposureMode: AVCaptureDevice.ExposureMode, atDevicePoint point: CGPoint, monitorSubjectAreaChange: Bool) {
        guard let activeInput = activeInput else { return }
        let device = activeInput.device
        
        DispatchQueue.main.async {
            do {
                try device.lockForConfiguration()
                // Ayarlama (netleme / pozlama) Yalnızca PointOfInterest bir (netleme / pozlama) işlemi başlatmaz.
                // Çağrı Yapma (Odak / Pozlama) Modu: yeni ilgilenilen noktayı uygulamak için.
                if focusMode != .locked && device.isFocusPointOfInterestSupported && device.isFocusModeSupported(focusMode) {
                    device.focusPointOfInterest = point
                    device.focusMode = focusMode
                }
                
                if exposureMode != .custom && device.isExposurePointOfInterestSupported && device.isExposureModeSupported(exposureMode) {
                    device.exposurePointOfInterest = point
                    device.exposureMode = exposureMode
                }
                
                device.isSubjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
                device.unlockForConfiguration()
            } catch let error {
                NSLog("Could not lock device for configuration: \(error)")
            }
        }
        
    }
    
//     --- whitebalance ayarları
    
    var whiteBalanceMaxGain:Float? {
        get{
            guard let activeInput = activeInput else {return nil}
            let device = activeInput.device
            if device.isWhiteBalanceModeSupported(AVCaptureDevice.WhiteBalanceMode.locked) {
                return device.maxWhiteBalanceGain
            }
            return nil
        }
    }
    
    /**
     Usage: Manuel olarak wb ayarlarını yapar
     - Parameter tempeture:  Işık rengi
     - Parameter tint:  Işık renk sıcaklığı
     - Returns: No return value
     */
    func setWhiteBalanceValue(tempeture:Float?, tint:Float?) {
        guard let activeInput = activeInput else { return }
        let device = activeInput.device
        
        if (device.isWhiteBalanceModeSupported(AVCaptureDevice.WhiteBalanceMode.locked)) {
            device.unlockForConfiguration()
            
            let temperatureAndTint = AVCaptureDevice.WhiteBalanceTemperatureAndTintValues(
                temperature: tempeture!,
                tint: tint!
            )
            stopWaitTimer() // otomatik çeken timer stop edeliyor
            setWhiteBalanceGains(device.deviceWhiteBalanceGains(for: temperatureAndTint))
        }
    }
    
    /// WhiteBalance - Beyazlık ve ton ayarlarını döndürür. temperature ve tint  döndürür.
    public func getWhiteBalanceValues()->AVCaptureDevice.WhiteBalanceTemperatureAndTintValues? {
        guard let activeInput = activeInput else { return nil }
        let device = activeInput.device
        let whiteBalanceGains = device.deviceWhiteBalanceGains
        let whiteBalanceTemperatureAndTint = device.temperatureAndTintValues(for: whiteBalanceGains)
        return whiteBalanceTemperatureAndTint
    }
    
    /// Camera whitebalance ayarlarını otomatik olarak dönüştürür.
    public func autoModeForCameraWhiteBalance() {
        guard let activeInput = self.activeInput else { return }
        let device = activeInput.device
        if device.isWhiteBalanceModeSupported(AVCaptureDevice.WhiteBalanceMode.continuousAutoWhiteBalance) {
            do {
                try device.lockForConfiguration()
                device.whiteBalanceMode = .continuousAutoWhiteBalance
                device.unlockForConfiguration()
            } catch let err {
                print("\(self.TAG): setDefaultSetting: ok \(err)")
            }
            startWaitTimer()
        }
    }
    
    
    /// Ayar fonksiyonu white balance ayarlarının atamasını otomatize eder.
    private func setWhiteBalanceGains(_ gains: AVCaptureDevice.WhiteBalanceGains) {
        guard let activeInput = activeInput else { return }
        let device = activeInput.device
        do {
            try device.lockForConfiguration()
            let normalizedGains = self.normalizedGains(activeInput, gains)
            if let gains = normalizedGains {
                device.setWhiteBalanceModeLocked(with: gains, completionHandler: nil)
            }
            device.unlockForConfiguration()
        } catch let error {
            NSLog("setWihteBalanceGains fonksiyon hatası: \(error)")
        }
    }
    
//  ISO ayarları
    private var autoIsoStatusHolder: Bool = true
    /// iso ayarlarının otomatik te veya manuel ayarda olduğu bilgisini döndürür veya yazar.
    var autoIsoStatus:Bool {
        set {
            autoIsoStatusHolder = newValue
        }get {
            return autoIsoStatusHolder
        }
    }
    
    /// iso desteklenen minimum değerini döndürür
    var isoMinValue:Float? {
        get{
            guard let activeInput = activeInput else {return nil}
            let device = activeInput.device
            let value = device.activeFormat.minISO
            return value
        }
    }
    /// iso desteklenen maximum değerini döndürür
    var isoMaxValue:Float? {
        get{
            guard let activeInput = activeInput else {return nil}
            let device = activeInput.device
            let value = device.activeFormat.maxISO
            return value
        }
    }
    
    /// isonun anlık değirini döndürür.
    var isoCurrentValue:Float?{
        get{
            guard let activeInput = activeInput else {return nil}
            let device = activeInput.device
            
            if (device.isExposureModeSupported(AVCaptureDevice.ExposureMode.custom)) {
                let value = device.iso
                return value
            }
            return nil
        }
    }
    
    /// otomatik iso ayarı yaptırır.
    func autoIso() {
        guard let activeInput = activeInput else {return}
        let device = activeInput.device
        do {
            try device.lockForConfiguration()
            device.exposureMode = .continuousAutoExposure
            autoIsoStatus = true
            device.unlockForConfiguration()
        } catch let error {
            print("\(TAG): setIsoValue: error=> \(error)")
        }
        
        startWaitTimer()
    }
    
    /// manuel iso ayarı yaptırır.
    var setIsoValue:Float = 0 {
        didSet {
            guard let activeInput = activeInput else {return}
            let device = activeInput.device
            do {
                try device.lockForConfiguration()
                device.exposureMode = .custom
                device.setExposureModeCustom(duration: AVCaptureDevice.currentExposureDuration, iso: setIsoValue, completionHandler: nil)
                autoIsoStatus = false
                device.unlockForConfiguration()
            } catch let error {
                print("\(TAG): setIsoValue: error=> \(error)")
            }
        }
    }
    
    func setManuelSettingFix() {
        DispatchQueue.main.async {
            guard let activeInput = self.activeInput else { return }
            let device = activeInput.device
            if (device.isWhiteBalanceModeSupported(AVCaptureDevice.WhiteBalanceMode.continuousAutoWhiteBalance)) {
                do {
                    try device.lockForConfiguration()
                    device.whiteBalanceMode = .continuousAutoWhiteBalance
                    let val = self.getWhiteBalanceValues()
                    if val != nil {
                        self.setWhiteBalanceGains(device.deviceWhiteBalanceGains(for: val!))
                    }
                } catch let err {
                    print("\(self.TAG): setDefaultSetting: ok \(err)")
                }
                
            }
        }
        
    }
    
   
}
