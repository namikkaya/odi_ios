//
//  CameraNavigationControllerViewController.swift
//  Odi
//
//  Created by Nok Danışmanlık on 29.05.2019.
//  Copyright © 2019 bilal. All rights reserved.
//

import UIKit
import AVFoundation

class CameraNavigationControllerViewController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        /*DispatchQueue.global(qos: .background).async { [weak self] () -> Void in
            DispatchQueue.main.async { () -> Void in
                self?.alertMessage()
            }
        }*/
    }
    

    func closeNavigationPage() {
        self.dismiss(animated: true) {
            print("Kapandı")
        }
    }
    
    func alertMessage() {
        //AppUtility.lockOrientation(UIInterfaceOrientationMask.landscapeLeft, andRotateTo: UIInterfaceOrientation.landscapeLeft)
        //let viewController = self
        
        //let currentViewController = UIApplication.shared.keyWindow?.rootViewController
        //currentViewController?.dismiss(animated: true, completion: nil)
        //navigationController?.dismiss(animated: true, completion: nil)
        
        
        print("Camera: alert Message Tetiklendi")
        let permision = UIAlertController (title: "İzin Yok!", message: "Odi'nin video kaydı yapabilmesi için kamera ve mikrofon izinlerine ihtiyacı var. Video kaydı yapabilmek için hemen \n'Ayarlar' -> 'Odi' -> 'Kamera & Mikrofon' \nsekmelerindeki izinleri açmalısınız.", preferredStyle: .alert)
        
        let settingsAction = UIAlertAction(title: "Ayarlar", style: .default) { (_) -> Void in
            let settingsUrl = NSURL(string:UIApplication.openSettingsURLString)
            if let url = settingsUrl {
                DispatchQueue.main.async {
                    UIApplication.shared.open(url as URL, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
                }
                self.navigationController?.popViewController(animated: true)
            }
        }
        
        let cancelAction = UIAlertAction(title: "İptal", style: UIAlertAction.Style.destructive, handler: { (act) in
            AppUtility.lockOrientation(UIInterfaceOrientationMask.portrait, andRotateTo: UIInterfaceOrientation.portrait)
            //self.navigationController?.popViewController(animated: true)
            if let nv = self.navigationController as? CameraNavigationControllerViewController {
                print("Close page tetiklendi")
                nv.closeNavigationPage()
            }
        })
        permision.addAction(settingsAction)
        permision.addAction(cancelAction)
        
        DispatchQueue.main.async {
            self.present(permision, animated: true, completion: nil)
        }
        
        /*if viewController.presentedViewController == nil {
         currentViewController?.present(permision, animated: true, completion: nil)
         } else {
         viewController.present(permision, animated: true, completion: nil)
         }*/
    }
    
    func checkPermission() {
        if AVCaptureDevice.authorizationStatus(for: AVMediaType.video) == .authorized && AVCaptureDevice.authorizationStatus(for: AVMediaType.audio) == .authorized {
            //already authorized
            print("Camera: Mikrofon ve Kamera izni verilmiş")
        } else {
            //self.goto(screenID: "TurnPhoneSplashVCID", animated: false, data: nil, isModal: true)
            print("Camera: izinler yok")
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { (granted: Bool) in
                if granted {
                    print("Camera: video izni var")
                } else {
                    /*
                     DispatchQueue.main.async { () -> Void in
                     //self.alertMessage()
                     
                     }*/
                    // return
                    //self.navigationController?.popViewController(animated: true)
                    
                    print("Camera: ses izni yok")
                    /*self.dismiss(animated: true, completion: {
                     DispatchQueue.main.async { () -> Void in
                     self.alertMessage()
                     }
                     })*/
                    //self.navigationController?.popViewController(animated: true)
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
                    /*
                     DispatchQueue.main.async { () -> Void in
                     //self.alertMessage()
                     self.navigationController?.popViewController(animated: true)
                     }
                     
                     return*/
                    //self.navigationController?.popViewController(animated: true)
                    /*
                     if self.navigationController != nil
                     {
                     let popup = self.SHOW_SIC(type: .reload)
                     popup?.setProgress(progressValue: 1.0)
                     AppUtility.lockOrientation(.portrait)
                     self.clearTempFolder()
                     self.HIDE_SIC(customView: (self.view)!)
                     self.navigationController?.dismiss(animated: true, completion: nil)
                     }
                     */
                }
            })
            
        }
    }

}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
