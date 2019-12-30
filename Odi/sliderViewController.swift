//
//  sliderViewController.swift
//  slidePaging
//
//  Created by Nok Danışmanlık on 25.05.2019.
//  Copyright © 2019 Brokoly. All rights reserved.
//

import UIKit

class sliderViewController: UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource,UICollectionViewDelegate {
    
    
    @IBOutlet var okeyButton: UIButton!
    @IBOutlet var nextButton: UIButton!
    @IBOutlet var collectionView: UICollectionView!
    //@IBOutlet var collectionView: UICollectionView!
    //@IBOutlet var pageController: UIPageControl!
    @IBOutlet var pageController: UIPageControl!
    
    
    var myData:[sliderModel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        okeyButton.layer.cornerRadius = 8
        okeyButton.layer.masksToBounds = true
        okeyButton.isHidden = true
        
        nextButton.layer.cornerRadius = 8
        nextButton.layer.masksToBounds = true
        nextButton.isHidden = false
        
        
        self.title = "Odi' ye Hoşgeldin"
        
        
        let page1 = sliderModel(text: "Odi’de sana en uygun projeler listelenir", imageURL: "http://odi.odiapp.com.tr/bannerimg/1.png")
        let page2 = sliderModel(text: "Akıllı video modülü ile kolayca dileyebilir…", imageURL: "http://odi.odiapp.com.tr/bannerimg/2.png")
        let page3 = sliderModel(text: "Odi’de sana en uygun projeler listelenir", imageURL: "http://odi.odiapp.com.tr/bannerimg/3.png")
        
        myData.append(page1)
        myData.append(page2)
        myData.append(page3)
        
        collectionViewConfig()
    }
    
    
    @IBAction func okeyButtonEvent(_ sender: Any) {
       directionVC()
    }
    
    func directionVC(animationStatus:Bool = true) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "RootControllerID") as! UINavigationController
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: animationStatus, completion: nil)
    }
    
    @IBAction func nextButtonEvent(_ sender: Any) {
        let row = pageController.currentPage + 1
        pageController.currentPage = row
        pageController.currentPage = row
        let indexPath = IndexPath(item: row, section: 0)
        collectionView.scrollToItem(at: indexPath, at: UICollectionView.ScrollPosition.centeredHorizontally, animated: true)
        
        if (row == 2) {
            okeyAnimation()
        }
        
    }
    
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        print("view did sub layer")
        
        collectionView.layoutIfNeeded()
        collectionView.layoutSubviews()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    private func collectionViewConfig() {
        collectionView.delegate = self
        collectionView.dataSource = self
        layoutCells()
        let nib = UINib(nibName: "sliderCell", bundle: nil)
        self.collectionView.register(nib, forCellWithReuseIdentifier: "sliderCell")
    }
    
    private func layoutCells() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.scrollDirection = .horizontal
        
        layout.itemSize = CGSize(width: (collectionView.frame.size.width), height: collectionView.frame.size.height)
        collectionView!.collectionViewLayout = layout
        if #available(iOS 11.0, *){
            layout.sectionInsetReference = .fromSafeArea
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return myData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "sliderCell", for: indexPath) as! sliderCell
        let row = indexPath.row
        cell.row = row
        cell.data = myData[row]
        //cell.setDelegate = self
        
        
        /*
        if (row == 2) {
            cell.typeButton = .okeyButton
        }else {
            cell.typeButton = .nextButton
        }
         */
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: (collectionView.frame.size.width), height: collectionView.frame.size.height)
    }
    
    /*
    func sliderEventListener(type: cellOkeyButtonType, row: Int) {
        print("Click : \(type) row: \(row)")
        pageController.currentPage = row+1
        if(type == .nextButton && row < 2){
            let indexPath = IndexPath(item: row+1, section: 0)
            collectionView.scrollToItem(at: indexPath, at: UICollectionView.ScrollPosition.centeredHorizontally, animated: true)
        }else {
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "WebVC") as! WebViewController
            //self.present(vc, animated: true, completion: nil)
            self.navigationController?.pushViewController(vc, animated: true)
        }
        
    }*/
    
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let x = targetContentOffset.pointee.x
        
        pageController.currentPage = Int(x / self.view.frame.width)
        
        if (Int(x / self.view.frame.width) == 2 && okeyButton.isHidden) {
            okeyButton.isHidden = false
            okeyButton.alpha = 0
            print("animasyon oynat")
            
            okeyAnimation()
            
        }
        
        
    }
    
    func okeyAnimation () {
        UIView.animate(withDuration: 0.1, animations: {
            self.okeyButton.transform = CGAffineTransform(scaleX: 0.2, y: 0.2)
            self.okeyButton.alpha = 0
            self.okeyButton.layoutIfNeeded()
        }) { (act) in
            UIView.animate(withDuration: 0.2, animations: {
                self.nextButton.transform = CGAffineTransform(scaleX: 0.2, y: 0.2)
                self.nextButton.alpha = 0
                self.nextButton.layoutIfNeeded()
            }, completion: { (act1) in
                self.nextButton.isHidden = true
                self.okeyButton.isHidden = false
                self.okeyButton.alpha = 0
                UIView.animate(withDuration: 0.2, animations: {
                    self.okeyButton.transform = CGAffineTransform(scaleX: 1, y: 1)
                    self.okeyButton.alpha = 1
                    self.okeyButton.layoutIfNeeded()
                }, completion: { (act2) in
                    
                })
            })
        }
    }
    
    @IBAction func pageControllerChangeCurrent(_ sender: Any) {
        let page: Int? = (sender as! UIPageControl).currentPage
        var frame: CGRect = self.collectionView.frame
        frame.origin.x = frame.size.width * CGFloat(page ?? 0)
        frame.origin.y = 0
        self.collectionView.scrollRectToVisible(frame, animated: true)
    }
    

}
