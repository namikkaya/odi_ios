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
    
    var odileData = (userId: "", videoId: "")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let o = WKUserContentController()
        o.add(self, name: "foo")
        let config = WKWebViewConfiguration()
        config.userContentController = o
        self.webView = WKWebView(frame: self.view.bounds, configuration: config)
        self.view.addSubview(self.webView!)
        webView?.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint(item: webView!, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: NSLayoutAttribute.bottom, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: webView!, attribute: NSLayoutAttribute.leading, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: NSLayoutAttribute.leading, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: webView!, attribute: NSLayoutAttribute.trailing, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: NSLayoutAttribute.trailing, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: webView!, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: NSLayoutAttribute.top, multiplier: 1, constant: 20).isActive = true
        webView?.uiDelegate = self
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
                case 1: break
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
        self.navigationController?.isNavigationBarHidden = true
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}
