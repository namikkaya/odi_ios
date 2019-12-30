//
//  KayaTextButton.swift
//  videoMuteSystem_hub
//
//  Created by Nok Danışmanlık on 27.11.2019.
//  Copyright © 2019 brokoly. All rights reserved.
//

import UIKit

class KayaTextButton: UIButton {

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
        
        let texton:UIImage = UIImage(named: "texton")!
        let textoff:UIImage = UIImage(named: "textoff")!
        
        let image = bool ? texton : textoff
        
        
        setImage(image, for: UIControl.State.normal)
    }

}
