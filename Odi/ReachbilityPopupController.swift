//
//  ReachbilityPopupController.swift
//  Odi
//
//  Created by Baran on 27.08.2018.
//  Copyright © 2018 bilal. All rights reserved.
//

import UIKit
import Reachability

class ReachbilityPopupController: UIViewController {

    var reachability =  Reachability()!
    var isNoConnection = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        popupView.layer.cornerRadius = 8.0
        setupReachability()
    }

    @IBOutlet weak var popupView: UIView!

    
    func setupReachability() {
        if isNoConnection {
            return
        }
        NotificationCenter.default.addObserver(self, selector: #selector(internetChanged(note:)), name: Notification.Name("reachabilityChanged") , object: reachability)
        do{
            try reachability.startNotifier()
        } catch {
            print("could not start notifier")
        }
    }
    @objc func internetChanged(note: Notification) {
        let reachability = note.object as! Reachability
        if reachability.connection != .none {
            print("REachable")
            self.back(animated: true, isModal: true)
        } else {
           print("Not Reachable")
        }
    }
    
}
