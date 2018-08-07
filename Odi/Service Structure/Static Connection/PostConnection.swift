//
//  PostConnection.swift
//  soapServiceConnection
//
//  Created by Baran on 3.05.2017.
//  Copyright © 2017 Baran. All rights reserved.
//

import Foundation
import SWXMLHash


class PostConnection : NSObject
{
    
    var delegate : ConnectionDelegate?
    var session : URLSession?
    var expectedContentLength = 0
    var buffer:NSMutableData = NSMutableData()
    var dataTask:URLSessionDataTask?
    
    func PostConnection(serviceUrl: String)
    {
        
        let urlString : String = serviceUrl
        
        let url : NSURL = NSURL(string: urlString)!
        let theRequest = NSMutableURLRequest(url: url as URL)
        theRequest.addValue("text/xml; charset=utf-8", forHTTPHeaderField: "Content-Type")
        theRequest.httpMethod = "POST"
        
        let configuration = URLSessionConfiguration.default
        let manqueue = OperationQueue.main
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: manqueue)
        
        session?.dataTask(with: theRequest as URLRequest) { (data, response, error) in
            print("Started Connection..")
            guard let data = data, error == nil else {                                                 // check for fundamental networking error
                print("error=\(String(describing: error))")
                self.delegate?.getError(errMessage: "servisResponse")
                return
            }
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {           // check for http errors
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print("response = \(String(describing: response))")
                self.delegate?.getError(errMessage: "servisResponse")
                return
            }
            
            let newXML = SWXMLHash.parse(data)
            if  self.delegate != nil {
                DispatchQueue.main.async {
                    self.delegate?.getJson(xmlData: newXML)
                }
            }
            
            }.resume()
    }
    func PostConnectionImage(fileName: String,image: UIImage)
    {
        
        var r  = URLRequest(url: URL(string: "http://odi.odiapp.com.tr/profilupload.php")!)
        r.httpMethod = "POST"
        let boundary = "Boundary-\(UUID().uuidString)"
        r.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        r.httpBody = createBody(parameters: ["":""],
                                boundary: boundary,
                                data:  UIImageJPEGRepresentation(image, 1.0)!,
                                mimeType: "image/jpg",
                                filename: fileName)
        
        let configuration = URLSessionConfiguration.default
        let manqueue = OperationQueue.main
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: manqueue)
        dataTask = session?.dataTask(with: r)
        dataTask?.resume()
        
    }
    func createBody(parameters: [String: String],
                    boundary: String,
                    data: Data,
                    mimeType: String,
                    filename: String) -> Data {
        let body = NSMutableData()
        
        let boundaryPrefix = "--\(boundary)\r\n"
        
        for (key, value) in parameters {
            body.appendString(boundaryPrefix)
            body.appendString("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            body.appendString("\(value)\r\n")
        }
        
        body.appendString(boundaryPrefix)
        body.appendString("Content-Disposition: form-data; name=\"image\"; filename=\"\(filename)\"\r\n")
        body.appendString("Content-Type: \(mimeType)\r\n\r\n")
        body.append(data)
        body.appendString("\r\n")
        body.appendString("--".appending(boundary.appending("--")))
        
        return body as Data
    }
    
}
extension NSMutableData {
    func appendString(_ string: String) {
        let data = string.data(using: String.Encoding.utf8, allowLossyConversion: false)
        append(data!)
    }
}

extension PostConnection: URLSessionDataDelegate {
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse,
                    completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        completionHandler(.allow)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        buffer.append(data)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        if self.delegate != nil {
            DispatchQueue.main.async {
                self.delegate?.progressHandler(value: Float(totalBytesSent) / Float(totalBytesExpectedToSend))
            }
        }
        
        
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if buffer.length > 0 {
            let nsdata = NSData(data: buffer as Data)
            let data = Data(referencing: nsdata)
            var string = ""
            if let returnData = String(data: data, encoding: .utf8) {
                string = returnData
            } else {
                print("")
            }
            if let da = data as? String {
                print(da)
            }
            if  self.delegate != nil {
                DispatchQueue.main.async {
                    self.delegate?.getStrin(string: string)
                }
            }
        } else {
            self.delegate?.getError(errMessage: "servisResponse")
            return
        }
        
        
        
    }
}
