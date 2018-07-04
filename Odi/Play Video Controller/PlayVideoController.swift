//
//  PlayVideoController.swift
//  Odi
//
//  Created by Baran on 22.12.2017.
//  Copyright © 2017 bilal. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer
import WebKit
import Photos
class PlayVideoController: UIViewController {
    
    var isImageUpload = false
    var currentTime = ""
    var thumbNailImage = UIImage()
    var videoId = ""
    var userId = ""
    var filePath = ""
    var videoURL : URL?
    var videoData : Data?
    var webViewForSuccess: WKWebView?
    var ftp = FTPUpload(baseUrl: "ftp.odiapp.com.tr:21", userName: "odiFtp@odiapp.com.tr", password: "Root123*" , directoryPath: "/img/")
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    override func viewDidAppear(_ animated: Bool) {
        if let uploadData = self.data as? [String: AnyObject] {
            if let userId = uploadData["userId"] as? String {
                self.userId = userId
            }
            if let filePath = uploadData["filePath"] as? String {
                self.filePath = filePath
            }
            if let videoId = uploadData["videoId"] as? String {
                self.videoId = videoId
            }
            if let videoPath = uploadData["videoURL"] as? URL {
                self.videoURL = videoPath
                DispatchQueue.global(qos: .background).async {
                    self.playVideo(from: videoPath);
                }
                
                self.thumbNailImage = getThumbnailFrom(path: videoPath)!
                do {
                    self.videoData = try Data(contentsOf: videoPath)
                } catch {
                    print("Unable to load data: \(error)")
                }
            }
        }
    }
    
    
    private func playVideo(from videoURL:URL) {
        DispatchQueue.main.async {
            print("main thread dispatch")
            print(videoURL)
            self.player = Player()
            self.player.delegate = self
            self.player.view.frame = self.videoView.bounds
            self.addChildViewController(self.player)
            self.videoView.addSubview(self.player.view)
            self.player.didMove(toParentViewController: self)
            self.player.setUrl(videoURL)
            self.player.playbackLoops = true
            self.player.playFromBeginning()
   
        }
    }
    @IBAction func againOdiButtonAct(_ sender: Any) {
        if self.player != nil {
            self.player.stop()
            self.player = nil
        }
        self.back(animated: true, isModal: true)
    }
    
    @IBAction func uploadFileButtonAct(_ sender: Any) {
        self.SHOW_SIC(type: .video)
        self.currentTime = Date().getCurrentHour()
        DispatchQueue.global(qos: .background).async {
            self.ftp.send(data:  self.videoData! , with: "\(self.videoId)_\(self.userId)_VID_\(Date().getTodayDateString())_\(self.currentTime).MOV", success: { error in
                DispatchQueue.main.async {
                    if error {
                        self.uploadDefaultImage(image: self.thumbNailImage)
                    }
                    else{
                       
                    }
                    self.addVideoGalleruy(filePath: self.filePath, compressedURL: self.videoURL!)
                }
            })
        }
        
    }
    @IBOutlet weak var videoView: UIView!
    private var player : Player!
    func showAlert(message: String) {
        self.HIDE_SIC(customView: self.view)
        let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
        
        // Create the actions
        let okAction = UIAlertAction(title: "Tamam",style: UIAlertActionStyle.default) {
            UIAlertAction in
            if self.presentingViewController != nil {
                self.dismiss(animated: false, completion: {
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "transitionBack"), object: nil, userInfo: nil)
                })
            }
            else {
                self.navigationController?.popToRootViewController(animated: true)
            }
        }
        // Add the actions
        alertController.addAction(okAction)
        // Present the controller
        self.present(alertController, animated: true, completion: nil)
    }
    func addVideoGalleruy(filePath: String,compressedURL: URL){
        guard let compressedData = NSData(contentsOf: compressedURL) else {
            return
        }
        DispatchQueue.global(qos: .background).async {
            DispatchQueue.main.async {
                compressedData.write(toFile: filePath, atomically: true)
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: URL(fileURLWithPath: filePath))
                }) { completed, error in
                    if completed {
                        print("Video is saved!")
                    }
                }
            }
        }
    }
    
    func getThumbnailFrom(path: URL) -> UIImage? {
        
        do {
            
            let asset = AVURLAsset(url: path , options: nil)
            let imgGenerator = AVAssetImageGenerator(asset: asset)
            imgGenerator.appliesPreferredTrackTransform = true
            let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(0, 1), actualTime: nil)
            let thumbnail = UIImage(cgImage: cgImage)
            
            return thumbnail
            
        } catch let error {
            
            print("*** Error generating thumbnail: \(error.localizedDescription)")
            return nil
            
        }
        
    }
    func uploadDefaultImage(image: UIImage) {
        DispatchQueue.global(qos: .background).async {
            guard let imageData = UIImagePNGRepresentation(image) else { return }
            self.ftp.send(data:  imageData , with: "\(self.videoId)_\(self.userId)_VID_\(Date().getTodayDateString())_\(self.currentTime).jpg", success: { error in
                DispatchQueue.main.async {
                    if error {
                        self.isImageUpload = true
                        let url = URL(string: "http://odi.odiapp.com.tr/upld.php?fileName=\(self.videoId)_\(self.userId)_VID_\(Date().getTodayDateString())_\(self.currentTime).MOV")!
                        let request = URLRequest(url: url)
                        self.webViewForSuccess = WKWebView(frame: CGRect.zero)
                        self.webViewForSuccess?.isHidden = true
                        self.view.addSubview(self.webViewForSuccess!)
                        self.webViewForSuccess!.navigationDelegate = self
                        self.webViewForSuccess!.load(request)
                        
                    }
                    else{
                        self.showAlert(message: "İşleminizi şuanda gerçekleştiremiyoruz fakat videonuz galerinize kayıt edilmiştir.")
                    }
                    
                }
            })
        }
    }
    
}

extension PlayVideoController : WKNavigationDelegate {
    func webView(_ webView: WKWebView,
                 didFinish navigation: WKNavigation!) {
        if !isImageUpload {
            uploadDefaultImage(image: self.thumbNailImage)
        }
        else{
            showAlert(message: "İşleminiz başarı ile gerçekleştrildi")
        }
    }
}

extension PlayVideoController: PlayerDelegate {
    
    func playerReady(_ player: Player) {
        
    }
    
    func playerPlaybackStateDidChange(_ player: Player) {
        
        
    }
    
    func playerBufferingStateDidChange(_ player: Player) {
        //loadingIndicatorView.stopAnimating()
    }
    
    func playerPlaybackWillStartFromBeginning(_ player: Player) {
    }
    
    func playerPlaybackDidEnd(_ player: Player) {
    }
    
    func playerCurrentTimeDidChange(_ player: Player) {
        
    }
    
    func playerWillComeThroughLoop(_ player: Player) {
        
    }
    func playerCurrentTime(_ player: String) {
        //print("Time:", player)
        //print("Baran")
        
    }
    
}

