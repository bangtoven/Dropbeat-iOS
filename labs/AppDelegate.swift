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
    var centerContainer: CenterViewController?
    var account: Account?
    
    var networkStatus = NetworkStatus.NotReachable
    var shouldInitializeQualityState = true
    var futureQuality: QualityState?
    var reachability: Reachability?
    
    var appLink: AppLinkParam?
    
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
        
        Account.loadLocation { (dict) -> Void in }
        
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
        switch(event!.subtype) {
        case .RemoteControlPlay:
            print("play clicked")
            guard let currentTrack = PlayerContext.currentTrack else {
                return
            }
            var params = [String: AnyObject]()
            params["track"] = currentTrack
            if let playlistId = PlayerContext.currentPlaylistId {
                params["playlistId"] =  playlistId
            }
            NSNotificationCenter.defaultCenter().postNotificationName(NotifyKey.playerPlay, object: params)
        case .RemoteControlPause:
            print("pause clicked")
            NSNotificationCenter.defaultCenter().postNotificationName(NotifyKey.playerPause, object: nil)
        case .RemoteControlPreviousTrack:
            print("prev clicked")
            NSNotificationCenter.defaultCenter().postNotificationName(NotifyKey.playerPrev, object: nil)
        case .RemoteControlNextTrack:
            print("next clicked")
            NSNotificationCenter.defaultCenter().postNotificationName(NotifyKey.playerNext, object: nil)
        case .RemoteControlStop:
            print("stop clicked")
        default:
            break
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
                else {
                    NSNotificationCenter.defaultCenter().postNotificationName(NotifyKey.likeUpdated, object: nil)
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
    
    func resetAppToFirstController() {
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let startupViewController = mainStoryboard.instantiateViewControllerWithIdentifier("StartupViewController") as! StartupViewController
        self.window!.rootViewController = startupViewController
    }
    
    func networkReachabilityChanged (noti: NSNotification) {
        networkStatus = reachability!.currentReachabilityStatus()
        
        if (networkStatus != .NotReachable) {
            let quality: QualityState = (networkStatus == .ReachableViaWiFi) ? .HQ : .LQ
            if (shouldInitializeQualityState || PlayerContext.playState == PlayState.STOPPED) {
                shouldInitializeQualityState = false
                PlayerContext.qualityState = quality
            } else {
                futureQuality = quality
            }
        }
        NSNotificationCenter.defaultCenter().postNotificationName(NotifyKey.networkStatusChanged, object: nil)
        
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

