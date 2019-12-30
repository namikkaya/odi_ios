//
//  versionViewController.swift
//  Odi
//
//  Created by Nok Danışmanlık on 11.11.2019.
//  Copyright © 2019 bilal. All rights reserved.
//

import UIKit

class versionViewController: UIViewController {
    
    @IBOutlet var contentContainer: UIView!
    var commentText:String?
    @IBOutlet var labelText: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        labelText.text = commentText
        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        contentUIStartConfig()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        contentUIContinuous()
    }
    
    ///////////////////////////////////////////////////////////
    // Açılış ve kapanış animasyon fonksiyonları
    private func contentUIStartConfig() {
        DispatchQueue.main.async {
            self.contentContainer.layer.cornerRadius = 10
            self.contentContainer.layer.masksToBounds = true
        }
        
        
        self.contentContainer.translatesAutoresizingMaskIntoConstraints = false
        UIView.animate(withDuration: 0.1) {
            self.contentContainer.alpha = 0.0
            self.contentContainer.transform = CGAffineTransform(translationX: 0, y: 20)
            self.contentContainer.layoutIfNeeded()
        }
    }
    
    private func contentUIContinuous() {
        UIView.animate(withDuration: 0.2, animations: {
            self.contentContainer.alpha = 1
            self.contentContainer.transform = CGAffineTransform(translationX: 0, y: -20)
            self.contentContainer.layoutIfNeeded()
        }) { (status) in
            
        }
    }
    
    private func exitViewController() {
        UIView.animate(withDuration: 0.2, animations: {
            self.contentContainer.alpha = 0.0
            self.contentContainer.transform = CGAffineTransform(translationX: 0, y: 20)
        }) { (status) in
            self.dismiss(animated: true, completion: {
                //Vibration.heavy.vibrate()
            })
        }
    }
    

    @IBAction func storeButtonEvent(_ sender: Any) {
        if let url = URL(string: "https://itunes.apple.com/in/app/odi/id1421138501?mt=8")
        {
                   if #available(iOS 10.0, *) {
                      UIApplication.shared.open(url, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
                   }
                   else {
                         if UIApplication.shared.canOpenURL(url as URL) {
                            UIApplication.shared.openURL(url as URL)
                        }
                   }
        }
    }
    
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
