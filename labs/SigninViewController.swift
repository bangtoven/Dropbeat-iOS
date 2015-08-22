//
//  SigninViewController.swift
//  labs
//
//  Created by vulpes on 2015. 5. 18..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

class SigninViewController: FBSigninableViewController{
    
    @IBOutlet weak var signinWithEmailBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        signinWithEmailBtn.layer.borderColor = UIColor(netHex: 0x982EF4).CGColor
        signinWithEmailBtn.layer.borderWidth = 1
        signinWithEmailBtn.layer.cornerRadius = 3.0
        
        if self.navigationController!.viewControllers.count <= 1 {
            let barBtn = UIBarButtonItem(title: NSLocalizedString("Close", comment: ""), style: UIBarButtonItemStyle.Plain, target: self, action: "onCloseBtnClicked:")
            barBtn.tintColor = UIColor(netHex: 0x982EF4)
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
