//
//  KayaCameraViewController.swift
//  videoMuteSystem_hub
//
//  Created by namikkaya on 29.11.2019.
//  Copyright © 2019 brokoly. All rights reserved.
//

import UIKit

@IBDesignable
class KayaCameraViewController: UIViewController, KayaCameraViewDelegate {
    
    private var recordButtonColorHolder:UIColor = UIColor.red
    /// recordbutton için
    @IBInspectable var recordButtonColor:UIColor {
        set {
            recordButtonColorHolder = newValue
        }get {
            return recordButtonColorHolder
        }
    }
    
    private var WBButtonHiddenStatusHolder:Bool = false
    /// wb
    @IBInspectable var WBButtonHiddenStatus:Bool {
        set {
            WBButtonHiddenStatusHolder = newValue
            guard let cV = cameraView else { return }
            cV.WBButtonHidden = newValue
        }get {
            return WBButtonHiddenStatusHolder
        }
    }
    
    var galleryImage:UIImage? = nil {
        didSet{
            if let cv = cameraView {
                cv.galleryImage = galleryImage
            }
        }
    }
    
//    MARK: - VIEW
    var cameraView:KayaCameraView?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.black
        
    }
    
    func addPreviewView(previewView:UIView) {
        self.viewConfiguration(targetView: previewView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if self.cameraView != nil {
            self.cameraView?.removeFromSuperview()
            self.cameraView = nil
        }
        
    }
    
    func didClose() {
        if cameraView != nil {
            cameraView?.didClose()
        }
    }

    func viewConfiguration(targetView:UIView) {
        // cameraView Component
        self.cameraView = KayaCameraView()
        self.cameraView?.setDelegate = self
        self.cameraView?.WBButtonHidden = self.WBButtonHiddenStatus
        self.cameraView?.frame = self.view.bounds
        //self.view.addSubview(self.cameraView!)
        targetView.addSubview(self.cameraView!)
        self.cameraView?.setNeedsDisplay()
        self.view.setNeedsLayout()
        
        
        
        //self.cameraView?.clearTempFolder()
        
        // layout size
        self.cameraView!.translatesAutoresizingMaskIntoConstraints = false
        self.cameraView!.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        self.cameraView!.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        self.cameraView!.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.cameraView!.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        self.cameraView?.rotated()
    }
    
//    MARK: - KayaCameraView Delegate
    /// Kamera kapatma buttonuna tıklandığında tetiklenir
    func KayaCameraViewDelegate_CloseButtonEvent() {
        
    }
    
    /// Daha önceden kaydedilmiş veya daha önce çekilmiş videolara ulaşmak istenildiğinde eğer atama yapılda ise gösteriler galeri buttonuna tıklandığında tetiklenir.
    func KayaCameraViewDelegate_OpenGallery() {
        
    }
    
    /**
     Usage:  Record edilmiş videonun image ve thumb dosyasıyla beraber haber verir
     - Parameter outputURL:  video path
     - Parameter originalImage:  video orjinal boyutu
     - Parameter thumbnail:  video 120x120 thumbnail
     - Returns: No return value
     */
    func KayaCameraViewDelegate_VideoOutPutExport(outputURL: URL?, originalImage: UIImage?, thumbnail: UIImage?) {
        
    }
    
    /**
    Usage:  Record edilmiş videonun image ve thumb dosyasıyla beraber haber verir
    - Parameter outputURL:  video path
    - Parameter originalImage:  video orjinal boyutu
    - Parameter thumbnail:  video 120x120 thumbnail
    - Returns: No return value
    */
    func KayaCameraViewdelegate_RecordStatus(recordStatus: RecordStatus) {
        
    }
    
    /**
    Usage:  Record edilmiş videonun image ve thumb dosyasıyla beraber haber verir
    - Parameter cameraPosition: camera pozisyonu 
    - Returns: No return value
    */
    func KayaCameraViewDelegate_ChangeCamera(cameraPosition: CameraPosition?) {
        
    }
    
    /**
    Usage:  camera input problemlerini döndürür
    */
    func KayaCameraViewDelegate_Error() {
        
    }
    
}
