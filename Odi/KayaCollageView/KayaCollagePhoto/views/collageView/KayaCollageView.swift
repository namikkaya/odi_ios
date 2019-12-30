//
//  KayaCollageView.swift
//  imageCollageCrop
//
//  Created by Nok Danışmanlık on 4.12.2019.
//  Copyright © 2019 brokoly. All rights reserved.
//

import UIKit

protocol KayaCollageViewDelegate:class {
    func KayaCollageView(currentRate:Double?, selectedImageView:UIImageView?)
}
extension KayaCollageViewDelegate {
    func KayaCollageView(currentRate:Double?, selectedImageView:UIImageView?) {}
}


/**
 Usage:  oranları düzgün girmen gerekiyor yoksa tasarım sapıtabilir
 346 - 350 boyutları ve oranlarıyla
 */
class KayaCollageView: UIView {
    private var view:UIView!
    private var nibName:String = "KayaCollageView"
    
    weak var setDelegate:KayaCollageViewDelegate?
    
//    MARK: - object
    @IBOutlet var leftImageView: UIImageView!
    @IBOutlet var rightTopImageView: UIImageView!
    @IBOutlet var rightBottomImageView: UIImageView!
    
//    MARK: - holder
    private var currentRate:Double?
    private var selectedImageView:UIImageView?
    
//    MARK: - Variables
    var rate:Double? {
        get {
            return currentRate
        }
    }
    
    var selected:UIImageView? {
        get {
            return selectedImageView
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup(){
        view = loadViewFromNib()
        view.frame = bounds
        view.autoresizingMask = [UIView.AutoresizingMask.flexibleWidth, UIView.AutoresizingMask.flexibleHeight]
        addSubview(view)
        configurationImageView()
    }
    
    
    func loadViewFromNib()-> UIView {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: nibName, bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
        return view
    }
//    MARK: - Config Functions
    fileprivate func configurationImageView() {
        leftImageView.isUserInteractionEnabled = true
        leftImageView.tag = 1
        rightTopImageView.isUserInteractionEnabled = true
        rightTopImageView.tag = 2
        rightBottomImageView.isUserInteractionEnabled = true
        rightBottomImageView.tag = 3
               
        let leftImageViewGesture = UITapGestureRecognizer(target: self, action:#selector(imageTapped(tapGestureRecognizer:)))
        let rightTopImageViewGesture = UITapGestureRecognizer(target: self, action:#selector(imageTapped(tapGestureRecognizer:)))
        let rightBottomImageViewGesture = UITapGestureRecognizer(target: self, action:#selector(imageTapped(tapGestureRecognizer:)))
        
        leftImageView.addGestureRecognizer(leftImageViewGesture)
        rightTopImageView.addGestureRecognizer(rightTopImageViewGesture)
        rightBottomImageView.addGestureRecognizer(rightBottomImageViewGesture)
    }
    
    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer)
    {
        if let tappedImage = tapGestureRecognizer.view as? UIImageView {
            switch tappedImage.tag {
            case 1:
                selectedImageView = leftImageView
                currentRate = Double(leftImageView.frame.size.width / leftImageView.frame.size.height)
                setDelegate?.KayaCollageView(currentRate: currentRate, selectedImageView: leftImageView)
                break
            case 2:
                selectedImageView = rightTopImageView
                currentRate = Double(rightTopImageView.frame.size.width / rightTopImageView.frame.size.height)
                setDelegate?.KayaCollageView(currentRate: currentRate, selectedImageView: rightTopImageView)
                break
            case 3:
                selectedImageView = rightBottomImageView
                currentRate = Double(rightBottomImageView.frame.size.width / rightBottomImageView.frame.size.height)
                setDelegate?.KayaCollageView(currentRate: currentRate, selectedImageView: rightBottomImageView)
                break
            default:
                print("boş")
                break
            }
        }
        
    }
    
    /**
     Usage: Bütün imagelar atanmış ise true / atanmamışsa false döner
     - Returns: Bool - true/false
     */
    func allCheckImage() -> Bool {
        var check:Bool = true
        if leftImageView.image == nil {
            check = false
        }
        if rightTopImageView == nil {
            check = false
        }
        if rightBottomImageView == nil {
            check = false
        }
        return check
    }
    
    
    public func snapshotImage() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, isOpaque, 0)
        self.drawHierarchy(in: self.bounds, afterScreenUpdates: false)
        let snapshotImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return snapshotImage
    }
}
