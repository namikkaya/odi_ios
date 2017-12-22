//
//  photosController.swift
//  Kolaj App
//
//  Created by bilal on 14/12/2017.
//  Copyright © 2017 bilal. All rights reserved.
//

import UIKit
import Photos
import WebKit
class PhotosViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionViewFlowLayout: UICollectionViewFlowLayout!
    
    var webViewForSuccess: WKWebView?
    @IBOutlet weak var scrennShotView: UIView!
    @IBOutlet weak var scrollView1: DragableScrollView!
    @IBOutlet weak var scrollView2: DragableScrollView!
    @IBOutlet weak var scrollView3: DragableScrollView!
    @IBOutlet weak var closeImage3: UIImageView!
    @IBOutlet weak var closeImage2: UIImageView!
    @IBOutlet weak var closeImage1: UIImageView!
    fileprivate var photoLibrary: PhotoLibrary!
    fileprivate var numberOfSections = 0
    
    @IBOutlet weak var dragImageView: UIImageView!
    var service : UploadImageService = UploadImageService()
    var id = ""
    override func viewDidLoad() {
    
       
        service.serviceDelegate = self
        addTapped()
        initCollectionView()
        PHPhotoLibrary.requestAuthorization { [weak self] result in
            if let _self = self {
                if result == .authorized {
                    _self.photoLibrary = PhotoLibrary()
                    _self.numberOfSections = 1
                    DispatchQueue.main.async {
                        _self.collectionView.reloadData()
                    }
                }
            }
        }
    }
    @IBAction func saveButtonClicked(_ sender: UIBarButtonItem) {
        self.closeImage1.image = nil
        self.closeImage2.image = nil
        self.closeImage3.image = nil
        self.dragImageView.image = nil
        service.connectService(fileName: "profil_\(id).jpg", image: scrennShotView.screenShot!)
        self.view.isUserInteractionEnabled = false
        self.SHOW_SIC()
    }
    func addTapped() {
        self.closeImage1.isUserInteractionEnabled = true
        let gesture = UITapGestureRecognizer(target: self, action: #selector(tapped1))
        self.closeImage1.addGestureRecognizer(gesture)
        self.closeImage2.isUserInteractionEnabled = true
        let gesture2 = UITapGestureRecognizer(target: self, action: #selector(tapped2))
        self.closeImage2.addGestureRecognizer(gesture2)
        self.closeImage3.isUserInteractionEnabled = true
        let gesture3 = UITapGestureRecognizer(target: self, action: #selector(tapped3))
        self.closeImage3.addGestureRecognizer(gesture3)
        
    }
    func tapped1()  {
        self.scrollView1.imageView?.image = nil
    }
    func tapped2()  {
        self.scrollView2.imageView?.image = nil
    }
    func tapped3()  {
        self.scrollView3.imageView?.image = nil
    }
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = false
        self.navigationController?.navigationBar.tintColor = UIColor.white
        
    }
}
extension  PhotosViewController: UploadImageServiceDelegte {
    func getResponse(error: Bool) {
        if error {
            let url = URL(string: "http://odi.beranet.com/?update=ok")!
            let request = URLRequest(url: url)
            self.webViewForSuccess = WKWebView(frame: CGRect.zero)
            self.webViewForSuccess?.isHidden = true
            self.view.addSubview(self.webViewForSuccess!)
            webViewForSuccess!.navigationDelegate = self
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
        
        // Create the actions
        let okAction = UIAlertAction(title: "Tamam",style: UIAlertActionStyle.default) {
            UIAlertAction in
            self.navigationController?.popViewController(animated: true)
            
        }
        // Add the actions
        alertController.addAction(okAction)
        // Present the controller
        self.present(alertController, animated: true, completion: nil)
    }
    
}
extension PhotosViewController : WKNavigationDelegate {
    func webView(_ webView: WKWebView,
                 didFinish navigation: WKNavigation!) {
        showAlert(message: "İşleminiz başarı ile gerçekleştrildi")
    }
}
extension PhotosViewController : DraggableCellDelegate {
    func draggingComplete(image: UIImage, location: CGPoint) {
        if scrollView1.frame.contains(location) {
            scrollView1.configureWith(image: image)
        } else if scrollView2.frame.contains(location) {
            scrollView2.configureWith(image: image)
        } else if scrollView3.frame.contains(location) {
            scrollView3.configureWith(image: image)
        }
        
    }
}
extension PhotosViewController: UICollectionViewDataSource {
    
    fileprivate var numberOfElementsInRow: Int {
        return 1
    }
    
    var sizeForCell: CGSize {
        let _numberOfElementsInRow = CGFloat(numberOfElementsInRow)
        let allWidthBetwenCells = _numberOfElementsInRow == 0 ? 0 : collectionViewFlowLayout.minimumInteritemSpacing*(_numberOfElementsInRow-1)
        let width = (collectionView.frame.height - allWidthBetwenCells)/_numberOfElementsInRow
        return CGSize(width: width, height: width)
    }
    
    func initCollectionView() {
        collectionView.dataSource = self
        collectionView.delegate = self
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return numberOfSections
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photoLibrary.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionViewCell", for: indexPath) as! CollectionViewCell
        cell.draggableDelegate = self
        return cell
    }
    
}

extension PhotosViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return sizeForCell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let cell = cell as! CollectionViewCell
        cell.cellImageView.image = nil
        DispatchQueue.global(qos: .background).async {
            self.photoLibrary.setPhoto(at: indexPath.row) { image in
                if let image = image {
                    DispatchQueue.main.async {
                        cell.cellImageView.image = image
                    }
                }
            }
        }
    }
}
