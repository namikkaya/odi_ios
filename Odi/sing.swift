//
//  sing.swift
//  Odi
//
//  Created by Nok Danışmanlık on 28.10.2019.
//  Copyright © 2019 bilal. All rights reserved.
//

import UIKit

class sing: NSObject {

    static let sharedInstance: sing = {
        let instance = sing()
        return instance
    }()
    
    override init() {
        super.init()
    }
}
