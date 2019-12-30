//
//  kayaDbManager.swift
//  dbSql_tutorial
//
//  Created by Nok Danışmanlık on 15.10.2019.
//  Copyright © 2019 namikkaya. All rights reserved.
//

import UIKit
import AVKit

/**
 Singleton class
 Database kontrolü her yerden yapılabilir.
 */
class kayaDbManager: NSObject {
    let TAG:String = "kayaDbManager: "
    
    private var mySql:sqlDataManager?
    private var fManager:fileDataManager?
    
    static let sharedInstance: kayaDbManager = {
        let instance = kayaDbManager()
        return instance
    }()
    
    override init() {
        super.init()
        mySql = sqlDataManager()
        fManager = fileDataManager()
    }
    
    
    /**
     
     Usage:  Videoyu temp klasöründen yeni isimlendirilmiş şekli ile videoFolder içine taşır ve db ye kaydeder.
     
     - Parameter videoName: temp dosyası içindeki adı
     - Parameter status: true dönerse başarılı işlem sayılır
     - Parameter newName: videoFolder dosyası içindeki adı yeni adı
     - Parameter failure: başarısız işlemlerde hatanın dönüşünü sağlar
     
     - Returns: No return value
     
     */
    func saveVideo(videoName:String,
                   newName:String,
                   projectId:String?,
                   cameraStatus:String?,
                   onStatus status: @escaping (Bool?) -> Void,
                   onFailure failure: @escaping (Error?) -> Void) {
        
        let thumbNameArray:[String] = newName.components(separatedBy: ".")
        let thumbName:String = "\(thumbNameArray[0]).jpg"
        
        let virtualVideo = tempFolder?.appendingPathComponent(videoName)
        let fm = FileManager.default
        var thumbVideo:UIImage?
        var thumbVideoImageName:String?
        if (fm.fileExists(atPath: virtualVideo!.path)) {
            thumbVideo = getThumbnailFrom(path: virtualVideo!)
            thumbVideoImageName = thumbSaveFile(image: thumbVideo!, fileName: thumbName)
        }
        
        print("dataÇözüm: newName: \(newName)")
        
        fManager?.tempToSaveVideoFolder(currentName: videoName, newName: newName, onStatus: { (check) in
            if let check = check {
                if (check) {
                    
                    let myModel = videoModel(projectId: projectId, videoPath: newName, thumbPath: thumbVideoImageName, cameraStatus: cameraStatus)
                    
                    self.insertVideo(model: myModel, onSuccess: { (checkStatus) in
                        status(true)
                    }) { (errorStatus:DATABASE_STATUS?) in
                        //print("dataÇözüm: errorStatus \(errorStatus)")
                        status(false)
                    }
                }else {
                    //print("dataÇözüm: 1.error \(check)")
                    status(false)
                }
            }else {
                //print("dataÇözüm: 2.error \(check)")
                status(false)
            }
        }, onFailure: { (error) in
            failure(error)
            //print("dataÇözüm: errorStatus \(error)")
        })
    }
    
