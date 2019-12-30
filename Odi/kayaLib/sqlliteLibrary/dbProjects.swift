//
//  dbControlManager.swift
//  dbSql_tutorial
//
//  Created by Nok Danışmanlık on 15.10.2019.
//  Copyright © 2019 namikkaya. All rights reserved.
//

import UIKit
import SQLite

class dbProjects: NSObject {
    private let TAG:String = "dbProjects: "
    
    private var dbFileURL:URL!
    private var dbName:String = "odi.sqlite3"
    
    var db:Connection!
    var path:String = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]
    let tableName = Table("projects")
    let id = Expression<Int64>("id")
    let projectId = Expression<String>("projectId")
    let createDate = Expression<String>("createDate") // 0=> kendi sesi 1=> dış ses


    override init() {
        super.init()
        createDB()
    }
    
    public func createDB(){
        do {
            if db == nil {
                db = try Connection("\(path)/\(dbName)")
            }
            try db.run(tableName.create { t in
                t.column(id, primaryKey: true)
                t.column(projectId)
                t.column(createDate)
            })
            
        } catch (let error){
            print("\(self.TAG): createDB: \(error)")
        }
    }
    
    /// proje ekler
    func insertProject(model:projectModel,
                       onSuccess success: @escaping (Bool?) -> Void,
                       onFailure failure: @escaping (Error?) -> Void) {
        do {
            if db == nil {
                db = try Connection("\(path)/\(dbName)")
            }
            
            let insert = tableName.insert(
                projectId <- model.projectId!,
                createDate <- model.createDate!
            )
            try db.run(insert)
            success(true)
        } catch (let error){
            print("videoDBManager: video eklenmedi bir problem var")
            failure(error)
        }
    }
    
    /// Bütün projeleri döndürür
    func getProjects(onSuccess success: @escaping (Bool?, [projectModel]?) -> Void,
                    onFailure failure: @escaping (Error?) -> Void){
        
        var myProjectModels: [projectModel] = []
        
        do {
            if db == nil {
                db = try Connection("\(path)/\(dbName)")
            }
            
            for item in try db.prepare(tableName) {
                let d:projectModel = projectModel(id: item[id], projectId: item[projectId], createDate: item[createDate])
                myProjectModels.append(d)
            }
            
            if(myProjectModels.count > 0){
                success(true,myProjectModels)
            }else{
                success(false,myProjectModels)
            }
        } catch (let error){
            failure(error)
        }
    }
    
    /// projectId ye göre projeyi getirir.
    func getProjectById(_projectId:String,
                        onSuccess success: @escaping (Bool?, projectModel?) -> Void,
                        onFailure failure: @escaping (Error?) -> Void) {
        
        do {
           if db == nil {
                db = try Connection("\(path)/\(dbName)")
            }
            
            let videoData = tableName.where(projectId==_projectId)
            var myprojectmodel:projectModel?
            for item in try db.prepare(videoData) {
                myprojectmodel = projectModel(id: item[id],
                                              projectId: item[projectId],
                                              createDate: item[createDate])
            }
            if (myprojectmodel == nil) {
                success(false,nil)
            }else {
                success(true,myprojectmodel)
            }
            
        } catch let error {
            failure(error)
        }
        
        
    }
    
    /// projeyi siler.
    func deleteProject(model:projectModel?,
                       onSuccess success: @escaping (DATABASE_STATUS?, Error?) -> Void) {
        guard let _model = model else {
            success(DATABASE_STATUS.NULL_PARAMETER, nil)
            return
        }
        
        guard let _projectId = _model.projectId else {
            success(DATABASE_STATUS.NULL_PARAMETER, nil)
            return
        }
        
        let item = tableName.filter(projectId == _projectId)
        do {
            if try db.run(item.delete()) > 0 {
                success(DATABASE_STATUS.SUCCESS, nil)
            } else {
                success(DATABASE_STATUS.NO_STAFF, nil)
            }
        } catch let error {
            success(DATABASE_STATUS.ERROR, error)
        }
        
    }
    
    /// projenin daha önce açılıp açılmadığı durumu
    func checkProject(_projectId:String,
                      onCallback callback: @escaping (Bool?, projectModel?) -> Void,
                      onFailure failure: @escaping (Error?) -> Void) {
        do {
            if db == nil {
                db = try Connection("\(path)/\(dbName)")
            }
             
            let videoData = tableName.where(projectId==_projectId)
            var myprojectmodel:[projectModel] = []
            for item in try db.prepare(videoData) {
                myprojectmodel.append(projectModel(id: item[id], projectId: item[projectId],createDate: item[createDate]))
            }
            if (myprojectmodel.count > 0) { // var
                callback(true, myprojectmodel[0])
            }else { // yok
                callback(false, nil)
            }
             
         } catch let error {
              failure(error)
         }
    }
    
     
    
}
