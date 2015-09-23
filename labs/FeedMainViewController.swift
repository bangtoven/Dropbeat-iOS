    //
//  FeedMainViewController.swift
//  labs
//
//  Created by Jungho Bang on 2015. 9. 24..
//  Copyright © 2015년 dropbeat. All rights reserved.
//

import UIKit

class FeedMainViewController: DropdownMenuController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.menubar = self.navigationController?.navigationBar
        self.dropShapeShouldShowWhenOpen(false)
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
