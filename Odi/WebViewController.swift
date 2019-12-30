//
//  ViewController.swift
//  Odi
//
//  Created by bilal on 21/12/2017.
//  Copyright © 2017 bilal. All rights reserved.
//

import UIKit
import WebKit
import AVFoundation
import Photos
import AVKit
import Reachability

import MessageUI

import Photos
import Crashlytics

class WebViewController: BaseViewController, WKScriptMessageHandler, WKNavigationDelegate,WKUIDelegate,MFMailComposeViewControllerDelegate{
    
    
    private let TAG:String = "WebViewController: "
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let viewAnimateHiddenOrigin : CGPoint = {
        let y : CGFloat =  -UIScreen.main.bounds.height
        let x : CGFloat = 0
        let coordinate = CGPoint.init(x: x, y: y)
        return coordinate
    }()
    let fullScreenOrigin : CGPoint = CGPoint.init(x: 0, y: 0)
    var updateTimer:Timer?
    @IBOutlet weak var webViewContainer: UIView!
    @IBOutlet var LaunchView: UIView!
    @IBOutlet weak var viewBottom: UIView!
    
    func initialLaunchViewConfigure(){
        self.LaunchView.alpha = 1.0
        self.LaunchView.frame = UIScreen.main.bounds
        self.LaunchView.frame.origin = fullScreenOrigin
        self.view.addSubview(LaunchView)
    }
    
    func hideLaunchScreenWithAnimate(){
        UIView.animate(withDuration: 2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 5, options: [.beginFromCurrentState], animations: {
            self.LaunchView.alpha = 0.4
            self.LaunchView.frame.origin = self.viewAnimateHiddenOrigin
        })
    }
    
    private func webViewReloaded(){
        webView?.reload()
    }
    
    // MARK: -
    var popUpController : SIC?
    var webView: FullScreenWKWebView?
    var webViewForSuccess: FullScreenWKWebView?
    var odiDataService = GetCameraServices()
    var odileData = (userId: "", videoId: "")
    var pickerController = UIImagePickerController()
    var service : UploadImageService = UploadImageService()
    var isUpdatedProfileImage = false
    var oneSignalID = UserPrefence.getOneSignalId()
    //Response Model
    var odiResponseModel = GetCameraResponseModel()
    var webViewReloadBool = false
    var backToOdi = false
    var thumbNailImage = UIImage()
     var ftp = FTPUpload(baseUrl: "odi.odiapp.com.tr", userName: "odiFtp@odiapp.com.tr", password: "Root123*" , directoryPath: "/img/")
    
    var timeOut:Timer?
    
    var dbMan:kayaDbManager?
    
    var verControl: APPVersionControl?
    let trans = galleryTransitionManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dbMan = kayaDbManager.sharedInstance
        
        /// crash test Button
        /*
        let button = UIButton(type: .roundedRect)
        button.frame = CGRect(x: 20, y: 50, width: 100, height: 30)
        button.setTitle("Crash", for: [])
        button.addTarget(self, action: #selector(self.crashButtonTapped(_:)), for: .touchUpInside)
        view.addSubview(button)
 */
        
        dbMan?.clearTimeOutVideo(onSuccess: { (status) in
            print("diff: işlem bitirildi")
        }, onFailure: { (error:DATABASE_STATUS?) in
            print("diff: \(String(describing: error))")
        })
        
        dbMan?.clearTempFile()
        
        startTimer()
        
