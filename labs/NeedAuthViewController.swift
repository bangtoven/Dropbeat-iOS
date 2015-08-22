//
//  NeedAuthViewController.swift
//  labs
//
//  Created by vulpes on 2015. 8. 18..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

class NeedAuthViewController: BaseViewController {

    @IBOutlet weak var signinBtn: UIButton!
    @IBOutlet weak var signupBtn: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()

        signinBtn.layer.borderColor = UIColor(netHex:0x982EF4).CGColor
        signinBtn.layer.borderWidth = 1
        signinBtn.layer.cornerRadius = 3.0
        
        signupBtn.layer.borderColor = UIColor(netHex:0x982EF4).CGColor
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
