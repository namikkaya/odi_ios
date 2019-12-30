//
//  UserDefaults.swift
//  Odi
//
//  Created by Baran Karaoğuz on 15.11.2018.
//  Copyright © 2018 bilal. All rights reserved.
//

import Foundation
import UIKit

class UserPrefences {
    // photo collage tool tip ilk defa görecek kontrolü
    static func getPhotoCollageFirstLook() -> Bool?{
        if UserDefaults.standard.object(forKey: "photoLook") != nil {
            return (UserDefaults.standard.object(forKey: "photoLook") != nil)
        }else {
            return false
        }
    }
    static func setPhotoCollageFirstLook(value:Bool) {
        UserDefaults.standard.set(value, forKey: "photoLook")
    }
    
    
    
    // camera tool tip ilk defa görecek kontrolü
    static func getCameraFirstLook() -> Bool?{
        if UserDefaults.standard.object(forKey: "cameraLook") != nil {
            return (UserDefaults.standard.object(forKey: "cameraLook") != nil)
        }else {
            return false
        }
    }
    // camera tool tip ilk defa görecek yazma
    static func setCameraFirstLook(value:Bool) {
        UserDefaults.standard.set(value, forKey: "cameraLook")
    }
    
    static func getPlayerFirstLook() -> Bool?{
        if UserDefaults.standard.object(forKey: "playerLook") != nil {
            return (UserDefaults.standard.object(forKey: "playerLook") != nil)
        }else {
            return false
        }
    }
    // player tool tip ilk defa görecek yazma
    static func setPlayerFirstLook(value:Bool) {
        UserDefaults.standard.set(value, forKey: "playerLook")
    }
    
    
    static func setBigKolajPhoto(isValue : UIImage!){
        UserDefaults.standard.set(isValue.pngData(), forKey: bigKolajImage)
    }
    
    static func getBigKolojPhoto() -> UIImage!{
        if let  returnIsTrueAnswer = UserDefaults.standard.object(forKey: bigKolajImage) {
            let returnImage : UIImage = UIImage(data: returnIsTrueAnswer as! Data)!
            return returnImage
        }
        else {
            return nil
        }
    }
    
    static func setsmallKolajOnePhoto(isValue : UIImage!){
        UserDefaults.standard.set(isValue.pngData(), forKey: smallKolajOneImage)
    }
    static func getsmallKolajOnePhoto() -> UIImage!{
        if let  returnIsTrueAnswer = UserDefaults.standard.object(forKey: smallKolajOneImage) {
            let returnImage : UIImage = UIImage(data: returnIsTrueAnswer as! Data)!
            return returnImage
        }
        else {
            return nil
        }
    }
    
    static func setsmallKolajTwoPhoto(isValue : UIImage!){
        UserDefaults.standard.set(isValue.pngData(), forKey: smallKolajTwoImage)
    }
    static func getsmallKolajTwoPhoto() -> UIImage!{
        if let  returnIsTrueAnswer = UserDefaults.standard.object(forKey: smallKolajTwoImage) {
            let returnImage : UIImage = UIImage(data: returnIsTrueAnswer as! Data)!
            return returnImage
        }
        else {
            return nil
        }
    }
    
    private static let bigKolajImage        = "bigKolajImage"
    private static let smallKolajOneImage   = "smallKolajOneImage"
    private static let smallKolajTwoImage   = "smallKolajTwoImage"
    
    private static let imageSliderStatus = "imageSliderStatus"

    static func imageSliderCheck () -> String {
        if let check = UserDefaults.standard.object(forKey: imageSliderStatus) as? String {
            if check == "OK" {
                return "OK"
            }else {
                return "NO"
            }
        }else{
            return "NO"
        }
    }
    
    static func imageSliderOK() {
        UserDefaults.standard.set("OK", forKey: imageSliderStatus)
    }
    
    static func imageSliderClear() {
        UserDefaults.standard.removeObject(forKey: imageSliderStatus)
    }
}
