//
//  ViewController.swift
//  labs
//
//  Created by Park Il Su on 2015. 5. 14..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit
import Alamofire


class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        Alamofire.request(.GET, "http://httpbin.org/get").responseJSON{ (_,_,JSON,_) in
            println(JSON)
        }
        /*
        Requests.search("alesso", respCb: { (_,_,JSON,_) in
            println(JSON)
        })
*/
        Requests.userSelf({ (_,_,JSON,_) in
            println(JSON)
        })
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}