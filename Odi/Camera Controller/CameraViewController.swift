//
//  ViewController.swift
//  OdiCameraTutorial
//
//  Created by Baran on 15.12.2017.
//  Copyright © 2017 CodingMind. All rights reserved.
//

import UIKit
import Photos
import AVFoundation
import AVKit
import QuartzCore
import CoreGraphics
import CoreText
import AMPopTip

enum PAGESTATUS {
    case Camera
    case Gallery
}


class CameraViewController: BaseViewController {
    
    var TAG:String = "CameraViewController: "
    var vcHolder:UIViewController?
    private var firstStart:Bool = false
    
    private var commpressStatus:Bool = false
    
    var VideoConnection : AVCaptureConnection? // yeni oluşturuduk....
    
    var frontDeviceCurrentOrientation:AVCaptureVideoOrientation?
    var backDeviceCurrentOrientation:AVCaptureVideoOrientation?
    
    private var dbManager:kayaDbManager?
    
    //@IBOutlet var galleryButton: UIButton!
    @IBOutlet var galleryButton: UIImageView!
    
    let transitionManager = galleryTransitionManager()
    
    private func openGalleryController() {
        dbManager?.getVideoByProjectId(projectId: self.odileData.videoId , onSuccess: { (status, data:[videoModel]?) in
            if let data = data {
                if (data.count < 1) {
                    DispatchQueue.main.async {
                        self.galleryButton.isHidden = true
                    }
                }else {
                    print("\(self.TAG): dataÇözüm: galleri sayfasına göndericek")

                    let vc = self.storyboard?.instantiateViewController(withIdentifier: "galleryVC") as! galleryViewController
                    vc.collectionData = data
                    vc.onCallback = self.galleryCallBack(_:_:)
                    vc.modalPresentationStyle = .overFullScreen
                    vc.transitioningDelegate = self.transitionManager
                    self.navigationController?.present(vc, animated: true, completion: nil)
                }
            }
            
        }, onFailure: { (error:Error?) in
            
        })
    }
    
    func playViewControllerCallback(_ status:Bool?) -> () {
        
        dbManager?.getVideoByProjectId(projectId: self.odileData.videoId , onSuccess: { (status, data:[videoModel]?) in
            if let data = data {
                if (data.count < 1) {
                    DispatchQueue.main.async {
                        self.galleryButton.isHidden = true
                    }
                }else {
                    DispatchQueue.main.async {
                        let myData:[videoModel] = data.reversed()
                        let thumb = self.load(fileName: myData[0].thumbPath!)
                        self.galleryButton.isHidden = false
                        
                        self.galleryButton.image = thumb
                        self.galleryButton.contentMode = .scaleAspectFill
                        self.galleryButton.layer.cornerRadius = 5
                        self.galleryButton.layer.masksToBounds = true
                        //self.galleryButton.clipsToBounds = true
                    }
                }
            }
            
        }, onFailure: { (error:Error?) in
            
        })
    }
    
    // callback dönüşü
    func galleryCallBack(_ gotoPlayView:Bool?,_ dataModel:videoModel?) -> () {
        if let gotoPlayView = gotoPlayView, let dataModel = dataModel {
            
            if (gotoPlayView) {
                let temp = videoFolder?.appendingPathComponent(dataModel.videoPath!)
                let filePath = temp!.path
                self.uploadData["filePath"] = filePath as AnyObject
                self.uploadData["videoURL"] = temp as AnyObject
                self.uploadData["userId"] = self.odileData.userId  as AnyObject
                self.uploadData["videoId"] = self.odileData.videoId as AnyObject
                self.uploadData["isNotFinishedCapture"] = self.isNotFinishedCapture as AnyObject
                self.uploadData["pageStatus"] = PAGESTATUS.Gallery as AnyObject
                self.uploadData["callBackCamera"] = playViewControllerCallback(_:) as AnyObject
                self.uploadData["cameraStatus"] = isFrontCamera as AnyObject
                self.goto(screenID: "PlayVideoControllerID", animated: true, data: self.uploadData as AnyObject, isModal: true)
            }
        }
        
        // gallery icon knotrol ettir
        dbManager?.getVideoByProjectId(projectId: self.odileData.videoId , onSuccess: { (status, data:[videoModel]?) in
            if let data = data {
                if (data.count < 1) {
                    DispatchQueue.main.async {
                        self.galleryButton.isHidden = true
                    }
                }else {
                    DispatchQueue.main.async {
                        let myData:[videoModel] = data.reversed()
                        let thumb = self.load(fileName: myData[0].thumbPath!)
                        self.galleryButton.isHidden = false
                        
                        self.galleryButton.image = thumb
                        self.galleryButton.contentMode = .scaleAspectFill
                        self.galleryButton.layer.cornerRadius = 5
                        self.galleryButton.layer.masksToBounds = true
                        //self.galleryButton.clipsToBounds = true
                    }
                }
            }
            
        }, onFailure: { (error:Error?) in
            
        })
    }
    
    private func load(fileName: String) -> UIImage? {
        let fileURL = videoFolder!.appendingPathComponent(fileName)
        do {
            let imageData = try Data(contentsOf: fileURL!)
            return UIImage(data: imageData)
        } catch {
            print("Error loading image : \(error)")
        }
        return nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.shared.isIdleTimerDisabled = true
        
        galleryButton.layer.cornerRadius = 5
        //galleryButton.clipsToBounds = true
        
        dbManager = kayaDbManager.sharedInstance
        
        toastMessageBG.layer.cornerRadius = toastMessageBG.frame.height / 2
        toastMessageBG.layer.masksToBounds = true
        
        AppUtility.lockOrientation(.landscapeRight)
        addObserverForOdi()
        
        //Mark :- Download mp3 file
        if odiResponseModel.TIP != "1" {
            DispatchQueue.main.async {
                self.popupController = self.SHOW_SIC(type: .reload)
                self.downloadFile(Response: self.odiResponseModel.cameraList, downloadedCound: 0)
            }
        } else {
            self.goto(screenID: "TurnPhoneSplashVCID", animated: false, data: nil, isModal: true)
        }
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action:#selector(imageTapped(tapGestureRecognizer:)))
        galleryButton.isUserInteractionEnabled = true
        galleryButton.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        let _ = tapGestureRecognizer.view as! UIImageView
        openGalleryController()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print("Camera: viewDidDisappear")
        UIApplication.shared.isIdleTimerDisabled = false
        firstStart = false;
        
    }
    
