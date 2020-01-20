//
//  KayaRecordButton.swift
//  videoMuteSystem_hub
//
//  Created by Nok Danışmanlık on 20.11.2019.
//  Copyright © 2019 brokoly. All rights reserved.
//

import UIKit

@IBDesignable
class KayaRecordButton: UIButton {
    var isRecording:Bool = false
    var circleLayer:CAShapeLayer?
    var filledCircle:CAShapeLayer?
    var squareView:UIView?
    var inView:UIView?
    
    
    var recordButtonColor:UIColor = UIColor.red {
        didSet {
            if let filledCircle = filledCircle {
                filledCircle.fillColor = recordButtonColor.cgColor
            }
        }
    }
    
    /**
     Usage: <#açıklama#>
     - Parameter <#value#>:  <#Value Açıklama#>
     - Returns: <#No return value#>
     */
    override init(frame: CGRect) {
        super.init(frame: frame)
        initButton()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initButton()
    }
    
    func initButton(){
        drawRingFittingInsideView()
        drawSquareCenter()
        activeButton(bool: false)
        addTarget(self, action: #selector(KayaRecordButton.buttonPressed), for: .touchUpInside)
    }
    
    @objc func buttonPressed(){
        activeButton(bool:!isRecording)
    }
    
    func activeButton(bool:Bool){
        isRecording = bool
        UIDesing(status: isRecording)
    }
    
    fileprivate func UIDesing(status:Bool) {
        if (status) {
            
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.2) {
                    self.inView!.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
                    self.setNeedsDisplay()
                }
            }
        }else {
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.2) {
                    self.inView!.transform = CGAffineTransform(scaleX: 1, y: 1)
                    self.setNeedsDisplay()
                }
            }
        }
    }
    
    
    internal func drawRingFittingInsideView()->() {
        let halfSize:CGFloat = min( bounds.size.width/2, bounds.size.height/2)
        let desiredLineWidth:CGFloat = 5    // your desired value

        let circlePath = UIBezierPath(
            arcCenter: CGPoint(x:halfSize,y:halfSize),
            radius: CGFloat( halfSize - (desiredLineWidth/2) ),
            startAngle: CGFloat(0),
            endAngle:CGFloat(Double.pi * 2),
            clockwise: true)

        circleLayer = CAShapeLayer()
        circleLayer?.path = circlePath.cgPath

        circleLayer?.fillColor = UIColor.clear.cgColor
        circleLayer?.strokeColor = UIColor.white.cgColor
        circleLayer?.lineWidth = desiredLineWidth
        layer.addSublayer(circleLayer!)
    }
    
    internal func drawSquareCenter() {
        squareView = UIView(frame: CGRect(x: 0,
                                              y: 0,
                                              width: self.frame.size.width - 20,
                                              height: self.frame.size.height - 20))
        //squareView.backgroundColor = UIColor.red
        squareView!.frame.origin.x = (self.frame.width - squareView!.frame.width) / 2
        squareView!.frame.origin.y = (self.frame.height - squareView!.frame.height) / 2
        self.addSubview(squareView!)
        
        squareView!.isUserInteractionEnabled = false
        squareView!.layer.masksToBounds = true
        squareView!.layer.cornerRadius = 8
        
        
        inView = UIView(frame: squareView!.bounds)
        inView?.backgroundColor = UIColor.blue
        inView?.layer.cornerRadius = 8
        self.addSubview(inView!)
        inView!.isUserInteractionEnabled = false
        
        squareView?.mask = inView
        
        let halfSize:CGFloat = min(squareView!.bounds.size.width/2, squareView!.bounds.size.height/2)
        let desiredLineWidth:CGFloat = 1    // your desired value

        let squareCirclePath = UIBezierPath(
            arcCenter: CGPoint(x:halfSize, y:halfSize),
            radius: CGFloat( halfSize - (desiredLineWidth/2) ),
            startAngle: CGFloat(0),
            endAngle:CGFloat(Double.pi * 2),
            clockwise: true)

        filledCircle = CAShapeLayer()
        filledCircle!.path = squareCirclePath.cgPath

        filledCircle!.fillColor = UIColor.red.cgColor
        squareView!.layer.addSublayer(filledCircle!)
    }

}
