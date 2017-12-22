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

class PlayVideoController: UIViewController {

    
    var ftp = FTPUpload(baseUrl: "ftp.beranet.com:21", userName: "odi@beranet.com", password: "[J9E]ox>" , directoryPath: "/img/")
    var videoData : Data?
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    override func viewDidAppear(_ animated: Bool) {
        if let videoPath = self.data as? URL {
            self.playVideo(from: videoPath);
            do {
                self.videoData = try Data(contentsOf: videoPath)
            } catch {
                print("Unable to load data: \(error)")
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
        ftp.send(data:  self.videoData! , with: "15_148_VID_20171222_1440265.MOV", success: { error in
            print("scussedd")
        })
        
    }
    @IBOutlet weak var videoView: UIView!
    
    
    private var player : Player!
    
    
    
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
