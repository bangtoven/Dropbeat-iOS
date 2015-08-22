//
//  SignupViewController.swift
//  labs
//
//  Created by vulpes on 2015. 8. 18..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

class SignupViewController: FBSigninableViewController {

    @IBOutlet weak var signupWithEmailBtn: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        signupWithEmailBtn.layer.borderWidth = 1
        signupWithEmailBtn.layer.borderColor = UIColor(netHex: 0x982EF4).CGColor
        signupWithEmailBtn.layer.cornerRadius = 3.0
        
        if self.navigationController!.viewControllers.count <= 1 {
            let barBtn = UIBarButtonItem(title: NSLocalizedString("Close", comment: ""), style: UIBarButtonItemStyle.Plain, target: self, action: "onCloseBtnClicked:")
            barBtn.tintColor = UIColor(netHex: 0x982EF4)
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
