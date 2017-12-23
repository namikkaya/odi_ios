//
//  Extensions.swift
//  AkademiAnaokulu
//
//  Created by MobileDeveloper on 10/25/17.
//  Copyright © 2017 MobileDeveloper. All rights reserved.
//

import Foundation
import UIKit

private var dataAssocKey = 0
extension UIViewController {
   
}
extension UIViewController {
    
    var data:AnyObject? {
        get {
            return objc_getAssociatedObject(self, &dataAssocKey) as AnyObject?
        }
        set {
            objc_setAssociatedObject(self, &dataAssocKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    func goto(screenID:String) {
        goto(screenID: screenID, animated: true, data: nil, isModal: false)
    }
    
    func goto(screenID:String, animated:Bool) {
        goto(screenID: screenID, animated: animated, data: nil, isModal: false)
    }
    
    func goto(screenID:String, data:AnyObject!) {
        goto(screenID: screenID, animated: true, data: data, isModal: false)
    }
    
    func goto(screenID:String, animated:Bool, data:AnyObject!) {
        goto(screenID: screenID, animated: animated, data: data, isModal: false)
    }
    
    func goto(screenID:String, animated:Bool, data:AnyObject!, isModal:Bool) {
        let vc:UIViewController = (self.storyboard?.instantiateViewController(withIdentifier: screenID))!
        if (data != nil) {
            vc.data = data
        }
        if isModal == true {
            vc.modalPresentationStyle = .overCurrentContext
            self.present(vc, animated: animated, completion:nil)
        }
        else {
            self.navigationController?.pushViewController(vc, animated: animated)
            self.navigationController?.setNavigationBarHidden(true, animated: false) // Navigation Barı Saklar.
        }
    }
    
    func goto(screenID:String, animated:Bool, data:AnyObject!, isModal:Bool, isNavigation:Bool, showNavBar:Bool) {
     
        
        let vc:UIViewController = (self.storyboard?.instantiateViewController(withIdentifier: screenID))!
        if (data != nil) {
            vc.data = data
        }
        if isModal == true {
            if isNavigation {
                let navVC:UINavigationController! = UINavigationController(rootViewController: vc)
                navVC.isNavigationBarHidden = !showNavBar
                self.present(navVC, animated: animated, completion:nil)
            }
            else {
                self.present(vc, animated: animated, completion:nil)
            }
            
            
        }
        else {
            self.navigationController?.pushViewController(vc, animated: animated)
        }
        
    }
    
    func back() {
        back(animated: true,isModal: false)
    }
    
    func back(animated:Bool) {
        back(animated: animated, isModal: false)
    }
    
    func back(animated:Bool, isModal:Bool) {
        if isModal == true {
            self.dismiss(animated: animated, completion: nil)
        }
        else {
            self.navigationController?.popViewController(animated: animated)
        }
    }
    
    func back(animated:Bool, screenID:String) {
        var index:NSInteger = -1
        let vcs:NSArray = NSArray(array: (self.navigationController?.viewControllers)!)
        for i in 0...vcs.count {
            
            if (vcs[i] as AnyObject).isKind(of: NSClassFromString("Etap.\(screenID)")!) {
                index = i
                break
            }
        }
        if index >= 0 {
            self.navigationController?.popToViewController(vcs[index] as! UIViewController, animated: true)
        }
    }
    
}

//UIView

extension UIView {
    
    var width:      CGFloat { return self.frame.size.width }
    var height:     CGFloat { return self.frame.size.height }
    var size:       CGSize  { return self.frame.size}
    
    var origin:     CGPoint { return self.frame.origin }
    var x:          CGFloat { return self.frame.origin.x }
    var y:          CGFloat { return self.frame.origin.y }
    var centerX:    CGFloat { return self.center.x }
    var centerY:    CGFloat { return self.center.y }
    
    var left:       CGFloat { return self.frame.origin.x }
    var right:      CGFloat { return self.frame.origin.x + self.frame.size.width }
    var top:        CGFloat { return self.frame.origin.y }
    var bottom:     CGFloat { return self.frame.origin.y + self.frame.size.height }
    
    func setWidth(width:CGFloat) {
        self.frame.size.width = width
    }
    
    func setHeight(height:CGFloat) {
        self.frame.size.height = height
    }
    
    func setSize(size:CGSize) {
        self.frame.size = size
    }
    
    func setOrigin(point:CGPoint) {
        self.frame.origin = point
    }
    
    func setX(x:CGFloat) {
        
        self.frame.origin = CGPoint(x: x, y: self.frame.origin.y)
    }
    
    func setY(y:CGFloat) {
        self.frame.origin = CGPoint(x: self.frame.origin.x, y: y)
    }
    
    func setCenterX(x:CGFloat) {
        self.center = CGPoint(x: x, y: self.center.y)
    }
    
    func setCenterY(y:CGFloat) {
        self.center = CGPoint(x: self.center.x, y: y)
    }
    
    func roundCorner(radius:CGFloat) {
        self.layer.cornerRadius = radius
    }
    
    func setTop(top:CGFloat) {
        self.frame.origin.y = top
    }
    
    func setLeft(left:CGFloat) {
        self.frame.origin.x = left
    }
    
    func setRight(right:CGFloat) {
        self.frame.origin.x = right - self.frame.size.width
    }
    
    func setBottom(bottom:CGFloat) {
        self.frame.origin.y = bottom - self.frame.size.height
    }
    
    func addShadow() {
        self.layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.05).cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: 2)
        self.layer.shadowRadius = 8.0
        self.layer.shadowOpacity = 0.3
    }
    
    func addShadow(offset: CGSize, color: UIColor = .black, opacity: Float = 0.5, radius: CGFloat = 5.0) {
        self.layer.masksToBounds = false
        self.layer.shadowColor = color.cgColor
        self.layer.shadowOffset = offset
        self.layer.shadowOpacity = opacity
        self.layer.shadowRadius = radius
    }
    
    func addShadow(location: VerticalLocation, color: UIColor = .black, opacity: Float = 0.5, radius: CGFloat = 5.0) {
        switch location {
        case .bottom:
            addShadow(offset: CGSize(width: 0, height: 10), color: color, opacity: opacity, radius: radius)
        case .top:
            addShadow(offset: CGSize(width: 0, height: -10), color: color, opacity: opacity, radius: radius)
        }
    }
    
    func circle() {
        self.layer.cornerRadius = self.width / 2.0
    }
}

extension CGFloat {
    func screenHorizontalCenter() -> CGFloat {
        return ((UIScreen.main.bounds.size.width - self) / 2.0)
    }
}

extension String {
    func loadImage(completion: @escaping (_ result: UIImage) -> Void) {
        //        Alamofire.request(method: .GET, url: self).responseImage { response in
        //            if let image = response.result.value {
        //                completion(result: image)
        //            }
        //        }
    }
}

extension UIView {
    func shake() {
        
        let animation = CAKeyframeAnimation()
        animation.keyPath = "position.x"
        animation.values =  [0, 20, -20, 10, 0]
        animation.keyTimes = [0, NSNumber(value: 1.0 / 6.0), NSNumber(value: 1.0 / 6.0), NSNumber(value: 5.0 / 6.0), 1]
        animation.duration = 0.3
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        animation.isAdditive = true
        self.layer.add(animation, forKey: "shake")
    }
    
}

extension UIImageView {
    
