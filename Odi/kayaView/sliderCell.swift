//
//  sliderCell.swift
//  slidePaging
//
//  Created by Nok Danışmanlık on 25.05.2019.
//  Copyright © 2019 Brokoly. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireImage
/*
enum cellOkeyButtonType:String {
    case nextButton
    case okeyButton
}

protocol sliderCellButtonEvent:class {
    func sliderEventListener(type:cellOkeyButtonType, row:Int)
}*/

class sliderCell: UICollectionViewCell {
    override func awakeFromNib() {
        super.awakeFromNib()
        okeyButton.layer.cornerRadius = 8
        okeyButton.layer.masksToBounds = true
    }
    
    //weak var setDelegate:sliderCellButtonEvent?
    
    var data:sliderModel? = nil {
        didSet {
            reloadedData()
        }
    }
    
    var row:Int?
    /*
    var typeButton:cellOkeyButtonType = .nextButton {
        didSet {
            if (typeButton == .nextButton) {
                okeyButton.setTitle("Geç", for: UIControl.State.normal)
            }else {
                okeyButton.setTitle("Tamam", for: UIControl.State.normal)
            }
        }
    }
 */
    
    func reloadedData() {
        setImage = data!.imageURL!
    }
    
    var setImage:String = "" {
        didSet {
            loadImage(imgStr: setImage)
        }
    }
    
    private func loadImage(imgStr:String) {
        Alamofire.request(imgStr).responseImage { response in
            //debugPrint(response)
            
//            print(response.request)
//            print(response.response)
//            debugPrint(response.result)
            
            if let image = response.result.value {
                //print("image downloaded: \(image)")
                self.imageView.image = image
                self.imageView.contentMode = .scaleAspectFit
                self.progress.isHidden = true
            }
        }
    }
    
    
    @IBAction func buttonEvent(_ sender: Any) {
        //setDelegate?.sliderEventListener(type: typeButton, row: row!)
    }
    
    
    @IBOutlet var progress: UIActivityIndicatorView!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var okeyButton: UIButton!
    
}
