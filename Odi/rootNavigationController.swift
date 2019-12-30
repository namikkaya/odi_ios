//
//  rootNavigationController.swift
//  Odi
//
//  Created by Nok Danışmanlık on 29.05.2019.
//  Copyright © 2019 bilal. All rights reserved.
//

import UIKit

class rootNavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.setNavigationBarHidden(false, animated: false)
    }
    

}
