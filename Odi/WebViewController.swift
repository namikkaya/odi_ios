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
    
    //Response Model
    var odiResponseModel = GetCameraResponseModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let o = WKUserContentController()
        o.add(self, name: "foo")
        let config = WKWebViewConfiguration()
        config.userContentController = o
        self.webView = WKWebView(frame: self.view.bounds, configuration: config)
        self.view.addSubview(self.webView!)
        webView?.translatesAutoresizingMaskIntoConstraints = false
        webView = WKWebView(frame:.zero , configuration: config)
        view.addSubview(webView!)
        webView?.uiDelegate = self
        //view = webView
        webView!.translatesAutoresizingMaskIntoConstraints = false
        
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[v0]|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0":webView!]))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-20-[v0]|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0":webView!]))
        let url = URL(string:"http://odi.beranet.com/")
        let req = URLRequest(url:url!)
        self.webView!.load(req)
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if(message.name == "foo") {
            print("JavaScript is sending a message \(message.body)")
            if let src = message.body as? String {
                let goTo = parseString(src:src)
                switch (goTo) {
                case 1:
                    self.odiDataService.serviceDelegate = self
                    self.odiDataService.connectService(serviceUrl: ("http://odi.beranet.com/core/odi.php?id=" + odileData.videoId))
                case 2:
                    performSegue(withIdentifier: "gotoPhotos", sender: nil)
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
        } else if src.range(of: "design/updateprofil.png?") != nil {
            let stringArray = src.components(separatedBy: "=")
            self.odileData.userId = stringArray[1]
            return 2
        }
        return 0
    }
    override func viewWillAppear(_ animated: Bool) {
        self.webView?.reload()
        self.navigationController?.isNavigationBarHidden = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}

extension WebViewController : GetCameraDelegate {
    func getError(errorMessage: String) {
        print(errorMessage)
    }
    func getResponse(response: GetCameraResponseModel) {
        self.odiResponseModel = response
        performSegue(withIdentifier: "CameraViewControllerID", sender: nil)
    }
}
