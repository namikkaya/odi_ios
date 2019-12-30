//
//  SIC.swift
//  Resten Glow
//
//  Created by Baran on 29.11.2017.
//  Copyright © 2017 bilal. All rights reserved.
//

import UIKit
import CircleProgressView


class SIC: BaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.radiusView.layer.cornerRadius = 15.0
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.view.frame = UIScreen.main.bounds
    }
    
    func setProgress(progressValue: Float?) {
        progressView.setProgress(Double(progressValue!), animated: true)
    }
    
    func setProgressNoAnimation(progressValue: Float?) {
        progressView.setProgress(Double(progressValue!), animated: false)
    }
    
    
    var type = SICType.reload
    @IBOutlet weak var progressView: CircleProgressView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var radiusView: UIView!
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if type == SICType.reload {
        }
    }
    
}
extension UIViewController {
    
    func SHOW_SIC(type : SICType) -> SIC?{
        let popOverVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SICID") as! SIC
        popOverVC.view.tag = 101
        popOverVC.view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        popOverVC.type = type
        switch type {
        case .image:
            popOverVC.label.text = "Kolaj yükleniyor lütfen bekleyiniz"
        case .profileImage:
            popOverVC.label.text = "Profil fotoğrafınız yükleniyor"
        case .video:
            popOverVC.label.text = "Video yükleniyor lütfen bekleyiniz"
        case .compressVideo:
            popOverVC.label.text = "Video hazırlanıyor."
        case .reload:
            popOverVC.label.text = ""
            popOverVC.view.backgroundColor = UIColor.white
        case .cameraReading:
            popOverVC.label.text = "Kamera Hazırlanıyor..."
            popOverVC.view.backgroundColor = UIColor.white
        case .returnOdi:
            popOverVC.label.text = "Hazırlanıyor..."
            popOverVC.view.backgroundColor = UIColor.white
        }
        self.addChild(popOverVC)
        popOverVC.view.frame = UIScreen.main.bounds
        self.view.addSubview(popOverVC.view)
        popOverVC.didMove(toParent: self)
        
        return popOverVC
    }
    func HIDE_SIC(customView: UIView){
        DispatchQueue.main.async {
            if let viewWithTag = customView.viewWithTag(101) {
                let vc = self.children.last
                vc?.removeFromParent()
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
    case cameraReading
    case returnOdi
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

