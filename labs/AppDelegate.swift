//
//  AppDelegate.swift
//  labs
//
//  Created by Park Il Su on 2015. 5. 14..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit
import Raygun4iOS

class NetworkStatus {
    static var NOT_REACHABLE = 0
    static var WIFI = 1
    static var OTHER = 2
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var centerContainer: CenterViewController?
    var account: Account?
    // 0 is NotReachable
    var networkStatus: Int = NetworkStatus.NOT_REACHABLE
    var shouldInitializeQualityState = true
    var futureQuality:QualityState? = nil
    var reachability: Reachability?
    var sharedTrackUid: String?
    var sharedPlaylistUid: String?
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)
        let touch = event!.allTouches()?.first
        let location = touch!.locationInView(self.window)
        let statusBarFrame = UIApplication.sharedApplication().statusBarFrame
        if (CGRectContainsPoint(statusBarFrame, location)) {
            NSNotificationCenter.defaultCenter().postNotificationName(NotifyKey.statusBarTapped, object: nil)
        }
    }

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        Account.loadLocation { (dict) -> Void in
//            print(Location.location)
        }
        
        // Override point for customization after application launch.
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "sender", name: NotifyKey.playerPlay, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "sender", name: NotifyKey.playerPrev, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "sender", name: NotifyKey.playerPause, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "sender", name: NotifyKey.playerNext, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "sender", name: NotifyKey.playerSeek, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "sender", name: NotifyKey.networkStatusChanged, object: nil)
        
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
    
    func sender () {}
    
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    override func remoteControlReceivedWithEvent(event: UIEvent?) {
        switch(event!.subtype) {
        case UIEventSubtype.RemoteControlPlay:
            print("play clicked")
            if PlayerContext.currentTrack == nil {
                return
            }
            var params: [String: AnyObject] = [String: AnyObject]()
            params["track"] = PlayerContext.currentTrack!
            if PlayerContext.currentPlaylistId != nil {
                params["playlistId"] =  PlayerContext.currentPlaylistId!
            }
            NSNotificationCenter.defaultCenter().postNotificationName(
                NotifyKey.playerPlay, object: params)
            break;
        
        case UIEventSubtype.RemoteControlPause:
            print("pause clicked")
            NSNotificationCenter.defaultCenter().postNotificationName(
                NotifyKey.playerPause, object: nil)
            break;
        
        case UIEventSubtype.RemoteControlPreviousTrack:
            print("prev clicked")
            NSNotificationCenter.defaultCenter().postNotificationName(
                NotifyKey.playerPrev, object: nil)
            break;
        
        case UIEventSubtype.RemoteControlNextTrack:
            print("next clicked")
            NSNotificationCenter.defaultCenter().postNotificationName(
                NotifyKey.playerNext, object: nil)
            break;
            
        case UIEventSubtype.RemoteControlStop:
            print("stop clicked")
            break;
        case UIEventSubtype.RemoteControlTogglePlayPause:
            // XXX: For IOS 6 compat.
            if (PlayerContext.playState == PlayState.PLAYING) {
                NSNotificationCenter.defaultCenter().postNotificationName(
                    NotifyKey.playerPause, object: nil)
            } else {
                if PlayerContext.currentTrack == nil {
                    return
                }
                var params: [String: AnyObject] = [String:AnyObject]()
                params["track"] = PlayerContext.currentTrack!
                if PlayerContext.currentPlaylistId != nil {
                    params["playlistId"] =  PlayerContext.currentPlaylistId!
                }
                params["section"] = PlayerContext.playingSection
                NSNotificationCenter.defaultCenter().postNotificationName(
                    NotifyKey.playerPlay, object: params)               
            }
            break;
        default:
            break;
        }
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        fetchUserLikeInfo()
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        FBSDKAppEvents.activateApp()
    }
    
    func fetchUserLikeInfo() {
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
                                self.fetchUserLikeInfo()
                        })
                    }
                    return
                }
                NSNotificationCenter.defaultCenter().postNotificationName(
                    NotifyKey.likeUpdated, object: nil)
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
                                self.fetchUserLikeInfo()
                        })
                    }
                    return
                }
            }
        }
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        handleCustomURL(url)
        return FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)
    }
    
    func handleCustomURL(url:NSURL) {
        if url.scheme == ExternalUrlKey.scheme && url.host == ExternalUrlKey.defaultIdentifier {
            if let query = url.getKeyVals() {
                let sharedTrackUid:String? = query["track"]
                if sharedTrackUid != nil {
                    redirectSharedTrack(sharedTrackUid!)
                    return
                }
                let sharedPlaylistUid:String? = query["playlist"]
                if sharedPlaylistUid != nil {
                    redirectSharedPlaylist(sharedPlaylistUid!)
                    return
                }
            }
        }
    }
    
    func resetAppToFirstController() {
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let startupViewController = mainStoryboard.instantiateViewControllerWithIdentifier("StartupViewController") as! StartupViewController
        self.window!.rootViewController = startupViewController
    }
    
    func networkReachabilityChanged (noti: NSNotification) {
        let status = reachability!.currentReachabilityStatus()
        networkStatus = status.rawValue
        if (networkStatus != NetworkStatus.NOT_REACHABLE) {
            let quality = networkStatus == NetworkStatus.WIFI ?
                    QualityState.HQ : QualityState.LQ
            if (shouldInitializeQualityState || PlayerContext.playState == PlayState.STOPPED) {
                shouldInitializeQualityState = false
                PlayerContext.qualityState = quality
            } else {
                futureQuality = quality
            }
        }
        NSNotificationCenter.defaultCenter().postNotificationName(
            NotifyKey.networkStatusChanged, object: nil)
        
        switch (networkStatus) {
        case 0:
            print("networkReachability: NotReachable")
            break
        case 1:
            print("networkReachability: ReachableViaWiFi")
            break
        case 2:
            print("networkReachability: ReachableViaWWAN")
            break
        default:
            break
        }
    }
    
    func redirectSharedTrack(uid:String) {
        sharedTrackUid = uid
        NSNotificationCenter.defaultCenter().postNotificationName(NotifyKey.trackShare, object: nil)
    }
    
    func redirectSharedPlaylist(uid:String) {
        sharedPlaylistUid = uid
        NSNotificationCenter.defaultCenter().postNotificationName(NotifyKey.playlistShare, object: nil)
    }
}

