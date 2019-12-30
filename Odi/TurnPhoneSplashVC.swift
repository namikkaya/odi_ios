//
//  TurnPhoneSplashVC.swift
//  Odi
//
//  Created by Baran Karaoğuz on 15.11.2018.
//  Copyright © 2018 bilal. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

class TurnPhoneSplashVC: UIViewController {
    @IBOutlet weak var understandButton: UIButton!
    var onCloseCallback:( (_ closeStatus:Bool? ) -> () )?
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(TurnPhoneSplashVC.rotated), name: UIDevice.orientationDidChangeNotification, object: nil)
        self.configure()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //AppUtility.lockOrientation(UIInterfaceOrientationMask.landscapeRight)
        rotated()
    }
    
    @objc func rotated() {
        if UIDevice.current.orientation == UIDeviceOrientation.landscapeLeft {
            //print("hareket: Sol")
            self.back(animated: true, isModal: true)
            //print("hareket: \(myHolderView)")
        }
        else if UIDevice.current.orientation == UIDeviceOrientation.landscapeRight{
            //print("hareket: Sağa Yatır")
            //print("hareket: \(myHolderView)")
            /*if (myHolderView == nil) {
                self.goto(screenID: "TurnPhoneSplashVCID", animated: false, data: nil, isModal: true)
            }*/
        }
        else if UIDevice.current.orientation == UIDeviceOrientation.portraitUpsideDown{
            //print("Ters")
            //print("hareket: \(myHolderView)")
            /*if (myHolderView == nil) {
                self.goto(screenID: "TurnPhoneSplashVCID", animated: false, data: nil, isModal: true)
            }*/
        }
        else if UIDevice.current.orientation == UIDeviceOrientation.portrait {
            //print("dik")
            //print("hareket: \(myHolderView)")
            //self.HIDE_SIC(customView: self.view)
            /*if (myHolderView == nil) {
                self.goto(screenID: "TurnPhoneSplashVCID", animated: false, data: nil, isModal: true)
            }*/
        }else {
            /*if (myHolderView == nil) {
                self.goto(screenID: "TurnPhoneSplashVCID", animated: false, data: nil, isModal: true)
            }*/
        }
    }
    
    @IBAction func understandButtonAct(_ sender: UIButton) {
        self.back(animated: false, isModal: true)
    }
    
    func configure() {
        self.understandButton.layer.borderColor = UIColor.white.cgColor
        self.understandButton.layer.borderWidth = 2.0
        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.95)
        self.view.transform = self.view.transform.rotated(by: CGFloat(-(Double.pi / 2)))
    }
    
    @IBAction func closeButtonEvent(_ sender: Any) {
        self.back(animated: true, isModal: true, callBack: onCloseCallback!)
    }
    
}
