//
//  PlayVideoController.swift
//  Odi
//
//  Created by Baran on 22.12.2017.
//  Copyright © 2017 bilal. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer
import WebKit
import Photos
import StoreKit
import AMPopTip
import CoreGraphics

enum AppStoreReviewManager {
    static func requestReviewIfAppropriate() {
        if #available( iOS 10.3,*){
            SKStoreReviewController.requestReview()
        }
    }
}

class PlayVideoController: BaseViewController {
    
    enum playerStatus:String {
        case play
        case pause
    }
    
    private let TAG:String = "PlayVideoController: "
    
    private var showreelArray:[String] = ["87","663","661","664","665","666","667"]
    private var tanitimID:String = "15"
    
    @IBOutlet var bottomContainer: UIView!
    @IBOutlet var myMediaController: UIView!
    fileprivate var playerStatusHolder:playerStatus = .play
    @IBOutlet var playPauseButton: UIButton!
    @IBOutlet var myProgress: UISlider!
    @IBOutlet weak var uploadVideoButton: UIButton!
    @IBOutlet var fakeGalleryButton: UIImageView!
    
    var popUpController : SIC?
    var isImageUpload = false
    var currentTime = ""
    var thumbNailImage = UIImage()
    var videoId = ""
    var userId = ""
    var filePath = ""
    var videoURL : URL?
    var videoData : Data?
    var webViewForSuccess: WKWebView?
    var pageStatus:PAGESTATUS?
    var ftp = FTPUpload(baseUrl: "ftp.odiapp.com.tr:21", userName: "odiFtp@odiapp.com.tr", password: "Root123*" , directoryPath: "/img/")
    
    var isFrontCamera:Bool = false;
    
    private var dbManager:kayaDbManager?
    
    @IBOutlet var galleryButton: UIImageView!
    
    private var showreelStatus:Bool = false
    private var tanitimStatus:Bool = false
    
    private var newVideoName:String?
    private var newThumbnailName:String?
    
    var myBarTimer:Timer?
    let transitionManager = galleryTransitionManager()
    
    private func saveAnimation() {
        if let videoPath = self.videoURL {
            getAnimationThumbnailFrom(path: videoPath, onCallback: { (image) in
                let thumbAnimation = image
                let animImageView:UIImageView = UIImageView(frame: self.view.bounds)
                self.view.addSubview(animImageView)
                animImageView.image = thumbAnimation
                
                let globalPoint = self.saveAlbumButton.superview?.convert(self.saveAlbumButton.origin, to: nil)
                
                self.runAnimation(iv: animImageView, to: globalPoint!)
            }) { (error) in
                print("hata")
            }
        }
    }
    
    private func runAnimation(iv:UIImageView, to: CGPoint) {
        UIView.animate(withDuration: 0.4, animations: {
            
            var transform2 = CATransform3DIdentity
            transform2 = CATransform3DTranslate(transform2, to.x, to.y, 20)
            
            var transform1 = CATransform3DIdentity
            transform1.m34 = 1.0 / 200
            transform1 = CATransform3DScale(transform1, 0.1, 0.1, 0.1)
            
            let transform = CATransform3DConcat(transform2,transform1)
            
            iv.layer.transform = transform
            iv.alpha = 0
        }) { (act) in
            iv.removeFromSuperview()
            UIView.animate(withDuration: 0.3,
                           delay: 0,
                           usingSpringWithDamping: 0.5,
                           initialSpringVelocity: 5,
                           options: .curveEaseInOut,
                           animations: {
                             self.galleryButton.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
            }) { (finish) in
                UIView.animate(withDuration: 0.5,
                               delay: 0,
                               usingSpringWithDamping: 0.5,
                               initialSpringVelocity: 5,
                               options: .curveEaseInOut,
                               animations: {
                                 self.galleryButton.transform = CGAffineTransform(scaleX: 1, y: 1)
                }) { (finish) in
                    
                }
                
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refreshData"), object: nil, userInfo: nil)
            }
        }
        
    }
    
    var firstAlertReq:Bool = false
    private func galleryButtonEvent() {
        if (pageStatus == PAGESTATUS.Gallery) {
            self.openGalleryController()
            return
        }
        if (saveAlbumButton.alpha == 0.5) {
            self.openGalleryController()
            return
        }else {
            if pageStatus == PAGESTATUS.Camera {
                if (!self.firstAlertReq) {
                    let alert = UIAlertController(title: "Video Silinecek!",
                                                  message: "Galeriden video seçmeden önce çektiğiniz bu videoyu kaydetmeniz gerekir. Eğer kaydetmezseniz ve galeriden video seçerseniz çektiğiniz bu video otomatik olarak silinecektir. Devam etmek istiyor musunuz?",
                                                  preferredStyle: .alert)

                    alert.addAction(UIAlertAction(title: "Evet", style: UIAlertAction.Style.default, handler: { (action) in
                        // işlem yapılacak
                        self.firstAlertReq = true
                        self.saveAlbumButton.isHidden = true
                        self.openGalleryController()
                    }))
                    
                    alert.addAction(UIAlertAction(title: "İptal", style: UIAlertAction.Style.cancel, handler: nil))

                    self.present(alert, animated: true)
                }else {
                    self.openGalleryController()
                }
            }
        }
    }
    
