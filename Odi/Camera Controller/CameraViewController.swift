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
import CoreGraphics
import CoreText


class CameraViewController: UIViewController {
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        AppUtility.lockOrientation(.landscapeRight)
        addObserverForOdi()
        
        //Mark :- Download mp3 file
        
        
        if odiResponseModel.TIP != "1" {
            DispatchQueue.main.async {
                self.SHOW_SIC(type: .reload)
                self.downloadFile(Response: self.odiResponseModel.cameraList, downloadedCound: 0)
            }
        }
    }
    
    func downloadFile(Response getCameraList:[GetCameraList],downloadedCound: Int) {
        print(downloadedCound)
        if downloadedCound < getCameraList.count {
            if getCameraList[downloadedCound].type == "0"
            {
                let urlstring = API.fileApi.rawValue + getCameraList[downloadedCound].soundfile
                let url = NSURL(string: urlstring)
                downloadFileFromURL(url: url!, count: downloadedCound)
    
            } else if getCameraList[downloadedCound].type == "" {
                let urlstring = API.fileApi.rawValue + getCameraList[downloadedCound].soundfile
                let url = NSURL(string: urlstring)
                downloadFileFromURL(url: url!, count: downloadedCound)
            } else {
                let count = downloadedCound + 1
                self.downloadFile(Response: getCameraList, downloadedCound: count)
            }
            
        } else  {
            print(self.odiResponseModel.cameraList)
            self.clearTempFolder()
            self.HIDE_SIC(customView: self.view)
        }
        
    }
    
    func downloadFileFromURL(url:NSURL,count:Int){
        
        var downloadTask:URLSessionDownloadTask
        downloadTask = URLSession.shared.downloadTask(with: url as URL, completionHandler: { [weak self](URL, response, error) -> Void in
            
            let time = NSNumber(value:(NSDate().timeIntervalSince1970 * 1000))
            let fileName = NSString(format:"%@_music.mov",time)
            let documentsUrl:URL =  (FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first as URL?)!
            let destinationFileUrl = documentsUrl.appendingPathComponent(fileName as String)
            
            do {
                try FileManager.default.copyItem(at: URL!, to: destinationFileUrl)
            } catch (let writeError) {
                print("Error creating a file \(destinationFileUrl) : \(writeError)")
            }
            self?.odiResponseModel.cameraList[count].path = destinationFileUrl
            let count = count + 1
            self?.downloadFile(Response: (self?.odiResponseModel.cameraList)!, downloadedCound: count)
        })
        downloadTask.resume()
    }
    
    //Mark :- It's GG
    func clearTempFolder() {
        let fileManager = FileManager.default
        let tempFolderPath = NSTemporaryDirectory()
        do {
            let filePaths = try fileManager.contentsOfDirectory(atPath: tempFolderPath)
            for filePath in filePaths {
                try fileManager.removeItem(atPath: tempFolderPath + filePath)
            }
        } catch {
            print("Could not clear temp folder: \(error)")
        }
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
        self.removeObserverForOdi()
    }
    
    func addObserver(){
        NotificationCenter.default.addObserver(self, selector: #selector(self.goBack(notification:)), name: NSNotification.Name(rawValue: "transitionBack") , object: nil)
    }
    func removeObserver(){
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "transitionBack") , object: nil)
    }
    
    @objc func goBack(notification: NSNotification){
        if let navigationController = self.navigationController
        {
            AppUtility.lockOrientation(.portrait, andRotateTo: .portrait)
            self.clearTempFolder()
            let _ = navigationController.popViewController(animated: true)
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "transitionBackToWebview"), object: nil, userInfo: nil)
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
            cameraController.videoOutput?.startRecording(to: outputFileURL, recordingDelegate: self)
            
            
            //Button configure
            self.closeButton.isHidden = true
            self.swapCameraButton.isHidden = true
            captureButton.setImage(#imageLiteral(resourceName: "stop2"), for: .normal)
            
            startCameraTimer()
            
            
        } else {
            kareokeLabel.setContentOffset(.zero, animated: false)
            isRecording = false
            cameraController.videoOutput?.stopRecording()
            self.skipButton.isHidden = true
            self.skipButton2.isHidden = true
            self.stopTimer()
            self.cameraTimerCount = 0
            self.closeButton.isHidden = false
            self.swapCameraButton.isHidden = false
            self.audioPlayer.pausePlayer()
            self.audioPlayer.audioPlayerNil()
            self.progressView.progress = 0
            self.lines.removeAll()
            lineDuration = 0
            lineCharacterDuration = 0
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
            AppUtility.lockOrientation(.portrait, andRotateTo: .portrait)
            self.clearTempFolder()
            let _ = navigationController.popViewController(animated: true)
        }
    }
    
    @IBAction func skipButtonAction(_ sender: Any) {
        kareokeLabel.setContentOffset(.zero, animated: false)
        stopTimer()
        skipButton.isHidden = true
        skipButton2.isHidden = true
        self.progressView.progress = 0.0
        self.lines.removeAll()
        lineDuration = 0
        lineCharacterDuration = 0
        cameraTimerCount += 1
        startCameraTimer()
    }
    
    
    //Storyboard Veriable
    @IBOutlet weak var skipButton: UIButton!
    @IBOutlet weak var skipButton2: UIButton!
    
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var closeTitleButton: UIButton!
    @IBOutlet weak var swapCameraButton: UIButton!
    @IBOutlet weak var progressView: UIProgressView!
    
    @IBOutlet weak var kareokeLabel: UITextView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var transparenView: UIView!
    
    //FileOutPut
    var fileOutPut : AVCaptureFileOutput!
    
    //Support Classes
    let cameraController = CameraController()
    var audioPlayer = AudioPlayer()
    
    //Supporter Veriable
    var isRecording = false
    var isFrontCamera = true
    var isTextClosed = false
    //For timer
    var duration = 0
    var lineDuration = 0
    var lineCharacterDuration = 0
    var lines = [String]()
    
    var subtitleString = ""
    var timer = Timer()
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
        
        if odiResponseModel.TIP == "1" {
            subtitleString = odiResponseModel.cameraList[cameraTimerCount].text
            self.runTimer(interval: TimeInterval(Float(odiResponseModel.cameraList[cameraTimerCount].duration)! / Float(subtitleString.count)))
            UIView.animate(withDuration: TimeInterval(Float(odiResponseModel.cameraList[cameraTimerCount].duration)!) , animations: {
                self.progressView.progress = 1.0
                self.view.layoutIfNeeded()
            })
        } else if odiResponseModel.TIP == "2" {
            typeTwoOdiFunc()
        } else if odiResponseModel.TIP == "3" {
            audioPlayer.initialPlayer(resource: odiResponseModel.cameraList[cameraTimerCount].path! as NSURL)
            audioPlayer.playPlayer()
            UIView.animate(withDuration: TimeInterval(audioPlayer.playerGetDuration() + 1) , animations: {
                self.progressView.progress = 1.0
                self.view.layoutIfNeeded()
            })
        }
        
    }
    
    fileprivate func addObserverForOdi(){
        NotificationCenter.default.addObserver(self, selector: #selector(self.typeTwoOdiFunc), name: NSNotification.Name.typeTwoOdi, object: nil)
    }
    
    fileprivate func removeObserverForOdi(){
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.typeTwoOdi, object: nil)
    }
    
    @objc func typeTwoOdiFunc(){
        if odiResponseModel.cameraList.count > cameraTimerCount {
            switch odiResponseModel.cameraList[cameraTimerCount].type {
            case "0":
                audioPlayer.initialPlayer(resource: odiResponseModel.cameraList[cameraTimerCount].path! as NSURL)
                audioPlayer.playPlayer()
                subtitleString = odiResponseModel.cameraList[cameraTimerCount].text
                self.runTimer(interval: TimeInterval(Float(audioPlayer.playerGetDuration()) / Float(subtitleString.count)))
                progressValue = Double(1.0 / Float(subtitleString.count))
                skipButton.isHidden = true
                skipButton2.isHidden = true
            case "1":
                subtitleString = odiResponseModel.cameraList[cameraTimerCount].text
                self.runTimer(interval: TimeInterval(Float(odiResponseModel.cameraList[cameraTimerCount].duration)! / Float(subtitleString.count)))
                progressValue = Double(1.0 / Float(subtitleString.count))
                
            default:break
            }
        }
    }
    
    func runTimer(interval: TimeInterval) {
        if timer.isValid {
            timer.invalidate()
        }
        
        timer = Timer.scheduledTimer(timeInterval: interval, target: self,   selector: (#selector(self.updateTimer)), userInfo: nil, repeats: true)
    }
    
    @objc func updateTimer() {
        duration += 1
        lineCharacterDuration += 1
        
        
        if odiResponseModel.TIP == "2" {
            self.progressView.progress += Float(progressValue)
            
            switch odiResponseModel.cameraList[cameraTimerCount].type {
            case "0":
                self.kareokeLabel.attributedText = customAttiribitudText(fontColor: UIColor.odiColor)
            case "1":
                self.kareokeLabel.attributedText = customAttiribitudText(fontColor: UIColor.userColor)
                self.skipButton.isHidden = false
                self.skipButton2.isHidden = false
            default:break
            }
        } else {
            self.kareokeLabel.attributedText = customAttiribitudText(fontColor: UIColor.userColor)
        }
        
        if lines.count == 0 {
            self.lines = getLinesArrayOfString(in: kareokeLabel)
        }
        if kareokeLabel.contentSize.height > kareokeLabel.frame.height { //Scroll var mı kontrolü
            if lines.count != 0 {
                if lineCharacterDuration == lines[lineDuration].count {
                    if lineDuration < 1 || (lines.count - lineDuration) < 3 {
                        //İlk satır ve son 3 satırda scrrol yapmaması için.
                    } else {
                        if let fontUnwrapped = self.kareokeLabel.font{
                            print("\(lineDuration) satır bitti")
                            self.kareokeLabel.setContentOffset(CGPoint(x: 0, y: kareokeLabel.contentOffset.y + fontUnwrapped.lineHeight + 4.4), animated: true)
                        }
                    }
                    lineDuration += 1
                    lineCharacterDuration = 0
                }
                
            }
        }
        
        
        if duration == subtitleString.count {
            kareokeLabel.setContentOffset(.zero, animated: false)
            kareokeLabel.attributedText = freeAttiribitudText()
            self.progressView.progress = 0.0
            cameraTimerCount += 1
            duration = 0
            lineDuration = 0
            lineCharacterDuration = 0
            self.lines.removeAll()
            stopTimer()
            self.skipButton.isHidden = true
            self.skipButton2.isHidden = true
            if odiResponseModel.cameraList.count > cameraTimerCount {
                 NotificationCenter.default.post(name: NSNotification.Name.typeTwoOdi, object: nil, userInfo: nil)
            }
        }
    }
    
    func stopTimer(){
        if timer.isValid {
                timer.invalidate()
                duration = 0
        }
        self.kareokeLabel.attributedText = freeAttiribitudText()
    }
    
}


//Mark: -Compress File
extension CameraViewController: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        
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
        
        let videoAsset: AVAsset = AVAsset( url: inputURL )
        let clipVideoTrack = videoAsset.tracks(withMediaType: AVMediaType.video).first! as AVAssetTrack
        
        
        let composition = AVMutableComposition()
        composition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: CMPersistentTrackID())
        
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = CGSize(width: clipVideoTrack.naturalSize.width, height: clipVideoTrack.naturalSize.height)
        videoComposition.frameDuration = CMTimeMake(1, 30)
        
        let transformer = AVMutableVideoCompositionLayerInstruction(assetTrack: clipVideoTrack)
        
        let instruction = AVMutableVideoCompositionInstruction()
        let startTime = CMTimeMake(0, 1)
        let timeRange = CMTimeRangeMake(startTime, videoAsset.duration)
        instruction.timeRange = timeRange
        var transform = CGAffineTransform.identity
        
        
        
        if isFrontCamera {
            transform = transform.scaledBy(x: -1.0, y: 1.0)
            transform = transform.translatedBy(x: 0.0, y: clipVideoTrack.naturalSize.height)
            transform = transform.rotated(by: degreeToRadian(180.0))
            transform = transform.translatedBy(x: 0.0, y: 0.0)
        }
        
        
        transformer.setTransform(transform, at: kCMTimeZero)
        instruction.layerInstructions = [transformer]
        videoComposition.instructions = [instruction]
        
        
        //let urlAsset = AVURLAsset(url: inputURL, options: nil)
        guard let exportSession = AVAssetExportSession(asset: videoAsset, presetName: AVAssetExportPresetMediumQuality) else {
            handler(nil)
            return
        }
        
        
        exportSession.videoComposition = videoComposition
        exportSession.outputURL = outputURL
        exportSession.outputFileType = AVFileType.mov
        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.exportAsynchronously { () -> Void in
            handler(exportSession)
        }
        
        
        let popup = self.SHOW_SIC(type: .compressVideo)
        DispatchQueue.global(qos: .background).async { [weak self] () -> Void in
            while exportSession.status == .waiting || exportSession.status == .exporting {
                DispatchQueue.main.async { () -> Void in
                    popup?.setProgress(progressValue: exportSession.progress)
                }
            }
        }
    }
    func degreeToRadian(_ x: CGFloat) -> CGFloat {
        return .pi * x / 180.0
    }
    
    func squareVideoCompositionForAsset(asset: AVAsset) -> AVVideoComposition {
        let track = asset.tracks(withMediaType: AVMediaType.video)[0]
        let length = max(track.naturalSize.width, track.naturalSize.height)
        
        var transform = track.preferredTransform
        
        let size = track.naturalSize
        
        var scale = CGFloat()
        if (transform.a == 0 && transform.b == 1 && transform.c == -1 && transform.d == 0) {
            scale = -1
        }
        else if (transform.a == 0 && transform.b == -1 && transform.c == 1 && transform.d == 0) {
            scale = -1
        }
        else if (transform.a == 1 && transform.b == 0 && transform.c == 0 && transform.d == 1) {
            scale = 1
        }
        else if (transform.a == -1 && transform.b == 0 && transform.c == 0 && transform.d == -1) {
            scale = 1
        }
        
        transform = transform.translatedBy(x: scale * -(size.width - length) / 2, y: scale * -(size.height - length) / 2)
        transform = transform.rotated(by: degreeToRadian(90))
        
        let transformer = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        transformer.setTransform(transform, at: kCMTimeZero)
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: kCMTimeZero, duration: kCMTimePositiveInfinity)
        instruction.layerInstructions = [transformer]
        
        let composition = AVMutableVideoComposition()
        composition.frameDuration = CMTime(value: 1, timescale: 30)
        composition.renderSize = CGSize(width: length, height: length)
        composition.instructions = [instruction]
        
        return composition
    }
    
}

