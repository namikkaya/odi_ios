//
//  ViewController.swift
//  OdiCameraTutorial
//
//  Created by Baran on 15.12.2017.
//  Copyright © 2017 CodingMind. All rights reserved.
//

import UIKit
import Photos

class CameraViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureCameraController()
        styleCaptureButton()
        print(odiResponseModel)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
    }
    override func viewDidAppear(_ animated: Bool) {
        AppUtility.lockOrientation(.landscapeRight, andRotateTo: .landscapeRight)
    }
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    //Action Button
    @IBAction func CaptureButtonAction(_ sender: UIButton) {
        if !isRecording {
            isRecording = true
            // Configure output path in temporary folder
            let outputPath = NSTemporaryDirectory() + "output.mp4"
            let outputFileURL = URL(fileURLWithPath: outputPath)
            cameraController.videoOutput?.startRecording(toOutputFileURL: outputFileURL, recordingDelegate: self)
            //Button configure
            captureButton.setImage(#imageLiteral(resourceName: "stop2"), for: .normal)
            
        } else {
            isRecording = false
            cameraController.videoOutput?.stopRecording()
            captureButton.setImage(#imageLiteral(resourceName: "rec"), for: .normal)
        }
    }
    
    @IBAction func closeTitleAction(_ sender: Any) {
        if isTextClosed {
            isTextClosed = !isTextClosed
            self.kareokeLabel.isHidden = true
        }
        else{
            isTextClosed = !isTextClosed
            self.kareokeLabel.isHidden = false
        }
        
    }
    
    @IBAction func swapCameraAct(_ sender: Any) {
        cameraController.swapCamera()
        if !isFrontCamera {
            isFrontCamera = !isFrontCamera
        }
        else{
            isFrontCamera = !isFrontCamera
        }
    }
    
    @IBAction func backToControllerAct(_ sender: Any) {
    }
    
    
    
    //Storyboard Veriable
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var closeTitleButton: UIButton!
    @IBOutlet weak var swapCameraButton: UIButton!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var kareokeLabel: UILabel!
    
    //Support Classes
    let cameraController = CameraController()
    var audioPlayer = AudioPlayer()
    
    //Supporter Veriable
    var isRecording = false
    var isFrontCamera = false
    var isTextClosed = false
    //For timer
    var duration = 0
    var subtitleString = ""
    var timer = Timer()
    //Response model
    var odiResponseModel = GetCameraResponseModel()
    
}

extension CameraViewController {
    
    func configureCameraController() {
        cameraController.prepareBackVideo(view: self.cameraView)
    }
    
    func styleCaptureButton() {
        captureButton.layer.borderColor = UIColor.white.cgColor
        captureButton.layer.borderWidth = 3
        captureButton.layer.cornerRadius = min(captureButton.frame.width, captureButton.frame.height) / 2
    }
    
    func recursiveAnimate(arrayCount: Int, array :[GetCameraList], newCount: Int){
        var count = newCount
        switch array[count].type {
        case "0":
            audioPlayer.initialPlayer(resource: array[count].soundfile, view: self.view)
            audioPlayer.playPlayer()
            subtitleString = array[count].text
            self.runTimer(interval: TimeInterval(Float(audioPlayer.playerGetDuration()) / Float(subtitleString.count)))
            
            UIView.animate(withDuration: TimeInterval(audioPlayer.playerGetDuration() + 1) , animations: {
                self.progressView.progress = 1.0
                self.view.layoutIfNeeded()
            }){ success in
                self.progressView.progress = 0
                self.view.layoutIfNeeded()
                count += 1
                if arrayCount > count {
                    self.audioPlayer.audioPlayerNil()
                    self.recursiveAnimate(arrayCount: array.count, array: array, newCount: count)
                }
            }
        case "1":
            kareokeLabel.text = array[count].text
            UIView.animate(withDuration: TimeInterval(array[count].duration) ?? 4.0, animations: {
                self.progressView.progress = 1.0
                self.view.layoutIfNeeded()
            }){ success in
                self.progressView.progress = 0
                self.view.layoutIfNeeded()
                print(arrayCount)
                print(count)
                count += 1
                if arrayCount > count {
                    self.recursiveAnimate(arrayCount: array.count, array: array, newCount: count)
                }
            }
        default:
            break
        }
    }
    
    func runTimer(interval: TimeInterval) {
        timer = Timer.scheduledTimer(timeInterval: 0.11, target: self,   selector: (#selector(self.updateTimer)), userInfo: nil, repeats: true)
    }
    @objc func updateTimer() {
        duration += 1
        let myMutableString = NSMutableAttributedString(
            string: subtitleString,
            attributes: [NSAttachmentAttributeName : UIFont(
                name: "Georgia",
                size: 18.0)!])
        myMutableString.addAttribute(
            NSForegroundColorAttributeName,
            value: UIColor.blue,
            range: NSRange(
                location:0,
                length:duration))
        self.kareokeLabel.attributedText = myMutableString
        if duration == subtitleString.count {
            duration = 0
            timer.invalidate()
        }
    }
    
    
}

extension CameraViewController: AVCaptureFileOutputRecordingDelegate {
    func capture(_ output: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
        
        //For compress code
        guard let data = NSData(contentsOf: outputFileURL as URL) else {
            return
        }
        print("File size before compression: \(Double(data.length / 1048576)) mb")
        let compressedURL = NSURL.fileURL(withPath: NSTemporaryDirectory() + NSUUID().uuidString + ".output.mp4")
        compressVideo(inputURL: outputFileURL as URL, outputURL: compressedURL) { (exportSession) in
            guard let session = exportSession else {
                return
            }
            switch session.status {
            case .unknown:
                break
            case .waiting:
                break
            case .exporting:
                break
            case .completed:
                guard let compressedData = NSData(contentsOf: compressedURL) else {
                    return
                }
                let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0];
                let filePath="\(documentsPath)/output.mp4"
                DispatchQueue.global(qos: .background).async {
                    DispatchQueue.main.async {
                        compressedData.write(toFile: filePath, atomically: true)
                        PHPhotoLibrary.shared().performChanges({
                            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: URL(fileURLWithPath: filePath))
                        }) { completed, error in
                            if completed {
                                print("Video is saved!")
                            }
                        }
                    }
                }
                print("File size after compression: \(Double(compressedData.length / 1048576)) mb")
            case .failed:
                break
            case .cancelled:
                break
            }
        }
    }
    
    func sizeForLocalFilePath(filePath:String) -> UInt64 {
        do {
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: filePath)
            if let fileSize = fileAttributes[FileAttributeKey.size]  {
                return (fileSize as! NSNumber).uint64Value
            } else {
                print("Failed to get a size attribute from path: \(filePath)")
            }
        } catch {
            print("Failed to get file attributes for local path: \(filePath) with error: \(error)")
        }
        return 0
    }
    func covertToFileString(with size: UInt64) -> String {
        var convertedValue: Double = Double(size)
        var multiplyFactor = 0
        let tokens = ["bytes", "KB", "MB", "GB", "TB", "PB",  "EB",  "ZB", "YB"]
        while convertedValue > 1024 {
            convertedValue /= 1024
            multiplyFactor += 1
        }
        print(String(format: "%4.2f %@", convertedValue, tokens[multiplyFactor]))
        return String(format: "%4.2f %@", convertedValue, tokens[multiplyFactor])
    }
    func compressVideo(inputURL: URL, outputURL: URL, handler:@escaping (_ exportSession: AVAssetExportSession?)-> Void) {
        let urlAsset = AVURLAsset(url: inputURL, options: nil)
        guard let exportSession = AVAssetExportSession(asset: urlAsset, presetName: AVAssetExportPresetMediumQuality) else {
            handler(nil)
            
            return
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = AVFileTypeQuickTimeMovie
        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.exportAsynchronously { () -> Void in
            handler(exportSession)
        }
    }
    
}



struct AppUtility {
    
    static func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
        
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            delegate.orientationLock = orientation
        }
    }
    
    /// OPTIONAL Added method to adjust lock and rotate to the desired orientation
    static func lockOrientation(_ orientation: UIInterfaceOrientationMask, andRotateTo rotateOrientation:UIInterfaceOrientation) {
        
        self.lockOrientation(orientation)
        
        UIDevice.current.setValue(rotateOrientation.rawValue, forKey: "orientation")
    }
    
}