//
//  galleryCell.swift
//  Odi
//
//  Created by Nok Danışmanlık on 24.10.2019.
//  Copyright © 2019 bilal. All rights reserved.
//

import UIKit
import AVKit

class galleryCell: UICollectionViewCell {
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    var thumb:UIImage?
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var videoNameLabel: UILabel!
    
    
    var data:videoModel? = nil {
        didSet {
            
            let videoInFolderPath = videoFolder?.appendingPathComponent((data?.videoPath!)!)
            
            if videoInFolderPath != nil {// videoURL
                DispatchQueue.main.async {
                    self.thumb = self.load(fileName: self.data!.thumbPath!)
                    self.imageView.image = self.thumb
                    self.imageView.contentMode = .scaleAspectFit
                    self.videoNameLabel.text = self.data?.videoPath
                }
            }
        }
    }
    
    func load(fileName: String) -> UIImage? {
        let fileURL = videoFolder!.appendingPathComponent(fileName)
        do {
            let imageData = try Data(contentsOf: fileURL!)
            return UIImage(data: imageData)
        } catch {
            print("Error loading image : \(error)")
        }
        return nil
    }
}
