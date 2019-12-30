//
//  GetByMemberService.swift
//  Resten Glow
//
//  Created by Baran on 29.11.2017.
//  Copyright © 2017 bilal. All rights reserved.
//

import Foundation
import SWXMLHash

class GetCameraServices : ConnectionDelegate
{
    func progressHandler(value: Float) {
        
    }
    
    let connection = PostConnection()
    var serviceDelegate : GetCameraDelegate?
    
    func connectService(serviceUrl : String)
    {
        connection.PostConnection(serviceUrl: serviceUrl)
    }
    
    func getJson(xmlData: XMLIndexer) {
        
        let result = xmlData["PROJE"]
        
        var responseData : GetCameraResponseModel = GetCameraResponseModel()
        
        
        for item in result["ATTR"].all {
            var responseList = GetCameraList()
            
            if let index = item["index"].element?.text {
                responseList.index = index
            }
            if let text = item["text"].element?.text {
                responseList.text = text
            }
            if let soundfile = item["soundfile"].element?.text {
                responseList.soundfile = soundfile
            }
            if let type = item["type"].element?.text {
                responseList.type = type
            }
            if let duration = item["duration"].element?.text {
                responseList.duration = duration
            }
            
            responseData.cameraList.append(responseList)
        }
        
        if let TIP = result["TIP"].element?.text {
            responseData.TIP = TIP
        }
        
        if  self.serviceDelegate != nil {
            self.serviceDelegate?.getResponse(response: responseData)
        }
        
    }
    func getStrin(string: String) {
    }
    func getError(errMessage: String) {
        if  self.serviceDelegate != nil {
            self.serviceDelegate?.getError(errorMessage: errMessage)
        }
    }
    
    init(){
        self.connection.delegate = self
    }
    
}

protocol GetCameraDelegate {
    func getResponse(response : GetCameraResponseModel)
    func getError(errorMessage : String)
}

struct GetCameraResponseModel {
    var TIP = ""
    var cameraList = [GetCameraList]()
}

struct GetCameraList {
    var index = ""
    var text = ""
    var soundfile = ""
    var duration = ""
    var type = ""
    var path : URL?
}


