//
//  AppDelegate.swift
//  labs
//
//  Created by Park Il Su on 2015. 5. 14..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit
import Raygun4iOS

enum AppLinkParam {
    case SHARED_TRACK(String)
    case SHARED_PLAYLIST(String)
    case USER(String)
    case USER_TRACK(user: String, track: String)
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    var reachability: Reachability?
    var networkStatus = NetworkStatus.NotReachable
    
    var appLink: AppLinkParam?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        UINavigationBar.appearance().tintColor = UIColor.dropbeatColor()
        self.window?.backgroundColor = UIColor.whiteColor()
        
        self.applicationWillEnterForeground(application)
        
        if let fromUrl = launchOptions?[UIApplicationLaunchOptionsURLKey] as? NSURL {
            handleCustomURL(fromUrl)
        }
        
        // GA settings
        let gai = GAI.sharedInstance()
        // optional
        gai.trackUncaughtExceptions = true
        gai.dispatchInterval = 20
        gai.logger.logLevel = GAILogLevel.Error
        gai.trackerWithTrackingId("UA-49094112-1")
        
        reachability = Reachability(hostName: "www.google.com")
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "networkReachabilityChanged:", name: kReachabilityChangedNotification, object: reachability)
        reachability!.startNotifier()
        
        Raygun.sharedReporterWithApiKey("5vjswgUxxTkQxkoeNzkJeg==")
        
        return FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    override func remoteControlReceivedWithEvent(event: UIEvent?) {
        DropbeatPlayer.defaultPlayer.remoteControlReceivedWithEvent(event)
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        loadAccountInfo()
    }

    func applicationDidBecomeActive(application: UIApplication) {
        FBSDKAppEvents.activateApp()
    }
}

extension AppDelegate {
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        completionHandler(UIBackgroundFetchResult.NewData)
        
        print(userInfo)
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        let characterSet: NSCharacterSet = NSCharacterSet( charactersInString: "<>" )
        
        let deviceTokenString: String = ( deviceToken.description as NSString )
            .stringByTrimmingCharactersInSet( characterSet )
            .stringByReplacingOccurrencesOfString( " ", withString: "" ) as String
        
        print("Registered device token: \(deviceTokenString)")
        
        Requests.sendPost(ApiPath.userUpdateDeviceID,
            params: ["key":deviceTokenString, "type":"IOS"],
            auth: true) { (result, error) -> Void in
                if error != nil {
                    print("Update device token FAILED: \(error!)")
                } else {
                    print("Updated device token: \(result!)")
                }
        }
        
        let settings: UIUserNotificationSettings = UIUserNotificationSettings( forTypes: [.Badge, .Alert, .Sound], categories: nil )
        application.registerUserNotificationSettings(settings)
    }
    
    func application( application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError ) {
        print("Register device token FAILED: \(error.localizedDescription)")
    }
}

extension AppDelegate {
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        handleCustomURL(url)
        return FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)
    }
    
    func handleCustomURL(url:NSURL) {
        if url.scheme == ExternalUrlKey.scheme && url.host == ExternalUrlKey.defaultIdentifier {
            var param: AppLinkParam?
            
            if let query = url.getKeyVals() where query.count == 1 {
                if let sharedTrackUid = query["track"] {
                    param = .SHARED_TRACK(sharedTrackUid)
                } else if let sharedPlaylistUid = query["playlist"] {
                    param = .SHARED_PLAYLIST(sharedPlaylistUid)
                }
            } else {
                var components = url.pathComponents!
                switch components.count {
                case 3:
                    if let user = components.popLast() {
                        param = .USER(user)
                    }
                case 4:
                    if let track = components.popLast(), user = components.popLast() {
                        param = AppLinkParam.USER_TRACK(user: user, track: track)
                    }
                default:
                    break
                }
            }
            
            if param != nil {
                self.appLink = param
                NSNotificationCenter.defaultCenter().postNotificationName(NotifyKey.fromAppLink, object: nil)
            } else {
                print("invalid custom url: \(url)")
            }
        }
    }
}

extension AppDelegate {
    func loadAccountInfo() {
        Account.loadLocation { (dict) -> Void in }
        
        if let account = Account.getCachedAccount() {
            account.syncLikeInfo{ (error) -> Void in
                if error != nil {
                    if self.window != nil && self.window!.rootViewController != nil{
                        ViewUtils.showConfirmAlert(
                            self.window!.rootViewController!,
                            title: NSLocalizedString("Failed to load", comment:""),
                            message: NSLocalizedString("Failed to fetch user like information.", comment:""),
                            positiveBtnText: NSLocalizedString("Retry", comment: ""),
                            positiveBtnCallback: { () -> Void in
                                self.loadAccountInfo()
                        })
                    }
                    return
                }
            }
            
            account.syncFollowingInfo { (error) -> Void in
                if error != nil {
                    if self.window != nil && self.window!.rootViewController != nil{
                        ViewUtils.showConfirmAlert(
                            self.window!.rootViewController!,
                            title: NSLocalizedString("Failed to load", comment:""),
                            message: NSLocalizedString("Failed to fetch user following information.", comment:""),
                            positiveBtnText: NSLocalizedString("Retry", comment: ""),
                            positiveBtnCallback: { () -> Void in
                                self.loadAccountInfo()
                        })
                    }
                    return
                }
            }
        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)
        let touch = event!.allTouches()?.first
        let location = touch!.locationInView(self.window)
        let statusBarFrame = UIApplication.sharedApplication().statusBarFrame
        if (CGRectContainsPoint(statusBarFrame, location)) {
            NSNotificationCenter.defaultCenter().postNotificationName(NotifyKey.statusBarTapped, object: nil)
        }
    }
    
    func setRootViewToStartupViewController () {
        if let old = self.window?.rootViewController {
            old.view.removeFromSuperview()
            old.removeFromParentViewController()
            self.window?.rootViewController = nil
        }
        
        let storyboard = UIStoryboard(name: "Launch", bundle: nil)
        let startupVC = storyboard.instantiateInitialViewController()
        self.window?.rootViewController = startupVC
    }
    
    func setRootViewToMainTabBarController () {
        if let old = self.window?.rootViewController {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let main = storyboard.instantiateInitialViewController()
            
            UIView.transitionFromView(old.view, toView: main!.view, duration: 0.2, options: UIViewAnimationOptions.TransitionCrossDissolve, completion: { (finished) -> Void in
                self.window?.rootViewController = nil
                self.window?.rootViewController = main
                old.view.removeFromSuperview()
                old.removeFromParentViewController()
            })
        } else {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let main = storyboard.instantiateInitialViewController()
            self.window?.rootViewController = main
        }
    }
    
    
    func networkReachabilityChanged (noti: NSNotification) {
        networkStatus = reachability!.currentReachabilityStatus()
        
        switch (networkStatus) {
        case .NotReachable:
            print("networkReachability: NotReachable")
        case .ReachableViaWiFi:
            print("networkReachability: ReachableViaWiFi")
        case .ReachableViaWWAN:
            print("networkReachability: ReachableViaWWAN")
        }
    }
}

