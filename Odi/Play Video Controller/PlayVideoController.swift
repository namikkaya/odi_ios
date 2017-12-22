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

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    override func viewDidAppear(_ animated: Bool) {
        if let videoPath = self.data as? URL {
            self.playVideo(from: videoPath)
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
        //FTP kodları yazılcak.
        
        
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
