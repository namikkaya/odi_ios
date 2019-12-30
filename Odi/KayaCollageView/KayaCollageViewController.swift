//
//  KayaCollageViewController.swift
//  Odi
//
//  Created by Nok Danışmanlık on 6.12.2019.
//  Copyright © 2019 bilal. All rights reserved.
//

import UIKit
import WebKit
import Mantis
import Photos

class KayaCollageViewController: UIViewController, KayaCollageViewDelegate, CropViewControllerDelegate{
    let TAG:String = "KayaCollageViewController"
    var webViewForSuccess: WKWebView?
    var popUpController : SIC?
    
    let onesignalID = UserPrefence.getOneSignalId()
    
    @IBOutlet var collegeView: KayaCollageView!
    
//    MARK: - Holder
    var id = ""
    fileprivate var currentVC: UIViewController!
    internal var myPickerController:UIImagePickerController?
    
    var currentRate:Double?
    var selectedImageView:UIImageView?
    
    // collectionView
    
    fileprivate let kCellReuseIdentifier = "imageCollectionViewCell"
    fileprivate let kColumnCnt: Int = 4
    fileprivate let kCellSpacing: CGFloat = 2
    fileprivate var fetchResult: PHFetchResult<PHAsset>!
    fileprivate var imageManager = PHCachingImageManager()
    fileprivate var targetSize =  PHImageManagerMaximumSize//CGSize.zero

//    MARK: - Class
    var service : UploadImageService = UploadImageService()
    
//    MARK: - Object
    
    @IBOutlet var collectionView: UICollectionView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collegeView.setDelegate = self
        service.serviceDelegate = self
        initView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        
        /*DispatchQueue.main.async {
            self.collectionView.reloadData()
        }*/
        
        
        
        let photos = PHPhotoLibrary.authorizationStatus()
        if photos == .notDetermined {
            PHPhotoLibrary.requestAuthorization({status in
                if status == .authorized{
                    self.loadPhotos()
                } else {
                    print("\(self.TAG) authorized else")
                }
            })
        } else if photos == .authorized {
            self.loadPhotos()
        } else if photos == .restricted {
            print("\(self.TAG) restricted else")
        }else{
            PHPhotoLibrary.requestAuthorization({status in
                if status == .authorized{
                    self.loadPhotos()
                } else {
                    print("\(self.TAG) else authorized else")
                    let permision = UIAlertController (title: "İzin Yok!", message: "Odi'nin fotoğraflarına ulaşması için iznine ihtiyacı var. Portre Kolajı oluşturmak için hemen \n'Ayarlar' -> 'Odi' -> 'Fotoğraflar' \nsekmesinden 'Okuma ve Yazma' seçeneğini seçin.", preferredStyle: .alert)
                    
                    let settingsAction = UIAlertAction(title: "Ayarlar", style: .default) { (_) -> Void in
                        let settingsUrl = NSURL(string:UIApplication.openSettingsURLString)
                        if let url = settingsUrl {
                            DispatchQueue.main.async {
                                UIApplication.shared.open(url as URL, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
                            }
                        }
                    }
                    
                    let cancelAction = UIAlertAction(title: "İptal", style: UIAlertAction.Style.destructive, handler: { (act) in
                        self.navigationController?.popViewController(animated: true)
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "transitionBackToWebview"), object: nil, userInfo: nil)
                    })
                    permision .addAction(settingsAction)
                    permision .addAction(cancelAction)
                    self.present(permision, animated: true, completion: nil)
                }
            })
        }
    }
    
    func KayaCollageView(currentRate: Double?, selectedImageView: UIImageView?) {
        self.currentRate = currentRate
        self.selectedImageView = selectedImageView
        showActionSheet(vc: self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = false
        self.navigationController?.navigationBar.tintColor = UIColor.white
    }
    
    func showActionSheet(vc: UIViewController) {
        currentVC = vc
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Kameradan", style: .default, handler: { (alert:UIAlertAction!) -> Void in
            self.camera()
        }))
        actionSheet.addAction(UIAlertAction(title: "Galeriden", style: .default, handler: { (alert:UIAlertAction!) -> Void in
            self.photoLibrary()
        }))
        actionSheet.addAction(UIAlertAction(title: "İptal", style: .cancel, handler: nil))
        vc.present(actionSheet, animated: true, completion: nil)
    }
    
    func photoLibrary() {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary){
            myPickerController = UIImagePickerController()
            myPickerController!.delegate = self;
            myPickerController!.mediaTypes = ["public.image"]
            myPickerController!.sourceType = .photoLibrary
            currentVC.present(myPickerController!, animated: true, completion: nil)
        }
    }
    
    func camera() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            myPickerController = UIImagePickerController()
            myPickerController!.delegate = self;
            myPickerController!.mediaTypes = ["public.image"]
            myPickerController!.sourceType = .camera
            myPickerController!.cameraDevice = .front
            currentVC.present(myPickerController!, animated: true, completion: nil)
        }
    }

    @IBAction func saveButtonEvent(_ sender: Any) {
        if !collegeView.allCheckImage() {
            print("boş item var")
        }else {
            print("işlem yapılacak")
            let myImage = collegeView.snapshotImage()
            service.connectService(fileName: "profil_\(id).jpg", image: myImage!)
            self.view.isUserInteractionEnabled = false
            self.navigationController?.navigationBar.isUserInteractionEnabled = false
            self.popUpController = self.SHOW_SIC(type: .image)
        }
    }
    
    func cropViewControllerDidCrop(_ cropViewController: CropViewController, cropped: UIImage) {
        if let imageV = selectedImageView {
            imageV.image = cropped
        }
        cropViewController.dismiss(animated: true, completion: nil)
    }
    
}

