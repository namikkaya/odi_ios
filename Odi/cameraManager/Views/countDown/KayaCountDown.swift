//
//  countDown.swift
//  countDown
//
//  Created by Nok Danışmanlık on 12.06.2019.
//  Copyright © 2019 Brokoly. All rights reserved.
//

import UIKit
import AVFoundation

protocol KayaCountDownDelegate:class {
    func KayaCountDownComplete()
    func KayaCountDownStart()
}

class KayaCountDown: UIView, AVAudioPlayerDelegate {
    weak var setDelegate:KayaCountDownDelegate?
    private var view:UIView!
    private var nibName:String = "KayaCountDown"
    
    @IBOutlet var textLabel: UILabel!
    
    private var arrStr:[String] = ["...","3","2","1"]
    
    var player: AVAudioPlayer?
    
    var ditURL:URL?
    var ditFinalURL:URL?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    fileprivate func setup(){
        view = loadViewFromNib()
        view.frame = bounds
        view.autoresizingMask = [UIView.AutoresizingMask.flexibleWidth, UIView.AutoresizingMask.flexibleHeight]
        addSubview(view)
        
        
        runInit()
        
        guard let urlDit = Bundle.main.url(forResource: "countDown", withExtension: "wav") else { return }
        ditURL = urlDit
        
        guard let urlFinalDit = Bundle.main.url(forResource: "countDownFinal", withExtension: "wav") else { return }
        ditFinalURL = urlFinalDit
    }
    
    func loadViewFromNib()-> UIView {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: nibName, bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
        return view
    }
    
    fileprivate func runInit() {
        textLabel.isHidden = true
    }
    
    fileprivate var countDownTimer:Timer?
    fileprivate var count:Int = 0;
    
    public func begin() {
        startTimer()
    }
    
    fileprivate func startTimer() {
        setDelegate?.KayaCountDownStart()
        clearTimer()
        playSoundDit()
        if countDownTimer == nil {
            textLabel.isHidden = false
            textLabel.text = arrStr[0]
            count += 1
            
            //player?.play()
            countDownTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(fire(timer:)), userInfo: nil, repeats: true)
        }
    }
    
    fileprivate func clearTimer() {
        if countDownTimer != nil {
            countDownTimer?.invalidate()
            countDownTimer = nil
            count = 0
        }
    }
    
    @objc func fire(timer: Timer) {
        
        if (count >= arrStr.count) {
            clearTimer()
            // bitiş işlemi
            count = 0
            textLabel.isHidden = true
            textLabel.text = arrStr[0]
            playSoundFinalDit()
            player?.play()
            
            //setDelegate?.KayaCountDownComplete()
        }else {
            // normal işlem
            player?.play()
            textLabel.text = arrStr[count]
            count += 1
        }
        
    }
    
    public func stopCountDown() {
        clearTimer()
        guard let player = player else { return }
        player.pause()
        textLabel.isHidden = true
        textLabel.text = arrStr[0]
        count = 0
    }
    
    deinit {
        clearTimer()
        if (setDelegate != nil) {
            setDelegate = nil
        }
        
    }
    
    func playSoundDit() {
        guard let url = Bundle.main.url(forResource: "countDown", withExtension: "wav") else { return }
        
        do {
            //try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default)
            //try AVAudioSession.sharedInstance().setActive(true)
            
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            
            guard let player = player else { return }
            
            player.prepareToPlay()
            
            
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func playSoundFinalDit() {
        guard let url = Bundle.main.url(forResource: "countDownFinal", withExtension: "wav") else { return }
        
        do {
            //try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default)
            //try AVAudioSession.sharedInstance().setActive(true)
            
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            
            player?.delegate = self
            
            guard let player = player else { return }
            
            player.prepareToPlay()
            
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        setDelegate?.KayaCountDownComplete()
    }
    
    
    
}
