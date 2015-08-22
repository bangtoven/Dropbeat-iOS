//
//  SigninWithEmailViewController.swift
//  labs
//
//  Created by vulpes on 2015. 8. 19..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

class SigninWithEmailViewController: BaseViewController, UIScrollViewDelegate, UITextFieldDelegate{

    @IBOutlet weak var scrollInner: UIView!
    @IBOutlet weak var scrollInnerWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var signinBtn: UIButton!

    @IBOutlet weak var passwordErrorView: UILabel!
    @IBOutlet weak var passwordInputView: UITextField!
    @IBOutlet weak var emailErrorView: UILabel!
    @IBOutlet weak var emailInputView: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollInnerWidthConstraint.constant = self.view.bounds.width
        
        signinBtn.layer.borderWidth = 1
        signinBtn.layer.cornerRadius = 3.0
        signinBtn.layer.borderColor = UIColor(netHex: 0x982EF4).CGColor
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.screenName = "SigninWithEmailViewScreen"
    }
    
    @IBAction func onTapped(sender: AnyObject) {
        emailInputView.endEditing(true)
        passwordInputView.endEditing(true)
    }
    
    @IBAction func onSigninBtnClicked(sender: AnyObject) {
        doSubmit()
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        switch(textField.tag) {
        case 0:
            passwordInputView.becomeFirstResponder()
            return true
        case 1:
            doSubmit()
            return true
        default:
            return false
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        scrollView.contentOffset = CGPointMake(0, scrollView.contentOffset.y)
    }
    
    func doSubmit() {
        emailErrorView.hidden = true
        passwordErrorView.hidden = true
        
        let email = emailInputView.text
        let password = passwordInputView.text
        
        if !isValid() {
            return
        }
        
        let progressHud = ViewUtils.showProgress(self, message: "")
        
        Requests.emailSignin(email, password: password) { (req:NSURLRequest, resp:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            if error != nil || result == nil {
                progressHud.hide(true)
                if (error != nil && error!.domain == NSURLErrorDomain &&
                        error!.code == NSURLErrorNotConnectedToInternet) {
                            
                    ViewUtils.showConfirmAlert(self,
                        title: NSLocalizedString("Failed to sign in", comment:""),
                        message: NSLocalizedString("Internet is not connected", comment:""),
                        positiveBtnText: NSLocalizedString("Retry", comment: ""),
                        positiveBtnCallback: { () -> Void in
                            self.doSubmit()
                        })
                    return
                }
                
                ViewUtils.showNoticeAlert(self,
                    title: NSLocalizedString("Failed to sign in", comment:""),
                    message: NSLocalizedString("Failed to form submit", comment:""))
                return
            }
            
            let json = JSON(result!)
            if !(json["success"].bool ?? false) || json["token"].string == nil {
                progressHud.hide(true)
                
                if json["error"].string != nil &&
                    json["error"].stringValue.toInt() != nil &&
                    self.handleRemoteError(json["error"].stringValue.toInt()!) {
                    return
                }
                
                ViewUtils.showNoticeAlert(self,
                    title: NSLocalizedString("Failed to sign in", comment:""),
                    message: NSLocalizedString("Failed to sign in", comment:""))
                return
            }
            self.afterSignin(json["token"].stringValue)
        }
        
    }
    
    func isValid() -> Bool {
        let email = emailInputView.text
        let password = passwordInputView.text
        
        var valid = true
        
        emailErrorView.text = ""
        if count(email) == 0 {
            emailErrorView.text = NSLocalizedString("Required Field", comment:"")
        } else if !Utils.isValidEmail(email) {
            emailErrorView.text = NSLocalizedString("Invalid email format", comment: "")
        }
        if count(emailErrorView.text!) > 0 {
            emailErrorView.hidden = false
            valid = false
        }
        
        passwordErrorView.text = ""
        if count(password) == 0 {
            passwordErrorView.text = NSLocalizedString("Required Field", comment:"")
            passwordErrorView.hidden = false
            valid = false
        }
        return valid
    }
    
    func handleRemoteError(errorCode:Int) -> Bool {
        switch(errorCode) {
        case 1:
            emailErrorView.text = NSLocalizedString("Email not found", comment: "")
            emailErrorView.hidden = false
            return true
        case 2:
            passwordErrorView.text = NSLocalizedString("Invalied password", comment:"")
            passwordErrorView.hidden = false
            return true
        default:
            return false
        }
    }

    func afterSignin(token:String) {
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
