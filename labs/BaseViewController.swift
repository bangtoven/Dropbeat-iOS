//
//  BaseViewController.swift
//  labs
//
//  Created by vulpes on 2015. 5. 25..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

class BaseViewController: GAITrackedViewController {
    
    var isVisible:Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        self.isVisible = true
        

        // Do any additional setup after loading the view.
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        self.isVisible = false
    }
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
