//
//  StartupViewController.swift
//  labs
//
//  Created by vulpes on 2015. 5. 20..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit
import Raygun4iOS

class StartupViewController: GAITrackedViewController {

    private var progressHud:MBProgressHUD?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: "appDidBecomeActive:",
            name: UIApplicationDidBecomeActiveNotification, object: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        if (self.progressHud == nil || self.progressHud?.alpha == 0) {
            self.progressHud = ViewUtils.showProgress(self, message: nil)
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
            self.progressHud = ViewUtils.showProgress(self, message: nil)
            checkVersion() {
                self.initialize()
            }
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "main" {
            var vc:CenterViewController = segue.destinationViewController as! CenterViewController
            var appDelegate:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            appDelegate.centerContainer = vc
        }
        if segue.identifier == "genre_tutorial" {
            let vc = segue.destinationViewController as! FavoriteGenreTutorialViewController
            vc.fromStartup = true
        }
    }
    
    func checkVersion(callback: ()->Void) {
        Requests.getClientVersion {
                (reuqest: NSURLRequest, response: NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            if (error != nil || result == nil) {
                var message:String?
                if (error != nil && error!.domain == NSURLErrorDomain &&
                        error!.code == NSURLErrorNotConnectedToInternet) {
                    message = NSLocalizedString("Internet is not connected. Please try again.", comment:"")
                } else {
                    message = NSLocalizedString("Failed to fetch version info.", comment:"")
                }
                ViewUtils.showNoticeAlert(self,
                    title: NSLocalizedString("Failed to fetch version info", comment:""),
                    message: message!,
                    btnText: NSLocalizedString("Retry", comment:""),
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
                    title: NSLocalizedString("Failed to fetch version info", comment:""),
                    message: NSLocalizedString("Improper data format", comment:""),
                    btnText: NSLocalizedString("Retry", comment:""),
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
                    title: NSLocalizedString("Get new version", comment:""),
                    
                    message: NSLocalizedString("We have released a new version of DROPBEAT. Please download on AppStore", comment:""),
                    btnText: NSLocalizedString("Download", comment:""),
                    callback: { () -> Void in
                        self.progressHud?.hide(true)
                        let url = NSURL(string: "http://itunes.apple.com/app/id998263412")
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
                    message = NSLocalizedString("Internet is not connected. Please try again.", comment:"")
                } else {
                    message = NSLocalizedString("Failed to fetch user info.", comment:"")
                    let keychainItemWrapper = KeychainItemWrapper(identifier: "net.dropbeat.spark", accessGroup:nil)
                    keychainItemWrapper["auth_token"] = nil
                }
                ViewUtils.showNoticeAlert(self,
                    title: NSLocalizedString("Failed to fetch user info", comment:""),
                    message: message!,
                    btnText: NSLocalizedString("Retry", comment:""),
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
        if Account.getCachedAccount() == nil {
            self.showMainController()
            return
        }
        
        var defaultDb:NSUserDefaults = NSUserDefaults.standardUserDefaults()
        var didAutoFollow:Bool? = defaultDb.objectForKey(UserDataKey.didAutoFollow) as? Bool
        if !(didAutoFollow ?? false) {
            checkFollowingCount({ (needAutoFollow:Bool?, error:NSError?) -> Void in
                if error != nil {
                    self.showMainController()
                    return
                }
                if !needAutoFollow! {
                    defaultDb.setBool(true, forKey: UserDataKey.didAutoFollow)
                    self.showMainController()
                    return
                }
                self.autoArtistFollow({ (error) -> Void in
                    if error == nil {
                        defaultDb.setBool(true, forKey: UserDataKey.didAutoFollow)
                    }
                    self.showMainController()
                })
            })
        } else {
            self.showMainController()
        }
    }
    
    func showMainController() {
        var popTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.5 * Double(NSEC_PER_SEC)))
        dispatch_after(popTime, dispatch_get_main_queue()) {
            self.progressHud?.hide(true)
            if let account = Account.getCachedAccount() {
                if count(account.favoriteGenreIds) == 0 {
                    self.performSegueWithIdentifier("genre_tutorial", sender: self)
                    return
                }
            }
            self.performSegueWithIdentifier("main", sender: self)
        }
    }
    
    func checkFollowingCount(callback:(needAutoFollow:Bool?, error:NSError?) -> Void) {
        Requests.following { (req:NSURLRequest, resp:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            if error != nil {
                callback(needAutoFollow: nil, error:error)
                return
            }
            if result == nil {
                callback(needAutoFollow: nil, error:error)
                return
            }
            
            let parser = Parser()
            let info:FollowingInfo = parser.parseFollowing(result!)
            if !info.success {
                callback(needAutoFollow: nil, error:error)
                return
            }
            if info.results!.count != 0 {
                callback(needAutoFollow: false, error:nil)
                return
            }
            callback(needAutoFollow: true, error: nil)
        }
    }
    
    func autoArtistFollow(callback:(error:NSError?) -> Void) {
        var needFBSignin:Bool = false
        var needFBRerequest:Bool = false
        
        if FBSDKAccessToken.currentAccessToken() == nil {
            needFBSignin = true
        } else {
            let accessToken:FBSDKAccessToken = FBSDKAccessToken.currentAccessToken()
            let expireDate:NSDate? = accessToken.expirationDate
            if expireDate == nil || NSDate() > expireDate {
                needFBSignin = true
                needFBRerequest = true
            }
            
            if !needFBSignin && !accessToken.hasGranted("user_likes") {
                needFBSignin = true
                needFBRerequest = true
            }
        }
        
        if needFBSignin {
            self.facebookSignin(needFBRerequest, callback: { (cancel:Bool, error:NSError?) -> Void in
                if error != nil {
                    callback(error:error)
                    return
                }
                if cancel {
                    callback(error:nil)
                    return
                }
                self.autoArtistFollow(callback)
                return
            })
            return
        }
        
        
        requestLikeInfos { (data:[FBPage]?, error:NSError?) -> Void in
            if error != nil {
                callback(error:error)
                return
            }
            if data == nil {
                callback(error:NSError(domain: "autoArtistFollow", code: 0, userInfo: nil))
                return
            }
            
            var names = [String]()
            
            for page in data! {
                names.append(page.name)
            }
            
            if names.count == 0 {
                callback(error: nil)
                return
            }
            
            Requests.artistFilter(names, respCb: {
                    (req:NSURLRequest, resp:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
                if error != nil {
                    println(error!)
                    callback(error:error)
                    return
                }
                
                if result == nil || !(JSON(result!)["success"].bool ?? false) {
                    callback(error:NSError(domain: "autoArtistFollow", code: 1, userInfo: nil))
                    return
                }
                
                var dataJson = JSON(result!)["data"]
                println(dataJson)
                var ids = [Int]()
                
                for (idx:String, s:JSON) in dataJson {
                    if s["id"] != nil {
                        let id = s["id"].intValue
                        ids.append(id)
                    }
                }
                
                if ids.count == 0 {
                    callback(error: nil)
                    return
                }
                
                Requests.follow(ids, respCb: { (req:NSURLRequest, resp:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
                    if error != nil {
                        callback(error:error)
                        return
                    }
                    
                    if result == nil || !(JSON(result!)["success"].bool ?? false) {
                        callback(error:NSError(domain: "autoArtistFollow", code: 1, userInfo: nil))
                        return
                    }
                    
                    callback(error:nil)
                })
            })
        }
    }
    
    func requestLikeInfos(callback:(data:[FBPage]?, error:NSError?) -> Void) {
        let request:FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me/likes", parameters: ["limit": 1000])
        request.startWithCompletionHandler({ (connection:FBSDKGraphRequestConnection!, result:AnyObject!, error:NSError!) -> Void in
            if (error != nil) {
                callback(data:nil, error:error)
                return
            }
            
            let likes = FBPageLikes.fromJson(result)
            if likes == nil {
                callback(data:nil, error:NSError(domain: "requestLikeInfos", code: 0, userInfo: nil))
                return
            }
            
            var data = [FBPage]()
            for page:FBPage in likes!.pages {
                data.append(page)
            }
            
            if likes!.nextPageToken != nil {
                self.requestNextLikeInfos(likes!.pages, pageUrl: likes!.nextPageToken!, callback: callback)
            } else {
                callback(data:data, error:nil)
            }
        })
    }
    
    func requestNextLikeInfos(pages:[FBPage], pageUrl:String, callback:(data:[FBPage]?, error:NSError?) -> Void) {
        Requests.sendGet(pageUrl, params: nil, auth:false, respCb: {
                (req:NSURLRequest, resp:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            if (error != nil) {
                callback(data:nil, error:error)
                return
            }
            
            if (result == nil) {
                callback(data:nil, error:NSError(domain: "requestLikeInfos", code: 0, userInfo: nil))
                return
            }
            let likes = FBPageLikes.fromJson(result!)
            if likes == nil {
                callback(data:nil, error:NSError(domain: "requestLikeInfos", code: 0, userInfo: nil))
                return
            }
            
            var concatPages = [FBPage]()
            
            for page:FBPage in pages {
                concatPages.append(page)
            }
            for page:FBPage in likes!.pages {
                concatPages.append(page)
            }
            
            if likes!.nextPageToken != nil {
                self.requestNextLikeInfos(likes!.pages, pageUrl: likes!.nextPageToken!, callback: callback)
            } else {
                callback(data:concatPages, error:nil)
            }
        })
    }
    
    func facebookSignin(rerequest:Bool, callback:(cancel:Bool, error:NSError?) -> Void) {
        ViewUtils.showConfirmAlert(self,
                title: NSLocalizedString("Permission Required", comment:""),
            message: NSLocalizedString("Grant permission to import your favorite followed artists from Facebook?", comment:""),
                positiveBtnText: NSLocalizedString("OK", comment:""),
                positiveBtnCallback: { () -> Void in
            
            var fbManager:FBSDKLoginManager = FBSDKLoginManager()
                    
            fbManager.logInWithReadPermissions(["user_likes"], handler: { (result:FBSDKLoginManagerLoginResult!, error:NSError!) -> Void in
                
                if error != nil || result.isCancelled || !result.grantedPermissions.contains("user_likes") {
                    // Process error
                    ViewUtils.showConfirmAlert(
                        self,
                        title: NSLocalizedString("Failed to connect facebook", comment:""),
                        message: NSLocalizedString("Failed to acquire user info permission. Do you want to retry facebook connect?", comment:""),
                        positiveBtnText: NSLocalizedString("Retry", comment:""), positiveBtnCallback: { () -> Void in
                            self.facebookSignin(rerequest, callback: callback)
                    }, negativeBtnText: NSLocalizedString("Not now", comment:""), negativeBtnCallback: { () -> Void in
                        callback(cancel:true, error:error != nil ? error : NSError(domain: "facebookSignin", code: 0, userInfo: nil))
                    })
                    return
                }
                callback(cancel:false, error: nil)
            })
                
        }, negativeBtnText: NSLocalizedString("Decline", comment:"")) { () -> Void in
            callback(cancel: true, error: nil)
            return
        }
        
    }
}
