//
//  KayaCamManViewController.swift
//  Odi
//
//  Created by Nok Danışmanlık on 29.11.2019.
//  Copyright © 2019 bilal. All rights reserved.
//

import UIKit
import AVKit

class KayaCamManViewController: KayaCameraViewController {
    
    let TAG:String = "KayaCamManViewController"
    
    var uploadData : [String : AnyObject] = [:]
    var isNotFinishedCapture = false
    
    private var dbManager:kayaDbManager?
    
    var odiResponseModel = GetCameraResponseModel()
    var popupController : SIC?
    
    var odileData = (userId: "", videoId: "")
    
    private var modelList:[KayaSubtitleModel] = []
    
    private var isRecording:Bool = false
    var rotateCheck: Bool = false
    
    private var closeStatus:Bool = false
    
    @IBOutlet var previewView: UIView!
    
    private var dismissAnimationStatus:Bool = false
    
    
    func closeOnCallback(_ closeStatus:Bool?) -> () {
        self.closeStatus = true
        self.didClose()
        self.dismiss(animated: dismissAnimationStatus, completion: nil)
    }

    override func viewDidLoad() {
        UIApplication.shared.isIdleTimerDisabled = true
        super.viewDidLoad()
        
        print("\(self.TAG): projeTakip -> projectID: \(odileData.videoId)")
        
        AppUtility.lockOrientation(.landscapeRight)
        dbManager = kayaDbManager.sharedInstance
        configure()
        
        
        DispatchQueue.main.async {
            self.popupController = self.SHOW_SIC(type: .cameraReading)
            //self.popupController!.setProgress(progressValue: 1.0)
            self.popupController?.setProgressNoAnimation(progressValue: 1.0)
        }
        /*
        self.popupController = self.SHOW_SIC(type: .cameraReading)
        self.popupController!.setProgress(progressValue: 1.0)*/
    }
    
    
    @IBOutlet var turn: UIView!
    @IBOutlet var inTurn: UIView!
    
    func configure() {
        //turn.backgroundColor = UIColor.black.withAlphaComponent(0.95)
        inTurn.transform = self.view.transform.rotated(by: CGFloat(-(Double.pi / 2)))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        NotificationCenter.default.addObserver(self,selector: #selector(self.rotated),name: UIDevice.orientationDidChangeNotification,object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.checkPermissionStatus(_:)),
                                               name: NSNotification.Name.ODI.CHECK_PERMISSION,
                                               object: nil)
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.goBack(notification:)), name: NSNotification.Name(rawValue: "transitionBack") , object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.refreshData(notification:)),
                                               name:NSNotification.Name(rawValue: "refreshData"),
                                               object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.refreshData(notification:)),name:NSNotification.Name(rawValue:"refData"),object: nil)
        /*
        DispatchQueue.global(qos: .background).async {
            DispatchQueue.main.async {
                self.addPreviewView(previewView: self.previewView)
                self.installData()
            }
        }*/
        self.addPreviewView(previewView: self.previewView)
        self.installData()
        
        rotated()
        
        checkPermission()
        
        getDBData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.isIdleTimerDisabled = false
        NotificationCenter.default.removeObserver(self)
        
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification,object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "transitionBack") , object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "refreshData") , object: nil)
    }
    
    override func didClose() {
        closeStatus = true
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification,object: nil)
        super.didClose()
        
    }
    
