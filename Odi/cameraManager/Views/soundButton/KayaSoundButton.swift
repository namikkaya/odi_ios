//
//  KayaSoundButton.swift
//  videoMuteSystem_hub
//
//  Created by Nok Danışmanlık on 27.11.2019.
//  Copyright © 2019 brokoly. All rights reserved.
//

import UIKit

class KayaSoundButton: UIButton {
    var isOn:Bool = true
    override init(frame: CGRect) {
        super.init(frame: frame)
        initButton()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initButton()
    }
    
    func initButton(){
        activeButton(bool: true)
        addTarget(self, action: #selector(kayaToogleButton.buttonPressed), for: .touchUpInside)
    }
    
    @objc func buttonPressed(){
        activeButton(bool:!isOn)
    }
    
    func activeButton(bool:Bool){
        isOn = bool
        
        let mute:UIImage = UIImage(named: "mute")!
        let unmute:UIImage = UIImage(named: "unmute")!
        
        let image = bool ? unmute : mute
        
        
        setImage(image, for: UIControl.State.normal)
    }
}
