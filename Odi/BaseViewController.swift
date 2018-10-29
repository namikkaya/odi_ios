//
//  BaseViewController.swift
//  Odi
//
//  Created by Baran on 27.08.2018.
//  Copyright © 2018 bilal. All rights reserved.
//

import UIKit
import Reachability

class BaseViewController: UIViewController {

    var reachability =  Reachability()!
    var isNoConnection = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupReachability()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
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
        } else {
            DispatchQueue.main.async {
                if !self.isNoConnection {
                    self.goto(screenID: "ReachbilityPopupControllerID", animated: true, data: nil, isModal: true)
                }
            }
        }
    }


}
