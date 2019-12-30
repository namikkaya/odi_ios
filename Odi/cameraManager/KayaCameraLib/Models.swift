//
//  Models.swift
//  videoMuteSystem_hub
//
//  Created by Nok Danışmanlık on 14.11.2019.
//  Copyright © 2019 brokoly. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit


struct KayaAppUtility {
    
    static func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            delegate.orientationLock = orientation
        }
    }
    
    static func lockOrientation(_ orientation: UIInterfaceOrientationMask, andRotateTo rotateOrientation:UIInterfaceOrientation) {
        self.lockOrientation(orientation)
        UIDevice.current.setValue(rotateOrientation.rawValue, forKey: "orientation")
        UINavigationController.attemptRotationToDeviceOrientation()
    }
    
}

/**
 Usage:  Dosya yollarını belirtir. Temp ve video file için
 - Parameter getValue: yol pathlerini döndürür
 - Parameter getFileFolder: dosya yollarını döndürür.
 - Returns: No return value
 */
enum KAYA_SAVE_VIDEOS_FILE:String {
    case VIDEOFOLDER = "KayaVideoFolder"
    case TEMPFOLDER = "KayaTempFolder"
    
    func getValue(type:KAYA_SAVE_VIDEOS_FILE) -> String {
        switch type {
        case .VIDEOFOLDER:
            return KAYA_SAVE_VIDEOS_FILE.VIDEOFOLDER.rawValue
        case .TEMPFOLDER:
            return KAYA_SAVE_VIDEOS_FILE.TEMPFOLDER.rawValue
        }
    }
    
    var videoFolder: String {
        switch self {
        case .VIDEOFOLDER:
            return KAYA_SAVE_VIDEOS_FILE.VIDEOFOLDER.rawValue
        case .TEMPFOLDER:
            return KAYA_SAVE_VIDEOS_FILE.TEMPFOLDER.rawValue
        }
    }
    
}

/**
 Usage: viedo folder dosyasını açar ve path döndürür
 - Returns: videoFolder path URL
 */
public func KayaVideoFolder() -> URL? {
    var videoFolder_in:URL?
    let documentsPath = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
    let logsPath = documentsPath.appendingPathComponent(KAYA_SAVE_VIDEOS_FILE.VIDEOFOLDER.videoFolder)
    if (!FileManager.default.fileExists(atPath: logsPath.path)) {
        do {
            try FileManager.default.createDirectory(atPath: (logsPath.path), withIntermediateDirectories: true, attributes: nil)
            print("createVideoFolder: DOSYA YAZILDI")
            videoFolder_in = logsPath
        } catch let error as NSError {
            print("createVideoFolder: DOSYA YAZILAMADI FOLDER \(error)")
        }
    }else {
        print("createVideoFolder: DOSYA daha önceden eklenmiş")
        videoFolder_in = logsPath
    }
    return videoFolder_in
}

/**
Usage: temp folder dosyasını açar ve path döndürür
- Returns: temp Folder path URL
*/

public func KayaTempFolder() -> URL? {
    var tempFolder_in:URL?
    let documentsPath = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
    let logsPath = documentsPath.appendingPathComponent(KAYA_SAVE_VIDEOS_FILE.TEMPFOLDER.videoFolder)
    if (!FileManager.default.fileExists(atPath: logsPath.path)) {
        do {
            try FileManager.default.createDirectory(atPath: (logsPath.path), withIntermediateDirectories: true, attributes: nil)
            print("createTempFolder: DOSYA YAZILDI")
            tempFolder_in = logsPath as URL?
        } catch let error as NSError {
            print("createTempFolder: DOSYA YAZILAMADI FOLDER \(error)")
        }
    }else {
        print("createTempFolder: DOSYA daha önceden eklenmiş")
        tempFolder_in = logsPath as URL?
    }
    return tempFolder_in
}


struct KayaSubtitleModel {
    var id:Int?
    var text:String?
    var soundURL:URL?
    var type:KAYA_SUBTITLE_TYPE?
    var duration:Double?
    
    /**
     Usage: Her dialog için bir model oluşturur.
     - Parameter id:  dialog id si
     - Parameter text:  subtitle text string i
     - Parameter soundURL:  myself olduğu an bu nil döner/ speaker tipinde audio dosyası yolu barındırır.
     - Parameter type:  dialog id si
     - Returns: No return value
     */
    init(id:Int?,
         text:String?,
         soundURL:URL?,
         duration:Double?,
         type: KAYA_SUBTITLE_TYPE) {
        self.id = id
        self.text = text
        self.soundURL = soundURL
        self.type = type
        
        if type == .speaker {
            self.duration = getDuration(urlPath: soundURL)
        }else {
            self.duration = duration
        }
    }
    
    // gelen sound url için duration döndürür.
    private func getDuration(urlPath:URL?) -> Double? {
        guard let urlPath = urlPath else { return nil }
        var myPlayer:AVAudioPlayer?
        do {
            myPlayer = try AVAudioPlayer(contentsOf: urlPath)
        } catch let error {
            print("KayaDuration: erorr -> \(error)")
        }
        
        if let player = myPlayer {
            let duration = player.duration
            if myPlayer != nil {
                myPlayer = nil
            }
            return duration
        }else {
            return nil
        }
    }
}
