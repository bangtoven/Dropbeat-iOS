//
//  SettingsViewController.swift
//  labs
//
//  Created by vulpes on 2015. 5. 15..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit
import MMDrawerController

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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onSigninBtnClicked(sender: UIButton) {
        var appDelegate:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        var centerViewController = appDelegate.centerContainer!.centerViewController as! CenterViewController
        centerViewController.showSigninView()
    }
    
    @IBAction func onSignoutBtnClicked(sender: UIButton) {
        ViewUtils.showConfirmAlert(self, title: "Are you sure?", message: "Are you sure you want to sign out?", positiveBtnText: "Sign out") { () -> Void in
            Account.signout()
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
