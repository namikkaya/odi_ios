//
//  DragableScrollView.swift
//  Kolaj App
//
//  Created by bilal on 14/12/2017.
//  Copyright © 2017 bilal. All rights reserved.
//

import UIKit

class DragableScrollView: UIScrollView {
    
    var imageView : UIImageView?
    func configureWith(image: UIImage){
        self.imageView?.removeFromSuperview()
        self.imageView = UIImageView()
        if imageView != nil {
            self.addSubview(imageView!)
            self.imageView?.isUserInteractionEnabled = true
            self.imageView?.contentMode = .scaleAspectFit
            self.imageView?.image = image
            self.imageView?.frame = CGRect(x: 0.0, y: 0.0, width: image.size.width, height: image.size.height)
            self.delegate = self
            let scaleHeight = self.frame.width/(imageView?.bounds.size.width)!
            let scaleWidth = self.frame.height/(imageView?.bounds.size.height)!
            self.minimumZoomScale = 0.1
            self.maximumZoomScale = 10.0
            self.zoomScale = min(scaleHeight,scaleWidth)
        }
        
    }

    func crop() -> UIImage? {
        let scale:CGFloat = 1/self.zoomScale
        let x:CGFloat = self.contentOffset.x * scale
        let y:CGFloat = self.contentOffset.y * scale
        let width:CGFloat = self.frame.size.width * scale
        let height:CGFloat = self.frame.size.height * scale
        let croppedCGImage = self.imageView?.image?.cgImage?.cropping(to: CGRect(x: x, y: y, width: width, height: height))
        let croppedImage = UIImage(cgImage: croppedCGImage!)
        return croppedImage
    }
   
}
extension DragableScrollView: UIScrollViewDelegate {
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView){
        scrollView.applyZoomToImageView()
    }
}
extension UIView {
    var screenShot: UIImage?  {
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 1.0);
        if let _ = UIGraphicsGetCurrentContext() {
            drawHierarchy(in: bounds, afterScreenUpdates: true)
            let screenshot = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return screenshot
        }
        return nil
    }
}


extension UIScrollView {
    
    func applyZoomToImageView() {
        guard let imageView = delegate?.viewForZooming?(in: self) as? UIImageView else { return }
        guard let image = imageView.image else { return }
        guard imageView.frame.size.valid && image.size.valid else { return }
        let size = image.size ~> imageView.frame.size
        imageView.frame.size = size
        self.contentInset = UIEdgeInsets(
            x: self.frame.size.width ~> size.width,
            y: self.frame.size.height ~> size.height
        )
        imageView.center = self.contentCenter
        if self.contentSize.width < self.visibleSize.width {
            imageView.center.x = self.visibleSize.center.x
        }
        if self.contentSize.height < self.visibleSize.height {
            imageView.center.y = self.visibleSize.center.y
        }
    }
    
    private var contentCenter: CGPoint {
        return CGPoint(x: contentSize.width / 2, y: contentSize.height / 2)
    }
    
    private var visibleSize: CGSize {
        let size: CGSize = bounds.standardized.size
        return CGSize(
            width:  size.width - contentInset.left - contentInset.right,
            height: size.height - contentInset.top - contentInset.bottom
        )
    }
}

fileprivate extension CGFloat {
    
    static func ~>(lhs: CGFloat, rhs: CGFloat) -> CGFloat {
        return lhs > rhs ? (lhs - rhs) / 2 : 0.0
    }
}

fileprivate extension UIEdgeInsets {
    
    init(x: CGFloat, y: CGFloat) {
        self.init()
        self.bottom = y
        self.left = x
        self.right = x
        self.top = y
    }
}

fileprivate extension CGSize {
    
    var valid: Bool {
        return width > 0 && height > 0
    }
    
    var center: CGPoint {
        return CGPoint(x: width / 2, y: height / 2)
    }
    
    static func ~>(lhs: CGSize, rhs: CGSize) -> CGSize {
        switch lhs > rhs {
        case true:
            return CGSize(width: rhs.width, height: rhs.width / lhs.width * lhs.height)
        default:
            return CGSize(width: rhs.height / lhs.height * lhs.width, height: rhs.height)
        }
    }
    
    static func >(lhs: CGSize, rhs: CGSize) -> Bool {
        return lhs.width / lhs.height > rhs.width / rhs.height
    }
}



