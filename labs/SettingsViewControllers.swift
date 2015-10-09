//
//  SettingsViewController.swift
//  labs
//
//  Created by vulpes on 2015. 5. 15..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//
import UIKit

class SettingsViewController: UITableViewController {

    @IBOutlet weak var signoutBtn: UIButton!
    @IBOutlet weak var signinBtn: UIButton!
    @IBOutlet weak var signupBtn: UIButton!
    @IBOutlet weak var versionView: UILabel!
    
    @IBOutlet var settingTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if Account.getCachedAccount() != nil {
            signinBtn.hidden = true
            signupBtn.hidden = true
            signoutBtn.hidden = false
        } else {
            signinBtn.hidden = false
            signupBtn.hidden = false
            signoutBtn.hidden = true
        }
        
        let verObject: AnyObject? = NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"]
        versionView.text = verObject as? String

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if tableView.indexPathForSelectedRow != nil {
            tableView.deselectRowAtIndexPath(tableView.indexPathForSelectedRow!, animated: false)
        }
    }
    
    @IBAction func onSignoutBtnClicked(sender: UIButton) {
        ViewUtils.showConfirmAlert(self,
            title: NSLocalizedString("Are you sure?", comment:""),
            message: NSLocalizedString("Are you sure you want to sign out?", comment:""),
            positiveBtnText: NSLocalizedString("Sign out", comment:""), positiveBtnCallback: { () -> Void in
                
                let keychainItemWrapper = KeychainItemWrapper(identifier: "net.dropbeat.spark", accessGroup:nil)
                keychainItemWrapper.resetKeychainItem()
                Account.account = nil
                let appDelegate:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                appDelegate.account = nil
//                _PlayerViewController.sharedInstance!.resignObservers()
                let navController:UINavigationController = appDelegate.window?.rootViewController as! UINavigationController
                navController.popToRootViewControllerAnimated(false)
        })
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section > 0 {
            return 50
        }
        if Account.getCachedAccount() != nil {
            return 50
        }
        return 126
    }
}


//
//  CopyrightViewController.swift
//  labs
//
//  Created by vulpes on 2015. 5. 22..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

class CopyrightViewController: UIViewController {

    @IBOutlet weak var webView: UIWebView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let htmlFile = NSBundle.mainBundle().pathForResource("copyright", ofType: "html")
        if (htmlFile != nil) {
            let request = NSURLRequest(URL: NSURL(fileURLWithPath: htmlFile!))
            webView.loadRequest(request)
        }
        

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
//  FeedbackViewController.swift
//  labs
//
//  Created by vulpes on 2015. 7. 31..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

class FeedbackViewController: BaseViewController,
        UITextFieldDelegate, UITextViewDelegate, UIScrollViewDelegate {

    @IBOutlet weak var scrollInnerWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var scrollInnerView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var emailView: UITextField!
    @IBOutlet weak var submitBtn: UIButton!
    @IBOutlet weak var textView: UITextView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let account = Account.getCachedAccount() {
            emailView.text = account.user!.email
        }
        
        submitBtn.layer.cornerRadius = 3.0
        submitBtn.layer.borderWidth = 1
        submitBtn.layer.borderColor = UIColor.dropbeatColor().CGColor
        
        textView.layer.cornerRadius = 3.0
        textView.layer.borderColor = UIColor(netHex: 0xcccccc).CGColor
        textView.layer.borderWidth = 1
        
        scrollInnerWidthConstraint.constant = view.bounds.width
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.screenName = "FeedbackScreen"
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textView.becomeFirstResponder()
        return true
    }
    
    func isValidEmail(testStr:String) -> Bool {
        let emailRegEx = "^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluateWithObject(testStr)
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        scrollView.contentOffset = CGPointMake(0, scrollView.contentOffset.y)
    }
    
    @IBAction func onTapped(sender: AnyObject) {
        emailView.endEditing(true)
        textView.endEditing(true)
    }
    
    @IBAction func onSubmitBtnClicked(sender: AnyObject) {
        var senderEmail:String?
        emailView.endEditing(true)
        textView.endEditing(true)
        senderEmail = emailView.text
        
        if senderEmail == nil || (senderEmail!).characters.count == 0 {
            ViewUtils.showNoticeAlert(self,
                title: NSLocalizedString("Invalid format", comment:""),
                message: NSLocalizedString("Email is required", comment:""))
            return
        }
        
        if !isValidEmail(senderEmail!) {
            ViewUtils.showNoticeAlert(self,
                title: NSLocalizedString("Invalid format", comment:""),
                message: NSLocalizedString("Invalid email format", comment:""))
            return
        }
        
        let text = textView.text
        if text == nil || text.characters.count == 0 {
            ViewUtils.showNoticeAlert(self,
                title: NSLocalizedString("Invalid format", comment:""),
                message: NSLocalizedString("Empty message cannot be sent", comment:""))
            return
        }
        let progressHud = ViewUtils.showProgress(self, message: NSLocalizedString("Sending..", comment:""))
        Requests.sendFeedback(senderEmail!, content: text) {
                (req, resp, result, error) -> Void in
            var message:String = NSLocalizedString("Failed to send feedback.", comment:"")
            var success = true
            if success && error != nil {
                success = false
                if (error!.domain == NSURLErrorDomain &&
                        error!.code == NSURLErrorNotConnectedToInternet) {
                    message = " " + NSLocalizedString("Internet is not connected", comment:"")
                }
            }
            
            if success && result == nil {
                success = false
            }
            
            if success && !(JSON(result!)["success"].bool ?? false) {
                success = false
            }
            
            if !success {
                progressHud.hide(true)
                ViewUtils.showConfirmAlert(self,
                    title: NSLocalizedString("Failed to send", comment:""),
                    message: message,
                    positiveBtnText: NSLocalizedString("Retry", comment:""),
                    positiveBtnCallback: { () -> Void in
                        
                        self.onSubmitBtnClicked(sender)
                        
                    }, negativeBtnText: NSLocalizedString("Cancel", comment:""), negativeBtnCallback: nil)
                return
            }
            ViewUtils.showNoticeAlert(self,
                    title: NSLocalizedString("Feedback Submitted!", comment:""),
                    message: NSLocalizedString("Thank you for your feedback.", comment:""),
                    btnText: NSLocalizedString("Confirm", comment:""), callback: { () -> Void in
                progressHud.hide(true)
                self.navigationController?.popViewControllerAnimated(true)
            })
        }
    }
}