//    MARK: - override method
    var isFrontCamera:Bool = true
    
    override func KayaCameraViewDelegate_OpenGallery() {
        openGalleryController()
    }
    
    override func KayaCameraViewDelegate_Error() {
        let alert = UIAlertController(title: "Kamera Hatası", message: "Kameraya ulaşmaya çalışırken geçici bir problem yaşandı. Lütfen tekrar deneyin.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tamam", style: UIAlertAction.Style.default, handler: { (act) in
            self.dismiss(animated: self.dismissAnimationStatus, completion: nil)
        }))
         
        self.present(alert, animated: true)
    }
    
    override func KayaCameraViewDelegate_CloseButtonEvent() {
        closeStatus = true
        AppUtility.lockOrientation(.portrait)
        self.dismiss(animated: dismissAnimationStatus) {
            print("\(self.TAG): KayaCameraViewDelegate_CloseButtonEvent: close button portrait")
        }
    }
    
    override func KayaCameraViewdelegate_RecordStatus(recordStatus: RecordStatus) {
        if RecordStatus.start == recordStatus {
            isRecording = true
        }else {
            isRecording = false
        }
    }
    
    override func KayaCameraViewDelegate_ChangeCamera(cameraPosition: CameraPosition?) {
        if cameraPosition == CameraPosition.FRONT {
            isFrontCamera = true
        }else {
            isFrontCamera = false
        }
    }
    
    override func KayaCameraViewDelegate_VideoOutPutExport(outputURL: URL?, originalImage: UIImage?, thumbnail: UIImage?) {
        guard let data = NSData(contentsOf: outputURL!) else {
            return
        }
        
        //print("File size before compression: \(Double(data.length / 1048576)) mb")
        // değiştirme
        
        //let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0];
        //let temp = tempFolder?.appendingPathComponent("output.mp4")
        let filePath = outputURL?.path//temp?.path
        self.uploadData["filePath"] = filePath as AnyObject
        self.uploadData["videoURL"] = outputURL as AnyObject
        self.uploadData["userId"] = self.odileData.userId  as AnyObject
        self.uploadData["videoId"] = self.odileData.videoId as AnyObject
        self.uploadData["isNotFinishedCapture"] = self.isNotFinishedCapture as AnyObject
        self.uploadData["pageStatus"] = PAGESTATUS.Camera as AnyObject
        self.uploadData["cameraStatus"] = isFrontCamera as AnyObject
        self.goto(screenID: "PlayVideoControllerID", animated: true, data: self.uploadData as AnyObject, isModal: true)
    }
    
    fileprivate func installData() {
        if odiResponseModel.TIP != "1" {
            DispatchQueue.main.async {
                if self.popupController == nil {
                    self.popupController = self.SHOW_SIC(type: .reload)
                }
                self.downloadFile(Response: self.odiResponseModel.cameraList, downloadedCound: 0)
                self.rotateCheck = false
            }
        } else {
            self.HIDE_SIC(customView: self.view)
            //self.goto(screenID: "TurnPhoneSplashVCID", animated: false, data: nil, isModal: true, callBack: closeOnCallback(_:))
        }
        
        // tip 1 ise indirilecek dosya yok altyazı var.
        if odiResponseModel.TIP == "1" {
            TypeOneConvertModels()
             rotateCheck = true
        }
    }