    private func openGalleryController() {
        dbManager?.getVideoByProjectId(projectId: videoId , onSuccess: { (status, data:[videoModel]?) in
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
                    self.present(vc, animated: true, completion: nil)
                }
            }
            
        }, onFailure: { (error:Error?) in
            
        })
    }
    
    @objc func imageTapped(sender:UITapGestureRecognizer)  {
        print("\(self.TAG): imageTapped: gallery button click")
        galleryButtonEvent()
    }
    
    // callback dönüşü
    func galleryCallBack(_ gotoPlayView:Bool?,_ dataModel:videoModel?) -> () {
        if let gotoPlayView = gotoPlayView, let dataModel = dataModel {
            
            if (gotoPlayView) {
                let temp = videoFolder?.appendingPathComponent(dataModel.videoPath!)
                let _filePath = temp!.path
                videoURL = temp
                filePath = _filePath
                
                if let status = dataModel.cameraStatus {
                    if status == "front" {
                        self.isFrontCamera = true
                    }else {
                        self.isFrontCamera = false
                    }
                }
                
                playVideo(from: videoURL!)
                
                DispatchQueue.global(qos: .background).async {
                    self.updateThumbnail(videoPath: self.videoURL!)
                }
            }
        }
        
        // gallery icon knotrol ettir
        dbManager?.getVideoByProjectId(projectId: videoId , onSuccess: { (status, data:[videoModel]?) in
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
                    }
                }
            }
            
        }, onFailure: { (error:Error?) in
            
        })
    }
    
    
    @IBAction func playPauseButtonEvent(_ sender: Any) {
        startTimer()
        
        if (playerStatusHolder == playerStatus.play) {
            self.player.pause()
            setPlayPauseStatus(status: PlayVideoController.playerStatus.pause)
        }else {
            self.player.playFromCurrentTime()
            setPlayPauseStatus(status: PlayVideoController.playerStatus.play)
            playerStatusHolder = playerStatus.play
        }
    }
    
    
    @IBAction func handlerSliderChange(_ sender: Any) {
        let value = Float64(myProgress.value) * self.player!.maximumDuration
        let seekTime = CMTime(value: Int64(value), timescale: 1)
        self.player.seekToTime(seekTime)
    }
    
    func setPlayPauseStatus(status:playerStatus){
        switch status {
        case .play:
            playPauseButton.setImage(UIImage(named: "pause"), for: UIControl.State.normal)
            playerStatusHolder = playerStatus.play
            break;
        case .pause:
            playPauseButton.setImage(UIImage(named: "play"), for: UIControl.State.normal)
            playerStatusHolder = playerStatus.pause
            break;
        }
    }
    
    fileprivate func startTimer() {
        if myBarTimer != nil {
            myBarTimer?.invalidate()
            myBarTimer = nil
        }
        myBarTimer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(fireTimer), userInfo: nil, repeats: false)
    }
    
    @objc func videoViewGestureAction(recognizer: UITapGestureRecognizer) {
        //myMediaController.isHidden = !myMediaController.isHidden
        setProgressBarHidden(status: !myMediaController.isHidden)
    }
    
    @objc func fireTimer(timer: Timer) {
        print("Timer çalıştı")
        if (myBarTimer != nil) {
            myBarTimer?.invalidate()
            myBarTimer = nil
        }
        
        setProgressBarHidden(status: true)
        
    }
    
    func setProgressBarHidden(status:Bool){
        myMediaController.isHidden = status
        if (status == false) {
            if (myBarTimer != nil) {
                myBarTimer?.invalidate()
                myBarTimer = nil
            }
            myBarTimer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(fireTimer), userInfo: nil, repeats: false)
        }else {
            if (myBarTimer != nil) {
                myBarTimer?.invalidate()
                myBarTimer = nil
            }
        }
    }
    
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        UIApplication.shared.isIdleTimerDisabled = false
        if (toolTipTimer != nil) {
            toolTipTimer?.invalidate()
            toolTipTimer = nil
        }
        if popTip != nil {
            popTip?.hide()
            popTip = nil
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fakeGalleryButton.isHidden = true
        saveAlbumButton.isHidden = true
        
        dbManager = kayaDbManager.sharedInstance
        myProgress.isContinuous = true
        AppStoreReviewManager.requestReviewIfAppropriate()
        let videoViewGesture = UITapGestureRecognizer(target: self, action: #selector(videoViewGestureAction))
        videoViewGesture.numberOfTapsRequired = 1
        videoView.addGestureRecognizer(videoViewGesture)
        
        let bottomContainerGesture = UITapGestureRecognizer(target: self, action: #selector(videoViewGestureAction))
        bottomContainerGesture.numberOfTapsRequired = 1
        bottomContainer.addGestureRecognizer(bottomContainerGesture)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        UIApplication.shared.isIdleTimerDisabled = true
        KayaAppUtility.lockOrientation(UIInterfaceOrientationMask.landscapeRight)
        if let uploadData = self.data as? [String: AnyObject] {
            if let userId = uploadData["userId"] as? String {
                self.userId = userId
            }
            
            if let filePath = uploadData["filePath"] as? String {
                self.filePath = filePath
            }
            
            if let videoId = uploadData["videoId"] as? String {
                self.videoId = videoId
                
                for item in showreelArray {
                    if item == videoId {
                        showreelStatus = true
                        // button image değiştirilebilir. Kontrolü gerekiyor.
                    }
                }
                
                if videoId == tanitimID {
                    tanitimStatus = true
                }
            }
            
            print("\(self.TAG): showreelStatus: \(showreelStatus)")

            
            
            if let myPageStatus = uploadData["pageStatus"] as? PAGESTATUS {
                switch myPageStatus {
                case .Camera:
                    pageStatus = .Camera
                    DispatchQueue.main.async {
                        self.saveAlbumButton.isHidden = false
                    }
                    break
                case .Gallery:
                    pageStatus = .Gallery
                    DispatchQueue.main.async {
                        self.saveAlbumButton.isHidden = true
                    }
                    break
                }
            }
            
            if let cameraStatus = uploadData["cameraStatus"] as? Bool {
                isFrontCamera = cameraStatus
            }
            
            if let videoPath = uploadData["videoURL"] as? URL {// videoURL
                self.videoURL = videoPath
                print("\(self.TAG) dataÇözüm:  videourl atama yapılıyor : \(String(describing: self.videoURL))")
                
                DispatchQueue.global(qos: .background).async {
                    self.playVideo(from: videoPath)
                    self.startTimer()
                    self.updateThumbnail(videoPath: videoPath)
                }
            }
        }
        
        dbManager?.getVideoByProjectId(projectId: videoId , onSuccess: { (status, data:[videoModel]?) in
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
                    }
                }
            }
            
        }, onFailure: { (error:Error?) in
            
        })
        
        let gesture:UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped(sender:)))
        galleryButton.isUserInteractionEnabled = true
        galleryButton.addGestureRecognizer(gesture)

        if UserPrefences.getPlayerFirstLook() != nil {
            if (!UserPrefences.getPlayerFirstLook()!) {
                fakeGalleryButton.isHidden = false
                toolTipStart()
                UserPrefences.setPlayerFirstLook(value: true)
            }else {
                fakeGalleryButton.isHidden = true
            }
        }else {
            fakeGalleryButton.isHidden = false
            toolTipStart()
            UserPrefences.setPlayerFirstLook(value: true)
        }
    }
    
    
    private func updateThumbnail(videoPath:URL) {
        DispatchQueue.main.async {
            self.thumbNailImage = self.getThumbnailFrom(path: videoPath)!
            /*do {
                self.videoData = try Data(contentsOf: videoPath)
            } catch {
                print("Unable to load data: \(error)")
            }*/
        }
    }
    
    
    //    MARK: - tool tip
    var popTip:PopTip?
    var toolTipTimer:Timer?
    var toolTipArray:[toolTipModel] = []
    var toolTipCounter:Int = 0
    var toolTipStartStatus:Bool = false // bir kere başladıysa tekrar başlatmaması için gerekli
    private func toolTipStart() {
        toolTipStartStatus = true
        let subtitleToolTip = toolTipModel(toolTipText: "Çektiğin videoları kaydedebilirsin",
                                           toolTipObject: saveAlbumButton,
                                           direction: .right)
        
        let soundToolTip = toolTipModel(toolTipText: "Kaydettiğin videolar proje galerisinde saklanır.",
                                        toolTipObject: galleryButton,
                                        direction: .left)
        
        
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
            fakeGalleryButton.isHidden = true
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
                     direction: toolTipArray[toolTipCounter].direction!,
                    maxWidth: 320,
                    in: bottomContainer,
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
    
    @objc func toolTipTimerEvent() {
        openToolTip()
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
    
    
    private func playVideo(from videoURL:URL) {
        if (self.player != nil) {
            self.player.stop()
            self.player = nil
        }
        DispatchQueue.main.async {
            print(videoURL)
            self.player = Player()
            self.player.delegate = self
            self.player.view.frame = self.videoView.bounds
            self.addChild(self.player)
            self.videoView.addSubview(self.player.view)
            self.player.didMove(toParent: self)
            self.player.setUrl(videoURL)
            self.player.playbackLoops = false
            self.player.playFromBeginning()
            self.setPlayPauseStatus(status: PlayVideoController.playerStatus.play)
        }
    }
    @IBAction func againOdiButtonAct(_ sender: Any) {
        if self.player != nil {
            self.player.stop()
            self.player = nil
        }
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refData"), object: nil, userInfo: nil)
        self.back(animated: true, isModal: true)
    }
    
    @IBAction func uploadFileButtonAct(_ sender: Any) {
        if self.player != nil {
            self.player.stop()
        }
        mySendVideo()
    }
    
    // güncelleme değiştirme
    // compress buraya eklenecek????
    private func mySendVideo() {
        uploadVideoButton.isUserInteractionEnabled = false
        uploadVideoButton.alpha = 0.5
        
        if let myFolder = KayaTempFolder() {
            let videoTempName = "\(NSUUID().uuidString).output.mp4"
            let compressedURL = myFolder.appendingPathComponent(videoTempName)
            convertVideo(inputURL: self.videoURL!, compressedURL: compressedURL)
        }
        
    }
    
    func convertVideo(inputURL: URL, compressedURL: URL) {
        let videoTempName = "\(NSUUID().uuidString).output2.mp4"
        let convertURL = KayaTempFolder()!.appendingPathComponent(videoTempName)
        //convertVideo(inputURL: self.videoURL!, compressedURL: compressedURL)
        if(isFrontCamera) {
            self.compressVideo(inputURL: self.videoURL!, outputURL: compressedURL) { (exportSession) in
                guard let session = exportSession else {
                    return
                }
                
                switch session.status {
                case .unknown:
                    break
                case .waiting:
                    break
                case .exporting:
                    break
                case .completed:
                    self.videoCustomCompress(inputURL: compressedURL, outputURL: convertURL, completion: { (status) in
                        if (status) { // çeviri başarılı
                            var newData:Data?
                            do {
                                newData = try Data(contentsOf:  convertURL) // videoURL compressedURL
                            } catch {
                                print("compress: Unable to load data: \(error)")
                            }
                                            
                            self.currentTime = Date().getCurrentHour()
                            
                            self.newVideoName = "\(self.videoId)_\(self.userId)_VID_\(Date().getTodayDateString())_\(self.currentTime).mp4"
                            self.newThumbnailName = "\(self.videoId)_\(self.userId)_VID_\(Date().getTodayDateString())_\(self.currentTime).jpg"
                            
                            if self.showreelStatus {
                                self.newVideoName = "showreel_\(self.userId).mp4"
                                self.newThumbnailName = "showreel_\(self.userId).jpg"
                            }
                            /*
                            if self.tanitimStatus {
                                self.newVideoName = "tanitim_\(self.userId).mp4"
                                self.newThumbnailName = "tanitim_\(self.userId).jpg"
                            }*/
                            
                                            
                            self.ftp.send(data:  newData! , with: self.newVideoName!, success: { success in
                                DispatchQueue.main.async {
                                    if success {
                                        if self.popUpController != nil {
                                            self.popUpController?.label.text = "Video Odiye gönderiliyor."
                                            self.popUpController?.progressView.setProgress(0.0, animated: false)
                                        }
                                        self.uploadDefaultImage(image: self.thumbNailImage, imageName: self.newThumbnailName!, videoName: self.newVideoName!)
                                    }
                                    else{
                                        self.uploadVideoButton.isUserInteractionEnabled = true
                                        self.uploadVideoButton.alpha = 1
                                        self.myShowAlertForProblem(message: "Video yüklenemedi. Lütfen videoyu tekrar yüklemek için ekranın sağ alt köşesindeki yükle düğmesine basın. Eğer hata tekrarlıyor ise videoyunuzu kaydedip daha sonra da yükleyebilirsiniz. Anlayışınız için teşekkür ederiz.kod:883")
                                    }
                                }
                            }, progressHandlar: {value in
                                if self.popUpController != nil {
                                    DispatchQueue.main.async { () -> Void in
                                        self.popUpController?.setProgress(progressValue: value)
                                    }
                                }
                                                
                            })
                        }else {
                            print("Çeviri başarısız oldu")
                            self.uploadVideoButton.isUserInteractionEnabled = true
                            self.uploadVideoButton.alpha = 1
                            self.myShowAlertForProblem(message: "Video yüklenemedi. Lütfen videoyu tekrar yüklemek için ekranın sağ alt köşesindeki yükle düğmesine basın. Eğer hata tekrarlıyor ise videoyunuzu kaydedip daha sonra da yükleyebilirsiniz. Anlayışınız için teşekkür ederiz.kod:880")
                        }
                    }) { (progressPer) in
                        DispatchQueue.main.async {
                            if (self.popUpController == nil) {
                                self.popUpController = self.SHOW_SIC(type: .compressVideo)
                            }else {
                                self.popUpController?.progressView.setProgress(0.0, animated: false)
                            }
                            self.popUpController?.setProgress(progressValue:progressPer)
                        }
                    }
                    
                    // --
                    break
                case .failed:
                    break
                case .cancelled:
                    break
                @unknown default: break
                    //
                }
            }
        }else {
            self.videoCustomCompress(inputURL: self.videoURL!, outputURL: compressedURL, completion: { (status) in
                if (status) { // çeviri başarılı
                    var newData:Data?
                    do {
                        newData = try Data(contentsOf:  compressedURL) // videoURL compressedURL
                    } catch {
                        print("compress: Unable to load data: \(error)")
                    }
                                    
                    self.currentTime = Date().getCurrentHour()
                    print("compress: ftp ye gönderecek ")
                                    
        
                    
                    self.newVideoName = "\(self.videoId)_\(self.userId)_VID_\(Date().getTodayDateString())_\(self.currentTime).mp4"
                    self.newThumbnailName = "\(self.videoId)_\(self.userId)_VID_\(Date().getTodayDateString())_\(self.currentTime).jpg"
                    
                    if self.showreelStatus {
                        self.newVideoName = "showreel_\(self.userId).mp4"
                        self.newThumbnailName = "showreel_\(self.userId).jpg"
                    }
                    
                    /*
                    if self.showreelStatus {
                        self.newVideoName = "showreel_\(self.userId).mp4"
                        self.newThumbnailName = "showreel_\(self.userId).jpg"
                    }
                    
                    if self.tanitimStatus {
                        self.newVideoName = "tanitim_\(self.userId).mp4"
                        self.newThumbnailName = "tanitim_\(self.userId).jpg"
                    }*/
                    
                    self.ftp.send(data:  newData! , with: self.newVideoName!, success: { success in
                        DispatchQueue.main.async {
                            if success {
                                if self.popUpController != nil {
                                    self.popUpController?.label.text = "Video Odiye gönderiliyor."
                                    self.popUpController?.progressView.setProgress(0.0, animated: false)
                                }
                                self.uploadDefaultImage(image: self.thumbNailImage, imageName: self.newThumbnailName!, videoName: self.newVideoName!)
                            }
                            else{
                                self.uploadVideoButton.isUserInteractionEnabled = true
                                self.uploadVideoButton.alpha = 1
                                self.myShowAlertForProblem(message: "Video yüklenemedi. Lütfen videoyu tekrar yüklemek için ekranın sağ alt köşesindeki yükle düğmesine basın. Eğer hata tekrarlıyor ise videoyunuzu kaydedip daha sonra da yükleyebilirsiniz. Anlayışınız için teşekkür ederiz.kod:886")
                            }
                        }
                    }, progressHandlar: {value in
                        if self.popUpController != nil {
                            DispatchQueue.main.async { () -> Void in
                                self.popUpController?.setProgress(progressValue: value)
                            }
                        }
                                        
                    })
                }else {
                    self.uploadVideoButton.isUserInteractionEnabled = true
                    self.uploadVideoButton.alpha = 1
                    self.myShowAlertForProblem(message: "Video yüklenemedi. Lütfen videoyu tekrar yüklemek için ekranın sağ alt köşesindeki yükle düğmesine basın. Eğer hata tekrarlıyor ise videoyunuzu kaydedip daha sonra da yükleyebilirsiniz. Anlayışınız için teşekkür ederiz.kod:887")
                }
            }) { (progressPer) in
                DispatchQueue.main.async {
                    if (self.popUpController == nil) {
                        self.popUpController = self.SHOW_SIC(type: .compressVideo)
                    }
                    self.popUpController?.setProgress(progressValue:progressPer)
                }
            }
        }
        
        /*
        self.videoCustomCompress(inputURL: self.videoURL!, outputURL: compressedURL, completion: { (status) in
            if (status) { // çeviri başarılı
                var newData:Data?
                do {
                    newData = try Data(contentsOf:  compressedURL) // videoURL compressedURL
                } catch {
                    print("compress: Unable to load data: \(error)")
                }
                                
                self.currentTime = Date().getCurrentHour()
                print("compress: ftp ye gönderecek ")
                                
                self.ftp.send(data:  newData! , with: "\(self.videoId)_\(self.userId)_VID_\(Date().getTodayDateString())_\(self.currentTime).mp4", success: { success in
                    DispatchQueue.main.async {
                        if success {
                            if self.popUpController != nil {
                                self.popUpController?.label.text = "Video Odiye gönderiliyor."
                                self.popUpController?.progressView.setProgress(0.0, animated: false)
                            }
                            self.uploadDefaultImage(image: self.thumbNailImage)
                        }
                        else{
                            self.myShowAlertForProblem(message: "Video yüklenemedi. Lütfen tekrar deneyiniz.")
                        }
                    }
                }, progressHandlar: {value in
                    if self.popUpController != nil {
                        DispatchQueue.main.async { () -> Void in
                            self.popUpController?.setProgress(progressValue: value)
                        }
                    }
                                    
                })
            }else {
                print("Çeviri başarısız oldu")
            }
        }) { (progressPer) in
            DispatchQueue.main.async {
                if (self.popUpController == nil) {
                    self.popUpController = self.SHOW_SIC(type: .compressVideo)
                }
                self.popUpController?.setProgress(progressValue:progressPer)
            }
        }*/
    }
    
    func myShowAlertForProblem(message: String) {
        self.HIDE_SIC(customView: self.view)
        
        let refreshAlert = UIAlertController(title: "", message: message, preferredStyle: UIAlertController.Style.alert)
        
        refreshAlert.addAction(UIAlertAction(title: "Anladım", style: .default, handler: { (action: UIAlertAction!) in
            //self.mySendVideo()
            self.uploadVideoButton.isUserInteractionEnabled = true
            self.uploadVideoButton.alpha = 1
        }))
        
        present(refreshAlert, animated: true, completion: nil)
    }
    
    
    @IBOutlet var saveAlbumButton: UIButton!
    @IBAction func saveAlbumAction(_ sender: Any) {
        print("albume kaydet -- ")
        /*
          Kameradan geldiğinde alert göster eğer gallery sayfasına giderse temp deki video yu sil.
         */
        saveVideoGallery()
    }
    
    private func saveVideoGallery() {
        saveAnimation()
        
        DispatchQueue.main.async {
            self.saveAlbumButton.alpha = 0.5
            self.saveAlbumButton.isUserInteractionEnabled = false
        }
               
        let videoNameArray = filePath.components(separatedBy: "/")
               
        let vn = videoNameArray[videoNameArray.count - 1]
        print("\(self.TAG) dataÇözüm: video ismi: \(vn)")
        
        let newName = "\(self.videoId)_\(self.userId)_VID_\(Date().dateNameVideoString())_\(self.currentTime).mp4"
        
        // video kaydedildi ve yazıldı.
        self.videoURL = videoFolder?.appendingPathComponent(newName)
        
        var cameraStatus:String = "front";
        if isFrontCamera {
            cameraStatus = "front"
        }else {
            cameraStatus = "back"
        }
               
        dbManager?.saveVideo(videoName: vn, newName: newName, projectId: videoId, cameraStatus: cameraStatus, onStatus: { (check) in
            if let check = check {
                if (check) {
                    print("\(self.TAG): dataÇözüm: video başarılı bir şekilde kaydedildi. durum \(check)")
                    print("\(self.TAG): dataÇözüm: önceki isim: \(vn) kaydedilen isim \(newName)")
                }else {
                    print("\(self.TAG): dataÇözüm: video yüklenemedi problem false")
                }
            }
        }, onFailure: { (error) in
            print("\(self.TAG): dataÇözüm: hata \(error.debugDescription) ")
        })
        
        dbManager?.getVideoByProjectId(projectId: videoId , onSuccess: { (status, data:[videoModel]?) in
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
                    }
                }
            }
        }, onFailure: { (error:Error?) in
            
        })
    }
    
    @objc func video(_ videoPath: String, didFinishSavingWithError error: Error?, contextInfo info: AnyObject) {
        let title = (error == nil) ? "Başarılı" : "Hata"
        let message = (error == nil) ? "Video fotoğraflara kaydedildi." : "Video kaydedilirken bir hata oluştu."
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tamam", style: UIAlertAction.Style.cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    
    @IBOutlet weak var videoView: UIView!
    private var player : Player!
    func showAlert(message: String) {
        self.HIDE_SIC(customView: self.view)
        let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
        
        // Create the actions
        let okAction = UIAlertAction(title: "Tamam",style: UIAlertAction.Style.default) {
            UIAlertAction in
            if self.presentingViewController != nil {
                self.dismiss(animated: false, completion: {
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "transitionBack"), object: nil, userInfo: nil)
                    // app
                    //
                })
            }
            else {
                self.navigationController?.popToRootViewController(animated: true)
            }
        }
        // Add the actions
        alertController.addAction(okAction)
        // Present the controller
        self.present(alertController, animated: true, completion: nil)
    }
    
    func showAlert2(message: String) {
        self.HIDE_SIC(customView: self.view)
        let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "Tamam",style: UIAlertAction.Style.default) {
            UIAlertAction in
            if self.presentingViewController != nil {
                self.dismiss(animated: false, completion: {
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "transitionBack"), object: nil, userInfo: nil)
                })
            }
            else {
                self.navigationController?.popToRootViewController(animated: true)
            }
        }
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
    func showAlertForNotFinishedCapture(message: String) {
        self.HIDE_SIC(customView: self.view)
        let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "Tamam",style: UIAlertAction.Style.default) {
            UIAlertAction in
           
        }
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
    // burası
    func addVideoGalleruy(filePath: String,compressedURL: URL){
        guard let compressedData = NSData(contentsOf: compressedURL) else {
            return
        }
        DispatchQueue.global(qos: .background).async {
            DispatchQueue.main.async {
                compressedData.write(toFile: filePath, atomically: true)
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: URL(fileURLWithPath: filePath))
                }) { completed, error in
                    if completed {
                        //ALERT
                        let title = (error == nil) ? "Başarılı" : "Hata"
                        let message = (error == nil) ? "Video kaydedildi" : "Video kaydedilirken bir hata oluştu."
                        
                        if (error == nil) {
                            DispatchQueue.main.async { // Correct
                                 self.saveAlbumButton.isHidden = true
                            }
                        }
                        
                        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Tamam", style: UIAlertAction.Style.cancel, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    }
                }
            }
        }
    }
    
    func getAnimationThumbnailFrom(path: URL,
                                   onCallback callback: @escaping (UIImage?) -> Void,
                                   onFailure failure: @escaping (Error?) -> Void){
        do {
            let asset = AVURLAsset(url: path , options: nil)
            let imgGenerator = AVAssetImageGenerator(asset: asset)
            imgGenerator.appliesPreferredTrackTransform = true
            let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(value: 0, timescale: 1), actualTime: nil)
            let thumbnail = UIImage(cgImage: cgImage)
            callback(thumbnail)
        } catch let error {
            print("*** Error generating thumbnail: \(error.localizedDescription)")
            failure(error)
        }
    }
    
    // image çevirir.
    func getThumbnailFrom(path: URL) -> UIImage? {
        do {
            let asset = AVURLAsset(url: path , options: nil)
            let imgGenerator = AVAssetImageGenerator(asset: asset)
            let clipVideoTrack = asset.tracks(withMediaType: AVMediaType.video).first! as AVAssetTrack
            let size = CGSize(width: clipVideoTrack.naturalSize.width, height: clipVideoTrack.naturalSize.height)
            
            var newSize:CGSize?
            if size.width >= size.height {
                let rate = size.width / size.height
                let newWidth:CGFloat = 320
                let newHeight = newWidth / rate
                newSize = CGSize(width: newWidth, height: newHeight)
            }
            
            imgGenerator.maximumSize = newSize!
            imgGenerator.appliesPreferredTrackTransform = true
            let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(value: 0, timescale: 1), actualTime: nil)
            let thumbnail = UIImage(cgImage: cgImage)
            let newThumbnail:UIImage = resizeImage2(image: thumbnail, targetSize: CGSize(width: 320, height: 180))
            let flippedImage = UIImage(cgImage: newThumbnail.cgImage!, scale: newThumbnail.scale, orientation: UIImage.Orientation.upMirrored)
            
            return flippedImage
            
        } catch let error {
            
            print("*** Error generating thumbnail: \(error.localizedDescription)")
            return nil
            
        }
        
    }
    
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage? {
        let size = image.size
        let widthRatio  = targetSize.width  / size.width
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
        return newImage
    }
    
    //72 dpi
    func resizeImage2(image:UIImage, targetSize:CGSize = CGSize(width: 320, height: 180)) -> UIImage{
        var newSize:CGSize = targetSize
        if UIScreen.main.scale == 2.0 && UIScreen.main.responds(to: #selector(NSDecimalNumberBehaviors.scale)) {
            
        }else {
            newSize = CGSize(width: targetSize.width/2.0, height: targetSize.height/2.0)
        }
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        
        let context = UIGraphicsGetCurrentContext()
        context!.interpolationQuality = .high
        let flipVertical = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: newSize.height)
        context!.concatenate(flipVertical)
        context!.draw(image.cgImage!, in: CGRect(x: 0.0, y: 0.0, width: image.size.width, height: image.size.height))
        
        let newImage2:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage2
    }
    
    func uploadDefaultImage(image: UIImage, imageName:String, videoName:String) {
        DispatchQueue.global(qos: .background).async {
            guard let imageData = image.jpegData(compressionQuality: 0.6) else { return }
            //self.ftp.send(data:  imageData , with: "\(self.videoId)_\(self.userId)_VID_\(Date().getTodayDateString())_\(self.currentTime).jpg", success: { error in
            self.ftp.send(data:  imageData , with: imageName, success: { error in
                DispatchQueue.main.async {
                    if error {
                        self.isImageUpload = true
                        //
                        //let url = URL(string: "http://odi.odiapp.com.tr/upld.php?fileName=\(self.videoId)_\(self.userId)_VID_\(Date().getTodayDateString())_\(self.currentTime).mp4")!
                        //let url = URL(string: "http://odi.odiapp.com.tr/upld.php?fileName=_VID_\(Date().getTodayDateString())_\(self.currentTime).mp4")!
                        
                        let url = URL(string: "http://odi.odiapp.com.tr/upld.php?fileName=\(videoName)&uzanti=mp4")!// değiştirme
                        print("gönderilen: request \(url)")
                        let request = URLRequest(url: url)
                        self.webViewForSuccess = WKWebView(frame: CGRect.zero)
                        self.webViewForSuccess?.isHidden = true
                        self.view.addSubview(self.webViewForSuccess!)
                        self.webViewForSuccess!.navigationDelegate = self
                        self.webViewForSuccess!.load(request)
                    }
                    else{
                        self.showAlert2(message: "İşleminizi şuanda gerçekleştiremiyoruz. kod:33")
                    }
                    
                }
            }, progressHandlar: {value in
                if self.popUpController != nil {
                    DispatchQueue.main.async { () -> Void in
                        self.popUpController?.setProgress(progressValue: value)
                    }
                }
            })
        }
    }
    
    func degreeToRadian(_ x: CGFloat) -> CGFloat {
        return .pi * x / 180.0
    }
    
    func compressVideo(inputURL: URL, outputURL: URL, handler:@escaping (_ exportSession: AVAssetExportSession?)-> Void) {
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
        
        // değiştirme AVAssetExportPreset960x540
        guard let exportSession = AVAssetExportSession(asset: videoAsset, presetName: AVAssetExportPreset960x540 /*AVAssetExportPresetHighestQuality*/) else {
            handler(nil)
            return
        }
        
        exportSession.videoComposition = videoComposition
        exportSession.outputURL = outputURL
        // DEĞİŞTİRME
        exportSession.outputFileType = AVFileType.mp4
        // yeni
        
        let bitrateprint = clipVideoTrack.estimatedDataRate
        print("compress: bitrate: \(bitrateprint)")
        
        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.exportAsynchronously { () -> Void in
            handler(exportSession)
        }
        
        if (self.popUpController == nil) {
            self.popUpController = self.SHOW_SIC(type: .compressVideo)
        }
        
        DispatchQueue.global(qos: .background).async { () -> Void in
            while exportSession.status == .waiting || exportSession.status == .exporting {
                DispatchQueue.main.async { () -> Void in
                    self.popUpController?.setProgress(progressValue: exportSession.progress)
                }
            }
        }
    }
    
    private func getVideoComposition(asset: AVAsset, videoSize: CGSize) -> AVMutableVideoComposition? {

        guard let videoTrack = asset.tracks(withMediaType: AVMediaType.video).first else {
            print("Unable to get video tracks")
            return nil
        }

        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = videoSize

        let seconds: Float64 = Float64(1.0 / videoTrack.nominalFrameRate)
        videoComposition.frameDuration = CMTimeMakeWithSeconds(seconds, preferredTimescale: 600);

        let layerInst = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)

        var transforms = asset.preferredTransform
        transforms = transforms.concatenating(CGAffineTransform(rotationAngle: CGFloat(90.0 * .pi / 180)))
        transforms = transforms.concatenating(CGAffineTransform(translationX: videoSize.width, y: 0))
        layerInst.setTransform(transforms, at: CMTime.zero)

        let inst = AVMutableVideoCompositionInstruction()
        inst.backgroundColor = UIColor.black.cgColor
        inst.layerInstructions = [layerInst]
        inst.timeRange = CMTimeRange(start: CMTime.zero, duration: asset.duration)

        videoComposition.instructions = [inst]
        return videoComposition

    }
    
}
//convertVideoToLowQuailtyWithInputURL
extension PlayVideoController {
    
