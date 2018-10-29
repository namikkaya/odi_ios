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
class PhotosViewController: BaseViewController {
    
    var popUpController : SIC?
    
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
    fileprivate var photoLibrary = PhotoLibrary()
    let onesignalID = UserPrefence.getOneSignalId()
    @IBOutlet weak var dragImageView: UIImageView!
    @IBOutlet weak var dragImageViewSmall1 : UIImageView!
    @IBOutlet weak var dragImageViewSmall2 : UIImageView!
    var choicesImageView = 0 // 1 = Scroolview1, 2= Scroolview2, 3= Scroolview3
    var service : UploadImageService = UploadImageService()
    var id = ""
    var isLoadNotificationID = false
    var setupUI = false
    
    //İmage collectionview veriable
    fileprivate let kCellReuseIdentifier = "imageCollectionViewCell"
    fileprivate let kColumnCnt: Int = 3
    fileprivate let kCellSpacing: CGFloat = 2
    fileprivate var fetchResult: PHFetchResult<PHAsset>!
    fileprivate var imageManager = PHCachingImageManager()
    fileprivate var targetSize = CGSize.zero
    
    
    override func viewDidLoad() {
    
//        pushNotificationID()
        service.serviceDelegate = self
        addTapped()
        initView()
        loadPhotos()
        
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()
        
        if (!setupUI) {
            self.centerStartBezierPath(cornerRadius: 0, myView: dragImageViewSmall1, color: .black)
            self.centerStartBezierPath(cornerRadius: 0, myView: dragImageViewSmall2, color: .black)
            self.centerStartBezierPath(cornerRadius: 0, myView: dragImageView, color: .black)
        }
        
    }
    
