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
    
    func requestAlertViewForImage(pickerController: UIImagePickerController, vc: UIViewController){
        let alertViewController = UIAlertController(title: "", message: "Choose your option", preferredStyle: .actionSheet)
        let camera = UIAlertAction(title: "Kamera", style: .default, handler: { (alert) in
            self.openCamera(pickerController: pickerController, vc: vc)
        })
        let gallery = UIAlertAction(title: "Galeri", style: .default) { (alert) in
            self.openGallary(pickerController: pickerController, vc: vc)
        }
        let cancel = UIAlertAction(title: "İptal et", style: .cancel) { (alert) in
            
        }
        alertViewController.addAction(camera)
        alertViewController.addAction(gallery)
        alertViewController.addAction(cancel)
        self.present(alertViewController, animated: true, completion: nil)
    }
    
    func requestAlertViewForVideo(pickerController: UIImagePickerController, vc: UIViewController){
        let alertViewController = UIAlertController(title: "", message: "Choose your option", preferredStyle: .actionSheet)
        let camera = UIAlertAction(title: "Kamera", style: .default, handler: { (alert) in
            self.openCamera(pickerController: pickerController, vc: vc)
        })
        let gallery = UIAlertAction(title: "Galeri", style: .default) { (alert) in
            self.openGallaryForVideo(pickerController: pickerController, vc: vc)
        }
        let cancel = UIAlertAction(title: "İptal et", style: .cancel) { (alert) in
            
        }
        alertViewController.addAction(camera)
        alertViewController.addAction(gallery)
        alertViewController.addAction(cancel)
        self.present(alertViewController, animated: true, completion: nil)
    }
    
    func openCamera(pickerController : UIImagePickerController, vc: UIViewController) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera) {
            pickerController.delegate = vc as? UIImagePickerControllerDelegate & UINavigationControllerDelegate
            pickerController.sourceType = UIImagePickerControllerSourceType.camera
            pickerController.mediaTypes = [kUTTypeImage] as [String]
            pickerController.allowsEditing = true
            self.present(pickerController, animated: true, completion: nil)
        }
        else {
            let alertWarning = UIAlertView(title:"Warning", message: "You don't have camera", delegate:nil, cancelButtonTitle:"OK", otherButtonTitles:"")
            alertWarning.show()
        }
    }
    func openGallary(pickerController : UIImagePickerController, vc: UIViewController) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.photoLibrary) {
            pickerController.delegate = vc as? UIImagePickerControllerDelegate & UINavigationControllerDelegate
            pickerController.sourceType = UIImagePickerControllerSourceType.photoLibrary
            pickerController.mediaTypes = [kUTTypeImage] as [String]
            pickerController.allowsEditing = true
            self.present(pickerController, animated: true, completion: nil)
        }
    }
    
    func openGallaryForVideo(pickerController : UIImagePickerController, vc: UIViewController) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.photoLibrary) {
            pickerController.delegate = vc as? UIImagePickerControllerDelegate & UINavigationControllerDelegate
            pickerController.sourceType = UIImagePickerControllerSourceType.photoLibrary
            pickerController.mediaTypes = [kUTTypeMovie] as [String]
            pickerController.allowsEditing = true
            self.present(pickerController, animated: true, completion: nil)
        }
    }
    
    func openCameraForVideo(pickerController : UIImagePickerController, vc: UIViewController) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera) {
            pickerController.delegate = vc as? UIImagePickerControllerDelegate & UINavigationControllerDelegate
            pickerController.sourceType = UIImagePickerControllerSourceType.camera
            pickerController.mediaTypes = [kUTTypeMovie as String]
            pickerController.allowsEditing = true
            self.present(pickerController, animated: true, completion: nil)
        }
        else {
            let alertWarning = UIAlertView(title:"Warning", message: "You don't have camera", delegate:nil, cancelButtonTitle:"OK", otherButtonTitles:"")
            alertWarning.show()
        }
    }
    
}
