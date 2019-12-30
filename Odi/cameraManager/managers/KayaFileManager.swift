//
//  KayaFileManager.swift
//  videoMuteSystem_hub
//
//  Created by Nok Danışmanlık on 29.11.2019.
//  Copyright © 2019 brokoly. All rights reserved.
//

import UIKit

class KayaFileManager: NSObject {
    
    let TAG:String = "KayaFileManager: "
    
    /**
     Usage: Temp klasöründe ki bütün videoları temizler
     */
    func clearTemp() {
        print("\(self.TAG): clearTemp")
        do {
            let filePaths = try FileManager.default.contentsOfDirectory(atPath: (KayaTempFolder()?.path)!)
            for filePath in filePaths {
                let path = KayaTempFolder()?.appendingPathComponent(filePath)
                try FileManager.default.removeItem(atPath: path!.path)
                print("\(self.TAG): clearTemp silinen item : \(KayaTempFolder()?.path ?? "")/\(filePath)")
            }
        } catch let error{
            print("\(self.TAG): clearTemp clearTemp : \(error)")
        }
    }
    
    /**
     Usage: documentDirectory deki videoların isimlerini değiştirir.
     - Parameter currentName: videonun ismi
     - Parameter newName: yeni adı
     - Parameter status: Bool durumu belirtir
     - Parameter failure: Error? tipinde dönüş
     - Returns: <#No return value#>
     */
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
            let tempPath = KayaTempFolder()?.appendingPathComponent(currentName)
            if (fileMan.fileExists(atPath: tempPath!.path)) {
                let videoPath = KayaVideoFolder()?.appendingPathComponent(newName)
                try FileManager.default.moveItem(at: tempPath!, to: videoPath!)
                status(true)
            }else {
                status(false)
            }
            
        } catch let error {
            failure(error)
        }
    }
    
    /**
     Usage: Video ve bağlantılı image ları siler
     - Parameter filePath:  video path
     - Parameter thumbPath:  thumbpath
     - Parameter originalImagePath:  büyük resim
     - Returns: callback
     */
    func deleteVideos(filePath:String,
                      thumbPath:String,
                      originalImagePath:String,
                      onStatus status: @escaping (Bool?) -> Void,
                      onFailure failure: @escaping (Error?) -> Void) {
        
        let filemanager = FileManager.default
        let destinationPath = KayaVideoFolder()?.appendingPathComponent(filePath)
        let thumbPath = KayaVideoFolder()?.appendingPathComponent(thumbPath)
        let originalPath = KayaVideoFolder()?.appendingPathComponent(originalImagePath)
        do {
            if (filemanager.fileExists(atPath: thumbPath!.path)) {
                try filemanager.removeItem(atPath: thumbPath!.path)
            }
            if (filemanager.fileExists(atPath: originalPath!.path)) {
                try filemanager.removeItem(atPath: originalPath!.path)
            }
            if (filemanager.fileExists(atPath: destinationPath!.path)) {
                try filemanager.removeItem(atPath: destinationPath!.path)
                status(true)
            }else {
                status(false)
            }
        } catch let error {
            failure(error)
        }
        
    }
}
