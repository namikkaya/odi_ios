//
//  fileDataManager.swift
//  Odi
//
//  Created by Nok Danışmanlık on 22.10.2019.
//  Copyright © 2019 bilal. All rights reserved.
//

import UIKit

class fileDataManager: NSObject {
    let TAG:String = "fileDataManager:"
    override init() {
        super.init()
        
        createFolders()
    }
    
    private func createVideoFolder() {
        let documentsPath = NSURL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
        let logsPath = documentsPath.appendingPathComponent(SAVE_VIDEOS_FILE.VIDEOFOLDER.videoFolder)
        if (!FileManager.default.fileExists(atPath: logsPath!.path)) {
            do {
                try FileManager.default.createDirectory(atPath: (logsPath?.path)!, withIntermediateDirectories: true, attributes: nil)
                print("\(self.TAG): DOSYA YAZILDI")
                videoFolder = logsPath as NSURL?
            } catch let error as NSError {
                print("\(self.TAG): DOSYA YAZILAMADI FOLDER \(error)")
            }
        }else {
            print("\(self.TAG): DOSYA daha önceden eklenmiş")
            videoFolder = logsPath as NSURL?
        }
        
    }
    
    private func createTempFolder() {
        let documentsPath = NSURL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
        let logsPath = documentsPath.appendingPathComponent(SAVE_VIDEOS_FILE.TEMPFOLDER.videoFolder)
        if (!FileManager.default.fileExists(atPath: logsPath!.path)) {
            do {
                try FileManager.default.createDirectory(atPath: (logsPath?.path)!, withIntermediateDirectories: true, attributes: nil)
                print("\(self.TAG): DOSYA YAZILDI")
                tempFolder = logsPath as NSURL?
            } catch let error as NSError {
                print("\(self.TAG): DOSYA YAZILAMADI FOLDER \(error)")
            }
        }else {
            print("\(self.TAG): DOSYA daha önceden eklenmiş")
            tempFolder = logsPath as NSURL?
        }
    }
    
    func createFolders() {
        createVideoFolder()
        createTempFolder()
    }
    
    func renameVideos(currentName:String,
                      newName:String,
                      onStatus status: @escaping (Bool?) -> Void,
                      onFailure failure: @escaping (Error?) -> Void) {
        do {
            let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            let documentDirectory = URL(fileURLWithPath: path)
            let originPath = documentDirectory.appendingPathComponent(currentName)
            let destinationPath = documentDirectory.appendingPathComponent(newName)
            try FileManager.default.moveItem(at: originPath, to: destinationPath)
            status(true)
        } catch let error {
            failure(error)
        }
    }
    
    
    // temp klasöründen taşınacak
    /**
        
     Usage: temp klasöründe ki videoyu videoFolder klasörüne ismini değiştirerek taşır.
     
     - Parameter currentName: dosyanın mevcut ismi
     - Parameter newName: Dosyanın yeni ismi
     - Parameter status: başarılı sonuçta true döner eğer dosya bulamazsa false
     - Parameter failure: başarız hata sonuçları döner
     
     - Returns: No return value
     
     */
    func tempToSaveVideoFolder(currentName:String,
                               newName:String,
                               onStatus status: @escaping (Bool?) -> Void,
                               onFailure failure: @escaping (Error?) -> Void) {
        do {
            let fileMan = FileManager.default
            let tempPath = tempFolder!.appendingPathComponent(currentName)
            
            if (fileMan.fileExists(atPath: tempPath!.path)) {
                let videoPath = videoFolder!.appendingPathComponent(newName)
                try FileManager.default.moveItem(at: tempPath!, to: videoPath!)
                print("dataÇözüm dosya yolu var")
                status(true)
            }else {
                print("dataÇözüm dosya yolu bulunamadı")
                status(false)
            }
            
        } catch let error {
            failure(error)
        }
    }
    
    
    func deleteVideos(filePath:String,
                      thumbPath:String,
                      onStatus status: @escaping (Bool?) -> Void,
                      onFailure failure: @escaping (Error?) -> Void) {
        
        let filemanager = FileManager.default
        let destinationPath = videoFolder!.appendingPathComponent(filePath)
        let thumbPath = videoFolder!.appendingPathComponent(thumbPath)
        do {
            if (filemanager.fileExists(atPath: thumbPath!.path)) {
                 try filemanager.removeItem(atPath: thumbPath!.path)
            }
            if (filemanager.fileExists(atPath: destinationPath!.path)) {
                try filemanager.removeItem(atPath: destinationPath!.path)
                print("vidDel: video silindi--------")
                status(true)
            }else {
                status(false)
            }
        } catch let error {
            failure(error)
        }
        
    }
    
    
    func clearTemp() {
        print("\(self.TAG): clearTemp")
        do {
            let filePaths = try FileManager.default.contentsOfDirectory(atPath: (tempFolder?.path)!)
            for filePath in filePaths {
                let path = tempFolder?.appendingPathComponent(filePath)
                try FileManager.default.removeItem(atPath: path!.path) // (tempFolder?.path!)! +"/"+ filePath
                print("\(self.TAG): clearTemp silinen item : \(tempFolder!.path!)/\(filePath)")
            }
        } catch let error{
            print("\(self.TAG): clearTemp clearTemp : \(error)")
        }
    }
}
