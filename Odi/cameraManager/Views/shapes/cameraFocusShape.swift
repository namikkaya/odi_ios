//
//  cameraFocusShape.swift
//  videoMuteSystem_hub
//
//  Created by Nok Danışmanlık on 20.11.2019.
//  Copyright © 2019 brokoly. All rights reserved.
//

import UIKit

class cameraFocusShape: NSObject, CAAnimationDelegate {
    private let TAG:String = "cameraFocusShape: "
    var layer:CAShapeLayer?
    var timer:Timer?
    var view:UIView?
    var point:CGPoint?
    var label:UILabel?
    override init() {
        super.init()
    }

    init(point:CGPoint, view:UIView) {
        super.init()
        self.view = view
        self.point = point
        layer = CAShapeLayer()
        layer!.path = UIBezierPath(roundedRect: CGRect(x: point.x - (80/2), y: point.y - (80/2), width: 80, height: 80), cornerRadius: 2).cgPath
        layer!.fillColor = UIColor.clear.cgColor
        layer!.strokeColor = UIColor.yellow.cgColor
        view.layer.addSublayer(layer!)
        
        //timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerEvent(timer:)), userInfo: nil, repeats: false)
        self.timer = Timer.scheduledTimer(timeInterval: 1.5, target: self, selector: #selector(timerEvent(timer:)), userInfo: nil, repeats: false)
        
        label = UILabel(frame: CGRect(x: point.x - (80/2), y: point.y + (80/2), width: 80, height: 21))
        label!.textAlignment = .center
        label?.text = "Odaklanıyor"
        label?.font = label?.font.withSize(14)
        label?.textColor = UIColor.yellow
        self.view!.addSubview(label!)
        
    }
    
    func clearMySelf() {
        if self.timer != nil {
            self.timer?.invalidate()
            self.timer = nil
        }
        if layer != nil {
            layer?.removeFromSuperlayer()
            layer = nil
        }
        if label != nil {
            label?.removeFromSuperview()
            label = nil
        }
    }
    
    @objc func timerEvent(timer:Timer) {
        guard let myTimer = self.timer else { return }
        myTimer.invalidate()
        self.timer = nil
        layerDelete()
        UIView.animate(withDuration: 0.7, animations: {
            if let label = self.label {
                label.alpha = 0
                self.view?.setNeedsDisplay()
                self.view?.layoutIfNeeded()
            }
        }) { (act) in
            if let label = self.label {
                label.alpha = 0
                self.view?.setNeedsDisplay()
                self.view?.layoutIfNeeded()
            }
        }
    }
    
    fileprivate func layerDelete() {
        CATransaction.begin()
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.delegate = self
        animation.fromValue = 1.5
        animation.toValue = 0.0
        animation.duration = 0.2
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        layer!.add(animation, forKey: "fade")
        CATransaction.commit()
    }
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        layer?.removeFromSuperlayer()
    }
    
    deinit {
        if self.timer != nil {
            self.timer?.invalidate()
            self.timer = nil
        }
        if layer != nil {
            layer?.removeFromSuperlayer()
            layer = nil
        }
        if label != nil {
            label?.removeFromSuperview()
            label = nil
        }
    }
}
