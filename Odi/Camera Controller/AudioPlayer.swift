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
    var timer:Timer!
    
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
    
    func startCaputeredMusic(recourceName: String,delegateVC: UIViewController) {
        let path = Bundle.main.path(forResource: "\(recourceName)", ofType : "wav")!
        let url = URL(fileURLWithPath : path)
        do {
            self.player = try AVAudioPlayer(contentsOf: url as URL)
            self.player?.delegate = delegateVC as? AVAudioPlayerDelegate
            player?.prepareToPlay()
            
        } catch let error as NSError {
            //self.player = nil
            print(error.localizedDescription)
        } catch {
            print("AVAudioPlayer init failed")
        }
    }
    
    func playPlayerForAction(viewController: CameraViewController){
        if player != nil {
            timer = Timer.scheduledTimer(timeInterval: 0.9, target: viewController, selector: #selector(viewController.updateTimerForPlayerCurrentTime), userInfo: nil, repeats: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.player?.play()
            } 
        }
    }
    func playerDidFinishPlaying(note: NSNotification) {
        // Your code here
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
