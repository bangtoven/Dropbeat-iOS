//
//  FeedbackViewController.swift
//  labs
//
//  Created by vulpes on 2015. 7. 31..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

class FeedbackViewController: BaseViewController {

    @IBOutlet weak var textViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var emailHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var emailView: UITextField!
    @IBOutlet weak var submitBtn: UIButton!
    @IBOutlet weak var textView: UITextView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if Account.getCachedAccount() != nil {
            emailView.hidden = true
            emailHeightConstraint.constant = 0
            textViewTopConstraint.constant = 0
        }
        
        submitBtn.layer.cornerRadius = 3.0
        textView.layer.cornerRadius = 3.0
        textView.layer.borderColor = UIColor(netHex: 0xcccccc).CGColor
        textView.layer.borderWidth = 1
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.screenName = "FeedbackScreen"
    }
    
    func isValidEmail(testStr:String) -> Bool {
        let emailRegEx = "^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluateWithObject(testStr)
    }
    
    @IBAction func onSubmitBtnClicked(sender: AnyObject) {
        var senderEmail:String?
        if Account.getCachedAccount() != nil {
            senderEmail = Account.getCachedAccount()!.user!.email
        } else {
            senderEmail = emailView.text
        }
        
        if senderEmail == nil || count(senderEmail!) == 0 {
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
        if text == nil || count(text) == 0 {
            ViewUtils.showNoticeAlert(self,
                title: NSLocalizedString("Invalid format", comment:""),
                message: NSLocalizedString("Empty message cannot be sent", comment:""))
            return
        }
        let progressHud = ViewUtils.showProgress(self, message: NSLocalizedString("Sending..", comment:""))
        Requests.sendFeedback(senderEmail!, content: text) {
                (req:NSURLRequest, resp:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
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
                progressHud.hide(false)
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
                progressHud.hide(false)
                self.navigationController?.popViewControllerAnimated(true)
            })
        }
    }
}