        let o = WKUserContentController()
        o.add(self, name: "foo")
        let config = WKWebViewConfiguration()
        config.userContentController = o
        self.webView = FullScreenWKWebView(frame: self.webViewContainer.bounds, configuration: config)
        self.view.addSubview(self.webView!)
        webViewContainer.addSubview(webView!)
        webView?.uiDelegate = self
        self.webView?.navigationDelegate = self
        self.addConstraints(to: webView!, with: self.webViewContainer)
        let url = URL(string:"http://odi.odiapp.com.tr/?kulID=\(oneSignalID)")
        let request = URLRequest(url: url!)
        webView!.load(request)
        self.webView?.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil);
        self.addObserver()
        
        if appDelegate.firstLogin {
            self.initialLaunchViewConfigure()
        }
        
        verControl = APPVersionControl()
    }
    /*
    @IBAction func crashButtonTapped(_ sender: AnyObject) {
        Crashlytics.sharedInstance().crash()
    }
     */
    
    func versionControlCheck() {
        verControl?.checkVersion(onCallback: { (status, str) in
            if let status = status, let str = str {
                if status {
                    let storyBoard = UIStoryboard(name: "Main", bundle: nil)
                    let alertViewController = (storyBoard.instantiateViewController(withIdentifier: "versionVC") as! versionViewController)
                    alertViewController.modalPresentationStyle = .overFullScreen
                    alertViewController.transitioningDelegate = self.trans
                    alertViewController.commentText = str
                    DispatchQueue.main.async {
                        self.present(alertViewController, animated: true, completion: nil)
                    }
                    
                }
            }
        })
    }
    
    @objc func fireTimer(timer: Timer) {
        if(timeOut != nil){
            timeOut?.invalidate()
            timeOut = nil
        }
        timerClean()
        timeOutAlert()
    }
    
    func timerClean() {
        if(timeOut != nil){
            timeOut?.invalidate()
            timeOut = nil
        }
    }
    
    func startTimer() {
        timerClean()
        timeOut = Timer.scheduledTimer(timeInterval: 15, target: self, selector: #selector(fireTimer), userInfo: nil, repeats: false)
    }
    
    func sendMail() {
        let emailTitle = "Sunucu bağlantı sorunu."
        let messageBody = "Odi Destek Ekibine; \n"
        let toRecipents = ["destek@odiapp.com.tr"]
        let mc: MFMailComposeViewController = MFMailComposeViewController()
        mc.mailComposeDelegate = self
        mc.setSubject(emailTitle)
        mc.setMessageBody(messageBody, isHTML: false)
        mc.setToRecipients(toRecipents)
        
        //self.presentViewController(mc, animated: true, completion: nil)
        self.present(mc, animated: true, completion: nil)
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        switch result {
        case .cancelled:
            print("Mail cancelled")
        case .failed:
            print("Mail failed failure: \(error!.localizedDescription)")
        case .sent:
            print("Mail sent")
        case .saved:
            print("Mail saved")
        default:
            break
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    func timeOutAlert() {
        let alert = UIAlertController(title: "Bağlantı Hatası!", message: "Şu an sunucuya bağlanılamıyor. Lütfen daha sonra tekrar deneyin, ya da Odi destek ekibiyle iletişime geçin.", preferredStyle: .alert)
        
//        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: nil))
//        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "İletişime Geç ", style: UIAlertAction.Style.destructive, handler: { (act) in
            self.sendMail()
        }))
        alert.addAction(UIAlertAction(title: "Tamam", style: UIAlertAction.Style.default, handler: { (act) in
            
        }))
        
       
        self.present(alert, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(self.internetStatus(_:)), name: NSNotification.Name.ODI.INTERNET_CONNECTION_STATUS, object: nil)
        
        versionControlCheck()
        // preferredStatusBarStyle update etmek için gerekli
        setNeedsStatusBarAppearanceUpdate()
    }
    
    @objc func internetStatus(_ notification: Notification) {
        guard let status = notification.userInfo?["status"] as? Bool else { return }
        if (status) {
            if (LaunchView.alpha >= 0.4 ) {
                let url = URL(string:"http://odi.odiapp.com.tr/?kulID=\(oneSignalID)")
                let request = URLRequest(url: url!)
                webView!.load(request)
            }
            DispatchQueue.main.async {
                self.webView?.reload()
                self.startTimer()
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidAppear(animated)
        timerClean()
        NotificationCenter.default.removeObserver(NSNotification.Name.ODI.INTERNET_CONNECTION_STATUS)
    }
    
    
    func addConstraints(to webView: UIView, with superView: UIView) {
        webView.translatesAutoresizingMaskIntoConstraints = false
        let leadingConstraint = NSLayoutConstraint(item: webView, attribute: .leading, relatedBy: .equal, toItem: superView, attribute: .leading, multiplier: 1, constant: 0)
        let trailingConstraint = NSLayoutConstraint(item: webView, attribute: .trailing, relatedBy: .equal, toItem: superView, attribute: .trailing, multiplier: 1, constant: 0)
        let topConstraint = NSLayoutConstraint(item: webView, attribute: .top, relatedBy: .equal, toItem: superView, attribute: .top, multiplier: 1, constant: 0.0)
        let bottomConstraint = NSLayoutConstraint(item: webView, attribute: .bottom, relatedBy: .equal, toItem: superView, attribute: .bottom, multiplier: 1, constant: 0)
        superView.addConstraints([leadingConstraint, trailingConstraint, topConstraint, bottomConstraint])
    }
    
    
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        //print("Sayfa yükleme: \(Float((self.webView?.estimatedProgress)!))")
        if (Float((self.webView?.estimatedProgress)!) >= 0.2) {
            timerClean()
        }else {
            timerClean()
            startTimer()
        }
        
        DispatchQueue.global(qos: .background).async { [weak self] () -> Void in
            if keyPath == "estimatedProgress" {
                if self?.popUpController != nil && self?.popUpController?.type == .reload {
                    DispatchQueue.main.async { () -> Void in
                        self?.popUpController?.setProgress(progressValue: Float((self?.webView?.estimatedProgress)!))
                        if Float((self?.webView?.estimatedProgress)!) == 1 {
                            self?.HIDE_SIC(customView: (self?.view)!)
                        }
                    }
                }
            }
        }
    }
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        //print(message.name)
        //print(message.body)
        if(message.name == "foo") {
            //print("JavaScript is sending a message \(message.body)")
            if let src = message.body as? String {
                let goTo = parseString(src:src)
                switch (goTo) {
                case 1:
                    self.odiDataService.serviceDelegate = self
                    self.odiDataService.connectService(serviceUrl: ("http://odi.odiapp.com.tr/core/odi.php?id=" + odileData.videoId))
                case 2:
                    //print("no 2")
                    performSegue(withIdentifier: "gotoPhotos", sender: nil)
                case 3:
                    //print("no 3")
                    
                    
                    service.serviceDelegate = self
                    //self.requestAlertViewForImage(pickerController: pickerController, vc: self,)
                    self.requestAlertViewForImage(pickerController: pickerController, vc: self) { (key) in
                        //print("TETİK VAR")
                        if (key == "photo") {
                            print("Seçilen photo")
                            self.checkPermissionPhoto()
                        }else{
                            print("Seçilen kamera")
                            self.checkPermissionCamera()
                        }
                    }
                    print("UserID:", odileData.userId)
                case 4:
                    UIApplication.shared.open(URL(string : odileData.userId)!, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: { (status) in
                    })
                case 5:
                    // photo picker
                    print("no 5")
                    self.requestAlertViewForVideo(pickerController: pickerController, vc: self)
                case 6:
                    print("no 6")
                    self.requestAlertViewForVideo(pickerController: pickerController, vc: self)
                case 7:
                    print("UserID:",self.odileData.userId)
                    playTrailer(videoPath: self.odileData.userId)
                default:break;
                }
            }
        }
    }
    
    
    private func checkPermissionPhoto() {
        let photos = PHPhotoLibrary.authorizationStatus()
        if photos == .notDetermined {
            PHPhotoLibrary.requestAuthorization({status in
                if status == .authorized{
                    // izin var direk işlem
                    self.kayaOpenGallery(pickerController: self.pickerController, vc: self)
                } else {
                    print("\(self.TAG) authorized else")
                }
            })
        } else if photos == .authorized {
            // işlem
            self.kayaOpenGallery(pickerController: self.pickerController, vc: self)
        } else if photos == .restricted {
            print("\(self.TAG) restricted else")
        }else{
            PHPhotoLibrary.requestAuthorization({status in
                if status == .authorized{
                    // işlem
                    self.kayaOpenGallery(pickerController: self.pickerController, vc: self)
                } else {
                    DispatchQueue.main.async {
                        let permision = UIAlertController (title: "İzin Yok!", message: "Odi'nin fotoğraflarına ulaşması için iznine ihtiyacı var. Hemen \n'Ayarlar' -> 'Odi' -> 'Fotoğraflar' \nsekmesinden 'Okuma ve Yazma' seçeneğini seçin.", preferredStyle: .alert)
                        
                        let settingsAction = UIAlertAction(title: "Ayarlar", style: .default) { (_) -> Void in
                            let settingsUrl = NSURL(string:UIApplication.openSettingsURLString)
                            if let url = settingsUrl {
                                DispatchQueue.main.async {
                                    UIApplication.shared.open(url as URL, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
                                }
                            }
                        }
                        
                        let cancelAction = UIAlertAction(title: "İptal", style: UIAlertAction.Style.destructive, handler: { (act) in
                            //self.navigationController?.popViewController(animated: true)
                            //NotificationCenter.default.post(name: NSNotification.Name(rawValue: "transitionBackToWebview"), object: nil, userInfo: nil)
                        })
                        permision .addAction(settingsAction)
                        permision .addAction(cancelAction)
                        self.present(permision, animated: true, completion: nil)
                    }
                    print("\(self.TAG) else authorized else")
                    
                }
            })
        }
    }
    
    func checkPermissionCamera() {
        if AVCaptureDevice.authorizationStatus(for: AVMediaType.video) == .authorized{
            //already authorized
            self.kayaOpenCamera(pickerController: self.pickerController, vc: self)
        } else {
            //print("Camera: izinler yok")
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { (granted: Bool) in
                if granted {
                    //print("Camera: video izni var")
                    self.kayaOpenCamera(pickerController: self.pickerController, vc: self)
                } else {
                    DispatchQueue.main.async {
                        let permision = UIAlertController (title: "İzin Yok!", message: "Odi'nin fotoğraf çekmesi için kamera iznine ihtiyacı var. Fotoğraf çekebilmek için hemen \n'Ayarlar' -> 'Odi' -> 'Kamera' \nsekmesindeki izni açmalısınız.", preferredStyle: .alert)
                        
                        let settingsAction = UIAlertAction(title: "Ayarlar", style: .default) { (_) -> Void in
                            let settingsUrl = NSURL(string:UIApplication.openSettingsURLString)
                            if let url = settingsUrl {
                                DispatchQueue.main.async {
                                    UIApplication.shared.open(url as URL, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
                                }
                            }
                        }
                        
                        let cancelAction = UIAlertAction(title: "İptal", style: UIAlertAction.Style.destructive, handler: { (act) in
                        })
                        permision .addAction(settingsAction)
                        permision .addAction(cancelAction)
                        self.present(permision, animated: true, completion: nil)
                    }
                }
            })
            
            
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let backItem = UIBarButtonItem()
        backItem.title = "Geri"
        navigationItem.backBarButtonItem = backItem
        if let destinationNavigationController = segue.destination as? UINavigationController {
            /*if let vc = destinationNavigationController.topViewController as? CameraViewController { // note: değiştirme
                vc.odiResponseModel = self.odiResponseModel
                vc.odileData = self.odileData
            }
            if let vc = destinationNavigationController.topViewController as? KayaCamManViewController { // note: değiştirme
                vc.odiResponseModel = self.odiResponseModel
                vc.odileData = self.odileData
            }*/
            if let vc = destinationNavigationController.topViewController as? fakeViewController { // note: değiştirme
                vc.odiResponseModel = self.odiResponseModel
                vc.odileData = self.odileData
            }
        }
        if let vc = segue.destination as? PhotosViewController {
            vc.id = self.odileData.userId
        }
    }
    
    func parseString(src: String) ->Int {
        if src.range(of:"design/odile.png?") != nil {
            let stringArray = src.components(separatedBy: "-")
            self.odileData.userId = stringArray[1]
            self.odileData.videoId = stringArray[2]
            
            Crashlytics.sharedInstance().setUserIdentifier(self.odileData.userId)
            return 1
        } else if src.range(of: "design/updateprofil.png?") != nil || src.range(of: "design/fotosec.png?id") != nil {
            let stringArray = src.components(separatedBy: "=")
            self.odileData.userId = stringArray[1]
            
            Crashlytics.sharedInstance().setUserIdentifier(self.odileData.userId)
            return 2
        } else if src.range(of: "design/prf.png?") != nil {
            let stringArray = src.components(separatedBy: "=")
            self.odileData.userId = stringArray[1]
            
            Crashlytics.sharedInstance().setUserIdentifier(self.odileData.userId)
            return 3
        } else if src.range(of: "link") != nil {
            let stringArray = src.components(separatedBy: "=")
            self.odileData.userId = stringArray[1] //userID is link
            
            Crashlytics.sharedInstance().setUserIdentifier(self.odileData.userId)
            return 4
        } else if src.range(of: "ek=showreel") != nil {
            let stringArray = src.components(separatedBy: "=")
            self.odileData.userId = stringArray[1] //userID is link
            
            Crashlytics.sharedInstance().setUserIdentifier(self.odileData.userId)
            return 5
        } else if src.range(of: "ek=tanitim") != nil {
            let stringArray = src.components(separatedBy: "=")
            self.odileData.userId = stringArray[1] //userID is link
            
            Crashlytics.sharedInstance().setUserIdentifier(self.odileData.userId)
            return 6
        } else if src.range(of: "videoPlayer=") != nil {
            let stringArray = src.components(separatedBy: "=")
            self.odileData.userId = stringArray[1] //userID is link
            Crashlytics.sharedInstance().setUserIdentifier(self.odileData.userId)
            return 7
        }
        return 0
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewWillAppear(_ animated: Bool) {
        AppUtility.lockOrientation(.portrait)
        //UIApplication.shared.statusBarStyle = .lightContent
        switch UIDevice.current.orientation {
        case .portrait:break
                        
        default:break
        }
        self.navigationController?.isNavigationBarHidden = true
    }
    
    

    func webView(_ webView: WKWebView,
                 didFinish navigation: WKNavigation!) {
        if isUpdatedProfileImage == true {
            HIDE_SIC(customView: self.view)
            isUpdatedProfileImage = false
        }
        else if webViewReloadBool == true {
            HIDE_SIC(customView: self.view)
            webViewReloadBool = false
        }
        else if webView.tag == 5 {
            self.popUpController = SHOW_SIC(type: .reload)
            self.webView?.reload()
            self.webViewReloadBool = true
        }
        
        if appDelegate.firstLogin {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.hideLaunchScreenWithAnimate()
                self.appDelegate.firstLogin = false
            }
        }
    }
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let urlStr = navigationAction.request.url?.absoluteString {
            if urlStr == "http://odi.odiapp.com.tr/" {
                viewBottom.isHidden = true
            } else {
                viewBottom.isHidden = false
            }
        }
        decisionHandler(.allow)
    }
    
    
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
    
    func addObserver(){
        NotificationCenter.default.addObserver(self, selector: #selector(self.comeBack(notification:)), name: NSNotification.Name(rawValue: "transitionBackToWebview") , object: nil)
    }
    func removeObserver(){
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "transitionBackToWebview") , object: nil)
    }
    
    @objc func comeBack(notification: NSNotification){
        //print("\(self.TAG): comeBack:")
        myHolderView = nil
        self.popUpController = SHOW_SIC(type: .reload)
        webView?.reload()
        self.webViewReloadBool = true
    }
}

