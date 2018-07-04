//
//  ViewController.swift
//  Odi
//
//  Created by bilal on 21/12/2017.
//  Copyright © 2017 bilal. All rights reserved.
//

import UIKit
import WebKit

class WebViewController: UIViewController, WKScriptMessageHandler, WKNavigationDelegate,WKUIDelegate{
    
    var webView: WKWebView?
    var odiDataService = GetCameraServices()
    var odileData = (userId: "", videoId: "")
    var pickerController = UIImagePickerController()
    var service : UploadImageService = UploadImageService()
    var isUpdatedProfileImage = false
    var oneSignalID = UserPrefence.getOneSignalId()
    //Response Model
    var odiResponseModel = GetCameraResponseModel()
    var webViewReloadBool = false
    
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
        
        let req = URLRequest(url:url!)
        self.webView!.load(req)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
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
        }
        return 0
    }
    override func viewWillAppear(_ animated: Bool) {
        AppUtility.lockOrientation(.portrait)
        switch UIDevice.current.orientation {
        case .portrait:
            SHOW_SIC(type: .reload)
            //self.webView?.reload()
            let url = URL(string: "http://odi.odiapp.com.tr/?update=ok")!
            let request = URLRequest(url: url)
            webView!.load(request)
            self.webViewReloadBool = true
        default:break
        }
        self.navigationController?.isNavigationBarHidden = true
    }

    func webView(_ webView: WKWebView,
                 didFinish navigation: WKNavigation!) {
        if isUpdatedProfileImage == true {
            HIDE_SIC(customView: self.view)
            showAlert(message: "İşleminiz başarı ile gerçekleştrildi")
            isUpdatedProfileImage = false
        }
        if webViewReloadBool == true {
            HIDE_SIC(customView: self.view)
            webViewReloadBool = false
        }
    }
    
    
    
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
    
}

extension WebViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let image = info[UIImagePickerControllerEditedImage] as! UIImage
        service.connectService(fileName: "profilImage_\(odileData.userId).jpg", image: image)
        self.webView?.navigationDelegate = self
        self.SHOW_SIC(type: .profileImage)
        dismiss(animated:true, completion: nil)
    }
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.pickerController.dismiss(animated: true, completion: nil)
        print("Cancel")
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