    func setBase64Image(base64String:String!) {
        if base64String == nil {
            return
        }
        DispatchQueue.main.async {
            let dataDecoded:NSData = NSData(base64Encoded: base64String, options: NSData.Base64DecodingOptions(rawValue: 0))!
            let decodedimage:UIImage = UIImage(data: dataDecoded as Data)!
            self.image = decodedimage
        }
    }
}

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(netHex:Int) {
        self.init(red:(netHex >> 16) & 0xff, green:(netHex >> 8) & 0xff, blue:netHex & 0xff)
    }
}

extension UINavigationBar {
    func removeBorder() {
        for parent in self.subviews {
            for childView in parent.subviews {
                if(childView is UIImageView) {
                    childView.removeFromSuperview()
                }
            }
        }
    }
}

extension UITableView {
    func removeEmptyCells() {
        self.tableFooterView = UIView()
    }
    
    func removeBackground() {
        self.backgroundView = nil
        self.backgroundColor = UIColor.clear
    }
}

extension UITableViewCell {
    func removeBackground() {
        self.backgroundColor = UIColor.clear
        self.backgroundView = nil
    }
}

extension UIApplication {
    class func topViewController(base: UIViewController? = (UIApplication.shared.delegate as! AppDelegate).window?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            if let selected = tab.selectedViewController {
                return topViewController(base: selected)
            }
        }
        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        return base
    }
}

//textfield
extension Data {
    var hexString: String {
        return map { String(format: "%02.2hhx", arguments: [$0]) }.joined()
    }
}
extension UITextField {
    func localization(locKey:String!) {
        if locKey != nil {
            //self.placeholder = Localization.loc(locKey)
        }
    }
    
    func setPlaceholderColor(color:UIColor!) {
        if self.placeholder != nil {
            self.attributedPlaceholder = NSAttributedString(string:self.placeholder!,
                                                            attributes:[NSForegroundColorAttributeName: color])
        }
        
    }
}

extension UILabel {
    func localization(locKey:String!) {
        if locKey != nil {
            //self.text = Localization.loc(locKey)
        }
    }
    
    func textSize() -> CGSize {
        let labelSize:CGSize! = self.intrinsicContentSize
        return labelSize
    }
}

extension UIButton {
    func localization(locKey:String!) {
        if locKey != nil {
            //self.setTitle(title: Localization.loc(locKey), forState: .Normal)
        }
    }
    
    func underline() {
        let attributes = [NSUnderlineStyleAttributeName: NSUnderlineStyle.styleSingle.rawValue]
        let attributedText = NSAttributedString(string: self.currentTitle!, attributes: attributes)
        self.titleLabel?.attributedText = attributedText
    }
    
    override func shake() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        animation.duration = 0.6
        animation.values = [-20.0, 20.0, -20.0, 20.0, -10.0, 10.0, -5.0, 5.0, 0.0 ]
        layer.add(animation, forKey: "shake")
    }
    
}
extension Date {
    func getTodayDateString() -> String {
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        let result = formatter.string(from: date)
        return result
    }
}
enum VerticalLocation: String {
    case bottom
    case top
}



