//
//  SignupWithEmailViewController.swift
//  labs
//
//  Created by vulpes on 2015. 8. 19..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

class SignupWithEmailViewController: BaseViewController, UIScrollViewDelegate, UITextFieldDelegate {

    @IBOutlet weak var createAccountBtn: UIButton!
    @IBOutlet weak var scrollInnerConstraint: NSLayoutConstraint!
    @IBOutlet weak var scrollInnerView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var passwordConfirmInputView: UITextField!
    @IBOutlet weak var passwordInputView: UITextField!
    @IBOutlet weak var lastNameInputView: UITextField!
    @IBOutlet weak var firstNameInputView: UITextField!
    @IBOutlet weak var nicknameInputView: UITextField!
    @IBOutlet weak var emailInputView: UITextField!
    
    @IBOutlet weak var emailErrorView: UILabel!
    @IBOutlet weak var nicknameErrorView: UILabel!
    @IBOutlet weak var firstNameErrorView: UILabel!
    @IBOutlet weak var lastNameErrorView: UILabel!
    @IBOutlet weak var passwordErrorView: UILabel!
    @IBOutlet weak var passwordConfirmErrorView: UILabel!
    
    private var isSubmitting = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        createAccountBtn.layer.cornerRadius = 3.0
        createAccountBtn.layer.borderColor = UIColor(netHex: 0x982EF4).CGColor
        createAccountBtn.layer.borderWidth = 1
        scrollInnerConstraint.constant = self.view.bounds.width
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func onSubmitBtnClicked(sender: AnyObject) {
        doSubmit()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.screenName = "SignupWithEmailViewScreen"
    }
    
    @IBAction func onTapped(sender: AnyObject) {
        emailInputView.endEditing(true)
        nicknameInputView.endEditing(true)
        firstNameInputView.endEditing(true)
        lastNameInputView.endEditing(true)
        passwordInputView.endEditing(true)
        passwordConfirmInputView.endEditing(true)
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        scrollView.contentOffset = CGPointMake(0, scrollView.contentOffset.y)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        switch(textField.tag) {
        case 0:
            nicknameInputView.becomeFirstResponder()
            return true
        case 1:
            firstNameInputView.becomeFirstResponder()
            return true
        case 2:
            lastNameInputView.becomeFirstResponder()
            return true
        case 3:
            passwordInputView.becomeFirstResponder()
            return true
        case 4:
            passwordConfirmInputView.becomeFirstResponder()
            return true
        case 5:
            doSubmit()
            return true
        default:
            return false
        }
    }
    