//Scrool textview
extension CameraViewController {
    
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

//MARK: - UITextView
extension UITextView{
    
    func numberOfLines() -> Int{
        if let fontUnwrapped = self.font{
            return Int(self.contentSize.height / fontUnwrapped.lineHeight)
        }
        
        return 0
    }
    
}

//Mark: -Attiribitud String
extension CameraViewController {
    func customAttiribitudText(fontColor: UIColor) -> NSMutableAttributedString {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineSpacing = 4.4
        let attributes:  [NSAttributedStringKey : Any] = [kCTParagraphStyleAttributeName as NSAttributedStringKey: paragraph]
        kareokeLabel.textContainerInset = .zero
        let myMutableString = NSMutableAttributedString(
            string: subtitleString,
            attributes: [kCTFontAttributeName as NSAttributedStringKey : UIFont(
                name: "Arial",
                size: 19.0)!])
        myMutableString.addAttributes(attributes, range: NSRange(
            location:0,
            length:duration))
        myMutableString.addAttribute(
            .foregroundColor,
            value: fontColor,
            range: NSRange(
                location:0,
                length:subtitleString.count))
        myMutableString.addAttribute(
            .foregroundColor,
            value: UIColor.white,
            range: NSRange(
                location:0,
                length:duration))
        return myMutableString
    }
    
    
    func freeAttiribitudText() -> NSMutableAttributedString {
        let myMutableString = NSMutableAttributedString(
            string: " ",
            attributes: [kCTFontAttributeName as NSAttributedStringKey : UIFont(
                name: "Arial",
                size: 19.0)!])
        return myMutableString
    }
    
