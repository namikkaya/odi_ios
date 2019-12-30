//
//  CollectionViewCell.swift
//  Kolaj App
//
//  Created by bilal on 14/12/2017.
//  Copyright © 2017 bilal. All rights reserved.
//

import UIKit

class imageCollectionViewCell: UICollectionViewCell {

    
    @IBOutlet weak var cellImageView: UIImageView!
    var draggableDelegate : DraggableCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    

}
protocol DraggableCellDelegate {
    func draggingComplete(image: UIImage,location : CGPoint)
}
