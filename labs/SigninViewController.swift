//
//  SigninViewController.swift
//  labs
//
//  Created by vulpes on 2015. 5. 18..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

class SigninViewController: BaseViewController {

    @IBOutlet weak var signinBtn: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var signinBgImage = UIImage(named: "facebook_btn_bg.png")
        signinBgImage = signinBgImage!.resizableImageWithCapInsets(UIEdgeInsetsMake(14, 14, 14, 14))
        signinBtn.setBackgroundImage(signinBgImage, forState: UIControlState.Normal)

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func dismiss() {
        presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func onSigninBtnClicked(sender: UIButton) {
        var fbManager:FBSDKLoginManager = FBSDKLoginManager()
        fbManager.logInWithReadPermissions(["email"], handler: { (result:FBSDKLoginManagerLoginResult!, error:NSError!) -> Void in
            if (error != nil) {
                // Process error
                ViewUtils.showNoticeAlert(self, title: "Failed to sign in", message: "Failed to request user info permission")
                return
            }
            if (result.isCancelled) {
                // Do nothing
                return
            }
            if (result.grantedPermissions.contains("email")) {
                self.requestProfileInfos()
            } else {
                ViewUtils.showNoticeAlert(self, title: "Failed to sign in", message: "Email permission required for Dropbeat signin")
            }
        })
    }
    
    func requestProfileInfos() {
        let fbManager:FBSDKLoginManager = FBSDKLoginManager()
        let request:FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me", parameters: nil)
        request.startWithCompletionHandler({ (connection:FBSDKGraphRequestConnection!, result:AnyObject!, error:NSError!) -> Void in
            if (error != nil) {
                ViewUtils.showNoticeAlert(self, title: "Failed to sign in", message: "Failed to fetch user profile")
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
                    var message:String?
                    if (error != nil && error!.domain == NSURLErrorDomain &&
                            error!.code == NSURLErrorNotConnectedToInternet) {
                        message = "Internet is not connected. Please try again."
                    } else {
                        message = "Failed to signin caused by undefined error."
                        if (error != nil) {
                            message! += " (\(error!.domain):\(error!.code))"
                        }
                    }
                    ViewUtils.showNoticeAlert(self, title: "Failed to sign in",
                        message: message!)
                    return
                }
                let res = result as! NSDictionary
                var success:Bool = res.objectForKey("success") as! Bool? ?? false
                if (!success) {
                    var errorMsg:String = res.objectForKey("error") as? String ?? "undefined error"
                    ViewUtils.showNoticeAlert(self, title: "Failed to sign in", message: errorMsg)
                    return
                }
                
                let token = res.objectForKey("token") as! String
                var userObj = res.objectForKey("user") as! NSDictionary
                let user = User(
                        id: String(userObj.valueForKey("id") as! Int),
                        email: userObj.valueForKey("last_name") as! String,
                        firstName: userObj.valueForKey("first_name") as! String,
                        lastName: userObj.valueForKey("last_name") as! String,
                        unlocked: userObj.valueForKey("unlocked") as! Bool,
                        createdAt: userObj.valueForKey("created_at") as! String,
                        fbId: userObj.valueForKey("fb_id") as! String
                    )
                
                self.afterSignin(user, token: token)
            })
        })
    }
    
    
    func afterSignin(user:User, token:String) {
        let keychainItemWrapper = KeychainItemWrapper(identifier: "net.dropbeat.spark", accessGroup:nil)
        keychainItemWrapper["auth_token"] = token
        Account.getAccountWithCompletionHandler({ (account:Account?, error:NSError?) -> Void in
            if (error != nil) {
                ViewUtils.showNoticeAlert(self, title: "Failed to sign in", message: "failed to get user info")
                return
            }
            if (account == nil) {
                ViewUtils.showNoticeAlert(self, title: "Failed to sign in", message: "Account is nil")
                return
            }
            self.dismiss()
            var appDelegate:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            appDelegate.resetAppToFirstController()
        })
    }
    

    @IBAction func onCloseBtnClicked(sender: AnyObject) {
        dismiss()
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