    @IBAction func saveButtonClicked(_ sender: UIBarButtonItem) {

        if dragImageView.image != nil || dragImageViewSmall1.image != nil || dragImageViewSmall2.image != nil {
            self.showToast(message: "Tüm çerçeveleri doldurmalısın.")
        } else {
            self.closeImage1.image = nil
            self.closeImage2.image = nil
            self.closeImage3.image = nil
            self.dragImageView.isHidden = true
            self.dragImageViewSmall1.isHidden = true
            self.dragImageViewSmall2.isHidden = true
            service.connectService(fileName: "profil_\(id).jpg", image: scrennShotView.screenShot!)
            self.view.isUserInteractionEnabled = false
            self.navigationController?.navigationBar.isUserInteractionEnabled = false
            self.popUpController = self.SHOW_SIC(type: .image)
        }
        
        
        
        
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
        
        
        self.scrollView1.isUserInteractionEnabled = true
        let gesture4 = UITapGestureRecognizer(target: self, action: #selector(tapped4))
        self.scrollView1.addGestureRecognizer(gesture4)
        
        self.scrollView2.isUserInteractionEnabled = true
        let gesture5 = UITapGestureRecognizer(target: self, action: #selector(tapped5))
        self.scrollView2.addGestureRecognizer(gesture5)
        
        self.scrollView3.isUserInteractionEnabled = true
        let gesture6 = UITapGestureRecognizer(target: self, action: #selector(tapped6))
        self.scrollView3.addGestureRecognizer(gesture6)
        
    }
    @objc func tapped1()  {
        self.scrollView1.imageView?.image = nil
        dragImageView.image = #imageLiteral(resourceName: "kolaj-maker-big")
    }
    @objc func tapped2()  {
        self.scrollView2.imageView?.image = nil
        dragImageViewSmall1.image = #imageLiteral(resourceName: "kolaj-maker-small")
    }
    @objc func tapped3()  {
        self.scrollView3.imageView?.image = nil
        dragImageViewSmall2.image = #imageLiteral(resourceName: "kolaj-maker-small")
    }
    
    @objc func tapped4()  {
        choicesImageView = 1
        self.centerStartBezierPath(cornerRadius: 0, myView: dragImageViewSmall1, color: .black)
        self.centerStartBezierPath(cornerRadius: 0, myView: dragImageViewSmall2, color: .black)
        self.centerStartBezierPath(cornerRadius: 0, myView: dragImageView, color: .orange)
        self.setupUI = true
    }
    @objc func tapped5()  {
        choicesImageView = 2
        self.centerStartBezierPath(cornerRadius: 0, myView: dragImageViewSmall1, color: .orange)
        self.centerStartBezierPath(cornerRadius: 0, myView: dragImageViewSmall2, color: .black)
        self.centerStartBezierPath(cornerRadius: 0, myView: dragImageView, color: .black)
        self.setupUI = true
    }
    @objc func tapped6()  {
        choicesImageView = 3
        self.centerStartBezierPath(cornerRadius: 0, myView: dragImageViewSmall1, color: .black)
        self.centerStartBezierPath(cornerRadius: 0, myView: dragImageViewSmall2, color: .orange)
        self.centerStartBezierPath(cornerRadius: 0, myView: dragImageView, color: .black)
        self.setupUI = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = false
        self.navigationController?.navigationBar.tintColor = UIColor.white
    }
    
    
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    func pushNotificationID(){
        isLoadNotificationID = true
        let url = URL(string: "http://odi.odiapp.com.tr/core/usernotid.php?userID=\(id)&phoneID=\(onesignalID)")!
        
        let request = URLRequest(url: url)
        self.webViewForSuccess = WKWebView(frame: CGRect.zero)
        self.webViewForSuccess?.isHidden = true
        self.view.addSubview(self.webViewForSuccess!)
        webViewForSuccess!.navigationDelegate = self
        webViewForSuccess!.load(request)
    }
    
}
extension  PhotosViewController: UploadImageServiceDelegte {
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
        
        // Create the actions
        let okAction = UIAlertAction(title: "Tamam",style: UIAlertActionStyle.default) {
            UIAlertAction in
            self.navigationController?.popViewController(animated: true)
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "transitionBackToWebview"), object: nil, userInfo: nil)
        }
        // Add the actions
        alertController.addAction(okAction)
        // Present the controller
        self.present(alertController, animated: true, completion: nil)
    }
    
    func showToast(message: String) {
        self.HIDE_SIC(customView: self.view)
        let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
        
        // Create the actions
        let okAction = UIAlertAction(title: "Tamam",style: UIAlertActionStyle.default) {
            UIAlertAction in
          
            
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
        if isLoadNotificationID {
            isLoadNotificationID = false
        }
        else{
            showAlert(message: "İşleminiz başarıyla gerçekleştirildi")
        }
    }
}

fileprivate extension PhotosViewController {
    fileprivate func initView() {
        let imgWidth = (UIScreen.main.bounds.width - (kCellSpacing * (CGFloat(kColumnCnt) - 1))) / CGFloat(kColumnCnt)
        targetSize = CGSize(width: imgWidth, height: imgWidth)
        
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = targetSize
        layout.minimumInteritemSpacing = kCellSpacing
        layout.minimumLineSpacing = kCellSpacing
        collectionView.collectionViewLayout = layout
        collectionView.register(UINib(nibName: kCellReuseIdentifier, bundle: nil), forCellWithReuseIdentifier: kCellReuseIdentifier)
        collectionView.dataSource = self
        collectionView.delegate = self
    }
    
    fileprivate func loadPhotos() {
        let options = PHFetchOptions()
        options.sortDescriptors = [
            NSSortDescriptor(key: "creationDate", ascending: false)
        ]
        fetchResult = PHAsset.fetchAssets(with: .image, options: options)
    }
}

extension PhotosViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kCellReuseIdentifier, for: indexPath) as! imageCollectionViewCell
        let photoAsset = fetchResult.object(at: indexPath.item)
        imageManager.requestImage(for: photoAsset, targetSize: targetSize, contentMode: .aspectFill, options: nil) { (image, info) -> Void in
            cell.cellImageView.image = image
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchResult.count
    }
}

