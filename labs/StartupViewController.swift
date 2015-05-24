//
//  StartupViewController.swift
//  labs
//
//  Created by vulpes on 2015. 5. 20..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit
import MMDrawerController
import MBProgressHUD
import Raygun4iOS

class StartupViewController: GAITrackedViewController {

    var progressHud:MBProgressHUD?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: "appDidBecomeActive:",
            name: UIApplicationDidBecomeActiveNotification, object: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        if (self.progressHud == nil || self.progressHud?.alpha == 0) {
            self.progressHud = ViewUtils.showProgress(self, message: "Initializing..")
            checkVersion() {
                self.initialize()
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.screenName = "StartupScreen"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidDisappear(animated: Bool) {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.removeObserver(self, name: UIApplicationDidBecomeActiveNotification, object: nil)
    }
    
    func appDidBecomeActive(noti:NSNotification) {
        if (self.progressHud == nil || self.progressHud?.alpha == 0) {
            self.progressHud = ViewUtils.showProgress(self, message: "Initializing..")
            checkVersion() {
                self.initialize()
            }
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "DrawerSegue") {
            var drawerController:MMDrawerController = segue.destinationViewController as! MMDrawerController
            drawerController.openDrawerGestureModeMask = MMOpenDrawerGestureMode.PanningCenterView
            drawerController.closeDrawerGestureModeMask = MMCloseDrawerGestureMode.PanningCenterView
            drawerController.setDrawerVisualStateBlock({ (drawerController:MMDrawerController!, drawerSide:MMDrawerSide, percentVisible:CGFloat) -> Void in
                var block:MMDrawerControllerDrawerVisualStateBlock
                block = MMSparkDrawerVisualStateManager.sharedMaanger.drawerVisualStateBlockForDrawerSide(drawerSide)
                block(drawerController, drawerSide, percentVisible)
            })
        
            var appDelegate:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            appDelegate.centerContainer = drawerController
        }
    }
    
    func checkVersion(callback: ()->Void) {
        Requests.getClientVersion {
                (reuqest: NSURLRequest, response: NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            if (error != nil || result == nil) {
                var message:String?
                if (error != nil && error!.domain == NSURLErrorDomain &&
                        error!.code == NSURLErrorNotConnectedToInternet) {
                    message = "Internet is not connected. Please try again."
                } else {
                    message = "Failed to fetch version info becuase of undefined error."
                    if (error != nil) {
                        message! += " (\(error!.domain):\(error!.code))"
                    }
                }
                ViewUtils.showNoticeAlert(self,
                    title: "Failed to fetch version info",
                    message: message!,
                    btnText: "Retry",
                    callback: { () -> Void in
                        self.progressHud?.hide(true)
                        self.checkVersion(callback)
                    })
                return
            }
            
            let res = result as! NSDictionary
            var iosVersion:String? = res.objectForKey("ios_version") as! String?
            if (iosVersion == nil) {
                ViewUtils.showNoticeAlert(self,
                    title: "Failed to fetch version info",
                    message: "Inproper data format",
                    btnText: "Retry",
                    callback: { () -> Void in
                        self.progressHud?.hide(true)
                        self.checkVersion(callback)
                    })
                return
            }
            let verObject: AnyObject? = NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"]
            let currVersion = verObject as? String
            
            let cmpResult = iosVersion!.compare(currVersion!, options:NSStringCompareOptions.NumericSearch)
            if (cmpResult == NSComparisonResult.OrderedDescending) {
                ViewUtils.showNoticeAlert(self,
                    title: "Get new version",
                    
                    message: "We have released a new version of DROPBEAT. Please download on AppStore",
                    btnText: "Download",
                    callback: { () -> Void in
                        self.progressHud?.hide(true)
                        let url = NSURL(string: "http://itunes.apple.com/app/id981451656")
                        (UIApplication).sharedApplication().openURL(url!)
                    })
                return
            }
            callback()
        }
    }
    
    func initialize() {
        Account.getAccountWithCompletionHandler({(account:Account?, error:NSError?) -> Void in
            if (error != nil) {
                var message:String?
                if (error != nil && error!.domain == NSURLErrorDomain &&
                        error!.code == NSURLErrorNotConnectedToInternet) {
                    message = "Internet is not connected. Please try again."
                } else {
                    message = "Failed to fetch user info becuase of undefined error."
                    if (error != nil) {
                        message! += " (\(error!.domain):\(error!.code))"
                    }
                }
                ViewUtils.showNoticeAlert(self,
                    title: "Failed to fetch user info",
                    message: message!,
                    btnText: "Retry",
                    callback: { () -> Void in
                        self.progressHud?.hide(true)
                        self.initialize()
                    })
                return
            }
            var appDelegate:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            appDelegate.account = account
            
            if (account != nil) {
                let email:String = account!.user!.email
                Raygun.sharedReporter().identify(email)
                
                // GA
                let tracker = GAI.sharedInstance().defaultTracker
                let userId:String = account!.user!.id
                tracker.set("&uid", value:userId)
            }
            self.fetchUserInfo()
        })
    }
    
    func fetchUserInfo() {
        let callback = { (error:NSError?) -> Void in
            self.progressHud?.hide(true)
            self.showMainController()
        }
        if (Account.getCachedAccount() != nil) {
            loadPlaylist(callback)
        } else {
            loadInitialPlaylist(callback)
        }
    }
    
    func loadPlaylist(callback:(error:NSError?) -> Void) {
        Requests.fetchAllPlaylists({ (request:NSURLRequest, response:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            if (error != nil || result == nil) {
                var message:String?
                if (error != nil && error!.domain == NSURLErrorDomain &&
                        error!.code == NSURLErrorNotConnectedToInternet) {
                    message = "Internet is not connected"
                } else {
                    message = "Failed to fetch playlists caused by undefined error."
                    if (error != nil) {
                        message! += " (\(error!.domain):\(error!.code))"
                    }
                }
                ViewUtils.showNoticeAlert(self,
                    title: "Failed to fetch playlists",
                    message: message!,
                    btnText: "Retry",
                    callback: { () -> Void in
                        self.progressHud?.hide(true)
                        self.loadPlaylist(callback)
                    })
                return
            }
            let playlists = Parser().parsePlaylists(result!).reverse()
            if (playlists.count == 0) {
                ViewUtils.showNoticeAlert(self, title: "Failed to fetch playlists", message: "At least one playlist should exist")
                callback(error: error)
                return
            }
            PlayerContext.playlists.removeAll(keepCapacity: false)
            for playlist in playlists {
                PlayerContext.playlists.append(playlist)
            }
            PlaylistViewController.updateCurrentPlaylist()
            callback(error:nil)
        })
    }
    
    func loadInitialPlaylist(callback:(error:NSError?) -> Void) {
        Requests.fetchInitialPlaylist({ (request:NSURLRequest, response:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            if (error != nil || result == nil) {
                var message:String?
                if (error != nil && error!.domain == NSURLErrorDomain &&
                        error!.code == NSURLErrorNotConnectedToInternet) {
                    message = "Internet is not connected"
                } else {
                    message = "Failed to fetch playlists caused by undefined error."
                    if (error != nil) {
                        message! += " (\(error!.domain):\(error!.code))"
                    }
                }
                ViewUtils.showNoticeAlert(self,
                    title: "Failed to fetch playlists",
                    message: message!,
                    btnText: "Retry",
                    callback: { () -> Void in
                        self.progressHud?.hide(true)
                        self.loadInitialPlaylist(callback)
                    })
                return
            }
            
            let json = JSON(result!)
            let playlistJson = json["playlist"]
            var playlists = [Playlist]()
            playlists.append(Playlist.fromJson(playlistJson.rawValue))
            
            PlayerContext.playlists.removeAll(keepCapacity: false)
            for playlist in playlists {
                PlayerContext.playlists.append(playlist)
            }
            PlaylistViewController.updateCurrentPlaylist()
            callback(error:nil)
        })
    }
    
    func showMainController() {
        performSegueWithIdentifier("DrawerSegue", sender: self)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
