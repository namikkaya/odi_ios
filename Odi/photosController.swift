//
//  photosController.swift
//  Kolaj App
//
//  Created by bilal on 14/12/2017.
//  Copyright © 2017 bilal. All rights reserved.
//

import UIKit
import Photos

class PhotosViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionViewFlowLayout: UICollectionViewFlowLayout!
    
    @IBOutlet weak var scrollView1: DragableScrollView!
    @IBOutlet weak var scrollView2: DragableScrollView!
    @IBOutlet weak var scrollView3: DragableScrollView!
    fileprivate var photoLibrary: PhotoLibrary!
    fileprivate var numberOfSections = 0
    
    override func viewDidLoad() {
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
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = false
        self.navigationController?.navigationBar.tintColor = UIColor.white
        
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
