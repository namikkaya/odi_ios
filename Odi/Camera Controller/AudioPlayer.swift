//
//  AudioPlayer.swift
//  Odi
//
//  Created by Baran on 20.12.2017.
//  Copyright © 2017 CodingMind. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

class AudioPlayer: NSObject {
    
    var player:AVPlayer?
    var playerItem:AVPlayerItem?
    
    func initialPlayer(resource : String, view: UIView){
        //İnitial player
        let url = URL(string: API.fileApi.rawValue + resource)
        let playerItem:AVPlayerItem = AVPlayerItem(url: url!)
        player = AVPlayer(playerItem: playerItem)
        let playerLayer=AVPlayerLayer(player: player!)
        playerLayer.frame=CGRect(x:0, y:0, width:10, height:50)
        view.layer.addSublayer(playerLayer)
    }
    func playPlayer(){
        if player != nil {
            self.player?.play()
        }
    }
    func pausePlayer(){
        if player != nil {
            self.player?.pause()
        }
    }
    func playerGetDuration() -> Int {
        let duration : CMTime = player!.currentItem!.asset.duration
        let seconds : Int = Int(CMTimeGetSeconds(duration))
        return seconds
    }
    func audioPlayerNil(){
        self.player = nil
        self.playerItem = nil
    }
    
    
}