    // yeni sistem temp folder temizleme
    private func clearTemp() {
        print("\(self.TAG): clearTemp")
        dbManager?.clearTempFile() // tempFolder temizler
    }
    
    
    func downloadFile(Response getCameraList:[GetCameraList],downloadedCound: Int) {
        DispatchQueue.global(qos: .background).async { [weak self] () -> Void in
            if self?.popupController != nil {
                DispatchQueue.main.async { () -> Void in
                    self?.popupController?.progressView.setProgress(Double(Double(downloadedCound) / Double(getCameraList.count)), animated: true)
                }
            }
        }
        if downloadedCound < getCameraList.count {
            if getCameraList[downloadedCound].type == "0"
            {
                let urlstring = API.fileApi.rawValue + getCameraList[downloadedCound].soundfile
                let url = NSURL(string: urlstring)
                downloadFileFromURL(url: url!, count: downloadedCound)
    
            } else if getCameraList[downloadedCound].type == "" {
                let urlstring = API.fileApi.rawValue + getCameraList[downloadedCound].soundfile
                let url = NSURL(string: urlstring)
                downloadFileFromURL(url: url!, count: downloadedCound)
            } else {
                let count = downloadedCound + 1
                self.downloadFile(Response: getCameraList, downloadedCound: count)
            }
            
        } else  {
            // download işlemi bittiğinde
            print(self.odiResponseModel.cameraList)
            //self.clearTempFolder()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.HIDE_SIC(customView: self.view)
                self.goto(screenID: "TurnPhoneSplashVCID", animated: false, data: nil, isModal: true)
            }
        }
        
    }
    
    func downloadFileFromURL(url:NSURL,count:Int){
        
        var downloadTask:URLSessionDownloadTask
        downloadTask = URLSession.shared.downloadTask(with: url as URL, completionHandler: { [weak self](URL, response, error) -> Void in
            
            let time = NSNumber(value:(NSDate().timeIntervalSince1970 * 1000))
            let fileName = NSString(format:"%@_music.mp4",time) // değiştirme mov
            
            let destinationFileUrl = tempFolder?.appendingPathComponent(fileName as String)
            
            do {
                try FileManager.default.copyItem(at: URL!, to: destinationFileUrl!)
            } catch (let writeError) {
                print("Error creating a file \(String(describing: destinationFileUrl)) : \(writeError)")
            }
            self?.odiResponseModel.cameraList[count].path = destinationFileUrl
            let count = count + 1
            self?.downloadFile(Response: (self?.odiResponseModel.cameraList)!, downloadedCound: count)
        })
        downloadTask.resume()
    }
    
    
    func clearTempFolder() {
        clearTemp()
        let fileManager = FileManager.default
        let tempFolderPath = NSTemporaryDirectory()
        do {
            let filePaths = try fileManager.contentsOfDirectory(atPath: tempFolderPath)
            for filePath in filePaths {
                try fileManager.removeItem(atPath: tempFolderPath + filePath)
            }
        } catch {
            print("Could not clear temp folder: \(error)")
        }
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        //self.captureButton.isEnabled = true
        self.addObserver()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        styleCaptureButton()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        print("Camera: viewDidAppear")
       
        commpressStatus = false
        
        styleCaptureButton()
        configureCameraController()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(CameraViewController.rotated),
                                               name: UIDevice.orientationDidChangeNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.checkPermissionStatus(_:)),
                                               name: NSNotification.Name.ODI.CHECK_PERMISSION,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(CameraViewController.appWillBackground),
                                               name: NSNotification.Name.ODI.APP_WILL_BACKGROUND,
                                               object: nil)
        
        
        
        if (UIDevice.current.freeDiskSpaceInBytes() < 100000000) { // 100mb tan küçük ise uyarı ver
            let alert = UIAlertController(title: "Yetersiz Hafıza", message: "Telefonunuzun kullanılabilir hafızası dolmak üzere. Kayıt yapabilmeniz için gereksiz olan media veya uygulamaları silerek yer açabilirsiniz.", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Tamam", style: UIAlertAction.Style.default, handler: { (act) in
                //self.dismiss(animated: true, completion: nil)
                self.navigationController?.popViewController(animated: true)
            }))
            
            self.present(alert, animated: true)
        }
        
        rotated()
        dbManager?.getVideoByProjectId(projectId: self.odileData.videoId , onSuccess: { (status, data:[videoModel]?) in
            if let data = data {
                if (data.count < 1) {
                    DispatchQueue.main.async {
                        self.galleryButton.isHidden = true
                    }
                }else{
                    DispatchQueue.main.async {
                        let myData:[videoModel] = data.reversed()
                        let thumb = self.load(fileName: myData[0].thumbPath!)
                        self.galleryButton.isHidden = false
                        self.galleryButton.image = thumb
                        self.galleryButton.contentMode = .scaleAspectFill
                        self.galleryButton.layer.cornerRadius = 5
                        self.galleryButton.layer.masksToBounds = true
                        //self.galleryButton.clipsToBounds = true
                        //self.galleryButton.clipsToBounds = true
                    }
                }
            }
            
        }, onFailure: { (error:Error?) in
            
        })
        
        /*
        popTip.show(text: "Hey! Listen!", direction: PopTipDirection.right, maxWidth: 200, in: transparenView, from: closeTitleButton.frame, duration: 3)
        popTip.shouldDismissOnTap = true
         */
        
    }
    
    //    MARK: - tool tip
    var popTip:PopTip?
    var toolTipTimer:Timer?
    var toolTipArray:[toolTipModel] = []
    var toolTipCounter:Int = 0
    var toolTipStartStatus:Bool = false // bir kere başladıysa tekrar başlatmaması için gerekli
    private func toolTipStart() {
        toolTipStartStatus = true
        let subtitleToolTip = toolTipModel(toolTipText: "Altyazıyı kapatıp, açabilirsin",
                                           toolTipObject: closeTitleButton,
                                           direction: .right)
        
        let soundToolTip = toolTipModel(toolTipText: "Dış sesi kapatıp, açabilirsin",
                                        toolTipObject: soundButtonObject,
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
            print("Animasyon bitti")
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
                    in: transparenView,
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
    
    @objc func appWillBackground(_ notification: Notification){
        
        print("appWillBackground +++")
        myTimer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(fire), userInfo: nil, repeats: false)
        self.captureButton.isUserInteractionEnabled = false
        self.isNotFinishedCapture = true
        stopTimer()
        self.audioPlayer.stopTimer()
        stopCaptureVideo()
        actionLabel.isHidden = true
        
        if (toolTipTimer != nil) {
            toolTipTimer?.invalidate()
            toolTipTimer = nil
        }
        if popTip != nil {
            popTip?.hide()
            popTip = nil
        }
    }
    
    
    // get free space
    func deviceRemainingFreeSpaceInBytes() -> Int64? {
        let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last!
        guard let systemAttributes = try? FileManager.default.attributesOfFileSystem(forPath: documentDirectory),
            let freeSize = systemAttributes[.systemFreeSize] as? NSNumber else { return nil}
        return freeSize.int64Value
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.stopTimer()
        self.closeButton.isHidden = false
        self.swapCameraButton.isHidden = false
        self.view.layer.removeAllAnimations()
        self.audioPlayer.pausePlayer()
        self.audioPlayer.audioPlayerNil()
        self.progressView.progress = 0
        self.removeObserver()
        self.removeObserverForOdi()
        
        NotificationCenter.default.removeObserver(self)
        
        if (toolTipTimer != nil) {
            toolTipTimer?.invalidate()
            toolTipTimer = nil
        }
        if popTip != nil {
            popTip?.hide()
            popTip = nil
        }
    }
    
    @objc func rotated() {
        
        print("hareket: var")
        if UIDevice.current.orientation == UIDeviceOrientation.landscapeLeft {
            print("hareket: Sol")
            //checkPermission()
            
            
            if !toolTipStartStatus && !UserPrefences.getCameraFirstLook()!{
                toolTipStart()
                UserPrefences.setCameraFirstLook(value: true)
            }
            
        }
        else if UIDevice.current.orientation == UIDeviceOrientation.landscapeRight{
            print("hareket: Sağa Yatır")

            if (myHolderView == nil && !isRecording && !commpressStatus) {
                self.goto(screenID: "TurnPhoneSplashVCID", animated: true, data: nil, isModal: true)
            }
        }
        else if UIDevice.current.orientation == UIDeviceOrientation.portraitUpsideDown{
            print("hareket: Ters")
            if (myHolderView == nil && !isRecording && !commpressStatus) {
                self.goto(screenID: "TurnPhoneSplashVCID", animated: true, data: nil, isModal: true)
            }
        }
        else if UIDevice.current.orientation == UIDeviceOrientation.portrait {
            print("hareket: dik")

            if (myHolderView == nil && !isRecording && !commpressStatus) {
                self.goto(screenID: "TurnPhoneSplashVCID", animated: true, data: nil, isModal: true)
            }
        }
    }
    
    @objc func checkPermissionStatus(_ notification: Notification) {
        checkPermission()
    }
    
    func checkPermission() {
        if AVCaptureDevice.authorizationStatus(for: AVMediaType.video) == .authorized && AVCaptureDevice.authorizationStatus(for: AVMediaType.audio) == .authorized {
            //already authorized
            print("Camera: Mikrofon ve Kamera izni verilmiş")
        } else {
            print("Camera: izinler yok")
            AppUtility.lockOrientation(UIInterfaceOrientationMask.landscapeRight)
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { (granted: Bool) in
                if granted {
                    print("Camera: video izni var")
                } else {
                    print("Camera: ses izni yok")
                    DispatchQueue.global(qos: .background).async { [weak self] () -> Void in
                        DispatchQueue.main.async { () -> Void in
                            self?.alertMessage()
                        }
                    }
                }
            })
            
            AVCaptureDevice.requestAccess(for: .audio, completionHandler: { (granted: Bool) in
                if granted {
                    // en son başarılı noktası
                    print("Camera: ses izni var")
                } else {
                    
                    print("Camera izni de yok")
                    DispatchQueue.global(qos: .background).async { [weak self] () -> Void in
                        DispatchQueue.main.async { () -> Void in
                            self?.alertMessage()
                        }
                    }
                    
                }
            })
            
        }
    }
    
    func alertMessage() {
    
        let permision = UIAlertController (title: "İzin Yok!", message: "Odi'nin video kaydı yapabilmesi için kamera ve mikrofon izinlerine ihtiyacı var. Video kaydı yapabilmek için hemen \n'Ayarlar' -> 'Odi' -> 'Kamera & Mikrofon' \nsekmelerindeki izinleri açmalısınız.", preferredStyle: .alert)
        
        let settingsAction = UIAlertAction(title: "Ayarlar", style: .default) { (_) -> Void in
            let settingsUrl = NSURL(string:UIApplication.openSettingsURLString)
            if let url = settingsUrl {
                DispatchQueue.main.async {
                    UIApplication.shared.open(url as URL, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
                }
                self.navigationController?.dismiss(animated: true, completion: nil)
            }
        }
        
        let cancelAction = UIAlertAction(title: "İptal", style: UIAlertAction.Style.destructive, handler: { (act) in
            if self.navigationController != nil {
                let popup = self.SHOW_SIC(type: .reload)
                popup?.setProgress(progressValue: 1.0)
                AppUtility.lockOrientation(.portrait)
                self.clearTempFolder()
                self.HIDE_SIC(customView: (self.view)!)
                self.navigationController?.dismiss(animated: true, completion: nil)
            }
        })
        permision.addAction(settingsAction)
        permision.addAction(cancelAction)
        
        self.present(permision, animated: true, completion: nil)
    }
    
    func addObserver(){
        NotificationCenter.default.addObserver(self, selector: #selector(self.goBack(notification:)), name: NSNotification.Name(rawValue: "transitionBack") , object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.refreshData(notification:)),
                                               name:NSNotification.Name(rawValue: "refreshData"),
                                               object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.refreshData(notification:)),name:NSNotification.Name(rawValue:"refData"),object: nil)
        
        
    }
    func removeObserver(){
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "transitionBack") , object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "refreshData") , object: nil)
    }
    
    @objc func refreshData(notification: NSNotification){
        dbManager?.getVideoByProjectId(projectId: self.odileData.videoId , onSuccess: { (status, data:[videoModel]?) in
            if let data = data {
                if (data.count < 1) {
                    DispatchQueue.main.async {
                        self.galleryButton.isHidden = true
                    }
                }else {
                    DispatchQueue.main.async {
                        let myData:[videoModel] = data.reversed()
                        let thumb = self.load(fileName: myData[0].thumbPath!)
                        self.galleryButton.isHidden = false
                        
                        self.galleryButton.image = thumb
                        self.galleryButton.contentMode = .scaleAspectFill
                        self.galleryButton.layer.cornerRadius = 5
                        self.galleryButton.layer.masksToBounds = true
                        //self.galleryButton.clipsToBounds = true
                    }
                }
            }
            
        }, onFailure: { (error:Error?) in
            
        })
    }
    
    @objc func goBack(notification: NSNotification){
        if self.navigationController != nil {
                AppUtility.lockOrientation(.portrait)
                self.clearTempFolder()
                self.navigationController?.dismiss(animated: true, completion: nil)
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "transitionBackToWebview"), object: nil, userInfo: nil)
            }
        
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    var myTimer:Timer?
    //Action Button
    @IBAction func CaptureButtonAction(_ sender: UIButton) {
        if !isRecording {
            self.isNotFinishedCapture = false
            self.captureButton.isUserInteractionEnabled = false
            audioPlayer.startCaputeredMusic(recourceName: "3,2,1_ses", delegateVC: self)
            audioPlayer.playPlayerForAction(viewController: self)
            self.galleryButton.isHidden = true
            toolTipFinish()
        } else {
            myTimer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(fire), userInfo: nil, repeats: false)
            self.captureButton.isUserInteractionEnabled = false
            self.isNotFinishedCapture = true
            stopCaptureVideo()
        }
    }
    
    @objc func fire(){
        guard let _t = myTimer else { return }
        _t.invalidate()
        
        guard let _ = self.captureButton else { return }
        self.captureButton.isUserInteractionEnabled = true
    }
    
    @IBAction func closeTitleAction(_ sender: Any) {
        if !isTextClosed {
            isTextClosed = !isTextClosed
            self.kareokeLabel.isHidden = true
            self.closeTitleButton.setImage(#imageLiteral(resourceName: "text"), for: .normal)
        }
        else{
            isTextClosed = !isTextClosed
            self.kareokeLabel.isHidden = false
            self.closeTitleButton.setImage(#imageLiteral(resourceName: "textoff"), for: .normal)
        }
        
    }
    
    @IBAction func swapCameraAct(_ sender: Any) {
        cameraController.swapCamera()
        if !isFrontCamera {
            isFrontCamera = !isFrontCamera
        }
        else{
            isFrontCamera = !isFrontCamera
        }
    }
    
    @IBAction func backToControllerAct(_ sender: Any) {
        if self.navigationController != nil
            {
                let popup = self.SHOW_SIC(type: .reload)
                popup?.setProgress(progressValue: 1.0)
                AppUtility.lockOrientation(.portrait)
                self.clearTempFolder()
                self.HIDE_SIC(customView: (self.view)!)
                self.navigationController?.dismiss(animated: true, completion: nil)
            }
        
    }
    
    @IBAction func skipButtonAction(_ sender: Any) {
        if odiResponseModel.cameraList.count > cameraTimerCount + 1 {
            kareokeLabel.setContentOffset(.zero, animated: false)
            stopTimer()
            skipButton.isHidden = true
            skipButton2.isHidden = true
            self.progressView.progress = 0.0
            self.lines.removeAll()
            lineDuration = 0
            lineCharacterDuration = 0
            cameraTimerCount += 1
            startCameraTimer()
        } else {
            stopCaptureVideo()
        }
       
    }
    
    
    
    var soundStatus:Bool = true
    @IBAction func soundStatus(_ sender: Any) {
        if (soundStatus) {
            audioPlayer.playerVolume = 0
            soundButtonObject.setImage(UIImage(named: "otherSoundClose"), for: UIControl.State.normal)
            soundStatus = false
            
            toastMessageClose()
        }else {
            audioPlayer.playerVolume = 1
            soundButtonObject.setImage(UIImage(named: "otherSoundOpen"), for: UIControl.State.normal)
            soundStatus = true
            
            toastMessageOpen()
        }
    }
    
    
    private func toastMessageOpen() {
        clearToastMessageTimer()
        
        toastMessageLabel.text = "Odi Sesi Açık"
        toastMessageContainer.isHidden = false
        toastMessageContainer.alpha = 1
        
        toastMessageTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector:#selector(toastMessageTimerEvent) , userInfo: nil, repeats: false)
    }
    
    private func toastMessageClose() {
         clearToastMessageTimer()
        
        toastMessageLabel.text = "Odi Sesi Kapalı"
        toastMessageContainer.isHidden = false
        toastMessageContainer.alpha = 1
        
        toastMessageTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector:#selector(toastMessageTimerEvent) , userInfo: nil, repeats: false)
    }
    
    @objc func toastMessageTimerEvent(timer:Timer?){
        toastMessageContainer.isHidden = false
        toastMessageContainer.alpha = 1
        UIView.animate(withDuration: 0.4, animations: {
            self.toastMessageContainer.alpha = 0
        }) { (status) in
            self.toastMessageContainer.isHidden = true
        }
    }
    
    private func clearToastMessageTimer() {
        if (toastMessageTimer != nil) {
            toastMessageTimer?.invalidate()
            toastMessageTimer = nil
            toastMessageContainer.layer.removeAllAnimations()
        }
    }
    
    var toastMessageTimer:Timer?
    
    
    @IBOutlet var soundButtonObject: UIButton!
    @IBOutlet var toastMessageLabel: UILabel!
    @IBOutlet var toastMessageContainer: UIView!
    @IBOutlet var toastMessageBG: UIView!
    
    //Storyboard Veriable
    @IBOutlet weak var actionLabel: UILabel!
    @IBOutlet weak var skipButton: UIButton!
    @IBOutlet weak var skipButton2: UIButton!
    
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var closeTitleButton: UIButton!
    @IBOutlet weak var swapCameraButton: UIButton!
    @IBOutlet weak var progressView: UIProgressView!
    
    @IBOutlet weak var kareokeLabel: UITextView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var transparenView: UIView!
    
    //FileOutPut
    var fileOutPut : AVCaptureFileOutput!
    
    //Support Classes
    let cameraController = CameraController()
    var audioPlayer = AudioPlayer()
    var popupController : SIC?
    
    //Supporter Veriable
    var isRecording = false
    var isFrontCamera = true
    var isTextClosed = false
    var isNotFinishedCapture = false
    //For timer
    var duration = 0
    var lineDuration = 0
    var lineCharacterDuration = 0
    var lines = [String]()
    
    var subtitleString = ""
    var timer = Timer()
    var cameraTimerDuration = 0
    var cameraTimerCount = 0
    var progressValue : Double = 0.0
    //Response model
    var odiResponseModel = GetCameraResponseModel()
    //Send data
    var odileData = (userId: "", videoId: "")
    var uploadData : [String : AnyObject] = [:]
    var videoPath = ""

}

extension CameraViewController {
    
    func configureCameraController() {
        cameraController.prepareBackVideo(view: self.cameraView)
    }
    
    func styleCaptureButton() {
        captureButton.layer.borderColor = UIColor.white.cgColor
        captureButton.layer.borderWidth = 3
        captureButton.layer.cornerRadius = min(captureButton.frame.width, captureButton.frame.height) / 2
    }
    
    func startCameraTimer(){
        
       
        
        if odiResponseModel.TIP == "1" {
            subtitleString = odiResponseModel.cameraList[cameraTimerCount].text
            let myMutableString = NSMutableAttributedString(
                string: subtitleString,
                attributes: [kCTFontAttributeName as NSAttributedString.Key : UIFont(name: "Arial",size: 19.0)!])
            
            
            //self.runTimer(interval: TimeInterval(Float(odiResponseModel.cameraList[cameraTimerCount].duration)! / Float(myMutableString.count)))
            //let sonuc = Float(Float(odiResponseModel.cameraList[cameraTimerCount].duration)! / Float(myMutableString.length))
            
            
            self.runTimer(interval: TimeInterval(Float(odiResponseModel.cameraList[cameraTimerCount].duration)! / Float(myMutableString.length))) // değişiklik
            
            UIView.animate(withDuration: TimeInterval(Float(odiResponseModel.cameraList[cameraTimerCount].duration)!) , animations: {
                self.progressView.progress = 1.0
                self.view.layoutIfNeeded()
            })
        } else if odiResponseModel.TIP == "2" {
            typeTwoOdiFunc()
        } else if odiResponseModel.TIP == "3" {
            audioPlayer.initialPlayer(resource: odiResponseModel.cameraList[cameraTimerCount].path! as NSURL)
            audioPlayer.playPlayer()
            UIView.animate(withDuration: TimeInterval(audioPlayer.playerGetDuration() + 1) , animations: {
                self.progressView.progress = 1.0
                self.view.layoutIfNeeded()
            })
        }
        
    }
    
    fileprivate func addObserverForOdi(){
        NotificationCenter.default.addObserver(self, selector: #selector(self.typeTwoOdiFunc), name: NSNotification.Name.typeTwoOdi, object: nil)
    }
    
    fileprivate func removeObserverForOdi(){
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.typeTwoOdi, object: nil)
    }
    
    @objc func typeTwoOdiFunc(){
        if odiResponseModel.cameraList.count > cameraTimerCount {
            switch odiResponseModel.cameraList[cameraTimerCount].type {
            case "0":
                audioPlayer.initialPlayer(resource: odiResponseModel.cameraList[cameraTimerCount].path! as NSURL)
                audioPlayer.playPlayer()
                subtitleString = odiResponseModel.cameraList[cameraTimerCount].text
                
                let myMutableString = NSMutableAttributedString(
                    string: subtitleString,
                    attributes: [kCTFontAttributeName as NSAttributedString.Key : UIFont(name: "Arial",size: 19.0)!])
                
                
                // değişiklik
                //self.runTimer(interval: TimeInterval(Float(audioPlayer.playerGetDuration()) / Float(subtitleString.count)))
                
                var sonuc:Float = 0.0;
                if (firstStart==false) {
                    sonuc = Float(audioPlayer.playerGetDuration()) / Float(myMutableString.length-12)
                }else {
                    sonuc = Float(audioPlayer.playerGetDuration()) / Float(myMutableString.length)
                }
                
                print("textControl:typeTwoOdiFunc: 0 Time Interval: \(audioPlayer.playerGetDuration()) -- \(myMutableString.length) --> sonuc \(sonuc)")
                //self.runTimer(interval: TimeInterval(Float(audioPlayer.playerGetDuration()) / Float(myMutableString.length-12)))
                self.runTimer(interval: TimeInterval(sonuc))
                
                progressValue = Double(1.0 / Float(subtitleString.count))
                skipButton.isHidden = true
                skipButton2.isHidden = true
            case "1":
                subtitleString = odiResponseModel.cameraList[cameraTimerCount].text
                
                // değişiklik
                //self.runTimer(interval: TimeInterval(Float(odiResponseModel.cameraList[cameraTimerCount].duration)! / Float(subtitleString.count)))
                let myMutableString = NSMutableAttributedString(
                    string: subtitleString,
                    attributes: [kCTFontAttributeName as NSAttributedString.Key : UIFont(name: "Arial",size: 19.0)!])
                
                
                //let sonuc = Float(odiResponseModel.cameraList[cameraTimerCount].duration)! / Float(myMutableString.length)
                
                //print("textControl:typeTwoOdiFunc: 1 Time Interval: \(odiResponseModel.cameraList[cameraTimerCount].duration) -- \(myMutableString.length) --> sonuc \(sonuc)")
                
                if odiResponseModel.cameraList.count-1 > cameraTimerCount {
                    self.runTimer(interval: TimeInterval(Float(odiResponseModel.cameraList[cameraTimerCount].duration)! / Float(myMutableString.length)))
                    
                    // değişiklik
                    //progressValue = Double(1.0 / Float(subtitleString.count))
                    progressValue = Double(1.0 / Float(myMutableString.length))
                }else {
                    self.runTimer(interval: TimeInterval(Float(odiResponseModel.cameraList[odiResponseModel.cameraList.count-1].duration)! / Float(myMutableString.length)))
                                       
                    // değişiklik
                    //progressValue = Double(1.0 / Float(subtitleString.count))
                    progressValue = Double(1.0 / Float(myMutableString.length))
                }
                
                
                
            default:break
            }
        }
    }
    
    
    
    func runTimer(interval: TimeInterval) {
        if timer.isValid {
            timer.invalidate()
        }
        
        print("textControl: Toplam bekleme süresi: \(interval)")
        firstStart = true
        timer = Timer.scheduledTimer(timeInterval: interval, target: self,   selector: (#selector(self.updateTimer)), userInfo: nil, repeats: true)
    }
    
    @objc func updateTimer() {
        duration += 1
        lineCharacterDuration += 1
        
        if odiResponseModel.TIP == "2" {
            self.progressView.progress += Float(progressValue)
            
            switch odiResponseModel.cameraList[cameraTimerCount].type {
            case "0":
                self.kareokeLabel.attributedText = NSMutableAttributedString(string: "")
                self.kareokeLabel.text = ""
                self.kareokeLabel.attributedText = customAttiribitudText(fontColor: UIColor.odiColor)
            case "1":
                self.kareokeLabel.attributedText = NSMutableAttributedString(string: "")
                self.kareokeLabel.text = ""
                self.kareokeLabel.attributedText = customAttiribitudText(fontColor: UIColor.userColor)
                self.skipButton.isHidden = false
                self.skipButton2.isHidden = false
            default:break
            }
        } else {
            self.kareokeLabel.attributedText = NSMutableAttributedString(string: "")
            self.kareokeLabel.text = ""
            self.kareokeLabel.attributedText = customAttiribitudText(fontColor: UIColor.userColor)
        }
        
        // satır sayacı--++
        if lines.count == 0 {
            self.lines = getLinesArrayOfString(in: kareokeLabel)
        }
        
        if kareokeLabel.contentSize.height > kareokeLabel.frame.height { //Scroll var mı kontrolü
            if lines.count != 0 {
                //print("textControl: lineCharacterDuration: \(lineCharacterDuration) = count:\(lines[lineDuration].count) | lineDuration: \(lineDuration)")
                // değişktirme
                // bu dış kısım if patlamasın diye eklendi
                
                if (lineDuration < lines.count) { // bu kısım eklendi
                    if lineCharacterDuration == lines[lineDuration].count {
                        if lineDuration < 1 || (lines.count - lineDuration) < 3 {
                            //İlk satır ve son 3 satırda scrrol yapmaması için.
                        } else {
                            if let fontUnwrapped = self.kareokeLabel.font{
                                //print("\(lineDuration) satır bitti")
                                self.kareokeLabel.setContentOffset(CGPoint(x: 0, y: kareokeLabel.contentOffset.y + fontUnwrapped.lineHeight + 4.4), animated: true)
                            }
                        }
                        lineDuration += 1
                        lineCharacterDuration = 0
                    }
                }
            }
        }
        
        let myMutableString = NSMutableAttributedString(string: subtitleString,
                                                        attributes: [kCTFontAttributeName as NSAttributedString.Key : UIFont(name: "Arial",size: 19.0)!])
        // değişiklik
        //if duration == subtitleString.count {
        //duration == myMutableString.length
        if duration == myMutableString.length {
            kareokeLabel.setContentOffset(.zero, animated: false)
            kareokeLabel.attributedText = freeAttiribitudText()
            self.progressView.progress = 0.0
            cameraTimerCount += 1
            duration = 0
            lineDuration = 0
            lineCharacterDuration = 0
            self.lines.removeAll()
            stopTimer()
            self.skipButton.isHidden = true
            self.skipButton2.isHidden = true
            if odiResponseModel.cameraList.count > cameraTimerCount {
                NotificationCenter.default.post(name: NSNotification.Name.typeTwoOdi, object: nil, userInfo: nil)
            } else {
                stopCaptureVideo()
            }
        }
    }
    
    func stopTimer(){
        if timer.isValid {
            timer.invalidate()
            duration = 0
        }
        self.kareokeLabel.attributedText = freeAttiribitudText()
    }
    
}


//Mark: -Compress File
extension CameraViewController: AVCaptureFileOutputRecordingDelegate {
    //** Galeri değişikliği yapılacak yer
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        
        //For compress code
        guard let data = NSData(contentsOf: outputFileURL as URL) else {
            return
        }
        
        print("File size before compression: \(Double(data.length / 1048576)) mb")
        // değiştirme
        
        //let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0];
        let temp = tempFolder?.appendingPathComponent("output.mp4")
        let filePath = temp?.path
        self.uploadData["filePath"] = filePath as AnyObject
        self.uploadData["videoURL"] = outputFileURL as AnyObject
        self.uploadData["userId"] = self.odileData.userId  as AnyObject
        self.uploadData["videoId"] = self.odileData.videoId as AnyObject
        self.uploadData["isNotFinishedCapture"] = self.isNotFinishedCapture as AnyObject
        self.uploadData["pageStatus"] = PAGESTATUS.Camera as AnyObject
        self.uploadData["cameraStatus"] = isFrontCamera as AnyObject
        self.goto(screenID: "PlayVideoControllerID", animated: true, data: self.uploadData as AnyObject, isModal: true)
        
    }
    
    func sizeForLocalFilePath(filePath:String) -> UInt64 {
        do {
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: filePath)
            if let fileSize = fileAttributes[FileAttributeKey.size]  {
                return (fileSize as! NSNumber).uint64Value
            } else {
                print("Failed to get a size attribute from path: \(filePath)")
            }
        } catch {
            print("Failed to get file attributes for local path: \(filePath) with error: \(error)")
        }
        return 0
    }
    
    func covertToFileString(with size: UInt64) -> String {
        var convertedValue: Double = Double(size)
        var multiplyFactor = 0
        let tokens = ["bytes", "KB", "MB", "GB", "TB", "PB",  "EB",  "ZB", "YB"]
        while convertedValue > 1024 {
            convertedValue /= 1024
            multiplyFactor += 1
        }
        print(String(format: "%4.2f %@", convertedValue, tokens[multiplyFactor]))
        return String(format: "%4.2f %@", convertedValue, tokens[multiplyFactor])
    }
    
    func compressVideo(inputURL: URL, outputURL: URL, handler:@escaping (_ exportSession: AVAssetExportSession?)-> Void) {
        commpressStatus = true
        
        
        let videoAsset: AVAsset = AVAsset( url: inputURL )
        let clipVideoTrack = videoAsset.tracks(withMediaType: AVMediaType.video).first! as AVAssetTrack
        
        
        let composition = AVMutableComposition()
        composition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: CMPersistentTrackID())
        
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = CGSize(width: clipVideoTrack.naturalSize.width, height: clipVideoTrack.naturalSize.height)
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        
        let transformer = AVMutableVideoCompositionLayerInstruction(assetTrack: clipVideoTrack)
        
        let instruction = AVMutableVideoCompositionInstruction()
        let startTime = CMTimeMake(value: 0, timescale: 1)
        let timeRange = CMTimeRangeMake(start: startTime, duration: videoAsset.duration)
        instruction.timeRange = timeRange
        var transform = CGAffineTransform.identity
        
        
        if isFrontCamera {
            transform = transform.scaledBy(x: -1.0, y: 1.0)
            transform = transform.translatedBy(x: 0.0, y: clipVideoTrack.naturalSize.height)
            transform = transform.rotated(by: degreeToRadian(180.0))
            transform = transform.translatedBy(x: 0.0, y: 0.0)
        }
        
        
        transformer.setTransform(transform, at: CMTime.zero)
        instruction.layerInstructions = [transformer]
        videoComposition.instructions = [instruction]
        
        
        //let urlAsset = AVURLAsset(url: inputURL, options: nil)
        // değiştirme AVAssetExportPreset960x540
        guard let exportSession = AVAssetExportSession(asset: videoAsset, presetName: AVAssetExportPreset960x540) else {
            handler(nil)
            return
        }
        
        
        exportSession.videoComposition = videoComposition
        exportSession.outputURL = outputURL
        // DEĞİŞTİRME
        exportSession.outputFileType = AVFileType.mp4
        // yeni
        
        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.exportAsynchronously { () -> Void in
            handler(exportSession)
        }
        
        
        let popup = self.SHOW_SIC(type: .compressVideo)
        DispatchQueue.global(qos: .background).async { () -> Void in
            while exportSession.status == .waiting || exportSession.status == .exporting {
                DispatchQueue.main.async { () -> Void in
                    popup?.setProgress(progressValue: exportSession.progress)
                }
            }
        }
    }
    
    func degreeToRadian(_ x: CGFloat) -> CGFloat {
        return .pi * x / 180.0
    }
    
    func squareVideoCompositionForAsset(asset: AVAsset) -> AVVideoComposition {
        let track = asset.tracks(withMediaType: AVMediaType.video)[0]
        let length = max(track.naturalSize.width, track.naturalSize.height)
        
        var transform = track.preferredTransform
        
        let size = track.naturalSize
        
        var scale = CGFloat()
        if (transform.a == 0 && transform.b == 1 && transform.c == -1 && transform.d == 0) {
            scale = -1
        }
        else if (transform.a == 0 && transform.b == -1 && transform.c == 1 && transform.d == 0) {
            scale = -1
        }
        else if (transform.a == 1 && transform.b == 0 && transform.c == 0 && transform.d == 1) {
            scale = 1
        }
        else if (transform.a == -1 && transform.b == 0 && transform.c == 0 && transform.d == -1) {
            scale = 1
        }
        
        transform = transform.translatedBy(x: scale * -(size.width - length) / 2, y: scale * -(size.height - length) / 2)
        transform = transform.rotated(by: degreeToRadian(90))
        
        let transformer = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        transformer.setTransform(transform, at: CMTime.zero)
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: CMTime.zero, duration: CMTime.positiveInfinity)
        instruction.layerInstructions = [transformer]
        
        let composition = AVMutableVideoComposition()
        composition.frameDuration = CMTime(value: 1, timescale: 30)
        composition.renderSize = CGSize(width: length, height: length)
        composition.instructions = [instruction]
        
        return composition
    }
    
}



