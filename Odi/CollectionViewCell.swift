//
//  CollectionViewCell.swift
//  Kolaj App
//
//  Created by bilal on 14/12/2017.
//  Copyright © 2017 bilal. All rights reserved.
//

import UIKit

class CollectionViewCell: UICollectionViewCell {

    
    @IBOutlet weak var cellImageView: UIImageView!
    var dragrableImage : UIImageView?
    var dragStartPositionRelativeToCenter : CGPoint?
    var draggableDelegate : DraggableCellDelegate?
    override func awakeFromNib() {
        super.awakeFromNib()
        addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(handlePan(nizer:))))
    }
    @objc func handlePan(nizer: UILongPressGestureRecognizer!) {
        
        if nizer.state == UIGestureRecognizerState.began {
            let locationInView = nizer.location(in: superview?.superview)
            if cellImageView.image == nil {
                return
            }
            print(locationInView)
            dragStartPositionRelativeToCenter = CGPoint(x: locationInView.x - center.x, y: locationInView.y - center.y)
            self.dragrableImage = UIImageView(image: self.cellImageView.image)
            self.dragrableImage?.frame = cellImageView.frame
            self.dragrableImage?.frame.origin = dragStartPositionRelativeToCenter!
            self.superview?.superview?.addSubview(dragrableImage!)
            layer.shadowOffset = CGSize(width: 0, height: 20)
            layer.shadowOpacity = 0.3
            layer.shadowRadius = 6
            
            return
        }
        
        if nizer.state == UIGestureRecognizerState.ended {
            let locationInView = nizer.location(in: superview?.superview)
            if self.draggableDelegate != nil {
                self.draggableDelegate?.draggingComplete(image: (self.dragrableImage?.image)!, location: locationInView)
            }
            dragStartPositionRelativeToCenter = nil
            self.dragrableImage?.removeFromSuperview()
            self.dragrableImage = nil
            layer.shadowOffset = CGSize(width: 0, height: 3)
            layer.shadowOpacity = 0.5
            layer.shadowRadius = 2
            
            return
        }
        
        let locationInView = nizer.location(in: superview?.superview)
        
        UIView.animate(withDuration: 0.1) {
            self.dragrableImage?.center = CGPoint(x: locationInView.x,
                                  y: locationInView.y)
        }
    }

}
protocol DraggableCellDelegate {
    func draggingComplete(image: UIImage,location : CGPoint)
}
