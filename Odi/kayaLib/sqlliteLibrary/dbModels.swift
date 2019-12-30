//
//  dbModels.swift
//  dbSql_tutorial
//
//  Created by Nok Danışmanlık on 15.10.2019.
//  Copyright © 2019 namikkaya. All rights reserved.
//

import Foundation

enum DATABASE_STATUS:String {
    case SUCCESS = "Başarılı bir şekilde silindi" // BAŞARILI
    case NO_STAFF = "Böyle bir kayıt bulunamadı" // BÖYLE BİR ELEMAN YOK
    case NULL_PARAMETER = "Parametrelerden biri anlamsız (null)"
    case ERROR = "Hata var."
    case ALREADY_EXISTS = "Dosya zaten var"
}

enum SAVE_VIDEOS_FILE:String {
    case VIDEOFOLDER = "KayaVideoFolder"
    case TEMPFOLDER = "KayaTempFolder"
    
    func getValue(type:SAVE_VIDEOS_FILE) -> String {
        switch type {
        case .VIDEOFOLDER:
            return SAVE_VIDEOS_FILE.VIDEOFOLDER.rawValue
        case .TEMPFOLDER:
            return SAVE_VIDEOS_FILE.TEMPFOLDER.rawValue
        }
    }
    
    
    var videoFolder: String {
        switch self {
        case .VIDEOFOLDER:
            return SAVE_VIDEOS_FILE.VIDEOFOLDER.rawValue
        case .TEMPFOLDER:
            return SAVE_VIDEOS_FILE.TEMPFOLDER.rawValue
        }
    }
    
}

let videoFilesDocument = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
//let videoFolder = NSURL(fileURLWithPath: videoFilesDocument).appendingPathComponent(SAVE_VIDEOS_FILE.VIDEOFOLDER.videoFolder)
//let tempFolder = NSURL(fileURLWithPath: videoFilesDocument).appendingPathComponent(SAVE_VIDEOS_FILE.TEMPFOLDER.videoFolder)

var videoFolder:NSURL?
var tempFolder:NSURL?

/**
 Project bilgisini tutar
 */
struct projectModel {
    var id:Int64?
    var projectId:String?
    var createDate:String?
    
    /// id, title, createDate alır
    init(id:Int64?, projectId:String?, createDate:String?) {
        self.id = id
        self.projectId = projectId
        self.createDate = createDate
    }
    
    /// title ve oluşturulma zamanı alır.
    init(projectId:String?, createDate:String?) {
        self.projectId = projectId
        self.createDate = createDate
    }
    
    /// title gönderilir otomatik olarak tarih ve id alır.
    init(projectId:String?) {
        self.projectId = projectId
        self.createDate = Date().dateToStringUTC()
    }
}

/**
 video bilgisi tutulur.
 */
struct videoModel {
    var id:Int64?
    var projectId:String?
    var createDate:String?
    var videoPath:String?
    var thumbPath:String?
    var cameraStatus:String?
    
    init(id:Int64?, projectId:String?, createDate:String?, videoPath:String?, thumbPath:String?, cameraStatus:String?) {
        self.id = id
        self.projectId = projectId
        self.createDate = createDate
        self.videoPath = videoPath
        self.thumbPath = thumbPath
        self.cameraStatus = cameraStatus
    }
    
    init(projectId:String?, createDate:String?, videoPath:String?, thumbPath:String?, cameraStatus:String?) {
        self.projectId = projectId
        self.createDate = createDate
        self.videoPath = videoPath
        self.thumbPath = thumbPath
        self.cameraStatus = cameraStatus
    }
    
    init(projectId:String?, videoPath:String?, thumbPath:String?, cameraStatus:String?) {
        self.projectId = projectId
        self.videoPath = videoPath
        self.createDate = Date().dateToStringUTC()
        self.thumbPath = thumbPath
        self.cameraStatus = cameraStatus
    }
}
