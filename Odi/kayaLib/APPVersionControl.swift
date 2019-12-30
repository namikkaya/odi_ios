//
//  APPVersionControl.swift
//  Odi
//
//  Created by Nok Danışmanlık on 11.11.2019.
//  Copyright © 2019 bilal. All rights reserved.
//

import UIKit
import Alamofire
import SWXMLHash

class APPVersionControl: NSObject {
    let TAG:String = "APPVersionControl"
    override init() {
        super.init()
    }
    
    /**
     
     Usage: Uygulama ile store daki uygulama arasında ki versiyon kontrolünü sağlar.
     
     - Parameter parametre: açıklama
     
     - Returns: No return value
     
     */
    public func checkVersion(onCallback callback: @escaping (Bool?, String?) -> Void) {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let systemVersion = UIDevice.current.systemVersion
        let xmlStringPath:String = "http://odi.odiapp.com.tr/img/iosVersionControl.xml"
        let url:URL = URL(string: xmlStringPath)!
        
        var urlRequest = URLRequest(url: url)
        urlRequest.cachePolicy = .reloadIgnoringCacheData
        URLCache.shared.removeCachedResponse(for: urlRequest)
        
        Alamofire.SessionManager.default.requestWithoutCache(xmlStringPath).response { response in
                if let data = response.data {
                    let xml = SWXMLHash.parse(data)
                    do {
                        let version = try xml.byKey("iosApp").byKey("versionControl").byKey("appVersion").element?.text
                        let desc = try xml.byKey("iosApp").byKey("versionControl").byKey("appDesc").element?.text
                        let targetVersion = try xml.byKey("iosApp").byKey("versionControl").byKey("iosVersion").element?.text
                        
                        self.checkVersionNumber(currentAppVersion: appVersion, targetAppVersion: version) { (status) in
                            self.checkVersionDecider(type: APPVersionControl.version_type.app, status: status!, desc: desc!, callback: callback)
                        }
                        
                        
                        self.checkSystemVersionNumber(currentSystemVersion: systemVersion, targetSystemVersion: targetVersion) { (status) in
                            self.checkVersionDecider(type: APPVersionControl.version_type.osx, status: status!, desc: desc!, callback: callback)
                        }
                        
                    } catch let error {
                        print("\(self.TAG): versionControl xml: \(error)")
                    }
                }
        }
        
    }
    
    enum version_type {
        case app
        case osx
    }
    
    var appVersionStatus:Bool?
    var iosVersionStatus:Bool?
    private func checkVersionDecider(type:version_type, status:Bool, desc:String , callback:(Bool?, String?) -> Void) {
        if type == version_type.app {
            appVersionStatus = status
            if let iosVersionStatus = iosVersionStatus {
                if appVersionStatus! && iosVersionStatus {
                    print("versionControl - decider: version_type güncelleme için gönder callBACK")
                    callback(true,desc)
                }else {
                    print("versionControl - decider: version_type GÜNCELLEME YAPILAMAZ-- callBACK")
                    callback(false,desc)
                }
            }
        }else {
            iosVersionStatus = status
            if let appVersionStatus = appVersionStatus {
                if appVersionStatus && iosVersionStatus! {
                    print("versionControl - decider: appversion güncelleme için gönder callBACK")
                    callback(true,desc)
                }else {
                    print("versionControl - decider: appversion  GÜNCELLEME YAPILAMAZ-- callBACK")
                    callback(false,desc)
                }
            }
        }
    }
    
    private func checkSystemVersionNumber(currentSystemVersion:String?,
                                          targetSystemVersion:String?,
                                          systemVersionOnCallback onCallback: @escaping (Bool?)->Void){
        
        if let currentSystemVersion = currentSystemVersion, let targetSystemVersion = targetSystemVersion {
            let currentSystemVersionArray = currentSystemVersion.components(separatedBy: ".")
            print("versionControl: \(currentSystemVersionArray)")
            
            let targetSystemVersionArray = targetSystemVersion.components(separatedBy: ".")
            print("versionControl: \(targetSystemVersionArray)")
            
            print("versionControl: 1. currentSystemVersionArray[0]: \(currentSystemVersionArray[0]) = \(targetSystemVersionArray[0])")
            if currentSystemVersionArray[0] < targetSystemVersionArray[0] {
                // sistem versiyonu 1. basamak hedef versiyonun birinci basamağından küçük ise false
                print("versionControl: 1.basamak işlem yapılamaz")
                onCallback(false)
                
            }else {
                print("versionControl: 2. currentSystemVersionArray[1]: \(currentSystemVersionArray[1]) = \(targetSystemVersionArray[1])")
                if currentSystemVersionArray[1] < targetSystemVersionArray[1] &&
                    currentSystemVersionArray[0] <= targetSystemVersionArray[0] {
                    // sistem versiyonu 2. basamak hedef versiyonun ikinci basamağından küçük ise false
                    print("versionControl: 2.basamak işlem yapılamaz")
                    onCallback(false)
                    
                }else {
                    // işlem olumlu yapılabilir
                    print("versionControl: Güncelleme yapılabilir")
                    onCallback(true)
                }
            }
                
        }
    }
    
