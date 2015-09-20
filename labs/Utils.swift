//
//  Utils.swift
//  labs
//
//  Created by vulpes on 2015. 5. 21..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    func rotate360Degrees(duration: CFTimeInterval = 1.0, completionDelegate: AnyObject? = nil) {
        let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotateAnimation.fromValue = 0.0
        rotateAnimation.toValue = CGFloat(M_PI * 2.0)
        rotateAnimation.duration = duration
        rotateAnimation.cumulative = true
        
        self.layer.removeAllAnimations()
        
        if let delegate: AnyObject = completionDelegate {
            rotateAnimation.delegate = delegate
        }
        self.layer.addAnimation(rotateAnimation, forKey: nil)
    }
}

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(netHex:Int) {
        self.init(red:(netHex >> 16) & 0xff, green:(netHex >> 8) & 0xff, blue:netHex & 0xff)
    }
    
    static func dropbeatColor(alpha: CGFloat = 1.0, saturation: CGFloat = 1.0) -> UIColor {
        var c = UIColor(netHex:0x982EF4)
        if alpha != 1.0 || saturation != 1.0 {
            c = UIColor(baseColor: c, alpha: alpha, saturation: saturation)
        }
        return c
    }
    
    convenience init(baseColor: UIColor, alpha: CGFloat = 1.0, saturation: CGFloat = 1.0) {
        var r: CGFloat = 0.0
        var g: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = 0.0
        baseColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        // alpha
        a = a * alpha
        
        // saturation
        func convert (v: CGFloat) -> CGFloat {
            return v + (1-v)*(1-saturation)
        }
        
        self.init(red: convert(r), green: convert(g), blue: convert(b), alpha: a)
    }
}

class PaddingLabel:UILabel {
    var topInset:CGFloat = 0.0
    var leftInset:CGFloat = 0.0
    var rightInset:CGFloat = 0.0
    var bottomInset:CGFloat = 0.0
    
    override func intrinsicContentSize() -> CGSize {
        var intrinsicSuperViewContentSize:CGSize = super.intrinsicContentSize()
        intrinsicSuperViewContentSize.height += topInset + bottomInset ;
        intrinsicSuperViewContentSize.width += leftInset + rightInset ;
        return intrinsicSuperViewContentSize ;
    }
    
    func setContentEdgeInsets(edgeInsets:UIEdgeInsets) {
        topInset = edgeInsets.top;
        leftInset = edgeInsets.left;
        rightInset = edgeInsets.right;
        bottomInset = edgeInsets.bottom;
        self.invalidateIntrinsicContentSize();
    }
}

class Utils {
    static func isValidEmail(testStr:String) -> Bool {
        let emailRegEx = "^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluateWithObject(testStr)
    }
}