extension KayaCollageViewController {
    func webView(_ webView: WKWebView,
                 didFinish navigation: WKNavigation!) {
        showAlert(message: "İşleminiz başarıyla gerçekleştirildi")
    }
}

extension  KayaCollageViewController: UploadImageServiceDelegte, WKNavigationDelegate {
    func progressHandler(value: Float) {
        if let popup = popUpController {
            DispatchQueue.global(qos: .background).async {  () -> Void in
                    DispatchQueue.main.async { () -> Void in
                        popup.setProgress(progressValue: value)
                    }
            }
        }
    }
    
    func getResponse(error: Bool) {
        if error {
            print(" getResponse FOTOĞRAF BAŞARILI BİR ŞEKİLDE KAYDEDİLDİ")
            let url = URL(string: "http://odi.odiapp.com.tr/?update=ok")!
            let request = URLRequest(url: url)
            self.webViewForSuccess = WKWebView(frame: CGRect.zero)
            self.webViewForSuccess?.isHidden = true
            self.view.addSubview(self.webViewForSuccess!)
            webViewForSuccess!.navigationDelegate = self
            webViewForSuccess!.load(request)
        } else {
            showAlert(message: "İşlem sırasında bir hata oluştu.")
        }
    }
    
    func getError(errorMessage: String) {
        
    }
    func showAlert(message: String) {
        self.HIDE_SIC(customView: self.view)
        let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "Tamam",style: UIAlertAction.Style.default) {
            UIAlertAction in
            self.navigationController?.popViewController(animated: true)
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "transitionBackToWebview"), object: nil, userInfo: nil)
        }
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func showToast(message: String) {
        self.HIDE_SIC(customView: self.view)
        let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "Tamam",style: UIAlertAction.Style.default) {
            UIAlertAction in
          
            
        }
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    
    
}



fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}


extension KayaCollageViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        currentVC.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let image = info[.originalImage] as? UIImage {
            print("image hazır \(image)")
            myPickerController?.dismiss(animated: true, completion: {
                let cropViewController = Mantis.cropViewController(image: image)
                cropViewController.delegate = self
                cropViewController.config.presetFixedRatioType = .alwaysUsingOnePresetFixedRatio(ratio: self.currentRate!)
                cropViewController.modalPresentationStyle = .fullScreen
                self.present(cropViewController, animated: true, completion: nil)
            })
        }else {
            print("problem var")
             myPickerController?.dismiss(animated: true, completion: nil)
        }
       
    }
}


