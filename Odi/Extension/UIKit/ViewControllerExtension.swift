//
//  ViewControllerExtension.swift
//  Odi
//
//  Created by Baran on 21.02.2018.
//  Copyright © 2018 bilal. All rights reserved.
//

import UIKit
import MobileCoreServices

extension UIViewController{
    
    func requestAlertViewForImage(pickerController: UIImagePickerController, vc: UIViewController, completion: @escaping (_ keyData:String)->()){
        
        let alertViewController = UIAlertController(title: "", message: "Profil Fotoğrafı için seçin", preferredStyle: .actionSheet)
        let camera = UIAlertAction(title: "Kamera", style: .default, handler: { (alert) in
            //self.openCamera(pickerController: pickerController, vc: vc)
            completion("Camera")
        })
        let gallery = UIAlertAction(title: "Galeri", style: .default) { (alert) in
            //self.openGallary(pickerController: pickerController, vc: vc)
            completion("photo")
        }
        let cancel = UIAlertAction(title: "İptal et", style: .cancel) { (alert) in
            
        }
        alertViewController.addAction(camera)
        alertViewController.addAction(gallery)
        alertViewController.addAction(cancel)
        
        alertViewController.popoverPresentationController?.sourceView = self.view
        self.present(alertViewController, animated: true, completion: nil)
    }
    
    func kayaOpenCamera(pickerController: UIImagePickerController, vc: UIViewController){
        self.openCamera(pickerController: pickerController, vc: vc)
    }
    
    func kayaOpenGallery(pickerController: UIImagePickerController, vc: UIViewController){
        self.openGallary(pickerController: pickerController, vc: vc)
    }
    
    func requestAlertViewForVideo(pickerController: UIImagePickerController, vc: UIViewController){
//        let alertViewController = UIAlertController(title: "", message: "Choose your option", preferredStyle: .actionSheet)
//        let camera = UIAlertAction(title: "Kamera", style: .default, handler: { (alert) in
//            self.openCamera(pickerController: pickerController, vc: vc)
//        })
//        let gallery = UIAlertAction(title: "Galeri", style: .default) { (alert) in
//            self.openGallaryForVideo(pickerController: pickerController, vc: vc)
//        }
//        let cancel = UIAlertAction(title: "İptal et", style: .cancel) { (alert) in
//
//        }
//        alertViewController.addAction(camera)
//        alertViewController.addAction(gallery)
//        alertViewController.addAction(cancel)
//        self.present(alertViewController, animated: true, completion: nil)
        self.openGallaryForVideo(pickerController: pickerController, vc: vc)
    }
    
    func openCamera(pickerController : UIImagePickerController, vc: UIViewController) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) {
            DispatchQueue.main.async {
                pickerController.delegate = vc as? UIImagePickerControllerDelegate & UINavigationControllerDelegate
                pickerController.sourceType = UIImagePickerController.SourceType.camera
                pickerController.mediaTypes = [kUTTypeImage] as [String]
                pickerController.allowsEditing = true
                self.present(pickerController, animated: true, completion: nil)
            }
        }
        else {
                
            let alert = UIAlertController(title: "Dikkat", message:"Kameranı kullanamıyoruz", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Tamam", style: .default) { _ in })
            self.present(alert, animated: true){}

            /*
            let alertWarning = UIAlertView(title:"Dikkat", message: "Kameranı kullanamıyoruz", delegate:nil, cancelButtonTitle:"Tamam", otherButtonTitles:"")
            
            alertWarning.show()
             */
        }
    }
    func openGallary(pickerController : UIImagePickerController, vc: UIViewController) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.photoLibrary) {
            DispatchQueue.main.async {
                pickerController.delegate = vc as? UIImagePickerControllerDelegate & UINavigationControllerDelegate
                pickerController.sourceType = UIImagePickerController.SourceType.photoLibrary
                pickerController.mediaTypes = [kUTTypeImage] as [String]
                pickerController.allowsEditing = true
                self.present(pickerController, animated: true, completion: nil)
            }
        }
    }
    
    func openGallaryForVideo(pickerController : UIImagePickerController, vc: UIViewController) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.photoLibrary) {
            DispatchQueue.main.async {
                pickerController.delegate = vc as? UIImagePickerControllerDelegate & UINavigationControllerDelegate
                pickerController.sourceType = UIImagePickerController.SourceType.photoLibrary
                pickerController.mediaTypes = [kUTTypeMovie] as [String]
                pickerController.allowsEditing = true
                self.present(pickerController, animated: true, completion: nil)
            }
        }
    }
    
    func openCameraForVideo(pickerController : UIImagePickerController, vc: UIViewController) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) {
            DispatchQueue.main.async {
                pickerController.delegate = vc as? UIImagePickerControllerDelegate & UINavigationControllerDelegate
                pickerController.sourceType = UIImagePickerController.SourceType.camera
                pickerController.mediaTypes = [kUTTypeMovie as String]
                pickerController.allowsEditing = true
                self.present(pickerController, animated: true, completion: nil)
            }
        }
        else {
            let alert = UIAlertController(title: "Dikkat", message:"Kameranı kullanamıyoruz", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Tamam", style: .default) { _ in })
            self.present(alert, animated: true){}
            /*
            let alertWarning = UIAlertView(title:"Dikkat", message: "Kamerayı kullanamıyoruz", delegate:nil, cancelButtonTitle:"Tamam", otherButtonTitles:"")
            alertWarning.show()
 */
        }
    }
    
    
    
}
