//
//  audioPlayer.swift
//  videoMuteSystem_hub
//
//  Created by Nok Danışmanlık on 22.11.2019.
//  Copyright © 2019 brokoly. All rights reserved.
//

import UIKit
import AVFoundation


enum KAYA_AUDIO_PLAYER_STATUS {
    case FINISH
    case PLAY
    case PREPARE
    case ERROR
    case STOP
}

protocol KayaAudioPlayerDelegate:class {
    func KayaAudioPlayerDelegate_Trigger(id:String?, status:KAYA_AUDIO_PLAYER_STATUS?)
}

extension KayaAudioPlayerDelegate {
    func KayaAudioPlayerDelegate_Trigger(id:String?, status:KAYA_AUDIO_PLAYER_STATUS?){}
}

class KayaAudioPlayer: NSObject, AVAudioPlayerDelegate {
    let TAG:String = "KayaAudioPlayer"
    
    weak var setDelegate:KayaAudioPlayerDelegate?
    
    private var myPlayer: AVAudioPlayer?
    private var volumeHolder:Float = 1
    private var idHolder:String = ""
    
    /**
     Usage: Ses açma kapatma için kullanılabilir
     - Parameter volume: ses düzeyi
     */
    var volume:Float {
        set {
            volumeHolder = newValue
            if let myPlayer = myPlayer {
                myPlayer.volume = newValue
            }
        }get{
            return volumeHolder
        }
    }
    
    override init() {
        super.init()
    }
    
    deinit {
        releasePlayer()
    }
    
    func playSound(filePath:URL?, id:String) {
        guard let filePath = filePath else { return }
        do {
            myPlayer = try AVAudioPlayer(contentsOf: filePath)
            myPlayer?.delegate = self
            myPlayer?.volume = volume
            print("\(self.TAG): playSound=> \(volume)")
        } catch let error {
            print(error)
        }
        guard let myPlayer = myPlayer else { return }
        myPlayer.play()
        
        idHolder = id
        setDelegate?.KayaAudioPlayerDelegate_Trigger(id: idHolder, status: KAYA_AUDIO_PLAYER_STATUS.PLAY)
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        setDelegate?.KayaAudioPlayerDelegate_Trigger(id: idHolder, status: KAYA_AUDIO_PLAYER_STATUS.FINISH)
    }
    
    func stopSound() {
        releasePlayer()
        setDelegate?.KayaAudioPlayerDelegate_Trigger(id: idHolder, status: KAYA_AUDIO_PLAYER_STATUS.STOP)
    }
    
    
    private func releasePlayer() {
        if myPlayer != nil {
            myPlayer?.stop()
            myPlayer?.delegate = nil
            myPlayer?.volume = 1
            myPlayer = nil
        }
    }
    
}
