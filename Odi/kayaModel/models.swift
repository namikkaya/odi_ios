//
//  models.swift
//  slidePaging
//
//  Created by Nok Danışmanlık on 25.05.2019.
//  Copyright © 2019 Brokoly. All rights reserved.
//

import Foundation
import UIKit
import AMPopTip

struct sliderModel {
    var text:String?
    var imageURL:String?
    
    init(text:String?, imageURL:String?) {
        self.text = text
        self.imageURL = imageURL
    }
}


struct toolTipModel {
    var toolTipText:String?
    var toolTipObject:AnyObject?
    var direction: PopTipDirection?
    
    init(toolTipText:String?, toolTipObject:AnyObject?, direction:PopTipDirection?) {
        self.toolTipText = toolTipText
        self.toolTipObject = toolTipObject
        self.direction = direction
    }
    
}
