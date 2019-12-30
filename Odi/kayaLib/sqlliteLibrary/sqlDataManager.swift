//
//  sqlDataManager.swift
//  dbSql_tutorial
//
//  Created by Nok Danışmanlık on 16.10.2019.
//  Copyright © 2019 namikkaya. All rights reserved.
//

import UIKit


class sqlDataManager: NSObject {
    private var videoDB:dbVideos?
    private var projectDB:dbProjects?
    private var fManager:fileDataManager?
    
    let TAG:String = "sqlDataManager:"
    
    override init() {
        super.init()
        videoDB = dbVideos()
        projectDB = dbProjects()
        fManager = fileDataManager()
    }
    
    public func insertVideo(model:videoModel?,
                            onSuccess success: @escaping (Bool?) -> Void,
                            onFailure failure: @escaping (DATABASE_STATUS?) -> Void) {
        
        guard let model = model else { return }
        
        projectDB?.checkProject(_projectId: model.projectId!, onCallback: { (status:Bool?, data:projectModel?) in
            if (status == true) { // proje var ekleme yapılmayacak yeni açılmayacak
                print("\(self.TAG): checkProject proje db de kayıtlı")
                self.videoDB?.checkVideo(model: model, onCallback: { (status:Bool?) in
                    if (status == false) { // kayıt yapılabilir
                        self.videoDB?.insertVideo(model: model, onSuccess: { (status:Bool?) in
                            if (status == true) {
                                success(true)
                                print("\(self.TAG): insertVideo: video başarılı bir şekilde kaydedildi")
                            }
                        }, onFailure: { (error:Error?) in
                            failure(DATABASE_STATUS.ERROR)
                            print("\(self.TAG): ERROR: \(String(describing: error)) -- 121")
                        })
                    }else { // bu video dosyası mevcut
                        print("\(self.TAG): video dosyası daha önce kaydedilmiş tekrar kaydedilmeyecek")
                        failure(DATABASE_STATUS.ALREADY_EXISTS)
                    }
                })
            }else { // proje açılacak
                print("\(self.TAG): checkProject yeni proje açılacak")
                let myProjectModel = projectModel(projectId: model.projectId)
                self.projectDB?.insertProject(model: myProjectModel, onSuccess: { (status:Bool?) in
                    if (status == true) {
                        // proje eklemesi tamamlandı
                        
                        self.videoDB?.checkVideo(model: model, onCallback: { (status:Bool?) in
                            if (status == false) { // kayıt yapılabilir
                                self.videoDB?.insertVideo(model: model, onSuccess: { (status:Bool?) in
                                    if (status == true) {
                                        success(true)
                                        print("\(self.TAG): insertVideo: video başarılı bir şekilde kaydedildi")
                                    }
                                }, onFailure: { (error:Error?) in
                                    failure(DATABASE_STATUS.ERROR)
                                    print("\(self.TAG): ERROR: \(String(describing: error)) -- 121 + ")
                                })
                            }else { // bu video dosyası mevcut
                                print("\(self.TAG): video dosyası daha önce kaydedilmiş tekrar kaydedilmeyecek")
                                failure(DATABASE_STATUS.ALREADY_EXISTS)
                            }
                        })
                        
                        
                    }
                }, onFailure: { (error:Error?) in
                    failure(DATABASE_STATUS.ERROR)
                })
            }
        }, onFailure: { (error:Error?) in // hata meydana geldi
            failure(DATABASE_STATUS.ERROR)
        })
    }
    
    func getVideoByProjectId(projectId:String?,
                             onSuccess success: @escaping (Bool?, [videoModel]?) -> Void,
                             onFailure failure: @escaping (Error?) -> Void) {
        
        guard let projectId = projectId else { return }
        
        videoDB?.getVideoByProjectId(_projectId: projectId, onSuccess: { (status:Bool?, data:[videoModel]?) in
            success(status, data)
        }, onFailure: { (error:Error?) in
            failure(error)
        })
    }
    
