//
//  UploadImageService.swift
//  Odi
//
//  Created by bilal on 21/12/2017.
//  Copyright © 2017 bilal. All rights reserved.
//

import Foundation
import SWXMLHash
class UploadImageService : ConnectionDelegate
{
    
    
    
    let connection = PostConnection()
    var serviceDelegate : UploadImageServiceDelegte?
    
    func connectService(fileName: String, image: UIImage)
    {
        connection.PostConnectionImage(fileName: fileName, image: image)
    }
    
    func getStrin(string: String) {
        if string == "UPLOADPROFIL_RESULT_SUCCESS_JPG" {
        self.serviceDelegate?.getResponse(error: true)
        } else {
        self.serviceDelegate?.getResponse(error: true)
        }
    }
    
    func getError(errMessage: String) {
        if  self.serviceDelegate != nil {
            self.serviceDelegate?.getError(errorMessage: errMessage)
        }
    }
    func getJson(xmlData: XMLIndexer) {
    }
    init(){
        self.connection.delegate = self
    }
    
}
protocol UploadImageServiceDelegte {
    func getResponse(error: Bool)
    func getError(errorMessage : String)
}