//    MARK: - Kontroller
    
    @objc func checkPermissionStatus(_ notification: Notification) {
        checkPermission()
    }
    
    private func freeDiskCheck() {
        if (UIDevice.current.freeDiskSpaceInBytes() < 100000000) { // 500mb tan küçük ise uyarı ver
            let alert = UIAlertController(title: "Yetersiz Hafıza", message: "Telefonunuzun kullanılabilir hafızası dolmak üzere. Kayıt yapabilmeniz için gereksiz olan media veya uygulamaları silerek yer açabilirsiniz.", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Tamam", style: UIAlertAction.Style.default, handler: { (act) in
                //self.dismiss(animated: true, completion: nil)
                self.dismiss(animated: self.dismissAnimationStatus) {
                    AppUtility.lockOrientation(UIInterfaceOrientationMask.portrait, andRotateTo: UIInterfaceOrientation.portrait)
                }
                //self.navigationController?.popViewController(animated: true)
            }))
            
            self.present(alert, animated: true)
        }
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
                    UIApplication.shared.open(url as URL, options: self.convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
                }
                //self.navigationController?.dismiss(animated: true, completion: nil)
                self.dismiss(animated: true, completion: nil)
            }
        }
        
        let cancelAction = UIAlertAction(title: "İptal", style: UIAlertAction.Style.destructive, handler: { (act) in
            let popup = self.SHOW_SIC(type: .returnOdi)
            popup?.setProgress(progressValue: 1.0)
            
            if self.cameraView != nil {
                 self.cameraView!.clearTempFolder()
            }
            self.HIDE_SIC(customView: (self.view)!)
            self.rotateCheck = true
            self.dismiss(animated: self.dismissAnimationStatus, completion: nil)
            
        })
        permision.addAction(settingsAction)
        permision.addAction(cancelAction)
        
        self.present(permision, animated: true, completion: nil)
    }
    
    fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
        return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
    }
    
    @objc func rotated() {
        
        if UIDevice.current.orientation == UIDeviceOrientation.landscapeLeft {
            print("hareket: Sol")
            DispatchQueue.main.async {
                self.freeDiskCheck()
            }
            openTurn()
        }
        else if UIDevice.current.orientation == UIDeviceOrientation.landscapeRight{
            print("hareket: Sağa Yatır")
            if (myHolderView == nil && !isRecording && rotateCheck) {
                if self.closeStatus == true {
                    return
                }
                closeTurn()
            }
        }
        else if UIDevice.current.orientation == UIDeviceOrientation.portraitUpsideDown{
            print("hareket: Ters")
            if (myHolderView == nil && !isRecording && rotateCheck) {
                if self.closeStatus == true {
                    return
                }
                closeTurn()
            }
        }
        else if UIDevice.current.orientation == UIDeviceOrientation.portrait {
            print("hareket: dik")
            if (myHolderView == nil && !isRecording && rotateCheck) {
                if self.closeStatus == true {
                    return
                }
                closeTurn()
            }
        }else {
            if (myHolderView == nil && !isRecording && rotateCheck) {
                if self.closeStatus == true {
                    return
                }
                closeTurn()
            }
        }
    }
    
    private func openTurn() {
        print("turn : aç")
        UIView.animate(withDuration: 0.2, animations: {
            let position = CGAffineTransform(translationX: 0, y: self.turn.frame.height)
            self.turn.transform = position
        }) { (act) in
            //self.turn.isHidden = true
        }
    }
    
    private func closeTurn() {
        print("turn : kapat ")
        UIView.animate(withDuration: 0.2, animations: {
            let position = CGAffineTransform(translationX: 0, y: 0)
            self.turn.transform = position
        }) { (act) in
            
        }
   }
    // database den verileri alır ve güncelleme yapar
    func getDBData() {
        dbManager?.getVideoByProjectId(projectId: self.odileData.videoId , onSuccess: { (status, data:[videoModel]?) in
            if let data = data {
                if (data.count < 1) {
                    DispatchQueue.main.async {
                        self.galleryImage = nil
                    }
                }else{
                    DispatchQueue.main.async {
                        let myData:[videoModel] = data.reversed()
                        let thumb = self.load(fileName: myData[0].thumbPath!)
                        self.galleryImage = thumb
                    }
                }
            }
            
        }, onFailure: { (error:Error?) in
            
        })
    }
    