    func doSubmit() {
        if isSubmitting {
            return
        }
        emailErrorView.hidden = true
        firstNameErrorView.hidden = true
        lastNameErrorView.hidden = true
        nicknameErrorView.hidden = true
        passwordErrorView.hidden = true
        passwordConfirmErrorView.hidden = true
        
        if !isValid() {
            return
        }
        let email = emailInputView.text
        let firstname = firstNameInputView.text
        let lastname = lastNameInputView.text
        let nickname = nicknameInputView.text
        let password = passwordInputView.text
        let passwordConfirm = passwordConfirmInputView.text
        
        isSubmitting = true
        
        let progressHud = ViewUtils.showProgress(self, message: "")
        Requests.emailSignup(email, firstName: firstname, lastName: lastname,
                nickname: nickname, password: password,
                respCb: { (req:NSURLRequest, resp:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
                    
                    if error != nil || result == nil {
                        self.isSubmitting = false
                        progressHud.hide(true)
                        if (error != nil && error!.domain == NSURLErrorDomain &&
                                error!.code == NSURLErrorNotConnectedToInternet) {
                                    
                            ViewUtils.showConfirmAlert(self,
                                title: NSLocalizedString("Failed to sign up", comment:""),
                                message: NSLocalizedString("Internet is not connected", comment:""),
                                positiveBtnText: NSLocalizedString("Retry", comment: ""),
                                positiveBtnCallback: { () -> Void in
                                    self.doSubmit()
                                })
                            return
                        }
                       
                        ViewUtils.showNoticeAlert(self,
                            title: NSLocalizedString("Failed to sign up", comment:""),
                            message: NSLocalizedString("Failed to submit form", comment:""))
                        return
                    }
                    
                    var json = JSON(result!)
                    
                    if !(json["success"].bool ?? false) || json["token"].string == nil {
                        self.isSubmitting = false
                        progressHud.hide(true)
                        
                        if json["error"].string != nil &&
                            json["error"].stringValue.toInt() != nil &&
                            self.handleRemoteError(json["error"].stringValue.toInt()!) {
                            return
                        }
                        
                        ViewUtils.showNoticeAlert(self,
                            title: NSLocalizedString("Failed to sign up", comment:""),
                            message: NSLocalizedString("Failed to submit form", comment:""))
                        return
                    }
                    progressHud.mode = MBProgressHUDMode.CustomView
                    progressHud.customView = UIImageView(image: UIImage(named:"37x-Checkmark.png"))
                    progressHud.hide(true, afterDelay: 1)
                    let popTime = dispatch_time(DISPATCH_TIME_NOW, Int64(1.0 * Double(NSEC_PER_SEC)));
                    dispatch_after(popTime, dispatch_get_main_queue(), {() -> Void in
                        self.afterSignup(json["token"].stringValue)
                    })
                    
        })
    }
    
    func afterSignup(token:String) {
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
    
    func handleRemoteError(errorCode:Int) -> Bool {
        switch(errorCode) {
        case 1:
            emailErrorView.text = NSLocalizedString("Email already exists", comment:"")
            emailErrorView.hidden = false
            return true
        case 2:
            nicknameErrorView.text = NSLocalizedString("Nickname already exists", comment:"")
            nicknameErrorView.hidden = false
            return true
        default:
            return false
        }
    }
    
    func isValid() -> Bool {
        let email = emailInputView.text
        let firstname = firstNameInputView.text
        let lastname = lastNameInputView.text
        let nickname = nicknameInputView.text
        let password = passwordInputView.text
        let passwordConfirm = passwordConfirmInputView.text
        
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
        
        firstNameErrorView.text = ""
        if count(firstname) == 0 {
            firstNameErrorView.text = NSLocalizedString("Required Field", comment:"")
        } else if count(firstname) > 30 {
            firstNameErrorView.text = NSString.localizedStringWithFormat(
                NSLocalizedString("Must be less than %d charaters long", comment:""), 30) as String
        }
        if count(firstNameErrorView.text!) > 0 {
            firstNameErrorView.hidden = false
            valid = false
        }
        
        lastNameErrorView.text = ""
        if count(lastname) == 0 {
            lastNameErrorView.text = NSLocalizedString("Required Field", comment:"")
        } else if count(lastname) > 30 {
            lastNameErrorView.text = NSString.localizedStringWithFormat(
                NSLocalizedString("Must be less than %d charaters long", comment:""), 30) as String
        }
        if count(firstNameErrorView.text!) > 0 {
            lastNameErrorView.hidden = false
            valid = false
        }
        
        nicknameErrorView.text = ""
        if count(nickname) == 0 {
            nicknameErrorView.text = NSLocalizedString("Required Field", comment:"")
        } else if count(nickname) > 25 {
            nicknameErrorView.text = NSString.localizedStringWithFormat(
                NSLocalizedString("Must be less than %d charaters long", comment:""), 25) as String
        }
        if count(nicknameErrorView.text!) > 0 {
            nicknameErrorView.hidden = false
            valid = false
        }
        
        passwordErrorView.text = ""
        if count(password) == 0 {
            passwordErrorView.text = NSLocalizedString("Required Field", comment:"")
        } else if count(password) > 25 {
            passwordErrorView.text = NSString.localizedStringWithFormat(
                NSLocalizedString("Must be less than %d charaters long", comment:""), 25) as String
        } else if count(password) < 6 {
            passwordErrorView.text = NSString.localizedStringWithFormat(
                NSLocalizedString("Must be longer than %d charaters", comment:""), 6) as String
        }
        if count(passwordErrorView.text!) > 0 {
            passwordErrorView.hidden = false
            valid = false
        }
        
        passwordConfirmErrorView.text = ""
        if count(passwordConfirm) == 0 {
            passwordConfirmErrorView.text = NSLocalizedString("Required Field", comment:"")
        } else if passwordConfirm != password {
            passwordConfirmErrorView.text = NSLocalizedString("Confirmation password for not match original", comment:"")
        }
        if count(passwordConfirmErrorView.text!) > 0 {
            passwordConfirmErrorView.hidden = false
            valid = false
        }
        
        return valid
    }
}
