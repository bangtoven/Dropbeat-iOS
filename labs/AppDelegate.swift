//
//  AppDelegate.swift
//  labs
//
//  Created by Park Il Su on 2015. 5. 14..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit
import MMDrawerController
import FBSDKCoreKit
import FBSDKLoginKit
import Raygun4iOS

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var centerContainer: MMDrawerController?
    var account: Account?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
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
        
        // GA settings
        let gai = GAI.sharedInstance()
        // optional
        gai.trackUncaughtExceptions = true
        gai.dispatchInterval = 20
        gai.logger.logLevel = GAILogLevel.Verbose
        
        gai.trackerWithTrackingId("UA-49094112-1")
        
        
        Raygun.sharedReporterWithApiKey("5vjswgUxxTkQxkoeNzkJeg==")
        return FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    func sender () {}
    
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    override func remoteControlReceivedWithEvent(event: UIEvent) {
        switch(event.subtype) {
        case UIEventSubtype.RemoteControlPlay:
            println("play clicked")
            var params: Dictionary<String, AnyObject> = [
                "track": PlayerContext.currentTrack!,
                "playlistId": PlayerContext.currentPlaylistId!
            ]
            NSNotificationCenter.defaultCenter().postNotificationName(
                NotifyKey.playerPlay, object: params)
            break;
        
        case UIEventSubtype.RemoteControlPause:
            println("pause clicked")
            NSNotificationCenter.defaultCenter().postNotificationName(
                NotifyKey.playerPause, object: nil)
            break;
        
        case UIEventSubtype.RemoteControlPreviousTrack:
            println("prev clicked")
            NSNotificationCenter.defaultCenter().postNotificationName(
                NotifyKey.playerPrev, object: nil)
            break;
        
        case UIEventSubtype.RemoteControlNextTrack:
            println("next clicked")
            NSNotificationCenter.defaultCenter().postNotificationName(
                NotifyKey.playerNext, object: nil)
            break;
            
        case UIEventSubtype.RemoteControlStop:
            println("stop clicked")
            break;
        case UIEventSubtype.RemoteControlTogglePlayPause:
            // XXX: For IOS 6 compat.
            if (PlayerContext.playState == PlayState.PLAYING) {
                NSNotificationCenter.defaultCenter().postNotificationName(
                    NotifyKey.playerPause, object: nil)
            } else {
                var params: Dictionary<String, AnyObject> = [
                    "track": PlayerContext.currentTrack!,
                    "playlistId": PlayerContext.currentPlaylistId!
                ]
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
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        FBSDKAppEvents.activateApp()
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject?) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)
    }
    
    func resetAppToFirstController() {
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let startupViewController = mainStoryboard.instantiateViewControllerWithIdentifier("StartupViewController") as! StartupViewController
        self.window!.rootViewController = startupViewController
    }
}

