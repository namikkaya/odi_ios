//
//  myExtension.swift
//  Odi
//
//  Created by Nok Danışmanlık on 3.04.2019.
//  Copyright © 2019 bilal. All rights reserved.
//

import Foundation
import UIKit

extension Notification.Name {
    public struct ODI {
        /// internet bağlantı durumlarını haber verir
        public static let INTERNET_CONNECTION_STATUS = Notification.Name(rawValue: "internet_connection_Status")
        public static let CHECK_PERMISSION = Notification.Name(rawValue: "check_permission")
        public static let APP_WILL_BACKGROUND = Notification.Name(rawValue: "app_will_background")
    }
}

extension UIView {

    func takeScreenshot() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, UIScreen.main.scale)
        drawHierarchy(in: self.bounds, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        if (image != nil)
        {
            return image!
        }
        return UIImage()
    }
    
    func snapshot() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: self.bounds.size)
        let image = renderer.image { ctx in
            self.drawHierarchy(in: self.bounds, afterScreenUpdates: true)
        }
        return image
    }
}
