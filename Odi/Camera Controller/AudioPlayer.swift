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
    
    var player:AVAudioPlayer?

    
    func initialPlayer(resource : NSURL){
        do {
            self.player = try AVAudioPlayer(contentsOf: resource as URL)
            player?.prepareToPlay()
            
        } catch let error as NSError {
            //self.player = nil
            print(error.localizedDescription)
        } catch {
            print("AVAudioPlayer init failed")
        }
        
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
        if player != nil {
            let duration = player?.duration
            return Int(duration!)
        }
        return 0
    }
    func audioPlayerNil(){
        self.player = nil
    }
    
    
}
