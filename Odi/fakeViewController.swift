//
//  fakeViewController.swift
//  Odi
//
//  Created by Nok Danışmanlık on 12.12.2019.
//  Copyright © 2019 bilal. All rights reserved.
//

import UIKit

class fakeViewController: UIViewController {

    var odiResponseModel = GetCameraResponseModel()
    var odileData = (userId: "", videoId: "")
    var fakeImage:UIImage?
    var first:Bool = false
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        
        let popup = self.SHOW_SIC(type: .cameraReading)
        popup?.setProgress(progressValue: 1.0)
        //AppUtility.lockOrientation(.landscapeRight)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !first {
            AppUtility.lockOrientation(.landscapeRight)
            
            //self.HIDE_SIC(customView: self.view)
            //self.didOpen()
            
            Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { (nTimer) in
                nTimer.invalidate()
                self.didOpen()
            }
            first = true
        }else {
            AppUtility.lockOrientation(UIInterfaceOrientationMask.portrait)
            
            let popup = self.SHOW_SIC(type: .returnOdi)
            popup?.setProgress(progressValue: 1.0)
            
            Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { (nTimer) in
                nTimer.invalidate()
                self.didClose()
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }

    
    func didOpen() {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "CameraViewControllerID") as! KayaCamManViewController
        vc.modalPresentationStyle = .fullScreen
        vc.odiResponseModel = odiResponseModel
        vc.odileData = odileData
        /*DispatchQueue.main.async {
            self.present(vc, animated: false) {
                self.HIDE_SIC(customView: self.view)
            }
        }*/
        self.present(vc, animated: false) {
            //self.HIDE_SIC(customView: self.view)
        }
    }
    
    func didClose() {
//        DispatchQueue.main.async {
//            //self.HIDE_SIC(customView: (self.view)!)
//            //self.navigationController?.dismiss(animated: false, completion: nil)
//            self.navigationController?.dismiss(animated: false, completion: {
//                self.HIDE_SIC(customView: (self.view)!)
//            })
//        }
        
        self.navigationController?.dismiss(animated: true, completion: {
            //self.HIDE_SIC(customView: (self.view)!)
        })
    }
    
    /*
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let backItem = UIBarButtonItem()
        backItem.title = "Geri"
        navigationItem.backBarButtonItem = backItem
        if let destinationNavigationController = segue.destination as? UINavigationController {
            /*if let vc = destinationNavigationController.topViewController as? CameraViewController { // note: değiştirme
                vc.odiResponseModel = self.odiResponseModel
                vc.odileData = self.odileData
            }*/
            if let vc = destinationNavigationController.topViewController as? KayaCamManViewController { // note: değiştirme
                vc.odiResponseModel = self.odiResponseModel
                vc.odileData = self.odileData
            }
        }
        if let vc = segue.destination as? KayaCollageViewController {
            vc.id = self.odileData.userId
        }
    }*/

}
