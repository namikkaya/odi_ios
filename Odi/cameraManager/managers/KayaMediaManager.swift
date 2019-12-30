//
//  KayaMediaManager.swift
//  videoMuteSystem_hub
//
//  Created by namikkaya on 22.11.2019.
//  Copyright © 2019 brokoly. All rights reserved.
//

import UIKit


protocol KayaMediaManagerDelegate:class {
    func KayaMediaManagerDelegate_finish()
    func KayaMediaManagerDelegate_NextButtonHidden(status:Bool)
}

extension KayaMediaManagerDelegate {
    func KayaMediaManagerDelegate_finish(){}
    func KayaMediaManagerDelegate_NextButtonHidden(status:Bool){}
}

class KayaMediaManager: NSObject,
KayaAudioPlayerDelegate,
KayaKaraokeViewManagerDelegate{
    enum orientation{
        case Vertical
        case Horizontal
    }
    
    var TAG:String = "KayaMediaManager: "
    
    /// DELEGATE
    weak var setDelegate:KayaMediaManagerDelegate?
    
//    MARK: - VIEWS
    var verticalSubtitle:KayaKaraokeViewManager?
    var horizontalSubtitle:KayaKaraokeViewManager?
    var selectedSubtitle:KayaKaraokeViewManager?
    
    var slider:KayaSlider?
    
//    MARK: - VALUES
    private var isHiddenSubtitleHolder:Bool = true
    
    /// Altyazının gösterilip / gösterilmeyeceği kararı
    var isHiddenSubtitle:Bool {
        set {
            isHiddenSubtitleHolder = newValue
            subtitleHidden(status: isHiddenSubtitleHolder)
        }get{
            return isHiddenSubtitleHolder
        }
    }
    
    private var isVolumeStatusHolder:Bool = true
    /// Ses açıp kapatılacak bilgisi
    var isVolumeStatus: Bool {
        set {
            isVolumeStatusHolder = newValue
            if let player = player {
                if isVolumeStatusHolder {
                    player.volume = 1
                }else {
                    player.volume = 0
                }
            }
        }get {
            return isVolumeStatusHolder
        }
    }
    
    private func subtitleHidden (status:Bool) {
        if selectedSubtitle != nil {
            selectedSubtitle?.isHidden = !status
        }
    }
    
    private var subtitleDataHolder:[KayaSubtitleModel]?
    /// Altyazı ve ses bilgilerini tutar
    var subtitleData:[KayaSubtitleModel]? {
        set{
            subtitleDataHolder = newValue
        }get {
            return subtitleDataHolder
        }
    }
    
    func nextDialog() {
        nextStep()
    }
    
    var setSliderMin:Float = 0 {
        didSet {
            if let slider = slider {
                slider.minimumValue = setSliderMin
            }
        }
    }
    
    var setSliderMax:Float = 100 {
        didSet{
            if let slider = slider {
                slider.maximumValue = setSliderMax
            }
        }
    }
    
    var setSliderValue:Float = 0 {
        didSet {
            if let slider = slider {
                if setSliderValue == 0 {
                    slider.setValue(setSliderValue, animated: false)
                }else {
                    slider.setValue(setSliderValue, animated: true)
                }
                
            }
        }
    }
    
    
//    MARK: - CLASS
    private var player:KayaAudioPlayer?
    
    override init() {
        super.init()
    }

    /**
     Usage:  Altyazı view kullanımalrı için H ve V
     - Parameter HsubtitleView:  yatay view
     - Parameter VsubtitleView:  dikey view
     - Returns: No return value
     */

    init(horizontal HsubtitleView:KayaKaraokeViewManager?,
         vertical VsubtitleView:KayaKaraokeViewManager?,
         slider timerSlider:KayaSlider?) {
        super.init()
        
        slider = timerSlider
        slider?.maximumValue = 1
        slider?.minimumValue = 0
        
        verticalSubtitle = VsubtitleView
        horizontalSubtitle = HsubtitleView
    
        verticalSubtitle?.setDelegate = self
        horizontalSubtitle?.setDelegate = self
        
        player = KayaAudioPlayer()
        player?.setDelegate = self
        
        if isVolumeStatus {
            player?.volume = 1
        }else {
            player?.volume = 0
        }
    }
    
    func setDesing(orientation: orientation) {
        switch orientation {
        case .Vertical:
            verticalDesing()
            break
        case .Horizontal:
            horizontalDesing()
            break
        }
    }
    
    private func verticalDesing() {
        guard let verticalSubtitle = verticalSubtitle, let horizontalSubtitle = horizontalSubtitle else { return  }
        verticalSubtitle.isHidden = false
        horizontalSubtitle.isHidden = true
        
        selectedSubtitle = verticalSubtitle
        selectedSubtitle?.isHidden = !isHiddenSubtitle
    }
    
    private func horizontalDesing() {
        guard let verticalSubtitle = verticalSubtitle, let horizontalSubtitle = horizontalSubtitle else { return }
        verticalSubtitle.isHidden = true
        horizontalSubtitle.isHidden = false
        
        selectedSubtitle = horizontalSubtitle
        selectedSubtitle?.isHidden = !isHiddenSubtitle
    }
    
    /// altyazı numarasına göre dolar
    private var subtitleCounter:Int = 0
    private var playIDHolder:String?
    private var typeHolder:KAYA_SUBTITLE_TYPE?
    
    func start() {
        self.slider!.setValue(0, animated: false)
        startAudioPlayer()
        startSubtitle()
        startSlider()
        subtitleCounter += 1
    }
    
    private func startSlider () {
        let myDuration = self.subtitleData![self.subtitleCounter].duration!.rounded(toPlaces: 3)
        
        print("\(self.TAG): slider duration: \(myDuration)")

        DispatchQueue.main.async {
            UIView.animate(withDuration: myDuration, delay: 0.0, options: .curveEaseInOut, animations: {
                 self.slider!.setValue(1, animated: true)
            }) { (ct) in
                 //self.slider!.setValue(0, animated: false)
            }
        }
        
    }
    
    private func startSubtitle() {
        guard let subtitleData = subtitleData else { return }
        selectedSubtitle?.setKaraoke(string: subtitleData[subtitleCounter].text!,
                                     timeDuration: subtitleData[subtitleCounter].duration!,
                                     type: subtitleData[subtitleCounter].type!)
        
    }
    
    private func startAudioPlayer() {
        guard let subtitleData = subtitleData else { return }
        
        if subtitleData[subtitleCounter].type == KAYA_SUBTITLE_TYPE.speaker {
            typeHolder = .speaker
            if subtitleData[subtitleCounter].soundURL != nil {
                player?.playSound(filePath: subtitleData[subtitleCounter].soundURL, id: String(subtitleData[subtitleCounter].id!))
            }
            // next button gizle -->
            setDelegate?.KayaMediaManagerDelegate_NextButtonHidden(status: true)
        }else {
            typeHolder = .mySelf
            // next button göster -->
            setDelegate?.KayaMediaManagerDelegate_NextButtonHidden(status: false)
        }
        
    }
    
    /// audio player hazır duruma getirilir.
    private func playerRelease() {
        player?.stopSound()
    }
    
    private func subtitleTextRelease() {
        selectedSubtitle?.deStroy()
    }
    
    private func sliderRelease() {
        print("zaman: 0")
        DispatchQueue.main.async {
            self.setSliderValue = 0
        }
    }
    
//    MARK: - Audio Functions
    //setKaraoke --
    
    
    /// seslerin tamamı bittiğinde veya kaydetme işlemi durdurulduğunda tetiklenmesi gerekir
    func finish() {
        playerRelease()
        subtitleTextRelease()
        sliderRelease()
        subtitleCounter = 0
        typeHolder = nil
        setDelegate?.KayaMediaManagerDelegate_finish()
    }
    
    /// çalan ses bittiğinde tetiklenir....
    private func audioFinish(id:String?) {
        checkFinishAudioAndText(type: KayaMediaManager.finishType.audio, status: true)
    }
    
//    MARK: - Finish chapter
    
    var audioFinishStatus:Bool = false
    var textFinishStatus:Bool = false
    enum finishType {
        case audio
        case text
    }
    
    
    private func checkFinishAudioAndText(type:finishType, status:Bool) {
        
        if type == finishType.audio && status{
            audioFinishStatus = true
            print("\(self.TAG): Ses dosyası bitiş")
        }else if type == finishType.text && status {
            textFinishStatus = true
            print("\(self.TAG): Text dosyası bitiş")
        }
        
        if typeHolder == KAYA_SUBTITLE_TYPE.speaker {
            if audioFinishStatus && textFinishStatus {
                audioFinishStatus = false
                textFinishStatus = false
                /// diğer elemana geçiş buradan yapılması gerekiyor...
                guard let subtitleData = subtitleData else { return }
                if subtitleCounter >= subtitleData.count {
                    finish()
                }else {
                    playerRelease()
                    subtitleTextRelease()
                    sliderRelease()
                    start()
                }
            }
        }else {
            if textFinishStatus {
                audioFinishStatus = false
                textFinishStatus = false
                guard let subtitleData = subtitleData else { return }
                if subtitleCounter >= subtitleData.count {
                    finish()
                }else {
                    playerRelease()
                    subtitleTextRelease()
                    sliderRelease()
                    start()
                }
            }
        }
    }
    
    private func nextStep() {
        audioFinishStatus = false
        textFinishStatus = false
        guard let subtitleData = subtitleData else { return }
        if subtitleCounter >= subtitleData.count {
            finish()
        }else {
            playerRelease()
            subtitleTextRelease()
            sliderRelease()
            start()
        }
    }
    
//    MARK: - KayaAudioPlayer Delegate
    
    func KayaAudioPlayerDelegate_Trigger(id: String?,
                                         status: KAYA_AUDIO_PLAYER_STATUS?) {
        
        guard let status = status, let id = id else { return }
        switch status {
        case .PLAY:
            playIDHolder = id
            break
        case .FINISH:
            audioFinish(id: id)
            break
        case .PREPARE:
            
            break
        case .STOP:
            
            break
        case .ERROR:
            
            break
        }
    }
//    MARK: - KayaKaraokeViewManagerDelegate
    
    func KayaKaraokeViewManagerDelegate_FinishParagraph() {
        checkFinishAudioAndText(type: KayaMediaManager.finishType.text, status: true)
    }
}
