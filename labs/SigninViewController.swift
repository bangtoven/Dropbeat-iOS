//
//  SigninViewController.swift
//  labs
//
//  Created by vulpes on 2015. 5. 18..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit

class SigninViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

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
                self.showSignupFailureAlert(errorText: error!.description)
                return
            }
            if (result.isCancelled) {
                // Do nothing
                return
            }
            if (result.grantedPermissions.contains("email")) {
                self.requestProfileInfos()
            } else {
                self.showSignupFailureAlert(errorText: "Email permission required for Dropbeat signin")
            }
        })
    }
    
    func requestProfileInfos() {
        let fbManager:FBSDKLoginManager = FBSDKLoginManager()
        let request:FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me", parameters: nil)
        request.startWithCompletionHandler({ (connection:FBSDKGraphRequestConnection!, result:AnyObject!, error:NSError!) -> Void in
            if (error != nil) {
                self.showSignupFailureAlert(errorText: error!.description)
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
                    self.showSignupFailureAlert(errorText: error!.description)
                    return
                }
                let res = result as! NSDictionary
                var success:Bool = res.objectForKey("success") as! Bool? ?? false
                if (!success) {
                    var errorMsg:String? = res.objectForKey("error") as! String?
                    self.showSignupFailureAlert(errorText: errorMsg)
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
        var testToken:String? = keychainItemWrapper["auth_token"] as! String?
        Account.getAccountWithCompletionHandler({ (account:Account?, error:NSError?) -> Void in
            if (error != nil) {
                self.showSignupFailureAlert(errorText: error?.description)
                return
            }
            if (account == nil) {
                self.showSignupFailureAlert(errorText: "Account is nil")
                return
            }
            self.dismiss()
        })
    }
    
    func showSignupFailureAlert(errorText:String?=nil) {
        let title = "Failed to signin"
        var message = "Failed to signin with facebook. "
        if (errorText != nil) {
            message += errorText!
        }
        let btnText = "confirm"
        
        if NSClassFromString("UIAlertController") != nil {
            let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: btnText, style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        } else {
            let  alert = UIAlertView()
            alert.title = title
            alert.message = message
            alert.addButtonWithTitle(btnText)
            alert.show()
        }
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
