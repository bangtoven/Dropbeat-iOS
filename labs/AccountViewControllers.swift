import UIKit

//
//  NeedAuthViewController.swift
//  labs
//
//  Created by vulpes on 2015. 8. 18..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

class NeedAuthViewController: BaseViewController {
    
    class func showNeedAuthViewController(from: UIViewController!) {
        let storyboard: UIStoryboard = UIStoryboard(name: "Settings", bundle: nil)
        let vc: UINavigationController = storyboard.instantiateViewControllerWithIdentifier("AccountRequired") as! UINavigationController
        from.presentViewController(vc, animated: true, completion: nil)
    }
    
    @IBOutlet weak var signinBtn: UIButton!
    @IBOutlet weak var signupBtn: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        signinBtn.layer.borderColor = UIColor.dropbeatColor().CGColor
        signinBtn.layer.borderWidth = 1
        signinBtn.layer.cornerRadius = 3.0
        
        signupBtn.layer.borderColor = UIColor.dropbeatColor().CGColor
        signupBtn.layer.borderWidth = 1
        signupBtn.layer.cornerRadius = 3.0
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.screenName = "NeedAuthViewScreen"
    }
    
    @IBAction func onCloseBtnClicked(sender: AnyObject) {
        if let navController = self.navigationController {
            
            navController.dismissViewControllerAnimated(true, completion: nil)
        } else {
            dismissViewControllerAnimated(true, completion: nil)
        }
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


//
//  FBSigninableTableViewController.swift
//  labs
//
//  Created by vulpes on 2015. 8. 18..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

class FBSigninableViewController: BaseViewController {
    
    @IBOutlet weak var signinWithFacebookBtn: UIButton!
    private var progressHud:MBProgressHUD?
    
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
                let user = User.parseUser(result!)
                
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

//
//  SigninViewController.swift
//  labs
//
//  Created by vulpes on 2015. 5. 18..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

class SigninViewController: FBSigninableViewController{
    
    @IBOutlet weak var signinWithEmailBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        signinWithEmailBtn.layer.borderColor = UIColor.dropbeatColor().CGColor
        signinWithEmailBtn.layer.borderWidth = 1
        signinWithEmailBtn.layer.cornerRadius = 3.0
        
        if self.navigationController!.viewControllers.count <= 1 {
            let barBtn = UIBarButtonItem(title: NSLocalizedString("Close", comment: ""), style: UIBarButtonItemStyle.Plain, target: self, action: "onCloseBtnClicked:")
            barBtn.tintColor = UIColor.dropbeatColor()
            self.navigationItem.leftBarButtonItem = barBtn
        }
    }

    func onCloseBtnClicked(sender: AnyObject) {
        presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
        
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.screenName = "SigninViewScreen"
    }
}


//
//  SigninWithEmailViewController.swift
//  labs
//
//  Created by vulpes on 2015. 8. 19..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

class SigninWithEmailViewController: BaseViewController, UIScrollViewDelegate, UITextFieldDelegate{
    
    @IBOutlet weak var scrollInner: UIView!
    @IBOutlet weak var scrollInnerWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var signinBtn: UIButton!
    
    @IBOutlet weak var passwordErrorView: UILabel!
    @IBOutlet weak var passwordInputView: UITextField!
    @IBOutlet weak var emailErrorView: UILabel!
    @IBOutlet weak var emailInputView: UITextField!
    
    private var isSubmitting = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollInnerWidthConstraint.constant = self.view.bounds.width
        
        signinBtn.layer.borderWidth = 1
        signinBtn.layer.cornerRadius = 3.0
        signinBtn.layer.borderColor = UIColor.dropbeatColor().CGColor
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
        emailInputView.endEditing(true)
        passwordInputView.endEditing(true)
        if isSubmitting {
            return
        }
        emailErrorView.hidden = true
        passwordErrorView.hidden = true
        
        let email = emailInputView.text
        let password = passwordInputView.text
        
        if !isValid() {
            return
        }
        
        let progressHud = ViewUtils.showProgress(self, message: "")
        isSubmitting = true
        
        Requests.emailSignin(email, password: password) { (req:NSURLRequest, resp:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            if error != nil || result == nil {
                self.isSubmitting = false
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
                    message: NSLocalizedString("Failed to submit form", comment:""))
                return
            }
            
            let json = JSON(result!)
            if !(json["success"].bool ?? false) || json["token"].string == nil {
                self.isSubmitting = false
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


//
//  SignupViewController.swift
//  labs
//
//  Created by vulpes on 2015. 8. 18..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

class SignupViewController: FBSigninableViewController {
    
    @IBOutlet weak var signupWithEmailBtn: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        signupWithEmailBtn.layer.borderWidth = 1
        signupWithEmailBtn.layer.borderColor = UIColor.dropbeatColor().CGColor
        signupWithEmailBtn.layer.cornerRadius = 3.0
        
        if self.navigationController!.viewControllers.count <= 1 {
            let barBtn = UIBarButtonItem(title: NSLocalizedString("Close", comment: ""), style: UIBarButtonItemStyle.Plain, target: self, action: "onCloseBtnClicked:")
            barBtn.tintColor = UIColor.dropbeatColor()
            self.navigationItem.leftBarButtonItem = barBtn
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.screenName = "SignupViewScreen"
    }
    
    func onCloseBtnClicked(sender: AnyObject) {
        presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
}


//
//  SignupWithEmailViewController.swift
//  labs
//
//  Created by vulpes on 2015. 8. 19..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

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
        createAccountBtn.layer.borderColor = UIColor.dropbeatColor().CGColor
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
        emailInputView.endEditing(true)
        nicknameInputView.endEditing(true)
        firstNameInputView.endEditing(true)
        lastNameInputView.endEditing(true)
        passwordInputView.endEditing(true)
        passwordConfirmInputView.endEditing(true)
        
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
                progressHud.customView = UIImageView(image: UIImage(named:"37x-Checkmark"))
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
        } else if email.indexOf("@dropbeat.net") > -1 {
            emailErrorView.text = NSLocalizedString("Invalid email domain", comment:"")
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
