//
//  Utils.swift
//  labs
//
//  Created by vulpes on 2015. 5. 21..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import Foundation
import UIKit

class ViewUtils {
    static func showNoticeAlert(viewController:UIViewController, title:String, message:String, btnText:String="confirm") {
        if (NSClassFromString("UIAlertController") != nil) {
            let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: btnText, style: UIAlertActionStyle.Default, handler: nil))
            viewController.presentViewController(alert, animated: true, completion: nil)
        } else {
            let  alert = UIAlertView()
            alert.title = title
            alert.message = message
            alert.addButtonWithTitle(btnText)
            alert.show()
        }
    }
}