    private func getThumbnailFrom(path: URL) -> UIImage? {
        
        do {
            let asset = AVURLAsset(url: path , options: nil)
            let imgGenerator = AVAssetImageGenerator(asset: asset)
            imgGenerator.appliesPreferredTrackTransform = true
            let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(value: 0, timescale: 1), actualTime: nil)
            let thumbnail = UIImage(cgImage: cgImage)
            
            return thumbnail
            
        } catch let error {
            
            print("*** Error generating thumbnail: \(error.localizedDescription)")
            return nil
            
        }
        
    }
    
    private func thumbSaveFile(image: UIImage, fileName:String) -> String? {
        let fileURL = videoFolder!.appendingPathComponent(fileName)
        let jpegData = image.jpegData(compressionQuality: 1.0)//image.UIImageJPEGRepresentation(compressionQuality: 1.0)
        try? jpegData!.write(to: fileURL!, options: .atomic)
        return fileName
    }
    
    /**
     
     Usage: Video yu db ye ekler. Sadece kayıt işlemi yapar herhangi bir dosya işlemine karışmaz
     
     - Parameter model: videoModel bilgisini alır
     - Parameter success: İşler yolunda gittiğinde true djner
     - Parameter failure: Herhangi bir hata aldığında
     
     - Returns: No return value
     
     */
    func insertVideo(model:videoModel?,
                     onSuccess success: @escaping (Bool?) -> Void,
                     onFailure failure: @escaping (DATABASE_STATUS?) -> Void) {
        
        mySql?.insertVideo(model: model, onSuccess: { (status:Bool?) in
            if (status == true) {
                success(true)
            }
        }, onFailure: { (failStatus:DATABASE_STATUS?) in
            failure(failStatus)
        })
    }
    
    /**
    
    Usage: proje ıd sine göre video listesini döndürür
    
    - Parameter projectId: projeID
    - Parameter success: true ve data döndürür aynı zamanda
    - Parameter failure: Herhangi bir hata aldığında
    
    - Returns: No return value
    
    */
    func getVideoByProjectId(projectId:String?,
                             onSuccess success: @escaping (Bool?, [videoModel]?) -> Void,
                             onFailure failure: @escaping (Error?) -> Void) {
        
        guard let projectId = projectId else { return }
        mySql?.getVideoByProjectId(projectId: projectId, onSuccess: { (status: Bool?, data: [videoModel]?) in
            success(status,data)
        }, onFailure: { (error:Error?) in
            failure(error)
        })
    }
    
    
    /**
     
     Usage: Video yu ve thumb dosyasını temizledikten sonra db deki kayıtlarını siler
     
     - Parameter videoData: videomodel
     
     - Returns: No return value
     
     */
    func deleteVideo(videoData:videoModel?,
                     onSuccess success: @escaping (Bool?) -> Void,
                     onFailure failure: @escaping (Error?) -> Void) {
        
        fManager?.deleteVideos(filePath: (videoData?.videoPath!)!,
                               thumbPath: videoData!.thumbPath!,
                               onStatus: { (checkStatus) in
            print("\(self.TAG): deleteVideo: video dosyası silindi")
            self.deleteVideoDB(id: videoData?.id) { (status) in
                print("\(self.TAG): deleteVideo: video database den silindi")
                success(true)
            }
        }, onFailure: { (error:Error?) in
            failure(error)
        })
    }
    
    /**
     videoyu siler ve silinen videonun ait olduğu projede başka video yok ise projeyide siler.
     */
    func deleteVideoDB(id:Int64?, onCallback callback: @escaping (Bool?) -> Void){
        guard let id = id else { return }
        mySql?.deleteVideo(id: id, onCallback: { (status:Bool?) in
            callback(status)
        })
    }
    
    /**
     projeyi siler ve projeye bağlı bütün videoları kaldırır.
     */
    func deleteProject(projectId:String?, onCallback callback: @escaping (Bool?) -> Void) {
        mySql?.deleteProject(projectId: projectId, onCallback: { (status:Bool?) in
            callback(status)
        })
    }
    
    func getProjectData(projectId:String?, onCallback callback: @escaping (Bool?,projectModel?) -> Void) {
        mySql?.getAllProject(onSuccess: { (status, data:[projectModel]?) in
            for i in 0..<data!.count{
                if data![i].projectId == projectId {
                    callback(true,data![i])
                    return
                }
            }
        }, onFailure: { (error) in
            callback(false,nil)
        })
    }
    
    
    func clearTempFile() {
        fManager?.clearTemp()
    }
    
    func clearTimeOutVideo(onSuccess success: @escaping (Bool?) -> Void,
                           onFailure failure: @escaping (DATABASE_STATUS?) -> Void) {
        
        mySql?.getAllProject(onSuccess: { (status:Bool?, data:[projectModel]?) in
            if let status = status {
                if status {
                    if data != nil {
                        for i in 0..<data!.count {
                            let createDate:Date = (data![i].createDate?.toDate())!
                            print("diff: today: \(Date()) - createDate: \(createDate)")
                            let diffDate = Date().daysBetween(date: createDate)
                            print("diff: \(diffDate)")
                            if(diffDate < -5) { // 5 günden daha fazla ise
                                self.deleteProject(projectId: data![i].projectId) { (status) in
                                    if let status = status {
                                        if status {
                                            print("diff: proje silindi")
                                        }
                                    }
                                    
                                    
                                }
                            }
                        }
                    }
                }
            }
        }, onFailure: { (error) in
            failure((error as! DATABASE_STATUS))
        })
    }
    
    deinit {
        if mySql != nil {
            mySql = nil
        }
        if fManager != nil {
            fManager = nil
        }
    }
    
}