extension WebViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
   
    
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)
        let myVideoURL = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.mediaURL)] as? URL
    
        if odileData.userId.range(of:"showreel") != nil {
            let videoURL = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.mediaURL)] as? URL
            guard let videoData = NSData(contentsOf: videoURL!) else {
                return
            }
            if Double(videoData.length / 1048576) < 50 {
                do {
                    let videoData = try Data(contentsOf: videoURL!)
                    self.thumbNailImage = getThumbnailFrom(path: videoURL!)!
                    uploadVideo(videoData: videoData)
                } catch {
                    print("Unable to load data: \(error)")
                }
            } else {
                DispatchQueue.global(qos: .background).async { [weak self] () -> Void in
                    DispatchQueue.main.async { () -> Void in
                        self!.showAlert(message: "Yüklemeye çalıştığınız video boyutu 50MB' tan büyük.")
                    }
                }
            }
            self.dismiss(animated: true, completion: nil)
        } else if odileData.userId.range(of:"tanitim") != nil {
            print("&&Tanitim")
            let videoURL = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.mediaURL)] as? URL
            guard let videoData = NSData(contentsOf: videoURL!) else {
                return
            }
            
            if Double(videoData.length / 1048576) < 50 {
                print("File size after compression: \(Double(videoData.length / 1048576)) mb")
                do {
                    let videoData = try Data(contentsOf: videoURL!)
                    self.thumbNailImage = getThumbnailFrom(path: videoURL!)!
                    uploadVideo(videoData: videoData)
                } catch {
                    print("Unable to load data: \(error)")
                }
                print("videoURL:\(String(describing: videoURL))")
            } else {
                DispatchQueue.global(qos: .background).async { [weak self] () -> Void in
                    DispatchQueue.main.async { () -> Void in
                        self!.showAlert(message: "Yüklemeye çalıştığınız video boyutu 50MB' tan büyük.")
                    }
                }
                
            }
            
            self.dismiss(animated: true, completion: nil)
        } else {
            // profil photo
            let image = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.editedImage)] as! UIImage
            
            var sendImage:UIImage?
            if image.size.width >= image.size.height {
                
                print("sendImage: size: \(image.size)")
                if image.size.width > 500 {
                    print("sendImage: width: ")
                    
                    let rate:Double = Double(image.size.width) / Double(image.size.height)
                    
                    let newWidth:Double = 500
                    let newHeight:Double = 500 / rate
                    print("sendImage: newSize: \(newWidth) - \(newHeight)")
                    let newImage = resizeImage(image: image, targetSize: CGSize(width: newWidth, height: newHeight))
                    sendImage = newImage!
                }else {
                    // orjinal image yolla
                    print("sendImage: width: orjinal gidecek")
                    sendImage = image
                }
            }else {
                if image.size.height > 500 {
                    print("sendImage: height: ")
                    let rate:Double = Double(image.size.height) / Double(image.size.width)
                    let newHeight:Double = 500
                    let newWidth:Double = 500 / rate
                    
                    print("sendImage: newSize: \(newWidth) - \(newHeight)")
                    let newImage = resizeImage(image: image, targetSize: CGSize(width: newWidth, height: newHeight))
                    sendImage = newImage!
                }else {
                    print("sendImage: height: orjinal gidecek")
                    sendImage = image
                }
            }
            
            service.connectService(fileName: "profilImage_\(odileData.userId).jpg", image: sendImage!)
            self.webView?.navigationDelegate = self
            self.popUpController = self.SHOW_SIC(type: .profileImage)
            dismiss(animated:true, completion: nil)
        }   
    }
    
    // yeniden boyutlandırma
    func resizeImage(image: UIImage?, targetSize: CGSize) -> UIImage? {
        guard let image = image else { return nil }
        let size = image.size

        let widthRatio  = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height

        var newSize: CGSize
        if(widthRatio >= heightRatio) {
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
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.pickerController.dismiss(animated: true, completion: nil)
        print("Cancel")
    }
    
    func getThumbnailFrom(path: URL) -> UIImage? {
        do {
            
            let asset = AVURLAsset(url: path , options: nil)
            let imgGenerator = AVAssetImageGenerator(asset: asset)
            imgGenerator.appliesPreferredTrackTransform = true
            let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(value: 0, timescale: 1), actualTime: nil)
            let thumbnail = UIImage(cgImage: cgImage)
            return thumbnail
            
        } catch let error {
            
            print("*** Error generating thumbnail: \(error.localizedDescription)")
            return nil
            
        }
        
    }
    
     
    
}

