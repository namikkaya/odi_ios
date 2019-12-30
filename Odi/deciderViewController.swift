//
//  deciderViewController.swift
//  Odi
//
//  Created by Nok Danışmanlık on 29.05.2019.
//  Copyright © 2019 bilal. All rights reserved.
//

import UIKit

class deciderViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        navigationController?.navigationBar.barStyle = .black
        super.viewDidAppear(animated)
        let controlString = UserPrefences.imageSliderCheck()
        if (controlString == "OK") {
            // direk yönlendir değil ise devam
            print("decider: Yönlendirme olacak")
            directionVC(animationStatus: false)
        }else {
            UserPrefences.imageSliderOK()
            print("decider: slider oynayacak ok lenecek")
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "sliderVC") as! sliderViewController
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func directionVC(animationStatus:Bool = true) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "RootControllerID") as! UINavigationController
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: animationStatus, completion: nil)
    }

}
