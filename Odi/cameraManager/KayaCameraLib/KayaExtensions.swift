//
//  extensions.swift
//  videoMuteSystem_hub
//
//  Created by Nok Danışmanlık on 13.11.2019.
//  Copyright © 2019 brokoly. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

extension KayaCameraManager {
    
    /**
     Usage: Posizyona göre ön veya arka kamerayı ayarlar ve geriye döndürür
     
     - Parameter position: Kamera pozisyonu ÖN / ARKA
     
     - Returns: AVCaptureDevice: Kamera döndürür.
     
     */
    internal func getDevice(position: CameraPosition)->AVCaptureDevice? {
        var avCapture:AVCaptureDevice?
        if (position == .FRONT) {
            if let device = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera,
                                                    for: AVMediaType.video,
                                                    position: AVCaptureDevice.Position.front){
                avCapture = device
            }
        }else {
            if let device = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera,
                                                    for: AVMediaType.video,
                                                    position: AVCaptureDevice.Position.back){
                avCapture = device
            }
        }
        return avCapture
    }
    
    /**
     
     Usage: Mikrofon girdisinin döndürür.
     
     */
    internal func getAudioInputDevice(captureDevice:AVCaptureDevice?,
                                      completion: (Bool?,AVCaptureDeviceInput?)->()) {
        if let captureDevice = captureDevice {
            var input:AVCaptureDeviceInput?
            do {
                input = try AVCaptureDeviceInput(device: captureDevice)
                completion(true, input)
            } catch let error {
                print("KAYA_HATA: \(error)")
                completion(false, input)
            }
        }
        
    }
    
    /**
     
     Usage: Kamera görüntü girdisini döndürür.
     
     - Parameter captureDevice: Kamera cihazı belirtilir.
     - Parameter completion: (Bool?,AVCaptureDeviceInput?)
     
     - Returns: No return value
     
     */
    internal func getInputDevive(captureDevice:AVCaptureDevice?,
                                 completion: (Bool?,AVCaptureDeviceInput?) -> ()) {
        if let captureDevice = captureDevice {
            var input:AVCaptureDeviceInput?
            do {
                input = try AVCaptureDeviceInput(device: captureDevice)
                completion(true, input)
            } catch let error {
                print("KAYA_HATA: \(error)")
                completion(false, input)
            }
        }
        
    }
    
    /// startSession görüntü almayı başlatır.
    internal func startSession() {
        if !captureSession!.isRunning {
            guard let capture = self.captureSession else { return  }
            capture.startRunning()
        }
    }
    
    /// stopSession görüntü  almayı bırakır.
    internal func stopSession() {
        if captureSession!.isRunning {
            guard let capture = self.captureSession else { return }
            capture.stopRunning()
        }
    }
    
    /// Ekran dönüşüne göre video boyutlarını ve görüntüsünü ayarlar
    internal func updateRotateVideo() {
        if (movieOutput.isRecording) {
            return
        }
        
        guard let orientation = currentVideoOrientation else { return }
        switch orientation {
        case .portrait:
            if let cc = captureConnection {
                if let cot = convertOrientation() {
                    cc.videoOrientation = cot
                }
            }
            videoPreviewLayer?.frame = CGRect(x: 0, y: 0, width: (previewView?.frame.size.width)!, height: (previewView?.frame.size.height)!)
            videoPreviewLayer?.connection?.videoOrientation = .portrait
            previewView!.setNeedsDisplay()
            print("\(self.TAG): updateRotateVideo: portrait")
            break
        case .landscapeLeft:
            if let cc = captureConnection {
                if let cot = convertOrientation() {
                    cc.videoOrientation = .landscapeRight
                }
            }
            videoPreviewLayer?.frame = CGRect(x: 0, y: 0, width: (previewView?.frame.size.width)!, height: (previewView?.frame.size.height)!)
            videoPreviewLayer?.connection?.videoOrientation = .landscapeRight
            previewView!.setNeedsDisplay()
            //self.layerUpdate(of: self.view)
            print("\(self.TAG): updateRotateVideo: landscapeLeft")
            break
        case .landscapeRight:
            if let cc = captureConnection {
                if let cot = convertOrientation() {
                    cc.videoOrientation = .landscapeRight
                }
            }
            videoPreviewLayer?.frame = CGRect(x: 0, y: 0, width: (previewView?.frame.size.width)!, height: (previewView?.frame.size.height)!)
            videoPreviewLayer?.connection?.videoOrientation = .landscapeRight
            previewView!.setNeedsDisplay()
            print("\(self.TAG): updateRotateVideo: landscapeRight")
            break
        default:
            // portrait
            if let cc = captureConnection {
                if let cot = convertOrientation() {
                    cc.videoOrientation = .landscapeRight
                }
            }
            videoPreviewLayer?.frame = CGRect(x: 0, y: 0, width: (previewView?.frame.size.width)!, height: (previewView?.frame.size.height)!)
            videoPreviewLayer?.connection?.videoOrientation = .portrait
            previewView!.setNeedsDisplay()
            print("\(self.TAG): updateRotateVideo: default")
            break
        }
    }
    
    internal func convertOrientation()-> AVCaptureVideoOrientation? {
        guard let orientation = currentVideoOrientation else { return nil}
        switch orientation {
        case .portrait:
            return .portrait
        case .landscapeLeft:
            return .landscapeRight
        case .landscapeRight:
            return .landscapeLeft
        default:
            return .landscapeRight
        }
    }
}