fileprivate extension KayaCollageViewController {
    // fileprivate
    func initView() {
        let imgWidth = (UIScreen.main.bounds.width - (kCellSpacing * (CGFloat(kColumnCnt) - 1))) / CGFloat(kColumnCnt)
        targetSize = CGSize(width: imgWidth, height: imgWidth)
        
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = targetSize
        layout.minimumInteritemSpacing = kCellSpacing
        layout.minimumLineSpacing = kCellSpacing
        collectionView.collectionViewLayout = layout
        
        let nib = UINib(nibName: kCellReuseIdentifier, bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: kCellReuseIdentifier)
        
        //collectionView.register(UINib(nibName: kCellReuseIdentifier, bundle: nil), forCellWithReuseIdentifier: kCellReuseIdentifier)
        
        collectionView.dataSource = self
        collectionView.delegate = self
    }
    // fileprivate
    func loadPhotos() {
        let options = PHFetchOptions()
        options.sortDescriptors = [
            NSSortDescriptor(key: "creationDate", ascending: false)
        ]
        
        fetchResult = PHAsset.fetchAssets(with: .image, options: options)
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
}

extension KayaCollageViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        //print("\(TAG) cellForItemAt: -- id: \(indexPath.row)")
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kCellReuseIdentifier, for: indexPath) as! imageCollectionViewCell
        
        let photoAsset = fetchResult.object(at: indexPath.row) // değiştirmee item
        
        let manager = PHImageManager.default()
        
        if cell.tag != 0 {
            manager.cancelImageRequest(PHImageRequestID(cell.tag))
        }
        // targetSize
        imageManager.requestImage(for: photoAsset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFill, options: nil) { (image, info) -> Void in
            cell.cellImageView.image = image
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let result = fetchResult {
            return result.count
        }
        return 0
    }
}

extension KayaCollageViewController: UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        DispatchQueue.main.async {
            self.imageManager.startCachingImages(for: indexPaths.map{ self.fetchResult.object(at: $0.item) }, targetSize: self.targetSize, contentMode: .aspectFill, options: nil)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        DispatchQueue.main.async {
            self.imageManager.stopCachingImages(for: indexPaths.map{ self.fetchResult.object(at: $0.item) }, targetSize: self.targetSize, contentMode: .aspectFill, options: nil)
        }
    }
}

extension KayaCollageViewController: UICollectionViewDelegate {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        return targetSize
    }
    
    // burası
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kCellReuseIdentifier, for: indexPath) as! imageCollectionViewCell
        
        let photoAsset = fetchResult.object(at: indexPath.item)
        
        // targetSize
        imageManager.requestImage(for: photoAsset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFill, options: nil) { (image, info) -> Void in
            cell.cellImageView.image = image
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let _ = collectionView.cellForItem(at: indexPath) as? imageCollectionViewCell {
            let photoAsset = fetchResult.object(at: indexPath.item)
            imageManager.requestImage(for: photoAsset,
                                      targetSize: PHImageManagerMaximumSize,
                                      contentMode: .aspectFill, options: nil) { (image, info) -> Void in
                
                if (self.selectedImageView != nil) {
                    if let img = image {
                        let cropViewController = Mantis.cropViewController(image: img)
                        cropViewController.delegate = self
                        cropViewController.config.presetFixedRatioType = .alwaysUsingOnePresetFixedRatio(ratio: self.currentRate!)
                        cropViewController.modalPresentationStyle = .fullScreen
                        self.present(cropViewController, animated: true, completion: nil)
                    }
                }else {
                    self.showToast(message: "Çerçeveyi seç, yüklemek istediğin fotoğrafa dokun")
                }
                
            }
            
            //self.showToast(message: "Çerçeveyi seç, yüklemek istediğin fotoğrafa dokun")
        }
        
    }
}

