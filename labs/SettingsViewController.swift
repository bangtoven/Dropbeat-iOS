//
//  SettingsViewController.swift
//  labs
//
//  Created by vulpes on 2015. 5. 15..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

class SettingsViewController: UITableViewController {

    @IBOutlet weak var accountInfoView: UIView!
    @IBOutlet weak var signinBtn: UIButton!
    @IBOutlet weak var emailView: UILabel!
    @IBOutlet weak var versionView: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let account = Account.getCachedAccount()
        if (account != nil) {
            emailView.text = account!.user!.email
            accountInfoView.hidden = false
            signinBtn.hidden = true
        } else {
            accountInfoView.hidden = true
            signinBtn.hidden = false
        }
        
        let verObject: AnyObject? = NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"]
        versionView.text = verObject as? String

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "sender", name: NotifyKey.appSignout, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotifyKey.appSignout, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func sender() {
    }
    
    @IBAction func onSigninBtnClicked(sender: UIButton) {
        var appDelegate:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        var centerViewController = appDelegate.centerContainer!.centerViewController as! CenterViewController
        centerViewController.showSigninView()
    }
    
    @IBAction func onSignoutBtnClicked(sender: UIButton) {
        ViewUtils.showConfirmAlert(self, title: "Are you sure?", message: "Are you sure you want to sign out?",
                positiveBtnText: "Sign out", positiveBtnCallback: { () -> Void in
            NSNotificationCenter.defaultCenter().postNotificationName(NotifyKey.appSignout, object: nil)
            Account.signout()
            PlaylistViewController.hasAccount = false
        })
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