    func videoCustomCompress(inputURL: URL, outputURL: URL, completion: @escaping (Bool) -> Void, progress:@escaping (Float) -> Void) {
        DispatchQueue.global(qos: .background).async {
            let videoAsset = AVURLAsset(url: inputURL, options: nil)
            let videoTrack = videoAsset.tracks(withMediaType: AVMediaType.video)[0]
            //let videoSize = videoTrack.naturalSize
            let durationTime = CMTimeGetSeconds(videoAsset.duration)
            let videoSize = CGSize(width: 960, height: 540)
            let calcVideoRate = ((520*294)*24)*4*0.07 // faktör 1 2 4
            let videoWriterCompressionSettings = [
                AVVideoAverageBitRateKey : Int(calcVideoRate),
                AVVideoProfileLevelKey : AVVideoProfileLevelH264Main31
                ] as [String : Any]
            
            print("compress: time duration org:  \(videoAsset.duration)")
            print("compress: time duration seconds:  \(durationTime)")
            print("compress: time duration int :  \(Int(durationTime))")

            let videoWriterSettings:[String : AnyObject] = [
                AVVideoCodecKey : AVVideoCodecType.h264 as AnyObject,
                AVVideoCompressionPropertiesKey : videoWriterCompressionSettings as AnyObject,
                AVVideoWidthKey : Int(videoSize.width) as AnyObject,
                AVVideoHeightKey : Int(videoSize.height) as AnyObject
            ]

            let videoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoWriterSettings)
            videoWriterInput.expectsMediaDataInRealTime = true
            
            videoWriterInput.transform = videoTrack.preferredTransform
            
            let videoWriter = try! AVAssetWriter(outputURL: outputURL as URL, fileType: AVFileType.mov)
            videoWriter.add(videoWriterInput)
            
            let videoReaderSettings:[String : AnyObject] = [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange) as AnyObject
            ]

