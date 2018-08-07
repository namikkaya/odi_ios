//
//  CircleViewClass.swift
//  CircleView
//
//  Created by Baran on 7.06.2017.
//  Copyright © 2017 CaWeb. All rights reserved.
//

import Foundation
import UIKit

class CircleViewClass: UIView {
    
    private var _classRadius : Float = 50
    private var _classRepliesQuestion : Float = 50
    private var _classTotalQuestion : Float = 100
    private var _classCircleColor : CGColor = UIColor.red.cgColor
    private var _classCircleAnimateDuration : CFTimeInterval = 3.0
    private var _classCircleWidth : Float = 5.0
    private var shapeLayer : CAShapeLayer!
    private var tintShapeLayer : CAShapeLayer!
    
    
    var classRepliesQuestion : Float {
        set{
            self._classRepliesQuestion = newValue * 2
        }
        get{
            return self._classRepliesQuestion / 2
        }
    }
    
    var classTotalQuestion : Float {
        set{
            self._classTotalQuestion = newValue * 2
        }
        get{
            return self._classTotalQuestion / 2
        }
    }
    
    var classCircleColor : CGColor {
        set{
            self._classCircleColor = newValue
        }
        get{
            return self._classCircleColor
        }
    }
    var classCircleAnimateDuration : CFTimeInterval {
        set{
            self._classCircleAnimateDuration = newValue
        }
        get{
            return self._classCircleAnimateDuration
        }
    }
    var classCircleWidth : Float {
        set{
            self._classCircleWidth = newValue
        }
        get{
            return self._classCircleWidth
        }
    }
    
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.configureView()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
       self.configureView()
        self.translatesAutoresizingMaskIntoConstraints = false
    }
    
    func createCircleView(){
        self._classRadius = Float(self.frame.width / 2)
        let startAngle = Float.pi * 3 / 2
        let endAngle = self.endAngleFunc(radius: self._classRadius, repliesQuestion: classRepliesQuestion, totalQuestion: classTotalQuestion)
        
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: frame.width / 2 ,y: frame.height / 2), radius: CGFloat(self._classRadius), startAngle: CGFloat(startAngle), endAngle:CGFloat(endAngle), clockwise: true)
        let tinCirclePath = UIBezierPath(arcCenter: CGPoint(x: frame.width / 2 ,y: frame.height / 2), radius: CGFloat(self._classRadius), startAngle: CGFloat(startAngle), endAngle:CGFloat(startAngle - 0.0001), clockwise: true)
       
        
        
        shapeLayer = self.createLayer(path: circlePath, lineWidth: CGFloat(classCircleWidth), strokeColor: classCircleColor)
        tintShapeLayer = self.createLayer(path: tinCirclePath, lineWidth: CGFloat(classCircleWidth / 3), strokeColor : UIColor.lightGray.cgColor)

        
        
        self.layer.addSublayer(shapeLayer)
        self.layer.insertSublayer(tintShapeLayer, below: shapeLayer)
        //self.choiseAnimate(customLayer: shapeLayer)
        //self.choiseAnimate(customLayer: tintShapeLayer)
    }
    
    private func createLayer(path : UIBezierPath , lineWidth : CGFloat , strokeColor : CGColor) -> CAShapeLayer {
        let shapeLayer = CAShapeLayer()
        
        shapeLayer.path = path.cgPath
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = strokeColor
        shapeLayer.lineWidth = lineWidth
        //shapeLayer.strokeEnd = 0.0
       // shapeLayer.strokeStart = 1.0
//        shapeLayer.lineJoin = kCALineJoinRound
        
        return shapeLayer
    }
    
    private func choiseAnimate(customLayer : CAShapeLayer) {
        let anim1 = CABasicAnimation(keyPath: "strokeEnd")
        anim1.fromValue         = 0.0
        anim1.toValue           = 1.0
        anim1.duration          = 0.0
        anim1.repeatCount       = 1.0
        anim1.autoreverses      = false
        anim1.isRemovedOnCompletion = false
        anim1.isAdditive = true
        anim1.fillMode = kCAFillModeForwards
        customLayer.add(anim1, forKey: "strokeEnd")
    }
    
    
    private func endAngleFunc(radius : Float, repliesQuestion: Float , totalQuestion : Float ) -> Float {
        
        let peripheryOfCircle = (Float.pi * 2) * radius
        let rate = (repliesQuestion * peripheryOfCircle) / totalQuestion
        
        var result : Float = 0
        if rate > peripheryOfCircle {
            result = rate / (peripheryOfCircle / 2)
        }
        else if rate == peripheryOfCircle {
            result = rate / (peripheryOfCircle / 2) - 0.0001
        }
        else if rate < peripheryOfCircle{
            result = rate / (peripheryOfCircle / 2)
        }
        
        let endAngle = (result  * Float.pi) - (Float.pi / 2)
        
        
        return endAngle
    }
    
    
    
    private func configureView(){
        shapeLayer = CAShapeLayer()
        tintShapeLayer = CAShapeLayer()
        
    }
    
    
}