struct AppUtility {
    
    static func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            delegate.orientationLock = orientation
            
            switch orientation {
            case .portrait:
                print("AppUtility lock: portrait")
                break
            case .landscapeRight:
                print("AppUtility lock: landscapeRight")
                break
            case .landscapeLeft:
                print("AppUtility lock: landscapeRight")
                break
            default:
                print("AppUtility lock: default")
                break
            }
        }
    }
    
    /// OPTIONAL Added method to adjust lock and rotate to the desired orientation
    static func lockOrientation(_ orientation: UIInterfaceOrientationMask, andRotateTo rotateOrientation:UIInterfaceOrientation) {
        print("AppUtility: lockOrientation andRotateTo \(orientation)")
        self.lockOrientation(orientation)
        
        UIDevice.current.setValue(rotateOrientation.rawValue, forKey: "orientation")
        switch orientation {
        case .portrait:
            print("AppUtility lockAndRotate: portrait")
            break
        case .landscapeRight:
            print("AppUtility lockAndRotate: landscapeRight")
            break
        case .landscapeLeft:
            print("AppUtility lockAndRotate: landscapeRight")
            break
        default:
            print("AppUtility lockAndRotate: default")
            break
        }
    }
    
}

//MARK: - UITextView
extension UITextView{
    
    func numberOfLines() -> Int{
        if let fontUnwrapped = self.font{
            return Int(self.contentSize.height / fontUnwrapped.lineHeight)
        }
        
        return 0
    }
    
}