            let videoReaderOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: videoReaderSettings)
            var videoReader: AVAssetReader!

            do{
                videoReader = try AVAssetReader(asset: videoAsset)
            }
            catch {
                print("video okuyucu hatası: \(error)")
                completion(false)
            }
            
            videoReader.add(videoReaderOutput)
            
            let audioWriterInput = AVAssetWriterInput(mediaType: AVMediaType.audio, outputSettings: nil)
            audioWriterInput.expectsMediaDataInRealTime = false
            videoWriter.add(audioWriterInput)
            
            //audio Okuyucu
            let audioTrack = videoAsset.tracks(withMediaType: AVMediaType.audio)[0]
            let audioReaderOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: nil)
            let audioReader = try! AVAssetReader(asset: videoAsset)
            audioReader.add(audioReaderOutput)
            videoWriter.startWriting()
            

            videoReader.startReading()
            videoWriter.startSession(atSourceTime: CMTime.zero)
            let processingQueue = DispatchQueue(label: "processingQueue1")
            videoWriterInput.requestMediaDataWhenReady(on: processingQueue, using: {() -> Void in
                while videoWriterInput.isReadyForMoreMediaData {
                    let sampleBuffer:CMSampleBuffer? = videoReaderOutput.copyNextSampleBuffer();
                    // progress compresor...
                    if let sb1 = sampleBuffer{
                        let presTime1 = CMSampleBufferGetPresentationTimeStamp(sb1)
                        let timeSecond1 = CMTimeGetSeconds(presTime1)
                        let per = Float(timeSecond1 / durationTime)
                        progress(per)
                    }else {
                        print("compress biri veya ikiside eksik")
                    }
                    
                    if videoReader.status == .reading && sampleBuffer != nil {
                        videoWriterInput.append(sampleBuffer!)
                    }
                    else {
                        videoWriterInput.markAsFinished()
                        if videoReader.status == .completed {
                            //ses yazılıyor...
                            audioReader.startReading()
                            videoWriter.startSession(atSourceTime: CMTime.zero)
                            let processingQueue = DispatchQueue(label: "processingQueue2")
                            audioWriterInput.requestMediaDataWhenReady(on: processingQueue, using: {() -> Void in
                                while audioWriterInput.isReadyForMoreMediaData {
                                    let _sampleBuffer:CMSampleBuffer? = audioReaderOutput.copyNextSampleBuffer()
                                    if audioReader.status == .reading && _sampleBuffer != nil {
                                        audioWriterInput.append(_sampleBuffer!)
                                    }
                                    else {
                                        audioWriterInput.markAsFinished()
                                        if audioReader.status == .completed {
                                            
                                            videoWriter.finishWriting(completionHandler: {() -> Void in
                                                completion(true)
                                                 print("compress: finishwriting")
                                                videoWriter.cancelWriting()
                                                videoReader.cancelReading()
                                                audioReader.cancelReading()
                                            })
                                        }
                                    }
                                }
                            })
                        }
                    }
                }
            })
        }
    }
    
    private func getVideoTransform() -> CGAffineTransform {
        switch UIDevice.current.orientation {
            case .portrait:
                return .identity
            case .portraitUpsideDown:
                return CGAffineTransform(rotationAngle: .pi)
            case .landscapeLeft:
                print("convert: ters çevrilecek")
                return CGAffineTransform(rotationAngle: .pi)//CGAffineTransform(scaleX: -1, y: 1)//CGAffineTransform(rotationAngle: .pi)
            case .landscapeRight:
                return CGAffineTransform(rotationAngle: -.pi/2)
            default:
                return .identity
            }
    }

}