    /// tek bir video siler
    func deleteVideo(id:Int64?, onCallback callback: @escaping (Bool?) -> Void) {
        guard let id = id else { return }
        // silinecek videonun ilk önce bilgisi alınır.
        videoDB?.getVideoData(_id: id, onData: { (status:Bool?, videoData:videoModel?) in
            if let status = status {
                if (status == true) {
                    if let videoData = videoData {
                        
                        print("\(self.TAG): getVideoData: video bilgisi alındı")
                        // bilgisi alınan video silinir.
                        self.videoDB?.deleteVideo(_id: videoData.id!, onCallback: { (deleteStatus:Bool?) in
                            
                            
                            self.fManager?.deleteVideos(filePath: videoData.videoPath!,
                                                        thumbPath: videoData.thumbPath!,
                                                        onStatus: { (status) in
                                
                            }, onFailure: { (error) in
                                print("hata \(String(describing: error))")
                            })
                            
                            print("\(self.TAG): getVideoData -> deleteVideo: video silindi")
                            // bilgisi alınan videonun projectId si ile bu projeye de başka video var mı kontrolu sağlanır.
                            self.videoDB?.getVideoByProjectId(_projectId: videoData.projectId!, onSuccess: { (otherVideoStatus:Bool?, otherVideoData:[videoModel]?) in
                                
                                if let otherVideoStatus = otherVideoStatus {
                                    // eğer başka video yok ise
                                    if (otherVideoStatus == false) {
                                        
                                        print("\(self.TAG): getVideoData -> deleteVideo -> getVideoByProjectId : galeride başka video yok")
                                        
                                        self.deleteProject(projectId: videoData.projectId!) { (deleteProjectStatus:Bool?) in
                                            if let deleteProjectStatus = deleteProjectStatus {
                                                if(deleteProjectStatus == true) {
                                                    callback(true)
                                                }
                                            }
                                        }
                                        
                                    }else { // silinenden başka video var ise
                                        print("\(self.TAG): getVideoData -> deleteVideo -> getVideoByProjectId : galeride başka videolar var")
                                        callback(true)
                                    }
                                }
                                
                            }, onFailure: { (error:Error?) in
                                callback(false)
                            })
                            
                            
                        })
                        
                        
                    }
                }else {
                    callback(false)
                }
            }
        })
    }
    
    /// proje silinir
    func deleteProject(projectId:String?, onCallback callback: @escaping (Bool?) -> Void) {
        guard let projectId = projectId else { return }
        // projenin bilgileri çekilir
        projectDB?.getProjectById(_projectId: projectId, onSuccess: { (status:Bool?, data:projectModel?) in
            
            // projeye bağlı olan videolar çekilir....
            self.videoDB?.getVideoByProjectId(_projectId: projectId, onSuccess: { (status:Bool?, videoData:[videoModel]?) in
                if (status == true) {
                    if let videoData = videoData {
                        for i in 0..<videoData.count {
                            self.deleteVideo(id: videoData[i].id!) { (status:Bool?) in
                                self.fManager?.deleteVideos(filePath: videoData[i].videoPath!, thumbPath: videoData[i].thumbPath!, onStatus: { (fileStatus) in
                                    print("diff: video dosyası silindi -------")
                                }, onFailure: { (error) in
                                    print("diff: error-- 12")
                                })
                            }
                        }
                    }
                }
            }, onFailure: { (error:Error?) in
                
            })
            
            
            if let data = data {
                self.projectDB?.deleteProject(model: data, onSuccess: { (status:DATABASE_STATUS?, error:Error?) in
                    if (status == DATABASE_STATUS.SUCCESS) {
                        callback(true)
                        print("PROJE SİLİNDİ")
                    }else {
                        callback(false)
                    }
                })
            }
            
        }, onFailure: { (error:Error?) in
            
        })
        
    }
    
    
    func getAllProject(onSuccess success: @escaping (Bool?, [projectModel]?) -> Void,
                       onFailure failure: @escaping (Error?) -> Void) {
        
        projectDB?.getProjects(onSuccess: { (status, data:[projectModel]?) in
            success(status,data)
        }, onFailure: { (error) in
            failure(error)
        })
    }
    
}
