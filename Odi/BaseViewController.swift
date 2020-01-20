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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupReachability()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        reachability.stopNotifier()
        NotificationCenter.default.removeObserver(self, name: .reachabilityChanged, object: reachability)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func setupReachability() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reachabilityChanged(note:)),
                                               name: .reachabilityChanged,
                                               object: reachability)
        do{
            try reachability.startNotifier()
        } catch {
            print("could not start notifier")
        }
    }
    @objc func reachabilityChanged(note: Notification) {
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