extension PlayVideoController : WKNavigationDelegate {
    func webView(_ webView: WKWebView,
                 didFinish navigation: WKNavigation!) {
        if !isImageUpload {
            uploadDefaultImage(image: self.thumbNailImage, imageName: self.newThumbnailName!, videoName: self.newVideoName!)
        }else{
            showAlert(message: "İşleminiz başarı ile gerçekleştirildi")
        }
    }
}

extension PlayVideoController: PlayerDelegate {
    
    func playerReady(_ player: Player) {
        print("playerReady ")
    }
    
    func playerPlaybackStateDidChange(_ player: Player) {
        //print("playerPlaybackStateDidChange \(player.playbackState)")
        if player.playbackState == PlaybackState.playing {
            print("ÇALIYOR")
        }
        if player.playbackState == PlaybackState.paused {
            print("DURDURULDU")
        }
        if player.playbackState == PlaybackState.failed {
            print("HATA")
        }
    }
    
    func playerBufferingStateDidChange(_ player: Player) {
        //loadingIndicatorView.stopAnimating()
        print("playerBufferingStateDidChange ")
    }
    
    func playerPlaybackWillStartFromBeginning(_ player: Player) {
        print("playerPlaybackWillStartFromBeginning ")
    }
    
    func playerPlaybackDidEnd(_ player: Player) {
        print("playerPlaybackDidEnd ")
        setProgressBarHidden(status: false)
        setPlayPauseStatus(status: PlayVideoController.playerStatus.pause)
        let seekTime = CMTime.zero
        self.player.seekToTime(seekTime)
    }
    
    func playerCurrentTimeDidChange(_ player: Player) {
        if (self.myProgress.isTracking) {
            return
        }
        let fraction = Double(player.currentTime) / Double(player.maximumDuration)
        myProgress.setValue(Float(fraction), animated: true)
    }
    
    func playerWillComeThroughLoop(_ player: Player) {
        print("playerWillComeThroughLoop ")
    }
    
    func playerCurrentTime(_ player: String) {
        //print("Time:", player)
        //print("Baran")
         //print("playerWillComeThroughLoop \(player)")
        
    }
    
}