extension PhotosViewController: UICollectionViewDataSourcePrefetching {
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

extension PhotosViewController: UICollectionViewDelegate {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        return targetSize
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? imageCollectionViewCell {
            
            switch choicesImageView {
            case 1:
                self.scrollView1.configureWith(image: cell.cellImageView.image!)
                self.dragImageView.image = nil
            case 2:
                self.scrollView2.configureWith(image: cell.cellImageView.image!)
                self.dragImageViewSmall1.image = nil
            case 3:
                self.scrollView3.configureWith(image: cell.cellImageView.image!)
                self.dragImageViewSmall2.image = nil
            default: self.showToast(message: "Çerçeveyi seç, yüklemek istediğin fotoğrafa dokun")
            }
        }
        
    }
}
extension PhotosViewController {
    func centerStartBezierPath(cornerRadius:CGFloat,myView: UIView,color: UIColor){
        
        let path = UIBezierPath()
        let frame = myView.frame
        let layer = CAShapeLayer()
        
        path.move(to: CGPoint(x: frame.width / 2.0, y: 0))
        path.addLine(to: CGPoint(x: frame.width - cornerRadius, y: 0))
        path.addArc(withCenter: CGPoint(x: frame.width - cornerRadius , y: cornerRadius),
                    radius: cornerRadius,
                    startAngle: CGFloat(-CGFloat.pi / 2),
                    endAngle: 0,
                    clockwise: true)
        path.addLine(to: CGPoint(x: frame.width, y: frame.height - cornerRadius))
        path.addArc(withCenter: CGPoint(x: frame.width - cornerRadius, y: frame.height - cornerRadius) , radius: cornerRadius, startAngle: 0, endAngle: CGFloat(CGFloat.pi / 2), clockwise: true)
        
        path.addLine(to: CGPoint(x: cornerRadius, y: frame.height))
        path.addArc(withCenter: CGPoint(x:cornerRadius, y: frame.height - cornerRadius) , radius: cornerRadius, startAngle: CGFloat(CGFloat.pi / 2), endAngle: CGFloat.pi, clockwise: true)
        path.addLine(to: CGPoint(x: 0, y: cornerRadius))
        path.addArc(withCenter: CGPoint(x:cornerRadius, y: cornerRadius) , radius: cornerRadius, startAngle: CGFloat.pi, endAngle: CGFloat(CGFloat.pi * 3/2), clockwise: true)
        
        path.close()
        path.apply(CGAffineTransform(translationX: 0, y: 0))
        
        layer.path = path.cgPath
        layer.fillColor = nil
        layer.strokeColor = color.cgColor
        layer.strokeStart = 0.0
        layer.strokeEnd = 0.0
        layer.lineDashPattern = [6, 6]
        layer.lineWidth = 2.0
        layer.lineJoin = kCALineJoinRound
        layer.name = "custom_drawing"
        if myView.layer.sublayers != nil {
            for layerr in myView.layer.sublayers! {
                if layerr.name == "custom_drawing" {
                    layerr.removeFromSuperlayer()
                }
            }
        }
        myView.layer.addSublayer(layer)
        self.choiseAnimate(customLayer: layer)
    }
    
    func choiseAnimate(customLayer : CAShapeLayer) {
        let anim1 = CABasicAnimation(keyPath: "strokeEnd")
        anim1.fromValue         = 0.0
        anim1.toValue           = 1.0
        anim1.duration          = 0.1
        anim1.repeatCount       = 1.0
        anim1.autoreverses      = false
        anim1.isRemovedOnCompletion = false
        anim1.isAdditive = true
        anim1.fillMode = kCAFillModeForwards
        customLayer.add(anim1, forKey: "strokeEnd")
    }
}
