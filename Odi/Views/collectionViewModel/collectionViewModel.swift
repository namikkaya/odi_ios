//
//  collectionViewModel.swift
//  Odi
//
//  Created by Nok Danışmanlık on 24.10.2019.
//  Copyright © 2019 bilal. All rights reserved.
//

import UIKit


protocol collectionViewModelDelegate:class {
    //func collectionViewModelCurrentPageChange(page:Int)
    func collectionViewModel_selected(row:Int)
    func collectionViewModel_emptyData()
}

class collectionViewModel: NSObject,
UICollectionViewDelegateFlowLayout,
UICollectionViewDataSource,
UICollectionViewDelegate,
UIGestureRecognizerDelegate{
    
    
    private let TAG:String = "collectionViewModel:"
    weak var context:AnyObject?
    weak var delegate:collectionViewModelDelegate?
    private var sliderData:[videoModel]?
    private var collectionView:UICollectionView?
    
    var cellWidth:CGFloat = 0
    var cellHeight:CGFloat = 0
    
    var dbManager:kayaDbManager?
    
    override init() {
        super.init()
        print("init -+-+-+-+-+-+-+-+-+-+-")
        dbManager = kayaDbManager.sharedInstance
    }
    
    convenience init(collectionView:UICollectionView,
                     context:UIViewController,
                     collectionViewData:[videoModel]) {
        self.init()
        //self.context = context
        
        if let myContextvidSlider = context as? galleryViewController {
            self.context = myContextvidSlider
            self.delegate = myContextvidSlider
        }
        
        
        self.sliderData = collectionViewData
        self.collectionView = collectionView
        print("\(self.TAG): convenience init")
        config()
    }
    
    private func config() {
        collectionView!.delegate = self
        collectionView!.dataSource = self
        layoutCells()
        let nib = UINib(nibName: "galleryCell", bundle: nil)
        self.collectionView!.register(nib, forCellWithReuseIdentifier: "galleryCell")
        
        let lpgr = UILongPressGestureRecognizer(target: self, action: #selector(collectionViewModel.handleLongPress))
        lpgr.minimumPressDuration = 0.7
        lpgr.delegate = self
        lpgr.delaysTouchesBegan = true
        self.collectionView?.addGestureRecognizer(lpgr)
    }
    
    private func layoutCells() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 1
        layout.minimumLineSpacing = 4
        layout.scrollDirection = .vertical
        
        layout.itemSize = calSize()!//CGSize(width: (self.collectionView!.frame.size.width), height: self.collectionView!.frame.size.height)
        self.collectionView!.collectionViewLayout = layout
        if #available(iOS 11.0, *){
            layout.sectionInsetReference = .fromSafeArea
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let data = self.sliderData else { return 0 }
        return data.count
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "galleryCell", for: indexPath) as? galleryCell{
            let row = indexPath.row
            cell.data = sliderData![row]
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "galleryCell", for: indexPath) as! galleryCell
        let row = indexPath.row
        cell.data = sliderData![row]
        
        return cell
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return calSize()!
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let x = targetContentOffset.pointee.x
        let pageNo:Int = Int(x / self.collectionView!.frame.width)
        print("\(self.TAG): pageNo: \(pageNo)")
        //self.delegate?.collectionViewModelCurrentPageChange(page: pageNo)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let row = indexPath.row
        
        if let _ = collectionView.dequeueReusableCell(withReuseIdentifier: "galleryCell", for: indexPath) as? galleryCell{
            delegate?.collectionViewModel_selected(row: row)
        }
    }
    
    
    internal func calSize()->CGSize?{
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            cellWidth = (collectionView!.frame.width)/3 - 6
            cellHeight = cellWidth * 0.7
            return CGSize(width: cellWidth, height: cellHeight)
        case .pad:
            cellWidth = (collectionView!.frame.width)/5 - 10
            cellHeight = cellWidth*0.7
            return CGSize(width: cellWidth, height: cellHeight)
        default:
            // telefon ayarlı
            cellWidth = (collectionView!.frame.width)/3 - 6
            cellHeight = cellWidth*0.7
            return CGSize(width: cellWidth, height: cellHeight)
        }
        
    }
    
    var timerGesture:Timer?
    
    @objc func handleLongPress(gesture : UILongPressGestureRecognizer!) {
        if gesture.state == .ended {
            if (timerGesture != nil) {
                timerGesture?.invalidate()
                timerGesture = nil
            }
            
            let p = gesture.location(in: self.collectionView)
            
            if let indexPath = self.collectionView!.indexPathForItem(at: p) {
                //let cell = self.collectionView.cellForItem(at: indexPath)
                if (self.collectionView!.cellForItem(at: indexPath) as? galleryCell) != nil {
                    let cell = self.collectionView!.cellForItem(at: indexPath) as! galleryCell
                    cell.alpha = 1
                }
            } else {
                print("couldn't find index path")
            }
        }
        
        if (gesture.state == .began) {
            let p = gesture.location(in: self.collectionView)
            
            if let indexPath = self.collectionView!.indexPathForItem(at: p) {
                if (self.collectionView!.cellForItem(at: indexPath) as? galleryCell) != nil {
                    let cell = self.collectionView!.cellForItem(at: indexPath) as! galleryCell
                    
                    if (timerGesture == nil) {
                        let myUserInfo:[String:IndexPath] = ["row":indexPath]
                        cell.alpha = 0.5
                        timerGesture = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector( collectionViewModel.longTimerEvent), userInfo: myUserInfo, repeats: false)
                    }
                }
            } else {
                print("couldn't find index path")
            }
            
        }
    }
    
    @objc func longTimerEvent(timer:Timer) {
        if (timer.userInfo != nil) {
            if let dict = timer.userInfo as? [String:IndexPath] {
                //Vibration.heavy.vibrate()
                guard let indexPath = dict["row"] else { return }

                if (self.collectionView!.cellForItem(at: indexPath) as? galleryCell) != nil {
                    let cell = self.collectionView!.cellForItem(at: indexPath) as! galleryCell
                    cell.alpha = 1
                    
                    let row = indexPath.row
                    alertView(data: sliderData![row])
                    /*let name:String = projectData![indexPath.row].title!
                    infoItemAlert(title: name, indexPath: indexPath)*/
                    print("alert")
                }
               
            }
        }
        if (timerGesture != nil) {
            timerGesture?.invalidate()
            timerGesture = nil
        }
    }
    
    private func alertView(data:videoModel) {
        let alert = UIAlertController(title: "Videoyu Sil", message: "Bu videoyu silmek istediğinize emin misiniz?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Sil", style: .default, handler: { (action) in
            print("\(self.TAG): işlem yapılacak")
            self.dbManager?.deleteVideo(videoData: data, onSuccess: { (status) in
                if let status = status {
                    if status {
                        print("\(self.TAG): alertView : silme işlemi gerçekleştirildi")
                        
                        self.deleteDataList(data: data)
                        if (self.sliderData!.count < 1) {
                            self.delegate?.collectionViewModel_emptyData()
                        }
                        self.collectionView!.reloadData()
                        
                    }else {
                        print("\(self.TAG): alertView : silme işleminde false döndü")
                    }
                }
            }, onFailure: { (error:Error?) in
                print("\(self.TAG): alertView : silme işlemi yapılırken hata alındı")
            })
            
        }))
        alert.addAction(UIAlertAction(title: " İptal", style: .cancel, handler: nil))
        
         
        if let myContextvidSlider = context as? galleryViewController {
             myContextvidSlider.present(alert, animated: true)
        }
    }
    
    private func deleteDataList(data:videoModel) {
        for i in 0..<sliderData!.count {
            if data.id == self.sliderData![i].id{
                self.sliderData?.remove(at: i)
                return
            }
        }
    }
    
    
    
}