//Mark: -Attiribitud String
extension CameraViewController {
    // burası
    func customAttiribitudText(fontColor: UIColor) -> NSMutableAttributedString {
        //print("textControl: \(subtitleString) +===== count:\(subtitleString.count) | \(kareokeLabel.text.count)")
        
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineSpacing = 4.4
        paragraph.firstLineHeadIndent = 5.0
        let attributes:  [NSAttributedString.Key : Any] = [kCTParagraphStyleAttributeName as NSAttributedString.Key: paragraph]
        kareokeLabel.textContainerInset = .zero
        let myMutableString = NSMutableAttributedString(
            string: subtitleString,
            attributes: [kCTFontAttributeName as NSAttributedString.Key : UIFont(name: "Arial",size: 19.0)!])
        
        let countLength = myMutableString.length;
        
        //print("textControl: \(subtitleString) +===== count:\(subtitleString.count) | \(countLength)")
        
        myMutableString.addAttributes(attributes, range: NSRange(location:0,length:duration))
        
        myMutableString.addAttribute(.foregroundColor, value: fontColor,
                                     range: NSRange(location:0,length:countLength)) // subtitleString.count
        
        // tekrar işaretler
        myMutableString.addAttribute(.foregroundColor, value: UIColor.white, range: NSRange(location:0, length:duration))
        
        return myMutableString
    }
    
    
    
