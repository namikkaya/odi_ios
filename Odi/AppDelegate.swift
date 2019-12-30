//
//  AppDelegate.swift
//  Odi
//
//  Created by bilal on 21/12/2017.
//  Copyright © 2017 bilal. All rights reserved.
//

import UIKit
import WebKit
import OneSignal
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, OSSubscriptionObserver {

    var window: UIWindow?
    var orientationLock = UIInterfaceOrientationMask.portrait
    var firstLogin = true
   
    
    
    func configureOneSignal(options : [UIApplication.LaunchOptionsKey: Any]?) {
        
        let notificationReceivedBlock: OSHandleNotificationReceivedBlock = { notification in
            
        }
        
        let notificationOpenedBlock: OSHandleNotificationActionBlock = { result in
            
        }
        
        
        OneSignal.idsAvailable { (pushID, pushToken) in
            if let playerId = pushID {
                print("Current playerId \(playerId)")
                UserPrefence.saveOneSignalId(id: playerId)
            }
        }
        
        let onesignalInitSettings = [kOSSettingsKeyAutoPrompt: false,
                                     kOSSettingsKeyInAppLaunchURL: true]
        
        OneSignal.initWithLaunchOptions(options,
                                        appId: "237ba484-e8cd-450f-8cde-57f8fd7e3569",
                                        handleNotificationReceived: notificationReceivedBlock,
                                        handleNotificationAction: notificationOpenedBlock,
                                        settings: onesignalInitSettings)
        
        OneSignal.inFocusDisplayType = OSNotificationDisplayType.notification
        OneSignal.add(self as OSSubscriptionObserver)
        OneSignal.promptForPushNotifications(userResponse: { accepted in
            print("User accepted notifications: \(accepted)")
        })
    }
    
    func onOSSubscriptionChanged(_ stateChanges: OSSubscriptionStateChanges!) {
        if !stateChanges.from.subscribed && stateChanges.to.subscribed {
            print("Subscribed for OneSignal push notifications!")
        }
        
        
        if let playerId = stateChanges.to.userId {
            print("Current playerId \(playerId)")
            UserPrefence.saveOneSignalId(id: playerId)
        }
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        configureOneSignal(options: launchOptions)
        /*let onesignalInitSettings = [kOSSettingsKeyAutoPrompt: false]
        
        // Replace 'YOUR_APP_ID' with your OneSignal App ID.
        OneSignal.initWithLaunchOptions(launchOptions,
                                        appId: "237ba484-e8cd-450f-8cde-57f8fd7e3569",
                                        handleNotificationAction: nil,
                                        settings: onesignalInitSettings)
        
        OneSignal.inFocusDisplayType = OSNotificationDisplayType.notification;
        
        // Recommend moving the below line to prompt for push after informing the user about
        //   how your app will use them.
        OneSignal.promptForPushNotifications(userResponse: { accepted in
            print("User accepted notifications: \(accepted)")
        })*/
        FirebaseApp.configure()
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        print("ARKA PLANA İTELENDİ")
        NotificationCenter.default.post(name: NSNotification.Name.ODI.APP_WILL_BACKGROUND, object: nil, userInfo: nil)
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return self.orientationLock
    }


}

