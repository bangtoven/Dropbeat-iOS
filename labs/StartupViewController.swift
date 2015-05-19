//
//  StartupViewController.swift
//  labs
//
//  Created by vulpes on 2015. 5. 20..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit
import MMDrawerController

class StartupViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        
//        Account.getAccountWithCompletionHandler({(account:Account?, error:NSError?) -> Void in
//            if (error != nil) {
//                println("failed to get account due to \(error!.description)")
//            }
//            var appDelegate:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
//            appDelegate.account = account
//        })
        self.performSegueWithIdentifier("DrawerSegue", sender: self)
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "DrawerSegue") {
            var drawerController:MMDrawerController = segue.destinationViewController as! MMDrawerController
            drawerController.openDrawerGestureModeMask = MMOpenDrawerGestureMode.PanningCenterView
            drawerController.closeDrawerGestureModeMask = MMCloseDrawerGestureMode.PanningCenterView
            drawerController.setDrawerVisualStateBlock({ (drawerController:MMDrawerController!, drawerSide:MMDrawerSide, percentVisible:CGFloat) -> Void in
                var block:MMDrawerControllerDrawerVisualStateBlock
                block = MMSparkDrawerVisualStateManager.sharedMaanger.drawerVisualStateBlockForDrawerSide(drawerSide)
                block(drawerController, drawerSide, percentVisible)
            })
        
            var appDelegate:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            appDelegate.centerContainer = drawerController
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
