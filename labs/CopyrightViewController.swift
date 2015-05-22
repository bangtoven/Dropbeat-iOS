//
//  CopyrightViewController.swift
//  labs
//
//  Created by vulpes on 2015. 5. 22..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

class CopyrightViewController: UIViewController {

    @IBOutlet weak var webView: UIWebView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var htmlFile = NSBundle.mainBundle().pathForResource("copyright", ofType: "html")
        if (htmlFile != nil) {
            var request = NSURLRequest(URL: NSURL(fileURLWithPath: htmlFile!)!)
            webView.loadRequest(request)
        }
        

        // Do any additional setup after loading the view.
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
