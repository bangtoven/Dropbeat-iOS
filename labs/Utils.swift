//
//  Utils.swift
//  labs
//
//  Created by vulpes on 2015. 5. 21..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import Foundation
import UIKit
import MBProgressHUD

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
    
    static func showConfirmAlert(viewController:UIViewController,
            title:String, message:String,
            positiveBtnText:String="Proceed", positiveBtnCallback: (() -> Void)?=nil,
            negativeBtnText:String="Cancel", negativeBtnCallback: (() -> Void)?=nil) {
            
        if (NSClassFromString("UIAlertController") != nil) {
            let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: positiveBtnText, style: UIAlertActionStyle.Default,
                    handler:{ (action:UIAlertAction!) -> Void in
                        positiveBtnCallback?()
                    }))
            alert.addAction(UIAlertAction(title: negativeBtnText, style: UIAlertActionStyle.Default,
                    handler:{ (action:UIAlertAction!) -> Void in
                        negativeBtnCallback?()
                    }))
            viewController.presentViewController(alert, animated: true, completion: nil)
        } else {
            let alertDelegate = AlertViewDelegate()
            alertDelegate.onClickedButtonAtIndex = { (alertView:UIAlertView, buttonIndex:Int) -> Void in
                if (buttonIndex == 0) {
                    positiveBtnCallback?()
                } else {
                    negativeBtnCallback?()
                }
            }
            let alert = UIAlertView()
            alert.title = title
            alert.message = message
            alert.addButtonWithTitle(positiveBtnText)
            alert.addButtonWithTitle(negativeBtnText)
            alert.delegate = alertDelegate
            alert.show()
        }
    }
    
    static func showTextInputAlert(viewController:UIViewController,
            title:String, message:String, placeholder:String,
            positiveBtnText:String="Submit", positiveBtnCallback: (result:String) -> Void,
            negativeBtnText:String="Cancel", negativeBtnCallback: (() -> Void)?=nil) {
    
        if (NSClassFromString("UIAlertController") != nil) {
            let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
            alert.addTextFieldWithConfigurationHandler({ (textField: UITextField!) in
                textField.placeholder = placeholder
            })
            alert.addAction(UIAlertAction(title: positiveBtnText, style: UIAlertActionStyle.Default,
                    handler:{ (action:UIAlertAction!) -> Void in
                        let textField = (alert.textFields as! [UITextField])[0]
                        positiveBtnCallback(result: textField.text)
                    }))
            alert.addAction(UIAlertAction(title: negativeBtnText, style: UIAlertActionStyle.Default,
                    handler:{ (action:UIAlertAction!) -> Void in
                        negativeBtnCallback?()
                    }))
            viewController.presentViewController(alert, animated: true, completion: nil)
            
            
        } else {
            
            let alertDelegate = AlertViewDelegate()
            alertDelegate.onClickedButtonAtIndex = { (alertView:UIAlertView, buttonIndex:Int) -> Void in
                if (buttonIndex == 0) {
                    let textField = alertView.textFieldAtIndex(0)!
                    positiveBtnCallback(result: textField.text)
                } else {
                    negativeBtnCallback?()
                }
            }
            let alert = UIAlertView()
            alert.alertViewStyle = UIAlertViewStyle.PlainTextInput
            let alertTextField = alert.textFieldAtIndex(0)
            alertTextField?.placeholder = placeholder
            alert.title = title
            alert.message = message
            alert.addButtonWithTitle(positiveBtnText)
            alert.addButtonWithTitle(negativeBtnText)
            alert.delegate = alertDelegate
            alert.show()
        }
    }

    
    
    
    static func showToast(viewController:UIViewController, message:String) {
        if (viewController.navigationController == nil) {
            return
        }
        let hud = MBProgressHUD.showHUDAddedTo(viewController.view, animated: true)
        hud.mode = MBProgressHUDMode.Text
        hud.labelText = message
        hud.margin = 10.0
        hud.yOffset = 150
        hud.removeFromSuperViewOnHide = true
        hud.hide(true, afterDelay: 1)
    }
    
    static func showProgress(viewController:UIViewController, message:String) -> MBProgressHUD {
        let hud = MBProgressHUD.showHUDAddedTo(viewController.view, animated: true)
        hud.mode = MBProgressHUDMode.Indeterminate
        hud.labelText = message
        hud.removeFromSuperViewOnHide = true
        hud.show(true)
        return hud
    }
}

class AlertViewDelegate: NSObject, UIAlertViewDelegate{
    var onClickedButtonAtIndex: ((alertView:UIAlertView, buttonIndex:Int) -> Void)?
    var onDidDismissWithButtonIndex: ((alertView:UIAlertView, buttonIndex:Int) -> Void)?
    var onCancel: ((alertView:UIAlertView) -> Void)?
    var onWillDismissWithButtonIndex: ((alertView:UIAlertView, buttonIndex:Int) -> Void)?
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        onClickedButtonAtIndex?(alertView: alertView, buttonIndex: buttonIndex)
    }
    
    func alertView(alertView: UIAlertView, didDismissWithButtonIndex buttonIndex: Int) {
        onDidDismissWithButtonIndex?(alertView: alertView, buttonIndex: buttonIndex)
    }
    
    func alertView(alertView: UIAlertView, willDismissWithButtonIndex buttonIndex: Int) {
        onWillDismissWithButtonIndex?(alertView: alertView, buttonIndex: buttonIndex)
    }
    
    func alertViewCancel(alertView: UIAlertView) {
        onCancel?(alertView: alertView)
    }
}