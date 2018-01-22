//
//  ViewController.swift
//  OdiCameraTutorial
//
//  Created by Baran on 15.12.2017.
//  Copyright © 2017 CodingMind. All rights reserved.
//

import UIKit
import Photos
import AVFoundation
import AVKit
import QuartzCore


class CameraViewController: UIViewController {
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        AppUtility.lockOrientation(.landscapeRight, andRotateTo: .landscapeRight)
        print(odiResponseModel)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        print("viewWillAppear")
        self.addObserver()
        
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        print("viewDidAppear")
        styleCaptureButton()
        configureCameraController()
        
    }
    override func viewWillDisappear(_ animated: Bool) {
        AppUtility.lockOrientation(.portrait, andRotateTo: .portrait)
        self.stopTimer()
        self.closeButton.isHidden = false
        self.swapCameraButton.isHidden = false
        self.view.layer.removeAllAnimations()
        self.audioPlayer.pausePlayer()
        self.audioPlayer.audioPlayerNil()
        self.progressView.progress = 0
        self.removeObserver()
    }
    
    func addObserver(){
        NotificationCenter.default.addObserver(self, selector: #selector(self.goBack(notification:)), name: NSNotification.Name(rawValue: "transitionBack") , object: nil)
    }
    func removeObserver(){
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "transitionBack") , object: nil)
    }
    
    func goBack(notification: NSNotification){
        if let navigationController = self.navigationController
        {
            let _ = navigationController.popViewController(animated: true)
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    //Action Button
    @IBAction func CaptureButtonAction(_ sender: UIButton) {
        if !isRecording {
            isRecording = true
            // Configure output path in temporary folder
            let outputPath = NSTemporaryDirectory() + "output.mov"
            let outputFileURL = URL(fileURLWithPath: outputPath)
            cameraController.videoOutput?.startRecording(toOutputFileURL: outputFileURL, recordingDelegate: self)
            //Button configure
            self.closeButton.isHidden = true
            self.swapCameraButton.isHidden = true
            captureButton.setImage(#imageLiteral(resourceName: "stop2"), for: .normal)
            startCameraTimer()
            
        } else {
            isRecording = false
            cameraController.videoOutput?.stopRecording()
            self.skipButton.isHidden = true
            self.stopTimer()
            self.stopCameraTimer()
            self.cameraTimerCount = 0
            self.closeButton.isHidden = false
            self.swapCameraButton.isHidden = false
            self.audioPlayer.pausePlayer()
            self.audioPlayer.audioPlayerNil()
            self.progressView.progress = 0
            captureButton.setImage(#imageLiteral(resourceName: "rec"), for: .normal)
        }
    }
    
    @IBAction func closeTitleAction(_ sender: Any) {
        if !isTextClosed {
            isTextClosed = !isTextClosed
            self.kareokeLabel.isHidden = true
            self.closeTitleButton.setImage(#imageLiteral(resourceName: "text"), for: .normal)
        }
        else{
            isTextClosed = !isTextClosed
            self.kareokeLabel.isHidden = false
            self.closeTitleButton.setImage(#imageLiteral(resourceName: "textoff"), for: .normal)
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
        if let navigationController = self.navigationController
        {
            let _ = navigationController.popViewController(animated: true)
        }
    }
    
    @IBAction func skipButtonAction(_ sender: Any) {
        stopTimer()
        stopCameraTimer()
        cameraTimerCount += 1
        startCameraTimer()
    }
    
    
    //Storyboard Veriable
    @IBOutlet weak var skipButton: UIButton!
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var closeTitleButton: UIButton!
    @IBOutlet weak var swapCameraButton: UIButton!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var kareokeLabel: UILabel!
    @IBOutlet weak var closeButton: UIButton!
    
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
    var cameraTimer = Timer()
    var cameraTimerDuration = 0
    var cameraTimerCount = 0
    var progressValue : Double = 0.0
    //Response model
    var odiResponseModel = GetCameraResponseModel()
    //Send data
    var odileData = (userId: "", videoId: "")
    var uploadData : [String : AnyObject] = [:]
    var videoPath = ""
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
    
    
    func startCameraTimer(){
        cameraTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self,   selector: (#selector(self.updateCameraTimer)), userInfo: nil, repeats: true)
    }
    
    @objc func updateCameraTimer(){
        cameraTimerDuration += 1
        if odiResponseModel.cameraList.count > cameraTimerCount {
            switch odiResponseModel.cameraList[cameraTimerCount].type {
            case "0":
                if cameraTimerDuration == 1 {
                    skipButton.isHidden = true
                    audioPlayer.initialPlayer(resource: odiResponseModel.cameraList[cameraTimerCount].soundfile, view: self.view)
                    audioPlayer.playPlayer()
                    subtitleString = odiResponseModel.cameraList[cameraTimerCount].text
                    self.runTimer(interval: TimeInterval(Float(audioPlayer.playerGetDuration()) / Float(subtitleString.count)))
                    progressValue = 1.0 / Double(audioPlayer.playerGetDuration() + 1)
                }
                if cameraTimerDuration <= (audioPlayer.playerGetDuration() + 1) {
                    self.progressView.progress += Float(progressValue)
                }
                else{
                    cameraTimer.invalidate()
                    self.progressView.progress = 0.0
                    cameraTimerDuration = 0
                    cameraTimerCount += 1
                    if odiResponseModel.cameraList.count > cameraTimerCount {
                        startCameraTimer()
                    }
                }
            case "1":
                if cameraTimerDuration == 1 {
                    skipButton.isHidden = false
                    let myMutableString = NSMutableAttributedString(
                        string: odiResponseModel.cameraList[cameraTimerCount].text,
                        attributes: [NSAttachmentAttributeName : UIFont(
                            name: "Georgia",
                            size: 18.0)!])
                    kareokeLabel.attributedText = myMutableString
                    progressValue = 1.0 / Double(odiResponseModel.cameraList[cameraTimerCount].duration)!
                }
                if cameraTimerDuration <= Int(odiResponseModel.cameraList[cameraTimerCount].duration)! {
                    self.progressView.progress += Float(progressValue)
                }
                else{
                    cameraTimer.invalidate()
                    self.progressView.progress = 0.0
                    cameraTimerDuration = 0
                    cameraTimerCount += 1
                    if odiResponseModel.cameraList.count > cameraTimerCount {
                        startCameraTimer()
                    }
                }
            default:
                break
            }
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
    func stopCameraTimer(){
        if cameraTimer != nil {
            if cameraTimer.isValid {
                cameraTimer.invalidate()
                cameraTimerDuration = 0
                progressValue = 0
            }
        }
    }
    
    
    
    func stopTimer(){
        if timer != nil {
            if timer.isValid {
                timer.invalidate()
                duration = 0
            }
        }
        let myMutableString = NSMutableAttributedString(
            string: "",
            attributes: [NSAttachmentAttributeName : UIFont(
                name: "Georgia",
                size: 18.0)!])
        self.kareokeLabel.attributedText = myMutableString
    }
    
}

extension CameraViewController: AVCaptureFileOutputRecordingDelegate {
    func capture(_ output: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
        self.SHOW_SIC(type: .compressVideo)
        //For compress code
        guard let data = NSData(contentsOf: outputFileURL as URL) else {
            return
        }
        print("File size before compression: \(Double(data.length / 1048576)) mb")
        let compressedURL = NSURL.fileURL(withPath: NSTemporaryDirectory() + NSUUID().uuidString + ".output.mov")
        
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
                let filePath="\(documentsPath)/output.mov"
                print(filePath)
                self.HIDE_SIC(customView: self.view)
                self.uploadData["filePath"] = filePath as AnyObject
                self.uploadData["videoURL"] = compressedURL as AnyObject
                self.uploadData["userId"] = self.odileData.userId  as AnyObject
                self.uploadData["videoId"] = self.odileData.videoId as AnyObject
                self.goto(screenID: "PlayVideoControllerID", animated: true, data: self.uploadData as AnyObject, isModal: true)
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

