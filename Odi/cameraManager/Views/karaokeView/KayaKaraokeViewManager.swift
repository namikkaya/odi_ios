//
//  karaokeViewManager.swift
//  karaoke_text
//
//  Created by namikkaya on 15.05.2019.
//  Copyright © 2019 Brokoly. All rights reserved.
//

import UIKit

/**
 Usage: Altyazı tipi enum
 - Parameter mySelf:  Kendi okuyacağı altyazı tipi
 - Parameter speaker:  Dış ses
 */
enum KAYA_SUBTITLE_TYPE {
    case mySelf
    case speaker
}

protocol KayaKaraokeViewManagerDelegate:class {
    func KayaKaraokeViewManagerDelegate_FinishParagraph()
}

extension KayaKaraokeViewManagerDelegate {
    func KayaKaraokeViewManagerDelegate_FinishParagraph() {}
}

@IBDesignable class KayaKaraokeViewManager: UIView {
    private let TAG:String = "KayaKaraokeViewManager:"
    private var view:UIView!
    private var nibName:String = "KayaKaraokeViewManager"
    @IBOutlet var textView: UITextView!
    
    weak var setDelegate:KayaKaraokeViewManagerDelegate?
    
    var selectedFontColor:UIColor = .red
    var defaultFontColor:UIColor = .white
    
    var textTimeInterval:TimeInterval?
    var textTimer:Timer?
    
    var count:Int = 0
    var length:Int = 0
    
    var lines:[String] = []
    var lineCount:Int = 0
    var lineCharacterDuration:Int = 0
    
    var fontSize:CGFloat = 19
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup(){
        view = loadViewFromNib()
        view.frame = bounds
        view.autoresizingMask = [UIView.AutoresizingMask.flexibleWidth, UIView.AutoresizingMask.flexibleHeight]
        addSubview(view)
        
        configuration()
    }
    
    func loadViewFromNib()-> UIView {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: nibName, bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
        return view
    }
    
    fileprivate func configuration() {
        textView.isUserInteractionEnabled = false
    }
    
    /**
     Usage:  Bilgiler gönderildiğinde işlem başlatılır.
     - Parameter string:  Altyazı text
     - Parameter timeDuration: Toplam altyazının akacağı zaman
     - Parameter type: Altyazı dış ses mi yoksa kendisi mi bilgisi
     - Parameter type: font size
     - Returns: No return value
     */
    func setKaraoke(string:String, timeDuration:Double, type:KAYA_SUBTITLE_TYPE, fontSize:CGFloat = 19) {
        textView.attributedText = emptyText()
        
        print("subtitle: setKaraoke: ")
        
        self.fontSize = fontSize
        switch type {
        case .mySelf:
            selectedFontColor = UIColor.userColor
            break
        case .speaker:
            selectedFontColor = UIColor.odiColor
            break
        }
        
        deStroy()
        
        let myMutableString = NSMutableAttributedString(string: string,
                                                        attributes: [kCTFontAttributeName as NSAttributedString.Key : UIFont(name: "Arial",size: self.fontSize)!])
        
        firstSetKaraoke(karaokeFontColor: selectedFontColor, bgFontColor: defaultFontColor, string: string)
        
        let tDuration = Float(timeDuration)
        let strLength = Float(myMutableString.length)
        length = myMutableString.length // karakter uzunluğu
        lines = getLinesArrayOfString(in: textView)
        
        
        let characterTime:TimeInterval = TimeInterval(tDuration/strLength) // karakter başına geçilecek zaman
        setKaraokeAnimation(string: string, characterTime: characterTime)
        //        print("tDuration: \(tDuration)")
        //        print("strLength: \(strLength)")
        //        print("characterTime: \(characterTime)")
        //        print("çağırılma saysıı")
    }
    
    fileprivate func firstSetKaraoke(karaokeFontColor:UIColor, bgFontColor:UIColor, string:String) {
        textView.attributedText = emptyText()
        textView.attributedText = setStepPaintText(kareokeFontColor: karaokeFontColor,
                                                   bgFontColor: bgFontColor,
                                                   titleString: string,
                                                   selectedTextLimit: count)
        textView.contentOffset.y = 0
        textView.isScrollEnabled = false
        textView.layoutIfNeeded() //if don't work, try to delete this line
        textView.isScrollEnabled = true
    }
    
