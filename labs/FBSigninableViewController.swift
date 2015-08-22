//
//  FBSigninableTableViewController.swift
//  labs
//
//  Created by vulpes on 2015. 8. 18..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

class FBSigninableViewController: BaseViewController {
    
    @IBOutlet weak var signinWithFacebookBtn: UIButton!
    var progressHud:MBProgressHUD?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        signinWithFacebookBtn.layer.cornerRadius = 3.0

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "sender", name: NotifyKey.appSignin, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotifyKey.appSignin, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func sender() {
        
    }
    
    @IBAction func onSigninWithFacebookBtnClicked(sender: UIButton) {
        var fbManager:FBSDKLoginManager = FBSDKLoginManager()
        progressHud = ViewUtils.showProgress(self, message: NSLocalizedString("Signining in..", comment:""))
        fbManager.logOut()
        fbManager.logInWithReadPermissions(["email", "user_likes"], handler: { (result:FBSDKLoginManagerLoginResult!, error:NSError!) -> Void in
            if (error != nil) {
                // Process error
                ViewUtils.showNoticeAlert(self,
                    title: NSLocalizedString("Failed to sign in", comment:""),
                    message: NSLocalizedString("Failed to acquire user info permission", comment:""))
                self.progressHud?.hide(true)
                return
            }
            if (result.isCancelled) {
                // Do nothing
                self.progressHud?.hide(true)
                return
            }
            if result.grantedPermissions.contains("email") {
                self.requestProfileInfos()
            } else {
                ViewUtils.showNoticeAlert(self,
                    title: NSLocalizedString("Failed to sign in", comment:""),
                    message: NSLocalizedString("Email and like permission required for Dropbeat signin", comment:""))
                self.progressHud?.hide(true)
            }
        })
    }
    
    func requestProfileInfos() {
        let fbManager:FBSDKLoginManager = FBSDKLoginManager()
        let request:FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me", parameters: nil)
        request.startWithCompletionHandler({ (connection:FBSDKGraphRequestConnection!, result:AnyObject!, error:NSError!) -> Void in
            if (error != nil) {
                ViewUtils.showNoticeAlert(self,
                    title: NSLocalizedString("Failed to sign in", comment:""),
                    message: NSLocalizedString("Failed to fetch user profile", comment:""))
                self.progressHud?.hide(true)
                fbManager.logOut()
                return
            }
            let userData = result as! NSDictionary
            var fbId:String = userData.objectForKey("id") as! String
            var firstName:String = userData.objectForKey("first_name") as! String
            var lastName:String = userData.objectForKey("last_name") as! String
            var email:String? = userData.objectForKey("email") as! String?
            if (email == nil) {
                var randId = Int(arc4random_uniform(89999999)) + 10000000
                email = "user\(randId)@dropbeat.net"
            }
            let userParam:[String:String] = [
                "email": email!,
                "first_name": firstName,
                "last_name": lastName,
                "fb_id": fbId
            ]
            
            Requests.userSignin(userParam, respCb: {
                    (request:NSURLRequest, response:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
                if (error != nil) {
                    fbManager.logOut()
                    var message:String?
                    if (error != nil && error!.domain == NSURLErrorDomain &&
                            error!.code == NSURLErrorNotConnectedToInternet) {
                        message = NSLocalizedString("Internet is not connected. Please try again.", comment:"")
                    } else {
                        message = NSLocalizedString("Failed to sign in.", comment:"")
                    }
                    ViewUtils.showNoticeAlert(self, title: NSLocalizedString("Failed to sign in", comment:""),
                        message: message!)
                    self.progressHud?.hide(true)
                    return
                }
                let res = JSON(result!)
                var success:Bool = res["success"].bool ?? false
                if (!success) {
                    fbManager.logOut()
                    var errorMsg:String = res["error"].string ?? NSLocalizedString("Failed to sign in", comment:"")
                    ViewUtils.showNoticeAlert(self, title: NSLocalizedString("Failed to sign in", comment:""), message: errorMsg)
                    self.progressHud?.hide(true)
                    return
                }
                
                let token = res["token"].stringValue
                var userObj = res["user"]
                let user = User(
                        id: String(userObj["id"].intValue),
                        email: userObj["last_name"].stringValue,
                        firstName: userObj["first_name"].stringValue,
                        lastName: userObj["last_name"].stringValue,
                        nickname: userObj["nickname"].stringValue,
                        fbId: userObj["fb_id"].string
                    )
                
                self.afterSignin(user, token: token)
            })
        })
    }
    
    
    func afterSignin(user:User, token:String) {
        let keychainItemWrapper = KeychainItemWrapper(identifier: "net.dropbeat.spark", accessGroup:nil)
        keychainItemWrapper.resetKeychain()
        keychainItemWrapper["auth_token"] = token
        
        self.dismissViewControllerAnimated(false, completion: nil)
        self.navigationController?.dismissViewControllerAnimated(false, completion: nil)
        
        NSNotificationCenter.defaultCenter().postNotificationName(NotifyKey.appSignin, object: nil)
        PlayerViewController.sharedInstance!.resignObservers()
        var appDelegate:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        var navController:UINavigationController = appDelegate.window?.rootViewController as! UINavigationController
        navController.popToRootViewControllerAnimated(false)
        
    }
}
