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
class PlayVideoController: UIViewController {

    var videoId = ""
    var userId = ""
    var videoData : Data?
    var webViewForSuccess: WKWebView?
    var ftp = FTPUpload(baseUrl: "ftp.beranet.com:21", userName: "odi@beranet.com", password: "[J9E]ox>" , directoryPath: "/img/")
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    override func viewDidAppear(_ animated: Bool) {
        if let uploadData = self.data as? [String: AnyObject] {
            if let userId = uploadData["userId"] as? String {
                self.userId = userId
            }
            if let videoId = uploadData["videoId"] as? String {
                self.videoId = videoId
            }
            if let videoPath = uploadData["videoURL"] as? URL {
                self.playVideo(from: videoPath);
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
        self.ftp.send(data:  self.videoData! , with: "\(self.videoId)_\(self.userId)_VID_\(Date().getTodayDateString())_1440265.MOV", success: { error in
            if error {
                let url = URL(string: "http://odi.beranet.com/upld.php?fileName=\(self.videoId)_\(self.userId)_VID_\(Date().getTodayDateString())_1440265.MOV")!
                let request = URLRequest(url: url)
                self.webViewForSuccess = WKWebView(frame: CGRect.zero)
                self.webViewForSuccess?.isHidden = true
                self.view.addSubview(self.webViewForSuccess!)
                self.webViewForSuccess!.navigationDelegate = self
                self.webViewForSuccess!.load(request)
            }
        })
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
                    self.navigationController?.popToRootViewController(animated: true)
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
}

extension PlayVideoController : WKNavigationDelegate {
    func webView(_ webView: WKWebView,
                 didFinish navigation: WKNavigation!) {
        showAlert(message: "İşleminiz başarı ile gerçekleştrildi")
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