    func freeAttiribitudText() -> NSMutableAttributedString {
        let myMutableString = NSMutableAttributedString(
            string: "",
            attributes: [kCTFontAttributeName as NSAttributedString.Key : UIFont(
                name: "Arial",
                size: 19.0)!])
        return myMutableString
    }
    
    func getLinesArrayOfString(in label: UITextView) -> [String] {
        
        var linesArray = [String]()
        
        guard let text = label.text, let font = label.font else {return linesArray}
        
        let rect = label.frame
        
        let myFont: CTFont = CTFontCreateWithName(font.fontName as CFString, font.pointSize, nil)
        // değişiklik
        //let attStr = NSMutableAttributedString(string: text)
        let attStr = NSMutableAttributedString(
            string: text,
            attributes: [kCTFontAttributeName as NSAttributedString.Key : UIFont(
                name: "Arial",
                size: 19.0)!])
        
        attStr.addAttribute(.font, value: myFont, range: NSRange(location: 0, length: attStr.length))
        
        let frameSetter: CTFramesetter = CTFramesetterCreateWithAttributedString(attStr as CFAttributedString)
        let path: CGMutablePath = CGMutablePath()
        path.addRect(CGRect(x: 0, y: 0, width: rect.size.width - 10, height: 100000), transform: .identity)
        
        let frame: CTFrame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, 0), path, nil)
        guard let lines = CTFrameGetLines(frame) as? [Any] else {return linesArray}
        
        for line in lines {
            
            let lineRef = line as! CTLine
            let lineRange: CFRange = CTLineGetStringRange(lineRef)
            let range = NSRange(location: lineRange.location, length: lineRange.length)
            let lineString: String = (text as NSString).substring(with: range)
            
            linesArray.append(lineString)
            
        }
        return linesArray
    }
    
}

