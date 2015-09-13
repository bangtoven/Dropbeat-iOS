//
//  UserViewController.swift
//  labs
//
//  Created by Jungho Bang on 2015. 9. 13..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

class UserHeaderView: AXStretchableHeaderView {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var profileImageHeightConstraint: NSLayoutConstraint!
    
    override func interactiveSubviews() -> [AnyObject]! {
        return [self.button]
    }
    
    override func didHeightRatioChange(ratio: CGFloat) {
        self.profileImageHeightConstraint.constant = 84 * ratio;
    }
}

class UserViewController: AXStretchableHeaderTabViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "UserName"
        
        self.headerView = UserHeaderView.instantiate()
        
        self.headerView.minimumOfHeight = 0;
        self.headerView.maximumOfHeight = 220.0;
        
        self.tabBar.tintColor = UIColor(netHex: 0x982EF4)
//        self.tabBar.tabBarStyle = AXTabBarStyleVariableWidthButton
        
        var vcArr: [UIViewController] = []
        for x in 0..<3 {
            var vc: UserDetailTableViewController = self.storyboard?.instantiateViewControllerWithIdentifier("UserDetailTableViewController") as! UserDetailTableViewController
            vc.arg = x
            vcArr.append(vc)
        }
        self.viewControllers = vcArr
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "statusBarTapped", name: NotifyKey.statusBarTapped, object: nil)
        
    }
    
    func statusBarTapped() {
        var index: Int = Int(self.selectedIndex)
        var selectedVC: UserDetailTableViewController = self.viewControllers[index] as! UserDetailTableViewController
        selectedVC.tableView.setContentOffset(CGPointMake(0, -self.headerView.maximumOfHeight-44), animated: true)
    }
    
    override func didHeightRatioChange(ratio: CGFloat) {
        switch ratio {
        case 0..<0.75:
            UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.Default, animated: true)
        case 0.75...1.0:
            UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.LightContent, animated: true)
        default:
            break
        }

        var ratio = ratio>1.0 ? 1.0 : ratio;

        self.navigationController?.navigationBar.lt_setBackgroundColor(UIColor(white: 1.0, alpha: 2.0 - 2*ratio))
        self.navigationController?.navigationBar.tintColor = UIColor(white: ratio, alpha: 1.0)
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName:UIColor(white: ratio, alpha: 1-ratio)]
        
        self.headerView.alpha = ratio
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.barTintColor = UIColor.clearColor()
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        self.navigationController?.navigationBar.shadowImage = UIImage()
        
        var mGradient = CAGradientLayer()
        mGradient.frame = self.headerView.bounds
        var colors = [CGColor]()
        colors.append(UIColor(red: 0, green: 0, blue: 0, alpha: 0.5).CGColor)
        colors.append(UIColor(red: 0, green: 0, blue: 0, alpha: 0).CGColor)
        mGradient.startPoint = CGPointMake(0.0, 0.0)
        mGradient.endPoint = CGPointMake(0.0, 0.1)
        mGradient.colors = colors
        
        self.headerView.layer.addSublayer(mGradient)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.navigationBar.barTintColor = nil
        self.navigationController?.navigationBar.tintColor = nil
        self.navigationController?.navigationBar.shadowImage = nil
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.Default, animated: false)
    }
}
