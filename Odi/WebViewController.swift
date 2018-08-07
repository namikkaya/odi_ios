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

class WebViewController: UIViewController, WKScriptMessageHandler, WKNavigationDelegate,WKUIDelegate{
    
    
    
    var popUpController : SIC?
    var webView: WKWebView?
    var webViewForSuccess: WKWebView?
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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let o = WKUserContentController()
        o.add(self, name: "foo")
        let config = WKWebViewConfiguration()
        config.userContentController = o
        self.webView = WKWebView(frame: self.view.bounds, configuration: config)
        self.webView?.scrollView.backgroundColor = UIColor(red: 255.0 / 255.0, green: 133.0 / 255.0, blue: 0.0, alpha: 1.0)
        self.view.addSubview(self.webView!)
        webView?.translatesAutoresizingMaskIntoConstraints = false
        webView = WKWebView(frame:.zero , configuration: config)
        view.addSubview(webView!)
        webView?.uiDelegate = self
        //view = webView
        webView!.translatesAutoresizingMaskIntoConstraints = false
        self.webView?.navigationDelegate = self
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[v0]|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0":webView!]))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-20-[v0]|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0":webView!]))
        let url = URL(string:"http://odi.odiapp.com.tr/?kulID=\(oneSignalID)")
        let request = URLRequest(url: url!)
        webView!.load(request)
        self.popUpController = SHOW_SIC(type: .reload)
        self.webView?.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil);
        self.addObserver()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "estimatedProgress" {
            if self.popUpController != nil  {
                DispatchQueue.main.async { () -> Void in
                    self.popUpController?.setProgress(progressValue: Float((self.webView?.estimatedProgress)!))
                }
            }
        }
    }
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print(message.name)
        print(message.body)
        if(message.name == "foo") {
            print("JavaScript is sending a message \(message.body)")
            if let src = message.body as? String {
                let goTo = parseString(src:src)
                switch (goTo) {
                case 1:
                    self.odiDataService.serviceDelegate = self
                    self.odiDataService.connectService(serviceUrl: ("http://odi.odiapp.com.tr/core/odi.php?id=" + odileData.videoId))
                case 2:
                    performSegue(withIdentifier: "gotoPhotos", sender: nil)
                case 3:
                    service.serviceDelegate = self
                    self.requestAlertViewForImage(pickerController: pickerController, vc: self)
                    print("UserID:", odileData.userId)
                case 4:
                    UIApplication.shared.open(URL(string : odileData.userId)!, options: [:], completionHandler: { (status) in
                    })
                case 5:
                    self.requestAlertViewForVideo(pickerController: pickerController, vc: self)
                case 6:
                    self.requestAlertViewForVideo(pickerController: pickerController, vc: self)
                default:break;
                }
            }
        }
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let backItem = UIBarButtonItem()
        backItem.title = "Geri"
        navigationItem.backBarButtonItem = backItem
        if let vc = segue.destination as? CameraViewController {
            vc.odiResponseModel = self.odiResponseModel
            vc.odileData = self.odileData
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
            print(stringArray)
            print(odileData)
            return 1
        } else if src.range(of: "design/updateprofil.png?") != nil || src.range(of: "design/fotosec.png?id") != nil {
            let stringArray = src.components(separatedBy: "=")
            self.odileData.userId = stringArray[1]
            return 2
        } else if src.range(of: "design/prf.png?") != nil {
            let stringArray = src.components(separatedBy: "=")
            self.odileData.userId = stringArray[1]
            return 3
        } else if src.range(of: "link") != nil {
            let stringArray = src.components(separatedBy: "=")
            self.odileData.userId = stringArray[1] //userID is link
            return 4
        } else if src.range(of: "showreel") != nil {
            let stringArray = src.components(separatedBy: "=")
            self.odileData.userId = stringArray[1] //userID is link
            return 5
        } else if src.range(of: "tanitim") != nil {
            let stringArray = src.components(separatedBy: "=")
            self.odileData.userId = stringArray[1] //userID is link
            return 6
        }
        return 0
    }
    override func viewWillAppear(_ animated: Bool) {
        AppUtility.lockOrientation(.portrait)
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
        else if self.childViewControllers.count == 1 {
            HIDE_SIC(customView: self.view)
        }
        print(self.childViewControllers.count)
        
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
        self.popUpController = SHOW_SIC(type: .reload)
        webView?.reload()
        self.webViewReloadBool = true
    }
    
}

