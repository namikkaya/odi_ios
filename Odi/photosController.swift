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
import Mantis
import AMPopTip

class PhotosViewController: BaseViewController, CropViewControllerDelegate {
    
    
    private let TAG:String = "PhotosViewController:"
    
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
    fileprivate let kColumnCnt: Int = 4
    fileprivate let kCellSpacing: CGFloat = 2
    fileprivate var fetchResult: PHFetchResult<PHAsset>!
    fileprivate var imageManager = PHCachingImageManager()
    fileprivate var targetSize = CGSize.zero
    
    fileprivate var currentVC: UIViewController!
    var currentRate:Double?
    
    // image assets
    var phAssetArray : [PHAsset] = []
    
    
    override func viewDidLoad() {
    
//        pushNotificationID()
        service.serviceDelegate = self
        addTapped()
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
            
            DispatchQueue.main.async {
                self.popUpController = self.SHOW_SIC(type: .image)
            }
            DispatchQueue.main.async {
                UserPrefences.setBigKolajPhoto(isValue: self.scrollView1.imageView?.image)
                UserPrefences.setsmallKolajOnePhoto(isValue: self.scrollView2.imageView?.image)
                UserPrefences.setsmallKolajTwoPhoto(isValue: self.scrollView3.imageView?.image)
                
                let image = self.scrennShotView.screenShot!
                           
                           var sendImage:UIImage?
                           if image.size.width >= image.size.height {
                               
                               print("sendImage: size: \(image.size)")
                               if image.size.width > 1000 {
                                   print("sendImage: width: ")
                                   
                                   let rate:Double = Double(image.size.width) / Double(image.size.height)
                                   
                                   let newWidth:Double = 1000
                                   let newHeight:Double = 1000 / rate
                                   print("sendImage: newSize: \(newWidth) - \(newHeight)")
                                let newImage = self.resizeImage(image: image, targetSize: CGSize(width: newWidth, height: newHeight))
                                   sendImage = newImage!
                               }else {
                                   // orjinal image yolla
                                   print("sendImage: width: orjinal gidecek")
                                   sendImage = image
                               }
                           }else {
                               if image.size.height > 1000 {
                                   print("sendImage: height: ")
                                   let rate:Double = Double(image.size.height) / Double(image.size.width)
                                   let newHeight:Double = 1000
                                   let newWidth:Double = 1000 / rate
                                   
                                   print("sendImage: newSize: \(newWidth) - \(newHeight)")
                                let newImage = self.resizeImage(image: image, targetSize: CGSize(width: newWidth, height: newHeight))
                                   sendImage = newImage!
                               }else {
                                   print("sendImage: height: orjinal gidecek")
                                   sendImage = image
                               }
                           }
                
                print("yüklenen kolaj: profil_\(self.id).jpg")
                self.service.connectService(fileName: "profil_\(self.id).jpg", image: sendImage!)
                self.view.isUserInteractionEnabled = false
                self.navigationController?.navigationBar.isUserInteractionEnabled = false
                
            }
        }
        
    }
    
    
    func resizeImage(image: UIImage?, targetSize: CGSize) -> UIImage? {
        guard let image = image else { return nil }
        let size = image.size

        let widthRatio  = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height

        var newSize: CGSize
        if(widthRatio >= heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }

        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage!
    }
    
    private var selectedItem:UIScrollView?
    var imageHolder1:UIImage?
    var imageHolder2:UIImage?
    var imageHolder3:UIImage?
    func cropViewControllerDidCrop(_ cropViewController: CropViewController, cropped: UIImage) {
        print("didcrop: ")
        let newCgIm = cropped.cgImage!.copy()
        let newImage = UIImage(cgImage: newCgIm!, scale: cropped.scale, orientation: cropped.imageOrientation)
        if let select = selectedItem {
            if self.scrollView1 == select {
                imageHolder1 = newImage
                self.scrollView1.configureWith(image: newImage)
                self.dragImageView.image = nil
                print("didcrop: if 1")
            }
            if self.scrollView2 == select {
                imageHolder2 = newImage
                self.scrollView2.configureWith(image: newImage)
                self.dragImageViewSmall1.image = nil
                print("didcrop: if 2")
            }
            if self.scrollView3 == select {
                imageHolder3 = newImage
                self.scrollView3.configureWith(image: newImage)
                self.dragImageViewSmall2.image = nil
                print("didcrop: if 3")
            }
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
        
        let doubleTapGesture4 = UITapGestureRecognizer(target: self, action: #selector(doubleTapped4))
        doubleTapGesture4.numberOfTapsRequired = 2
        self.scrollView1.addGestureRecognizer(doubleTapGesture4)

        gesture4.require(toFail: doubleTapGesture4)
        
        self.scrollView2.isUserInteractionEnabled = true
        let gesture5 = UITapGestureRecognizer(target: self, action: #selector(tapped5))
        self.scrollView2.addGestureRecognizer(gesture5)
        
        let doubleTapGesture5 = UITapGestureRecognizer(target: self, action: #selector(doubleTapped5))
        doubleTapGesture5.numberOfTapsRequired = 2
        self.scrollView2.addGestureRecognizer(doubleTapGesture5)

        gesture5.require(toFail: doubleTapGesture5)
        
        self.scrollView3.isUserInteractionEnabled = true
        let gesture6 = UITapGestureRecognizer(target: self, action: #selector(tapped6))
        self.scrollView3.addGestureRecognizer(gesture6)
        
        let doubleTapGesture6 = UITapGestureRecognizer(target: self, action: #selector(doubleTapped6))
        doubleTapGesture6.numberOfTapsRequired = 2
        self.scrollView3.addGestureRecognizer(doubleTapGesture6)

        gesture6.require(toFail: doubleTapGesture6)
    }
    
    internal var myPickerController:UIImagePickerController?
    func openPhotoLibrary() {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary){
            myPickerController = UIImagePickerController()
            myPickerController!.delegate = self;
            myPickerController!.mediaTypes = ["public.image"]
            myPickerController!.sourceType = .photoLibrary
            self.present(myPickerController!, animated: true, completion: nil)
        }
    }
    
    @objc func doubleTapped4 () {
        print("çift tık işledi----")
        
        let rate = Double(self.scrollView1.frame.size.width / self.scrollView1.frame.size.height)
        currentRate = rate
        selectedItem = self.scrollView1
        
        tapped4()
        
        openPhotoLibrary()
        
    }
    
    @objc func doubleTapped5 () {
        print("çift tık işledi----")
        
        let rate = Double(self.scrollView2.frame.size.width / self.scrollView2.frame.size.height)
        currentRate = rate
        selectedItem = self.scrollView2
        tapped5()
        openPhotoLibrary()
        
    }
    
    @objc func doubleTapped6 () {
        print("çift tık işledi----")
        
        let rate = Double(self.scrollView3.frame.size.width / self.scrollView3.frame.size.height)
        currentRate = rate
        selectedItem = self.scrollView3
        tapped6()
        
        openPhotoLibrary()
        
    }
    
    @objc func tapped1()  {
        print("tapped 1")
        self.scrollView1.imageView?.image = nil
        dragImageView.image = #imageLiteral(resourceName: "kolaj-maker-big")
    }
    @objc func tapped2()  {
        print("tapped 2")
        self.scrollView2.imageView?.image = nil
        dragImageViewSmall1.image = #imageLiteral(resourceName: "kolaj-maker-small")
    }
    @objc func tapped3()  {
        print("tapped 3")
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
    
    var first:Bool = true
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = false
        self.navigationController?.navigationBar.tintColor = UIColor.white
        
        if first {
            first = false
            DispatchQueue.global(qos: .background).async {
                if (UserPrefences.getBigKolojPhoto() != nil) && (UserPrefences.getsmallKolajOnePhoto() != nil) && (UserPrefences.getsmallKolajTwoPhoto() != nil) {
                    let bigImage =  UserPrefences.getBigKolojPhoto()
                    let smallOneImage = UserPrefences.getsmallKolajOnePhoto()
                    let smallTwoImage = UserPrefences.getsmallKolajTwoPhoto()
                    DispatchQueue.main.async {
                        self.scrollView1.configureWith(image: bigImage!)
                        self.dragImageView.image = nil
                        self.scrollView2.configureWith(image: smallOneImage!)
                        self.dragImageViewSmall1.image = nil
                        self.scrollView3.configureWith(image: smallTwoImage!)
                        self.dragImageViewSmall2.image = nil
                    }
                }
            }
            
        }
        
        

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
    
    //    MARK: - TOOLTIP
    var popTip:PopTip?
    var toolTipTimer:Timer?
    var toolTipArray:[toolTipModel] = []
    var toolTipCounter:Int = 0
    var toolTipStartStatus:Bool = false // bir kere başladıysa tekrar başlatmaması için gerekli
    private func toolTipStart() {
        toolTipStartStatus = true
        let tooltip1 = toolTipModel(toolTipText: "Çerçeveyi seç",
                                           toolTipObject: scrollView1,
                                           direction: .right)
        
        
        let tooltip2 = toolTipModel(toolTipText: "Yüklemek istediğin fotoğrafa dokun",
                                           toolTipObject: collectionView,
                                           direction: .up)
        
        let tooltip3 = toolTipModel(toolTipText: "Galeriye erişmek için çerçeveye 2 kez tıkla",
                                        toolTipObject: scrollView1,
                                        direction: .right)
        
        
        toolTipArray.append(tooltip1)
        toolTipArray.append(tooltip2)
        toolTipArray.append(tooltip3)
       
        openToolTip()
        toolTipTimer = Timer.scheduledTimer(timeInterval: 4,
                                            target: self,
                                            selector: #selector(toolTipTimerEvent),
                                            userInfo: nil,
                                            repeats: true)
    }
    
    private func openToolTip() {
        if (toolTipCounter == toolTipArray.count) {
            if (toolTipTimer != nil) {
                toolTipTimer?.invalidate()
                toolTipTimer = nil
            }
            if popTip != nil {
                popTip?.hide()
                popTip = nil
            }
            return
        }
        
        if popTip != nil {
            popTip?.hide()
            popTip = nil
        }
        
        let object = toolTipArray[toolTipCounter].toolTipObject as? UIView
        popTip = PopTip()
        
        popTip!.bubbleColor = UIColor.init("#FF8400", alpha: 1.0)
        //popTip!.shouldDismissOnTap = true
        popTip!.actionAnimation = .bounce(16)
        popTip!.font = UIFont.systemFont(ofSize: 18, weight: UIFont.Weight.regular)//UIFont(name: "Avenir-Medium", size: 12)!
        popTip!.show(text: toolTipArray[toolTipCounter].toolTipText!,
                     direction: toolTipArray[toolTipCounter].direction!,
                    maxWidth: 320,
                    in: self.view,
                    from: object!.frame,
                    duration: 4)
       
        popTip!.tapHandler = { popTip in
            if (self.toolTipTimer != nil) {
                self.toolTipTimer?.invalidate()
                self.toolTipTimer = nil
            }
            if self.popTip != nil {
                self.popTip?.hide()
                self.popTip = nil
            }
            self.toolTipTimer = Timer.scheduledTimer(timeInterval: 5,
            target: self,
            selector: #selector(self.toolTipTimerEvent),
            userInfo: nil,
            repeats: true)
            self.openToolTip()
        }
        
        toolTipCounter += 1
    }
    
    private func toolTipFinish() {
        if (self.toolTipTimer != nil) {
            self.toolTipTimer?.invalidate()
            self.toolTipTimer = nil
        }
        if self.popTip != nil {
            self.popTip?.hide()
            self.popTip = nil
        }
    }
    
    @objc func toolTipTimerEvent() {
        openToolTip()
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

extension PhotosViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
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
        
        let myOptions = PHImageRequestOptions()
        myOptions.deliveryMode = .opportunistic
        myOptions.isSynchronous = false
        
        for i in 0..<fetchResult.count {
            phAssetArray.append(fetchResult[i])
        }
        
        self.imageManager.startCachingImages(for: phAssetArray,
                                             targetSize: CGSize(width: 120, height: 120),
                                             contentMode: PHImageContentMode.aspectFill,
                                             options: myOptions)
        
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
        
        if !toolTipStartStatus && !UserPrefences.getPhotoCollageFirstLook()!{
            toolTipStart()
            UserPrefences.setPhotoCollageFirstLook(value: true)
        }
    }
}

extension PhotosViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        print("\(TAG) cellForItemAt: -- id: \(indexPath.row)")
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kCellReuseIdentifier, for: indexPath) as! imageCollectionViewCell
        // kod değiştir ve cache image lar al
        /*let photoAsset = fetchResult.object(at: indexPath.row) // değiştirmee item
        
        let manager = PHImageManager.default()
        
        if cell.tag != 0 {
            manager.cancelImageRequest(PHImageRequestID(cell.tag))
        }
        
        imageManager.requestImage(for: photoAsset, targetSize: targetSize, contentMode: .aspectFill, options: nil) { (image, info) -> Void in
            cell.cellImageView.image = image
        }*/
        
        phAssetArray[indexPath.row].getImageFromAsset(imageSize: CGSize(width: 120, height: 120)) { (myImage:UIImage) in
            cell.cellImageView.image = myImage
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


// bu nedir amk böyle cache mi olur
/*
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
}*/

extension PhotosViewController: UICollectionViewDelegate {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        return targetSize
    }
    
    
    // burası
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        print("\(TAG) -- willDisplaye")
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kCellReuseIdentifier, for: indexPath) as! imageCollectionViewCell
        
        /*let photoAsset = fetchResult.object(at: indexPath.item)
        imageManager.requestImage(for: photoAsset, targetSize: targetSize, contentMode: .aspectFill, options: nil) { (image, info) -> Void in
            cell.cellImageView.image = image
        }*/
        
        phAssetArray[indexPath.row].getImageFromAsset(imageSize: CGSize(width: 120, height: 120)) { (myImage:UIImage) in
            cell.cellImageView.image = myImage
        }
        
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let _ = collectionView.cellForItem(at: indexPath) as? imageCollectionViewCell {
            let photoAsset = fetchResult.object(at: indexPath.item)
            let options = PHImageRequestOptions()
            options.version = .original
            
            switch choicesImageView {
            case 1:
                imageManager.requestImage(for: photoAsset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFill, options: options) { (image, info) -> Void in
                    if let img = image {
                        print("orgImage: 1 \(img.size)")
                        self.scrollView1.configureWith(image: img)
                        self.dragImageView.image = nil
                    }
                }
                
            case 2:
                imageManager.requestImage(for: photoAsset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFill, options: options) { (image, info) -> Void in
                    if let img = image {
                        print("orgImage: 2 \(img.size)")
                        self.scrollView2.configureWith(image: img)
                        self.dragImageViewSmall1.image = nil
                    }
                }
            case 3:
                imageManager.requestImage(for: photoAsset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFill, options: options) { (image, info) -> Void in
                    if let img = image {
                        print("orgImage: 3 \(img.size)")
                        self.scrollView3.configureWith(image: img)
                        self.dragImageViewSmall2.image = nil
                    }
                }
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
        path.fill()
        path.apply(CGAffineTransform(translationX: 0, y: 0))
        
        layer.path = path.cgPath
        layer.fillColor = nil
        layer.strokeColor = color.cgColor
        layer.lineDashPattern = [6, 6]
        layer.lineWidth = 2.0
        layer.lineJoin = CAShapeLayerLineJoin.round
        layer.name = "custom_drawing"
        if myView.layer.sublayers != nil {
            for layerr in myView.layer.sublayers! {
                if layerr.name == "custom_drawing" {
                    layerr.removeFromSuperlayer()
                }
            }
        }
        myView.layer.addSublayer(layer)
        //self.choiseAnimate(customLayer: layer)
    }
    
    func choiseAnimate(customLayer : CAShapeLayer) {
        let anim1 = CABasicAnimation(keyPath: "strokeEnd")
        anim1.fromValue         = 0.0
        anim1.toValue           = 1.0
        anim1.duration          = 0.0
        anim1.repeatCount       = 1.0
        anim1.autoreverses      = false
        anim1.isRemovedOnCompletion = false
        anim1.isAdditive = true
        anim1.fillMode = CAMediaTimingFillMode.forwards
        customLayer.add(anim1, forKey: "strokeEnd")
    }
}


// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}


extension UIImageView{
 func fetchImage(asset: PHAsset, contentMode: PHImageContentMode, targetSize: CGSize) {
    let options = PHImageRequestOptions()
    options.version = .original
    PHImageManager.default().requestImage(for: asset, targetSize: targetSize, contentMode: contentMode, options: options) { image, _ in
        guard let image = image else { return }
        switch contentMode {
        case .aspectFill:
            self.contentMode = .scaleAspectFill
            break
        case .aspectFit:
            self.contentMode = .scaleAspectFit
            break
        @unknown default:
            
            break
        }
        self.image = image
    }
   }
}


extension PHAsset {
    func getImageFromAsset(imageSize:CGSize, callback:@escaping (_ result:UIImage) -> ()) {
        let asset:PHAsset = self
        let requestOptions = PHImageRequestOptions()
        requestOptions.resizeMode = PHImageRequestOptionsResizeMode.fast
        requestOptions.deliveryMode = PHImageRequestOptionsDeliveryMode.highQualityFormat
        requestOptions.isNetworkAccessAllowed = true
        requestOptions.isSynchronous = true
        PHImageManager.default().requestImage(for: asset, targetSize: imageSize, contentMode: PHImageContentMode.default, options: requestOptions, resultHandler: { (currentImage, info) in
            callback(currentImage!)
        })
    }
}
