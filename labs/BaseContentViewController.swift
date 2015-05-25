//
//  BaseContentViewController.swift
//  labs
//
//  Created by vulpes on 2015. 5. 20..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

class BaseContentViewController: BaseViewController {
    
    var navDrawerBtn:UIBarButtonItem {
        let menuImage = UIImage(named: "menu-100.png")
        let menuBtn = UIButton(frame: CGRectMake(0,0,30,30))
        menuBtn.addTarget(self, action: "menuBtnClicked:", forControlEvents: UIControlEvents.TouchUpInside)
        menuBtn.setImage(menuImage, forState: UIControlState.Normal)
        menuBtn.imageEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        return UIBarButtonItem(customView: menuBtn)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController!.navigationBar.barStyle = UIBarStyle.Black
        self.navigationItem.leftBarButtonItem = self.navDrawerBtn

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func menuBtnClicked(sender: AnyObject) {
        var appDelegate:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.centerContainer!.toggleDrawerSide(MMDrawerSide.Left, animated: true, completion: nil)
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
