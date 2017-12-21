//
//  DragableScrollView.swift
//  Kolaj App
//
//  Created by bilal on 14/12/2017.
//  Copyright © 2017 bilal. All rights reserved.
//

import UIKit

class DragableScrollView: UIScrollView,UIScrollViewDelegate {
    
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
            self.minimumZoomScale = 0.01
            self.maximumZoomScale = 10.0
            self.zoomScale = min(scaleHeight,scaleWidth)
            self.contentSize = CGSize(width: (self.imageView?.bounds.width)! * 3, height: (self.imageView?.bounds.height)! * 3)
            self.contentOffset = CGPoint(x: self.contentSize.width/2 - self.bounds.width/2, y: self.contentSize.height/2 - self.bounds.height/2)
            self.imageView?.center = CGPoint(x: self.contentSize.width/2, y: self.contentSize.height/2)
        }
        
    }
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let offsetX = max((self.bounds.size.width - self.contentSize.width)/2 , 0.0)
        let offsetY = max((self.bounds.size.height - self.contentSize.height)/2 , 0.0)
        self.imageView?.center = CGPoint(x:self.contentSize.width * 0.5 + offsetX, y:self.contentSize.height * 0.5 + offsetY)
    }
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
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