class ViewUtils {
    static func showNoticeAlert(viewController:UIViewController, title:String, message:String, btnText:String=NSLocalizedString("Confirm", comment:""), callback:(() -> Void)?=nil) {
        
        if #available(iOS 8.0, *) {
            let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: btnText, style: UIAlertActionStyle.Default,
                handler:{ (action:UIAlertAction!) -> Void in
                    callback?()
            }))
            viewController.presentViewController(alert, animated: true, completion: nil)
        } else {
            let alert = UIAlertView()
            let alertDelegate = AlertViewDelegate.sharedInstance
            alertDelegate.onClickedButtonAtIndex = { (alertView:UIAlertView, buttonIndex:Int) -> Void in
                if (buttonIndex == 0) {
                    callback?()
                }
                alert.delegate = nil
                alertDelegate.onClickedButtonAtIndex = nil
            }
            alert.title = title
            alert.message = message
            alert.addButtonWithTitle(btnText)
            alert.delegate = alertDelegate
            alert.show()
        }
    }
    
    static func showConfirmAlert(viewController:UIViewController,
            title:String, message:String,
            positiveBtnText:String=NSLocalizedString("Proceed", comment:""), positiveBtnCallback: (() -> Void)?=nil,
            negativeBtnText:String=NSLocalizedString("Cancel", comment:""), negativeBtnCallback: (() -> Void)?=nil) {
            
        if #available(iOS 8.0, *) {
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
            let alert = UIAlertView()
            let alertDelegate = AlertViewDelegate.sharedInstance
            alertDelegate.onClickedButtonAtIndex = { (alertView:UIAlertView, buttonIndex:Int) -> Void in
                if (buttonIndex == 0) {
                    positiveBtnCallback?()
                } else {
                    negativeBtnCallback?()
                }
                alert.delegate = nil
                alertDelegate.onClickedButtonAtIndex = nil
            }
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
            positiveBtnText:String=NSLocalizedString("Submit", comment:""), positiveBtnCallback: (result:String) -> Void,
            negativeBtnText:String=NSLocalizedString("Cancel", comment:""), negativeBtnCallback: (() -> Void)?=nil) {
    
        if #available(iOS 8.0, *) {
            let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
            alert.addTextFieldWithConfigurationHandler({ (textField: UITextField) in
                textField.placeholder = placeholder
            })
            alert.addAction(UIAlertAction(title: positiveBtnText, style: UIAlertActionStyle.Default,
                    handler:{ (action:UIAlertAction) -> Void in
                        let textField = alert.textFields![0]
                        positiveBtnCallback(result: textField.text!)
                    }))
            alert.addAction(UIAlertAction(title: negativeBtnText, style: UIAlertActionStyle.Default,
                    handler:{ (action:UIAlertAction!) -> Void in
                        negativeBtnCallback?()
                    }))
            viewController.presentViewController(alert, animated: true, completion: nil)
            
            
        } else {
            
            let alert = UIAlertView()
            let alertDelegate = AlertViewDelegate.sharedInstance
            alertDelegate.onClickedButtonAtIndex = { (alertView:UIAlertView, buttonIndex:Int) -> Void in
                if (buttonIndex == 0) {
                    let textField = alertView.textFieldAtIndex(0)!
                    positiveBtnCallback(result: textField.text!)
                } else {
                    negativeBtnCallback?()
                }
                alert.delegate = nil
                alertDelegate.onClickedButtonAtIndex = nil
            }
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
    
    static func showCheck(viewController:UIViewController, message:String) {
        var vc = viewController
        if viewController.navigationController != nil {
            vc = viewController.navigationController!
        }
        let hud:MBProgressHUD = MBProgressHUD.showHUDAddedTo(vc.view, animated: true)
//        hud.color = UIColor(netHex: 0x8F2CEF).colorWithAlphaComponent(0.8)
        hud.customView = UIImageView(image: UIImage(named: "37x-Checkmark"))
    	hud.mode = MBProgressHUDMode.CustomView;
        hud.labelText = message
        hud.margin = 10.0
        hud.yOffset = 150
        hud.removeFromSuperViewOnHide = true
        hud.hide(true, afterDelay: 1)
    }
    
    static func showToast(viewController:UIViewController, message:String) {
        var vc = viewController
        if viewController.navigationController != nil {
            vc = viewController.navigationController!
        }
        let hud:MBProgressHUD = MBProgressHUD.showHUDAddedTo(vc.view, animated: true)
        hud.mode = MBProgressHUDMode.Text
        hud.labelText = message
        hud.margin = 10.0
        hud.yOffset = 150
        hud.removeFromSuperViewOnHide = true
        hud.hide(true, afterDelay: 1)
    }
    
    static func showProgress(viewController:UIViewController, message:String?) -> MBProgressHUD {
        var vc = viewController
        if viewController.navigationController != nil {
            vc = viewController.navigationController!
        }
        let hud = MBProgressHUD.showHUDAddedTo(vc.view, animated: true)
        hud.mode = MBProgressHUDMode.Indeterminate
//        hud.labelText = message
        hud.removeFromSuperViewOnHide = true
        hud.show(true)
        return hud
    }
}

class AlertViewDelegate: NSObject, UIAlertViewDelegate{
    private static var sharedInstance = AlertViewDelegate()
    
    var onClickedButtonAtIndex: ((alertView:UIAlertView, buttonIndex:Int) -> Void)?
    var onDidDismissWithButtonIndex: ((alertView:UIAlertView, buttonIndex:Int) -> Void)?
    var onCancel: ((alertView:UIAlertView) -> Void)?
    var onWillDismissWithButtonIndex: ((alertView:UIAlertView, buttonIndex:Int) -> Void)?
    
    private override init() {
        super.init()
    }
    
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