    fileprivate func setKaraokeAnimation(string:String, characterTime:TimeInterval) {
        textView.attributedText = emptyText()
        let userInfo:[String:Any] = ["karaokeFontColor": selectedFontColor, "bgFontColor":defaultFontColor, "string":string]
        firstSetTextRequest(userInfo: userInfo)
        textTimer = Timer.scheduledTimer(timeInterval: characterTime, target: self, selector: #selector(fireTimer), userInfo: userInfo, repeats: true)
    }
    
    private func firstSetTextRequest(userInfo:[String:Any]) {
        let _:UIColor = userInfo["karaokeFontColor"] as! UIColor
        let bgFontColor:UIColor = userInfo["bgFontColor"] as! UIColor
        let string:String = userInfo["string"] as! String
        
        textView.attributedText = setStepPaintText(kareokeFontColor: UIColor.white,
                                                   bgFontColor: bgFontColor,
                                                   titleString: string,
                                                   selectedTextLimit: 1)
    }
    
    @objc func fireTimer(timer:Timer) {
        if(length == count) {
            if textTimer != nil {
                textTimer?.invalidate()
                textTimer = nil
            }
            print("\(self.TAG): BİTTİ----- subttile")
            setDelegate?.KayaKaraokeViewManagerDelegate_FinishParagraph()
            return
        }
        
        if textTimer != nil {
            if  let userInfo = timer.userInfo as? [String: Any] {
                count = count + 1
                
                let karaokeFontColor:UIColor = userInfo["karaokeFontColor"] as! UIColor
                let bgFontColor:UIColor = userInfo["bgFontColor"] as! UIColor
                let string:String = userInfo["string"] as! String
                
                textView.attributedText = setStepPaintText(kareokeFontColor: karaokeFontColor,
                                                           bgFontColor: bgFontColor,
                                                           titleString: string,
                                                        selectedTextLimit: count)
                
            }else {
                if textTimer != nil {
                    textTimer?.invalidate()
                    textTimer = nil
                }
            }
        }
        
    }
    
    fileprivate func setStepPaintText(kareokeFontColor:UIColor,
                                      bgFontColor:UIColor = UIColor.black,
                                      titleString:String,
                                      selectedTextLimit:Int) -> NSMutableAttributedString {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineSpacing = 4.4
        
        let attributes:  [NSAttributedString.Key : Any] = [kCTParagraphStyleAttributeName as NSAttributedString.Key: paragraph]
        
        textView.textContainerInset = .zero
        
        let myMutableString = NSMutableAttributedString( string: titleString,
                                                         attributes: [kCTFontAttributeName as NSAttributedString.Key : UIFont(name: "Arial", size: self.fontSize)!])
        
        myMutableString.addAttributes(attributes,
                                      range: NSRange(location: 0, length: selectedTextLimit))
        
        myMutableString.addAttribute(.foregroundColor,
                                     value: bgFontColor,
                                     range: NSRange(location:0, length: titleString.count))
        
        myMutableString.addAttribute(.foregroundColor,
                                     value: kareokeFontColor,
                                     range: NSRange(location:0, length: selectedTextLimit))
        
        myMutableString.addAttribute(NSAttributedString.Key.shadow,
                                     value: UIColor.red,
                                     range: NSRange(location: 0, length: titleString.count))
        
        let myShadow = NSShadow()
        myShadow.shadowBlurRadius = 1
        myShadow.shadowOffset = CGSize(width: 1, height: 1)
        myShadow.shadowColor = UIColor.black
        
        let myAttribute = [ NSAttributedString.Key.shadow: myShadow ]
        myMutableString.addAttributes(myAttribute, range: NSRange(location:0, length: titleString.count))
        
        setScrollLine()
        return myMutableString
    }
    
    func emptyText() -> NSMutableAttributedString {
        let myMutableString = NSMutableAttributedString(string: "",
                                                        attributes: [kCTFontAttributeName as NSAttributedString.Key : UIFont(name: "Arial",size: self.fontSize)!])
        return myMutableString
    }
    
    /// satır satır ayırıp geri gönderir.
    fileprivate func getLinesArrayOfString(in label: UITextView) -> [String] {
        
        var linesArray = [String]()
        
        guard let text = label.text, let font = label.font else {return linesArray}
        
        var rect = label.frame
        
        rect.size.width = self.frame.size.width
        
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
    
    fileprivate func setScrollLine() {
        lineCharacterDuration += 1
        if textView.contentSize.height > textView.frame.height { //Scroll var mı kontrolü
            if lines.count != 0 {
                if (lineCount < lines.count) { // bu kısım eklendi
                    if lineCharacterDuration == lines[lineCount].count {
                        let calc = textView.contentSize.height - textView.frame.size.height
                        // en son bottom lar birbirine oturduğunu anda scroll yapma
                        if lineCount < 1 || calc < textView.contentOffset.y { //|| (lines.count - lineCount) < 3
                            //İlk satır ve son 3 satırda scrrol yapmaması için.
                            //print("Scroll yapmasın")
                        } else {
                            if let fontUnwrapped = self.textView.font{
                                self.textView.setContentOffset(CGPoint(x: 0, y: textView.contentOffset.y + fontUnwrapped.lineHeight + 4.4), animated: true)
                            }
                        }
                        lineCount += 1
                        lineCharacterDuration = 0
                    }
                }
            }
        }
    }
    
    func stopKareoke() {
        if textTimer != nil {
            textTimer?.invalidate()
            textTimer = nil
        }
        textView.attributedText = emptyText()
    }
    
    func deStroy() {
        if textTimer != nil {
            textTimer?.invalidate()
            textTimer = nil
        }
        textView.attributedText = emptyText()
        count = 0
        length = 0
        lines.removeAll()
        lines = []
        lineCount = 0
        lineCharacterDuration = 0
        if (textTimer != nil) {
            textTimer?.invalidate()
            textTimer = nil
        }
        if textTimeInterval != nil {
            textTimeInterval = nil
        }
    }
    
    deinit {
        deStroy()
    }
}