extension WebViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
   public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if odileData.userId.range(of:"showreel") != nil {
           
            let videoURL = info[UIImagePickerControllerMediaURL] as? URL
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
                
                print("videoURL:\(String(describing: videoURL))")
            } else {
                showAlert(message: "Seçtiğiniz videonun boyutu çok büyük")
            }
            self.dismiss(animated: true, completion: nil)
        } else if odileData.userId.range(of:"tanitim") != nil {
            print("&&Tanitim")
            let videoURL = info[UIImagePickerControllerMediaURL] as? URL
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
                showAlert(message: "Seçtiğiniz videonun boyutu çok büyük")
            }
            
           
            self.dismiss(animated: true, completion: nil)
        } else {
            let image = info[UIImagePickerControllerEditedImage] as! UIImage
            service.connectService(fileName: "profilImage_\(odileData.userId).jpg", image: image)
            self.webView?.navigationDelegate = self
            self.popUpController = self.SHOW_SIC(type: .profileImage)
            dismiss(animated:true, completion: nil)
        }   
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
            let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(0, 1), actualTime: nil)
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
    func getResponse(response: GetCameraResponseModel) {
        self.odiResponseModel = response
        AppUtility.lockOrientation(.landscapeRight, andRotateTo: .landscapeRight)
        performSegue(withIdentifier: "CameraViewControllerID", sender: nil)
    }
}

extension  WebViewController: UploadImageServiceDelegte {
    func progressHandler(value: Float) {
        if let popup = popUpController {
            DispatchQueue.global(qos: .background).async { [weak self] () -> Void in
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
        
        // Create the actions
        let okAction = UIAlertAction(title: "Tamam",style: UIAlertActionStyle.default) {
            UIAlertAction in
            self.navigationController?.popViewController(animated: true)
            
        }
        // Add the actions
        alertController.addAction(okAction)
        // Present the controller
        self.present(alertController, animated: true, completion: nil)
    }
    
}
//Mark: -Upload
extension WebViewController {
    func uploadVideo(videoData: Data){
        self.popUpController = self.SHOW_SIC(type: .video)
        DispatchQueue.global(qos: .background).async {
            print((self.odileData.userId))
            self.ftp.send(data:  videoData , with: "\(self.odileData.userId).MOV", success: { error in
                DispatchQueue.main.async {
                    if error {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { // change 2 to desired number of seconds
                            if self.popUpController != nil {
                                self.popUpController?.label.text = "Video resmi yükleniyor."
                                self.popUpController?.progressView.setProgress(0.0, animated: false)
                            }
                            self.uploadDefaultImage(image: self.thumbNailImage)
                            print("Yolladımm")
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
            guard let imageData = UIImagePNGRepresentation(image) else { return }
            self.ftp.send(data:  imageData , with: "\(self.odileData.userId).jpg", success: { error in
                DispatchQueue.main.async {
                    if error {
                        self.showreelAndtanitimWebview()
                    }
                    else{
                        self.HIDE_SIC(customView: self.view)
                        self.showAlert(message: "İşleminizi şuanda gerçekleştiremiyoruz.")
                        
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
            let id = self.odileData.userId.components(separatedBy: "_")
            print(id)
            let url = URL(string: "http://odi.odiapp.com.tr/?yeni_islem=showreel&id=\(id[1])")!
            let request = URLRequest(url: url)
            self.webViewForSuccess = WKWebView(frame: CGRect.zero)
            self.webViewForSuccess?.isHidden = true
            self.webViewForSuccess?.tag = 5
            self.view.addSubview(self.webViewForSuccess!)
            self.webViewForSuccess!.uiDelegate = self
            self.webViewForSuccess!.navigationDelegate = self
            self.webViewForSuccess!.load(request)
         } else {
            let id = self.odileData.userId.components(separatedBy: "_")
            print(id)
            print(id)
            let url = URL(string: "http://odi.odiapp.com.tr/?yeni_islem=tanitim&id=\(id[1])")!
            let request = URLRequest(url: url)
            self.webViewForSuccess = WKWebView(frame: CGRect.zero)
            self.webViewForSuccess?.isHidden = true
            self.webViewForSuccess?.tag = 5
            self.view.addSubview(self.webViewForSuccess!)
            self.webViewForSuccess!.uiDelegate = self
            self.webViewForSuccess!.navigationDelegate = self
            self.webViewForSuccess!.load(request)
        }

    }

    
    
}




