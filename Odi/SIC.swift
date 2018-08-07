//
//  SIC.swift
//  Resten Glow
//
//  Created by Baran on 29.11.2017.
//  Copyright © 2017 bilal. All rights reserved.
//

import UIKit
import CircleProgressView


class SIC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.radiusView.layer.cornerRadius = 15.0
    }


    func setProgress(progressValue: Float?) {
        print(Double(progressValue!))
        progressView.setProgress(Double(progressValue!), animated: true)
        
    }
    
    
    
    
    @IBOutlet weak var progressView: CircleProgressView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var radiusView: UIView!
    
}
extension UIViewController {
    func SHOW_SIC(type : SICType ) -> SIC?{
        let popOverVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SICID") as! SIC
        popOverVC.view.tag = 101
        popOverVC.view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        switch type {
        case .image:
            popOverVC.label.text = "Kolaj yükleniyor lütfen bekleyiniz..."
        case .profileImage:
            popOverVC.label.text = "Profil resminiz yükleniyor lütfen bekleyiniz..."
        case .video:
            popOverVC.label.text = "Video yükleniyor lütfen bekleyiniz..."
        case .compressVideo:
            popOverVC.label.text = "Video sıkıştırılıyor."

        case .reload:
            popOverVC.label.text = ""
            popOverVC.view.backgroundColor = UIColor.white
        }
        self.addChildViewController(popOverVC)
        popOverVC.view.frame = self.view.frame
        self.view.addSubview(popOverVC.view)
        popOverVC.didMove(toParentViewController: self)
        
        return popOverVC
    }
    func HIDE_SIC(customView: UIView){
        DispatchQueue.main.async {
            if let viewWithTag = customView.viewWithTag(101) {
                let vc = self.childViewControllers.last
                vc?.removeFromParentViewController()
                viewWithTag.removeFromSuperview()
            }else{
                print("No!")
            }
        }
    }
    
}
enum SICType {
    case profileImage
    case video
    case image
    case compressVideo
    case reload
}


class UserPrefence {
    
    static let userDefaults = UserDefaults.standard
    
    static func saveOneSignalId(id: String) {
        self.userDefaults.set(id, forKey: oneSignalUserId)
    }
    static func getOneSignalId() -> String {
        if let id = userDefaults.value(forKeyPath: oneSignalUserId) as? String {
            return id
        }
        return ""
    }
    static func removeoneSignalUserId(){
        UserDefaults.standard.removeObject(forKey: oneSignalUserId)
    }
    
    private static let oneSignalUserId = "oneSignalUserId"
}

