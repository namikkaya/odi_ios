//
//  CameraController.swift
//  AV Foundation
//
//  Created by Pranjal Satija on 29/5/2017.
//  Copyright © 2017 AppCoda. All rights reserved.
//

import AVFoundation
import UIKit

class CameraController: NSObject {
    lazy var captureSession: AVCaptureSession = {
        let session = AVCaptureSession()
        session.sessionPreset = AVCaptureSessionPresetHigh
        return session
    }()
    
    var videoOutput: AVCaptureMovieFileOutput?
    //Input devices
    var currentDevice: AVCaptureDevice?
    var audioDevice: AVCaptureDevice?
    
    var previewLayer: AVCaptureVideoPreviewLayer?
        
}

extension CameraController {
    
    func prepareBackVideo(view: UIView){
        // Selecting input device
        
        if let device = AVCaptureDevice.defaultDevice(withDeviceType: AVCaptureDeviceType.builtInDuoCamera, mediaType: AVMediaTypeVideo, position: .front) {
            currentDevice = device
        }else if let device = AVCaptureDevice.defaultDevice(withDeviceType: AVCaptureDeviceType.builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .front) {
            currentDevice = device
            
        }
        if let audioDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio) {
            self.audioDevice = audioDevice
        }
        
        
        // Get the input data source
        guard let captureDeviceInput = try? AVCaptureDeviceInput(device: currentDevice!) else { return }
        guard let captureAudioDeviceInput = try? AVCaptureDeviceInput(device: audioDevice!) else { return }

        
        
        videoOutput = AVCaptureMovieFileOutput()
        
        // Configure the session with the input and the output devices
        if captureSession.canAddInput(captureDeviceInput) && captureSession.canAddInput(captureAudioDeviceInput) {
            captureSession.addInput(captureDeviceInput)
            captureSession.addInput(captureAudioDeviceInput)
            if captureSession.canAddOutput(videoOutput!) {
                captureSession.addOutput(videoOutput!)
            } else {
                print("captureSession can't add output")
            }
        } else {
            print("captureSession can't add input")
        }        
        
        // Configure camera preview layer
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.connection.videoOrientation = .landscapeRight
        view.layer.addSublayer(previewLayer!)
        previewLayer?.videoGravity = AVLayerVideoGravityResize
        previewLayer?.frame = view.layer.frame
       
        
        // Start captureSession
        captureSession.startRunning()
    }
    
    func swapCamera() {
        
        // Get current input
        guard let input = captureSession.inputs[0] as? AVCaptureDeviceInput else { return }
        guard let inputAudio = captureSession.inputs[1] as? AVCaptureDeviceInput else { return }
        
        // Begin new session configuration and defer commit
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }
        
        // Create new capture device
        var newDevice: AVCaptureDevice?
        var newAudioDevice : AVCaptureDevice?
        if let audioDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio) {
            newAudioDevice = audioDevice
        }
        
        if input.device.position == .back {
            newDevice = captureDevice(with: .front)
        } else {
            newDevice = captureDevice(with: .back)
        }
        
        // Create new capture input
        guard let captureDeviceInput = try? AVCaptureDeviceInput(device: newDevice!) else { return }
        guard let captureAudioDeviceInput = try? AVCaptureDeviceInput(device: newAudioDevice!) else { return }
        
        // Swap capture device inputs
        captureSession.removeInput(input)
        captureSession.removeInput(inputAudio)
        captureSession.addInput(captureDeviceInput)
        captureSession.addInput(captureAudioDeviceInput)
    }
    
    /// Create new capture device with requested position
    fileprivate func captureDevice(with position: AVCaptureDevicePosition) -> AVCaptureDevice? {
        
        let devices = AVCaptureDeviceDiscoverySession(deviceTypes: [ .builtInWideAngleCamera, .builtInMicrophone, .builtInTelephotoCamera ], mediaType: AVMediaTypeVideo, position: .unspecified).devices
        
        if let devices = devices {
            for device in devices {
                if device.position == position {
                    return device
                }
            }
        }
        
        return nil
    }
    
    
    func flashOn(device:AVCaptureDevice)
    {
        do{
            if (device.hasTorch)
            {
                try device.lockForConfiguration()
                device.torchMode = .on
                device.flashMode = .on
                device.unlockForConfiguration()
            }
        }catch{
            //DISABEL FLASH BUTTON HERE IF ERROR
            print("Device tourch Flash Error ");
        }
    }
    
    func flashOff(device:AVCaptureDevice)
    {
        do{
            if (device.hasTorch){
                try device.lockForConfiguration()
                device.torchMode = .off
                device.flashMode = .off
                device.unlockForConfiguration()
            }
        }catch{
            //DISABEL FLASH BUTTON HERE IF ERROR
            print("Device tourch Flash Error ");
        }
    }
    
}