//Mark :- For Capture button action
extension CameraViewController {
    
    
    
    func startCaptureVideo(){
       
        
        isRecording = true
        // Configure output path in temporary folder
        // değiştirme
        
        
        //let outputPath = NSTemporaryDirectory() + "output.mp4"
        let myTempFolder = tempFolder?.appendingPathComponent("output.mp4")
        //let outputPath = tempFolder?.appendingPathComponent("output.mp4")
        
        
        let outputFileURL = myTempFolder//URL(fileURLWithPath: outputPath)
        cameraController.videoOutput?.movieFragmentInterval = CMTime.invalid
        cameraController.videoOutput?.startRecording(to: outputFileURL!, recordingDelegate: self)
        //Button configureCMTimeMake
        self.closeButton.isHidden = true
        self.swapCameraButton.isHidden = true
        self.soundButtonObject.isHidden = true
        self.galleryButton.isHidden = true
        captureButton.setImage(#imageLiteral(resourceName: "stop2"), for: .normal)
        startCameraTimer()
        print("takip: startCapture")
    }
    
    func stopCaptureVideo(){
        print("takip: stopCaptureVideo")
        
        kareokeLabel.setContentOffset(.zero, animated: false)
        isRecording = false
        cameraController.videoOutput?.stopRecording()
        self.skipButton.isHidden = true
        self.skipButton2.isHidden = true
        self.stopTimer()
        self.cameraTimerCount = 0
        self.closeButton.isHidden = false
        self.swapCameraButton.isHidden = false
        self.soundButtonObject.isHidden = false
        self.galleryButton.isHidden = false
        self.audioPlayer.pausePlayer()
        self.audioPlayer.audioPlayerNil()
        self.progressView.progress = 0
        self.lines.removeAll()
        
        lineDuration = 0
        lineCharacterDuration = 0
        captureButton.setImage(#imageLiteral(resourceName: "rec"), for: .normal)
    }
}

extension CameraViewController : AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.audioPlayer.player?.delegate = nil
        self.audioPlayer.audioPlayerNil()
        if self.audioPlayer.timer.isValid {
            self.audioPlayer.timer.invalidate()
        }
        self.actionLabel.isHidden = true
        self.captureButton.isUserInteractionEnabled = true
        self.startCaptureVideo()
    }
    