extension WebViewController : GetCameraDelegate {
    func getError(errorMessage: String) {
        print(errorMessage)
    }
    
    // NOTE:  Data buradan çekiliyor...
    func getResponse(response: GetCameraResponseModel) {
        self.odiResponseModel = response
        AppUtility.lockOrientation(.landscapeRight)
        self.performSegue(withIdentifier: "CameraViewControllerID", sender: self)
    }
}

extension  WebViewController: UploadImageServiceDelegte {
    func progressHandler(value: Float) {
        print("UploadImageServiceDelegte: ",value)
        if let popup = popUpController {
            DispatchQueue.global(qos: .background).async {
                DispatchQueue.main.async { () -> Void in
                    popup.setProgress(progressValue: value)
                }
            }
        }
    }
    
    func getResponse(error: Bool) {
        if error {
            isUpdatedProfileImage = true
            let url = URL(string: "http://odi.odiapp.com.tr/?update=ok")!
            let request = URLRequest(url: url)
            webView!.load(request)
        } else {
            showAlert(message: "İşlem sırasında bir hata oluştu.")
        }
    }
    func showAlert(message: String) {
        self.HIDE_SIC(customView: self.view)
        let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "Tamam",style: UIAlertAction.Style.default) {
            UIAlertAction in
            self.navigationController?.popViewController(animated: true)
            
        }
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
}
//Mark: -Upload
extension WebViewController {
    func uploadVideo(videoData: Data){
        self.popUpController = self.SHOW_SIC(type: .video)
        DispatchQueue.global(qos: .background).async {
            //print((self.odileData.userId))
            self.ftp.send(data:  videoData , with: "\(self.odileData.userId).mp4", success: { error in // değiştirme
                DispatchQueue.main.async {
                    if error { // error true ise başarılı
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { // change 2 to desired number of seconds
                            if self.popUpController != nil {
                                self.popUpController?.label.text = "Video resmi yükleniyor."
                                self.popUpController?.progressView.setProgress(0.0, animated: false)
                            }
                            self.uploadDefaultImage(image: self.thumbNailImage)
                        }
                    }
                    else{
                        self.HIDE_SIC(customView: self.view)
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
    
    func uploadDefaultImage(image: UIImage) {
        DispatchQueue.global(qos: .background).async {
            guard let imageData = image.pngData() else { return }
            self.ftp.send(data:  imageData , with: "\(self.odileData.userId).jpg", success: { error in
                DispatchQueue.main.async {
                    if error {
                        self.showreelAndtanitimWebview()
                    }
                    else{
                        self.HIDE_SIC(customView: self.view)
                        self.showAlert(message: "İşleminizi şuanda gerçekleştiremiyoruz. kod:22")
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
    
    func showreelAndtanitimWebview(){
         if self.odileData.userId.range(of: "showreel") != nil {
            print("gönderilen showreel webviewcontroller")
            let id = self.odileData.userId.components(separatedBy: "_")
            let url = URL(string: "http://odi.odiapp.com.tr/?yeni_islem=showreel&id=\(id[1])&uzanti=mp4")!
            let request = URLRequest(url: url)
            self.webViewForSuccess = FullScreenWKWebView(frame: CGRect.zero)
            self.webViewForSuccess?.isHidden = true
            self.webViewForSuccess?.tag = 5
            self.view.addSubview(self.webViewForSuccess!)
            self.webViewForSuccess!.uiDelegate = self
            self.webViewForSuccess!.navigationDelegate = self
            self.webViewForSuccess!.load(request)
         } else {
            print("gönderilen tanitim webviewcontroller")
            let id = self.odileData.userId.components(separatedBy: "_")
            let url = URL(string: "http://odi.odiapp.com.tr/?yeni_islem=tanitim&id=\(id[1])&uzanti=mp4")!
            let request = URLRequest(url: url)
            self.webViewForSuccess = FullScreenWKWebView(frame: CGRect.zero)
            self.webViewForSuccess?.isHidden = true
            self.webViewForSuccess?.tag = 5
            self.view.addSubview(self.webViewForSuccess!)
            self.webViewForSuccess!.uiDelegate = self
            self.webViewForSuccess!.navigationDelegate = self
            self.webViewForSuccess!.load(request)
        }

    }

    func playTrailer(videoPath : String){
        try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category(rawValue: convertFromAVAudioSessionCategory(AVAudioSession.Category.playback)))
        try? AVAudioSession.sharedInstance().setActive(true)
        guard let url = URL(string: videoPath) else {
            return
        }
        let player = AVPlayer(url: url)
        let controller = AVPlayerViewController()
        controller.player = player
        
        present(controller, animated: true) {
            player.play()
        }
    }
    
    
}

class FullScreenWKWebView: WKWebView {
    override var safeAreaInsets: UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
	return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromAVAudioSessionCategory(_ input: AVAudioSession.Category) -> String {
	return input.rawValue
}