extension Date {
    
    func currentDayString() -> String {
        let date = Date()
        let format = DateFormatter()
        format.dateFormat = "yyyy_MM_dd_HH_mm_ss"
        let formattedDate = format.string(from: date)
        return formattedDate
    }
}

extension UIColor {
    // hex sample: 0xf43737
    convenience init(_ hex: Int, alpha: Double = 1.0) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255.0, green: CGFloat((hex >> 8) & 0xFF) / 255.0, blue: CGFloat((hex) & 0xFF) / 255.0, alpha: CGFloat(255 * alpha) / 255)
    }

    convenience init(_ hexString: String, alpha: Double = 1.0) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)

        let r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (r, g, b) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (1, 1, 0)
        }

        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(255 * alpha) / 255)
    }

    convenience init(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat = 1) {
        self.init(red: (r / 255), green: (g / 255), blue: (b / 255), alpha: a)
    }
    
    func setGradientBackground(startColor:UIColor, endColor:UIColor, frame:CGRect) -> CAGradientLayer{
        let layer = CAGradientLayer()
        layer.frame = frame
        layer.colors = [startColor.cgColor, endColor.cgColor]
        return layer
    }
    
}

extension UIView {
    func setGradientBackground(colorOne: UIColor, colorTwo: UIColor){
        DispatchQueue.main.async {
            let gradientLayer = CAGradientLayer()
            
            let mySize:CGRect?
            
            if self.bounds.width < self.bounds.height {
                mySize = CGRect(x: self.bounds.origin.x, y: self.bounds.origin.y, width: self.bounds.size.height, height: self.bounds.size.width)
            }else {
                mySize = CGRect(x: self.bounds.origin.x, y: self.bounds.origin.y, width: self.bounds.size.width, height: self.bounds.size.height)
            }
            
            //print("gradient size: \(mySize)")
            
            gradientLayer.frame = mySize!//bounds
            gradientLayer.colors = [colorOne.cgColor, colorTwo.cgColor]
            gradientLayer.locations = [0.0,1.0]
            gradientLayer.name = "gback"
            self.layer.insertSublayer(gradientLayer, at: 0)
        }
        
    }
    
    func setBack(colorOne:UIColor, colorTwo:UIColor, colorThree:UIColor, colorFour:UIColor){
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = self.bounds
        
        gradientLayer.colors = [colorOne.cgColor, colorTwo.cgColor, colorThree.cgColor, colorFour.cgColor]
        gradientLayer.locations = [0.0, 0.2, 0.4, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 0, y: 0)
        layer.insertSublayer(gradientLayer, at: 0)
    }
    
    func clearGradientBackground() {
        for item in self.layer.sublayers ?? [] where item.name == "gback" {
            item.removeFromSuperlayer()
        }
    }
    
    func screenshot() -> UIImage {
        if #available(iOS 10.0, *) {
            return UIGraphicsImageRenderer(size: bounds.size).image { _ in
                drawHierarchy(in: CGRect(origin: .zero, size: bounds.size), afterScreenUpdates: true)
            }
        } else {
            UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, UIScreen.main.scale)
            drawHierarchy(in: self.bounds, afterScreenUpdates: true)
            let image = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
            UIGraphicsEndImageContext()
            return image
        }
    }
}

extension KayaCameraManager {
    // SETTER Function
    internal func normalizedGains(_ activeInput: AVCaptureDeviceInput?, _ gains: AVCaptureDevice.WhiteBalanceGains) -> AVCaptureDevice.WhiteBalanceGains? {
        guard let activeInput = activeInput else { return nil }
        let device = activeInput.device
        var g = gains
        
        g.redGain = max(1.0, g.redGain)
        g.greenGain = max(1.0, g.greenGain)
        g.blueGain = max(1.0, g.blueGain)
        
        g.redGain = min(device.maxWhiteBalanceGain, g.redGain)
        g.greenGain = min(device.maxWhiteBalanceGain, g.greenGain)
        g.blueGain = min(device.maxWhiteBalanceGain, g.blueGain)
        
        return g
    }
}

extension KayaCameraView {
    
}

extension Notification.Name {
    public struct KAYA_CAMERA_NOTIFICATION {
        /// App background dan geri geldiği zaman tetiklenir. Uygulama yeniden aktif olduğunda.
        public static let APP_ACTIVE = Notification.Name(rawValue: "app_active")
        
        /// App arka plana itildiği zaman tetiklenir.
        public static let APP_WILL_BACKGROUND = Notification.Name(rawValue: "app_will_background")
        
    }
}

extension UISlider {
    var currentPresentationValue: Float {
        guard let presentation = layer.presentation(),
            let thumbSublayer = presentation.sublayers?.max(by: {
                $0.frame.height < $1.frame.height
            })
            else { return self.value }

        let bounds = self.bounds
        let trackRect = self.trackRect(forBounds: bounds)
        let minRect = self.thumbRect(forBounds: bounds, trackRect: trackRect, value: 0)
        let maxRect = self.thumbRect(forBounds: bounds, trackRect: trackRect, value: 1)
        let value = (thumbSublayer.frame.minX - minRect.minX) / (maxRect.minX - minRect.minX)
        return Float(value)
    }
}

extension Double {
    /// Rounds the double to decimal places value
    func rounded(toPlaces places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
