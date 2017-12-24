//
//  SIC.swift
//  Resten Glow
//
//  Created by Baran on 29.11.2017.
//  Copyright © 2017 bilal. All rights reserved.
//

import UIKit

class SIC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.gray.withAlphaComponent(0.2)
        self.indicator.startAnimating()
    }

    override func viewWillDisappear(_ animated: Bool) {
        self.indicator.stopAnimating()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
}
extension UIViewController {
    func SHOW_SIC(type : SICType ){
        let popOverVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SICID") as! SIC
        popOverVC.view.tag = 101
        popOverVC.view.backgroundColor = UIColor.black
        switch type {
        case .image:
            popOverVC.label.text = "Kolaj yükleniyor lütfen bekleyiniz..."
        case .video:
            popOverVC.label.text = "Video yükleniyor lütfen bekleyiniz..."
        case .compressVideo:
            popOverVC.label.text = "Video sıkıştırılıyor."
        }
        self.addChildViewController(popOverVC)
        popOverVC.view.frame = self.view.frame
        self.view.addSubview(popOverVC.view)
        popOverVC.didMove(toParentViewController: self)
    }
    func HIDE_SIC(customView: UIView){
        DispatchQueue.main.async {
            //print("Start remove sibview")
            if let viewWithTag = customView.viewWithTag(101) {
                viewWithTag.removeFromSuperview()
            }else{
                print("No!")
            }
        }
    }
}
enum SICType {
    case video
    case image
    case compressVideo
}
