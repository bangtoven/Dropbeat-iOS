//
//  StartupViewController.swift
//  labs
//
//  Created by vulpes on 2015. 5. 20..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit
//import Raygun4iOS
import Fabric
import Crashlytics

protocol AfterSignUpDelegate {
    func signUpDidFinished()
}

class StartupViewController: GAITrackedViewController, FBEmailSubmitViewControllerDelegate, AfterSignUpDelegate {

    @IBOutlet weak var activityIndicatorView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let playIndicator = VYPlayIndicator()
        playIndicator.frame = activityIndicatorView.bounds
        playIndicator.color = UIColor.dropbeatColor()
        playIndicator.animatePlayback()
        self.activityIndicatorView.backgroundColor = UIColor.whiteColor()
        self.activityIndicatorView.layer.addSublayer(playIndicator)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.screenName = "StartupScreen"
    }
    
    var versionChecked = false
    override func viewDidAppear(animated: Bool) {
        if versionChecked != true {
            checkVersion() {
                self.versionChecked = true
                
                Track.loadSoundCloudKey({ (error: NSError) -> Void in
                    print("loadSoundCloudKey: "+error.description)
                })
                self.initialize()
            }
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "need_email" {
            let vc = segue.destinationViewController as! FBEmailSubmitViewController
            vc.delegate = self
        } else if segue.identifier == "ShowTutorial" {
            let nav = segue.destinationViewController as! UINavigationController
            let vc = nav.topViewController as! TutorialViewController
            vc.delegate = self
        }
    }
    
    func signUpDidFinished() {
        self.dismissViewControllerAnimated(true) { () -> Void in
            self.initialize()
        }
    }
    
    func onAfterEmailUpdate() {
        fetchUserInfo()
    }
    
    func initialize() {
        Requests.getFeedGenre { (result, error) -> Void in
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
                    if (error != nil &&
                        error!.domain == NSURLErrorDomain &&
                        (error!.code == NSURLErrorNotConnectedToInternet || error!.code == NSURLErrorTimedOut)) {
                            message = NSLocalizedString("Please check your internet connection. \nLet's see if we can fix this together. Cross your fingers and hit the Retry.", comment:"")
                    } else {
                        message = "Something went wrong, but Dropbeat is so awesome that you should give it a try. Cross your fingers, hit the retry, and our app shall be healed."//NSLocalizedString("Failed to fetch user info", comment:"")
                        let keychainItemWrapper = KeychainItemWrapper(identifier: "net.dropbeat.spark", accessGroup:nil)
                        keychainItemWrapper.setObject(nil, forKey: "auth_token")
                    }
                    ViewUtils.showNoticeAlert(self,
                        title: "We're sorry.",//NSLocalizedString("Failed to fetch user info", comment:""),
                        message: message!,
                        btnText: NSLocalizedString("Retry", comment:""),
                        callback: { () -> Void in
                            self.initialize()
                    })
                    return
                }
                
                if (account != nil) {
                    let email:String = account!.user!.email
                    
//                    Raygun.sharedReporter().identify(email)
                    Crashlytics.sharedInstance().setUserEmail(email)
                    
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
            self.performSegueWithIdentifier("ShowTutorial", sender: self)
            return
        }
        
        let account = Account.getCachedAccount()!
        
        let email = account.user!.email
        if email.indexOf("@dropbeat.net") > -1 {
            performSegueWithIdentifier("need_email", sender: nil)
            return
        }
        
        let pushNotiGuideShown = "pushNotiGuideShown"
        let pushNotiAllowed = "pushNotiAllowed"
        let defaults = NSUserDefaults.standardUserDefaults()
        if defaults.boolForKey(pushNotiGuideShown) != true {
            defaults.setBool(true, forKey: pushNotiGuideShown)
            
            ViewUtils.showConfirmAlert(self,
                title: "Get messages from Dropbeat",
                message: "You will be asked for permission to receive push notifications.\n Push notifications let you know new posts from the artists you're following.",
                positiveBtnText: "Allow",
                positiveBtnCallback: { () -> Void in
                    defaults.setBool(true, forKey: pushNotiAllowed)
                    defaults.synchronize()
                    
                    let application = UIApplication.sharedApplication()
                    application.registerForRemoteNotifications()
                    application.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: [.Badge, .Alert, .Sound], categories: nil))
                    
                    self.showMainController()
                }, negativeBtnCallback: { () -> Void in
                    defaults.setBool(false, forKey: pushNotiAllowed)
                    defaults.synchronize()
                    
                    self.showMainController()
            })
        } else {
            if defaults.boolForKey(pushNotiAllowed) {
                UIApplication.sharedApplication().registerForRemoteNotifications()
            }
            self.showMainController()
        }
        
    }
    
    func showMainController() {
        let popTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.5 * Double(NSEC_PER_SEC)))
        dispatch_after(popTime, dispatch_get_main_queue()) {
            
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            appDelegate.setRootViewToMainTabBarController()
        }
    }
    
    
    func requestLikeInfos(callback:(data:[FBPage]?, error:NSError?) -> Void) {
        let request:FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me/likes", parameters: ["limit": 1000])
        request.startWithCompletionHandler({ (connection:FBSDKGraphRequestConnection!, result:AnyObject!, error:NSError!) -> Void in
            if (error != nil) {
                callback(data:nil, error:error)
                return
            }
            
            let likes = FBPageLikes.parseFBPageLikes(JSON(result!))
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
        Requests.sendGet(pageUrl, params: nil, auth:false) { (result, error) -> Void in
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
        }
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
    
    func checkVersion(callback: ()->Void) {
        Requests.getClientVersion { (result, error) -> Void in
            if (error != nil || result == nil) {
                ViewUtils.showNoticeAlert(self,
                    title: "We're sorry.",//NSLocalizedString("Failed to fetch version info", comment:""),
                    message: "Please check your internet connection. \nLet's see if we can fix this together. Cross your fingers and hit the Retry.",//message!,
                    btnText: NSLocalizedString("Retry", comment:""),
                    callback: { () -> Void in
                        self.checkVersion(callback)
                })
                return
            }
            
            let iosVersion = result!["ios_version"].string
            if (iosVersion == nil) {
                ViewUtils.showNoticeAlert(self,
                    title: NSLocalizedString("Failed to fetch version info", comment:""),
                    message: NSLocalizedString("Improper data format", comment:""),
                    btnText: NSLocalizedString("Retry", comment:""),
                    callback: { () -> Void in
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
                        let url = NSURL(string: "http://itunes.apple.com/app/id998263412")
                        (UIApplication).sharedApplication().openURL(url!)
                })
                return
            }
            callback()
        }
    }
}
