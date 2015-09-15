//
//  ViewController.swift
//  playground
//
//  Created by Jungho Bang on 2015. 9. 10..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var resourceTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "Show User" {
            var uvc: UserViewController = segue.destinationViewController as! UserViewController
            uvc.resource = self.resourceTextField.text
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Plain, target:nil, action:nil)
        }
    }
    
    @IBAction func userBtnTapped(sender: AnyObject) {
        self.resourceTextField.text = "teksu"
    }
    
    @IBAction func artistBtnTapped(sender: AnyObject) {
        self.resourceTextField.text = "oliver-heldens"
    }

    @IBAction func channelBtnTapped(sender: AnyObject) {
        self.resourceTextField.text = "liquicity"
    }
}