    func getLinesArrayOfString(in label: UITextView) -> [String] {
        /// An empty string's array
        var linesArray = [String]()
        
        guard let text = label.text, let font = label.font else {return linesArray}
        
        let rect = label.frame
        
        let myFont: CTFont = CTFontCreateWithName(font.fontName as CFString, font.pointSize, nil)
        let attStr = NSMutableAttributedString(string: text)
        attStr.addAttribute(.font, value: myFont, range: NSRange(location: 0, length: attStr.length))
        
        let frameSetter: CTFramesetter = CTFramesetterCreateWithAttributedString(attStr as CFAttributedString)
        let path: CGMutablePath = CGMutablePath()
        path.addRect(CGRect(x: 0, y: 0, width: rect.size.width - 10, height: 100000), transform: .identity)
        
        let frame: CTFrame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, 0), path, nil)
        guard let lines = CTFrameGetLines(frame) as? [Any] else {return linesArray}
        
        for line in lines {
            
            let lineRef = line as! CTLine
            let lineRange: CFRange = CTLineGetStringRange(lineRef)
            let range = NSRange(location: lineRange.location, length: lineRange.length)
            let lineString: String = (text as NSString).substring(with: range)
            
            linesArray.append(lineString)
            
        }
        return linesArray
    }
    
}

//Mark :- For Exporter
extension CameraController {
    
}



extension NSNotification.Name {
    static let typeTwoOdi = NSNotification.Name("TypeTwoOdi")
}
extension UIColor {
    static let odiColor = UIColor(red: 0.0 / 255.0, green: 131.0 / 255.0, blue: 178.0 / 255.0, alpha: 1.0)
    static let userColor = UIColor(red: 255.0 / 255.0, green: 132.0 / 255.0, blue: 0.0 / 255.0, alpha: 1.0)
}

