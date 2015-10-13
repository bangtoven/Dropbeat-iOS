//
//  StartupViewController.swift
//  labs
//
//  Created by vulpes on 2015. 5. 20..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit
import Raygun4iOS

class StartupViewController: GAITrackedViewController, FBEmailSubmitViewControllerDelegate {

    private var progressHud:MBProgressHUD?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(animated: Bool) {
        if (self.progressHud == nil || self.progressHud?.alpha == 0) {
            self.progressHud = ViewUtils.showProgress(self, message: nil)
            checkVersion() {
                Track.loadSoundCloudKey({ (error: NSError) -> Void in
                    print("loadSoundCloudKey: "+error.description)
                })
                self.initialize()
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.screenName = "StartupScreen"
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "appDidBecomeActive:",
            name: UIApplicationDidBecomeActiveNotification, object: nil)
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
        if segue.identifier == "need_email" {
            let vc = segue.destinationViewController as! FBEmailSubmitViewController
            vc.delegate = self
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
            let iosVersion:String? = res.objectForKey("ios_version") as! String?
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
        Requests.getFeedGenre { (req, resp, result, error) -> Void in
            if (error != nil) {
                    ViewUtils.showConfirmAlert(self,
                        title: NSLocalizedString("Failed to load", comment:""),
                        message: error!.localizedDescription,
                        positiveBtnText: NSLocalizedString("Retry", comment: ""),
                        positiveBtnCallback: { () -> Void in
                            self.initialize()
                    })
                    return
            }
            
            let _ = GenreList.parseGenre(result!)
         
            Account.getAccountWithCompletionHandler({(account:Account?, error:NSError?) -> Void in
                if (error != nil) {
                    var message:String?
                    if (error != nil && error!.domain == NSURLErrorDomain &&
                        error!.code == NSURLErrorNotConnectedToInternet) {
                            message = NSLocalizedString("Internet is not connected. Please try again.", comment:"")
                    } else {
                        message = NSLocalizedString("Failed to fetch user info", comment:"")
                        let keychainItemWrapper = KeychainItemWrapper(identifier: "net.dropbeat.spark", accessGroup:nil)
                        keychainItemWrapper.setObject(nil, forKey: "auth_token")
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
//                let appDelegate:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
//                appDelegate.account = account
                
                if (account != nil) {
                    let email:String = account!.user!.email
                    Raygun.sharedReporter().identify(email)
                    
                    // GA
                    let tracker = GAI.sharedInstance().defaultTracker
                    let userId:String = account!.user!.id!
                    tracker.set("&uid", value:userId)
                }
                self.fetchUserInfo()
            })
        }
    }
    
    func fetchUserInfo() {
        if Account.getCachedAccount() == nil {
            self.showMainController()
            return
        }
        
        let account = Account.getCachedAccount()!
        
        let email = account.user!.email
        if email.indexOf("@dropbeat.net") > -1 {
            progressHud?.hide(true)
            performSegueWithIdentifier("need_email", sender: nil)
            return
        }
        
        self.showMainController()
    }
    
    func showMainController() {
        let popTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.5 * Double(NSEC_PER_SEC)))
        dispatch_after(popTime, dispatch_get_main_queue()) {
            self.progressHud?.hide(true)
//            if let account = Account.getCachedAccount()
//                where account.favoriteGenreIds.count == 0 {
//                    self.performSegueWithIdentifier("genre_tutorial", sender: self)
//                    return
//            }
            
//            self.performSegueWithIdentifier("main", sender: self)
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            appDelegate.setRootViewToMainTabBarController()
            
        }
    }
    
    @IBAction func unwindFromGenreTutorialToStart(sender: UIStoryboardSegue) {
        print("unwindFromGenreTutorialToStart")
    }
    
    func requestLikeInfos(callback:(data:[FBPage]?, error:NSError?) -> Void) {
        let request:FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me/likes", parameters: ["limit": 1000])
        request.startWithCompletionHandler({ (connection:FBSDKGraphRequestConnection!, result:AnyObject!, error:NSError!) -> Void in
            if (error != nil) {
                callback(data:nil, error:error)
                return
            }
            
            let likes = FBPageLikes.parseFBPageLikes(result)
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
                (req, resp, result, error) -> Void in
            if (error != nil) {
                callback(data:nil, error:error)
                return
            }
            
            if (result == nil) {
                callback(data:nil, error:NSError(domain: "requestLikeInfos", code: 0, userInfo: nil))
                return
            }
            let likes = FBPageLikes.parseFBPageLikes(result!)
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
            
            let fbManager:FBSDKLoginManager = FBSDKLoginManager()
                    
            fbManager.logInWithReadPermissions(["user_likes"], fromViewController:self, handler: { (result:FBSDKLoginManagerLoginResult!, error:NSError!) -> Void in
                
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
    
    func onAfterEmailUpdate() {
        fetchUserInfo()
    }
}