    private func checkVersionNumber(currentAppVersion:String?, targetAppVersion:String?, versionOnCallback versionCallback: @escaping (Bool?) -> Void) {
        
        if let current = currentAppVersion, let target = targetAppVersion {
            let currentArray = current.components(separatedBy: ".")
            let targetArray = target.components(separatedBy: ".")
            
            let currentB1 = currentArray[0]
            let currentB2 = currentArray[1]
            let currentB3 = currentArray[2]
            
            let targetB1 = targetArray[0]
            let targetB2 = targetArray[1]
            let targetB3 = targetArray[2]
            
            
            print("versionControl appVersion:current \(currentB1) = \(targetB1)")
            if currentB1 < targetB1 {
                print("versionControl appVersion: 1 güncelleme yapılması gerekiyor")
                versionCallback(true)
            }else if (currentB1 == targetB1) {
                if (currentB2 < targetB2) {
                    print("versionControl appVersion: 2 güncelleme yapılması gerekiyor")
                    versionCallback(true)
                }else if (currentB2 == targetB2) {
                    if (targetB3 > currentB3) {
                        print("versionControl appVersion: 3 güncelleme yapılması gerekiyor")
                        versionCallback(true)
                    }else {
                        print("versionControl appVersion: 97 Güncelleme yapılamaz")
                        versionCallback(false)
                    }
                }else {
                    print("versionControl appVersion: 98 Güncelleme yapılamaz")
                    versionCallback(false)
                }
            }else {
                print("versionControl appVersion: 99 Güncelleme yapılamaz")
                versionCallback(false)
            }
        }
    }
}

extension Alamofire.SessionManager{
    @discardableResult
    open func requestWithoutCache(
        _ url: URLConvertible,
        method: HTTPMethod = .get,
        parameters: Parameters? = nil,
        encoding: ParameterEncoding = URLEncoding.default,
        headers: HTTPHeaders? = nil)// also you can add URLRequest.CachePolicy here as parameter
        -> DataRequest
    {
        do {
            var urlRequest = try URLRequest(url: url, method: method, headers: headers)
            urlRequest.cachePolicy = .reloadIgnoringCacheData // <<== Cache disabled
            let encodedURLRequest = try encoding.encode(urlRequest, with: parameters)
            return request(encodedURLRequest)
        } catch {
            // TODO: find a better way to handle error
            print(error)
            return request(URLRequest(url: URL(string: "http://example.com/wrong_request")!))
        }
    }
}
/*
Alamofire.request(url, method: HTTPMethod.get, parameters: nil).response { response in
    if (response.error == nil) {
        if let data = response.data {
            let xml = SWXMLHash.parse(data)
            print("versionControl: \(xml)")
            do {
                let version = try xml.byKey("iosApp").byKey("versionControl").byKey("appVersion").element?.text
                let desc = try xml.byKey("iosApp").byKey("versionControl").byKey("appDesc").element?.text
                let targetVersion = try xml.byKey("iosApp").byKey("versionControl").byKey("iosVersion").element?.text
               
                
                print("versionControl: \(version) + desc: \(desc) + \(targetVersion) - mysystemver: \(systemVersion)")
                
                /*self.checkVersionNumber(current: appVersion, target: version) { (status) in
                    callback(status, desc)
                }*/
                
                self.checkVersionNumber(currentAppVersion: appVersion, targetAppVersion: version) { (status) in
                    //callback(status,desc)
                }
                
                
            } catch let error {
                print("\(self.TAG): versionControl xml: \(error)")
            }

        }
    }else {
        print("\(self.TAG): versionControl: xml HATA VAR")
    }
}*/