    @objc func updateTimerForPlayerCurrentTime() {
        if (audioPlayer.player == nil) {
            return
        }
        let timePlayed = audioPlayer.player?.currentTime
        let seconds = Int(Float(timePlayed!).truncatingRemainder(dividingBy: 60))
        switch seconds {
        case 0:
            self.actionLabel.isHidden = false
            self.actionLabel.text = "3"
        case 1:
            self.actionLabel.text = "2"
        case 2:
            self.actionLabel.text = "1"
        default:break
        }
        
        print(seconds)
        
    }
}

extension NSNotification.Name {
    static let typeTwoOdi = NSNotification.Name("TypeTwoOdi")
}
extension UIColor {
    static let odiColor = UIColor(red: 0.0 / 255.0, green: 131.0 / 255.0, blue: 178.0 / 255.0, alpha: 1.0) // mavi
    static let userColor = UIColor(red: 255.0 / 255.0, green: 132.0 / 255.0, blue: 0.0 / 255.0, alpha: 1.0) // sarı
}

extension UIDevice {
    
    func totalDiskSpaceInBytes() -> Int64 {
        do {
            guard let totalDiskSpaceInBytes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())[FileAttributeKey.systemSize] as? Int64 else {
                return 0
            }
            return totalDiskSpaceInBytes
        } catch {
            return 0
        }
    }
    
    func freeDiskSpaceInBytes() -> Int64 {
        do {
            guard let totalDiskSpaceInBytes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())[FileAttributeKey.systemFreeSize] as? Int64 else {
                return 0
            }
            return totalDiskSpaceInBytes
        } catch {
            return 0
        }
    }
    
    func usedDiskSpaceInBytes() -> Int64 {
        return totalDiskSpaceInBytes() - freeDiskSpaceInBytes()
    }
    
    func totalDiskSpace() -> String {
        let diskSpaceInBytes = totalDiskSpaceInBytes()
        if diskSpaceInBytes > 0 {
            return ByteCountFormatter.string(fromByteCount: diskSpaceInBytes, countStyle: ByteCountFormatter.CountStyle.binary)
        }
        return "toplam alan bilinmiyor"
    }
    
    func freeDiskSpace() -> String {
        let freeSpaceInBytes = freeDiskSpaceInBytes()
        if freeSpaceInBytes > 0 {
            return ByteCountFormatter.string(fromByteCount: freeSpaceInBytes, countStyle: ByteCountFormatter.CountStyle.binary)
        }
        return "boş alan bilinmiyor"
    }
    
    func usedDiskSpace() -> String {
        let usedSpaceInBytes = totalDiskSpaceInBytes() - freeDiskSpaceInBytes()
        if usedSpaceInBytes > 0 {
            return ByteCountFormatter.string(fromByteCount: usedSpaceInBytes, countStyle: ByteCountFormatter.CountStyle.binary)
        }
        return "kullanılan alan bilinmiyor"
    }
    
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