//    MARK: - Ses ve altyazıların indirilmesi
    
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
            print("\(self.TAG): indirme işlemi bitirildi")
            convertModels()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.HIDE_SIC(customView: self.view)
                self.rotateCheck = true
                self.rotated()
            }
        }
        
    }
    
    func downloadFileFromURL(url:NSURL,count:Int){
        var downloadTask:URLSessionDownloadTask
        downloadTask = URLSession.shared.downloadTask(with: url as URL, completionHandler: { [weak self](URL, response, error) -> Void in
            
            let time = NSNumber(value:(NSDate().timeIntervalSince1970 * 1000))
            let fileName = NSString(format:"%@_music.mp4",time) // değiştirme mov
            /*
            let documentsUrl:URL =  (FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first as URL?)!
            let destinationFileUrl = documentsUrl.appendingPathComponent(fileName as String)*/
            
            // temp folder a gönderilecek
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
    
    fileprivate func convertModels() {
        for i in 0..<odiResponseModel.cameraList.count {
            if odiResponseModel.cameraList[i].type == "1"{
                let myModel:KayaSubtitleModel = KayaSubtitleModel(id: Int(odiResponseModel.cameraList[i].index),
                                                                  text: odiResponseModel.cameraList[i].text,
                                                                  soundURL: nil,
                                                                  duration: Double(odiResponseModel.cameraList[i].duration),
                                                                  type: KAYA_SUBTITLE_TYPE.mySelf)
                modelList.append(myModel)
                
            }else {
                let destinationFileUrl:URL = odiResponseModel.cameraList[i].path!
                let filePath = destinationFileUrl
                let fileManager = FileManager.default
                if fileManager.fileExists(atPath: filePath.path) {
                    print("\(self.TAG): corvertModels: Dosya var")
                } else {
                    print("\(self.TAG): corvertModels: Dosya YOK")
                }
                
                let myModel:KayaSubtitleModel = KayaSubtitleModel(id: Int(odiResponseModel.cameraList[i].index),
                                                                  text: odiResponseModel.cameraList[i].text,
                                                                  soundURL: destinationFileUrl,
                                                                  duration: nil,
                                                                  type: KAYA_SUBTITLE_TYPE.speaker)
                modelList.append(myModel)
                
                modelList = modelList.sorted(by: { $0.id! < $1.id! })
            }
           
        }
        
        print("\(self.TAG): data count: \(modelList.count)")
        if cameraView != nil {
            cameraView!.subtitleData = modelList
        }else {
            print("\(self.TAG): cameraView == nil")
        }
        
    }
    
    fileprivate func TypeOneConvertModels() {
        for i in 0..<odiResponseModel.cameraList.count {
            
            let myModel:KayaSubtitleModel = KayaSubtitleModel(id: Int(odiResponseModel.cameraList[i].index),
                                                              text: odiResponseModel.cameraList[i].text,
                                                              soundURL: nil,
                                                              duration: Double(odiResponseModel.cameraList[i].duration),
                                                              type: KAYA_SUBTITLE_TYPE.mySelf)
            modelList.append(myModel)
        }
        
        print("\(self.TAG): data count: \(modelList.count)")
        if cameraView != nil {
            cameraView!.subtitleData = modelList
        }else {
            print("\(self.TAG): cameraView == nil")
        }
    }
    
//    MARK: - Callback - Notification
    
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
                
                if dataModel.cameraStatus == "front" {
                    self.uploadData["cameraStatus"] = true as AnyObject
                }else {
                    self.uploadData["cameraStatus"] = false as AnyObject
                }
                 // isFrontCamera
                self.goto(screenID: "PlayVideoControllerID", animated: true, data: self.uploadData as AnyObject, isModal: true)
            }
        }
        
        getDBData()
    }
    
    func playViewControllerCallback(_ status:Bool?) -> () {
        getDBData()
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
    
    let transitionManager = galleryTransitionManager()
    // galeri açar
    private func openGalleryController() {
        dbManager?.getVideoByProjectId(projectId: self.odileData.videoId , onSuccess: { (status, data:[videoModel]?) in
            if let data = data {
                if (data.count < 1) {
                    DispatchQueue.main.async {
                        self.galleryImage = nil
                    }
                }else {
                    let vc = self.storyboard?.instantiateViewController(withIdentifier: "galleryVC") as! galleryViewController
                    vc.collectionData = data
                    vc.onCallback = self.galleryCallBack(_:_:)
                    vc.modalPresentationStyle = .overFullScreen
                    vc.transitioningDelegate = self.transitionManager
                    //self.navigationController?.present(vc, animated: true, completion: nil)
                    self.present(vc, animated: true, completion: nil)
                }
            }
            
        }, onFailure: { (error:Error?) in
            
        })
    }
    
    @objc func refreshData(notification: NSNotification){
        getDBData()
        AppUtility.lockOrientation(UIInterfaceOrientationMask.landscapeRight)
        rotated()
    }
    
    @objc func goBack(notification: NSNotification){
        closeStatus = true
        AppUtility.lockOrientation(.portrait)
        if (self.cameraView != nil) {
            self.cameraView!.clearTempFolder()
        }
        
        self.dismiss(animated: dismissAnimationStatus) {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "transitionBackToWebview"), object: nil, userInfo: nil)
        }
        
    }
    
    @IBAction func turnViewCloseButtonEvent(_ sender: Any) {
        self.closeStatus = true
        self.didClose()
        self.dismiss(animated: dismissAnimationStatus, completion: nil)
    }
    
}
