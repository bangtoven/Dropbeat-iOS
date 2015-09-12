//
//  UserViewController.swift
//  labs
//
//  Created by Jungho Bang on 2015. 9. 13..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

class UserHeaderView: AXStretchableHeaderView, AXStretchableHeaderViewDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var button: UIButton!
    
    static func instantiate() -> UserHeaderView{
        var nib = UINib(nibName: "UserHeaderView", bundle: nil)
        var uhv: UserHeaderView = nib.instantiateWithOwner(self, options: nil).first as! UserHeaderView
        uhv.delegate = uhv
        return uhv
    }
    
    func interactiveSubviewsInStretchableHeaderView(stretchableHeaderView: AXStretchableHeaderView!) -> [AnyObject]! {
        return [self.button]
    }
    
}

class UserViewController: AXStretchableHeaderTabViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "UserName"
        
        self.headerView = UserHeaderView.instantiate()
        
        self.headerView.minimumOfHeight = 0;
        self.headerView.maximumOfHeight = 220.0;
        
        var vcArr: [UIViewController] = []
        for x in 0..<3 {
            var vc: UserDetailTableViewController = self.storyboard?.instantiateViewControllerWithIdentifier("UserDetailTableViewController") as! UserDetailTableViewController
            vc.arg = String(x)+"."
            vcArr.append(vc)
        }
        self.viewControllers = vcArr
        
    }
    
    override func layoutHeaderViewAndTabBar() {
        super.layoutHeaderViewAndTabBar()
        var headerHeight = self.headerView.frame.height
        var ratio = (headerHeight-64 - self.headerView.minimumOfHeight) /
                    (self.headerView.maximumOfHeight - self.headerView.minimumOfHeight)
        if ratio > 1.0 {
            ratio = 1.0
        }
        
//        self.navigationController?.navigationBar.barTintColor = UIColor(white: 1.0, alpha: 1.0 - ratio)
        self.navigationController?.navigationBar.lt_setBackgroundColor(UIColor(white: 1.0, alpha: 1.0 - ratio))
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
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.navigationController?.navigationBar.barTintColor = nil
        self.navigationController?.navigationBar.tintColor = nil
        self.navigationController?.navigationBar.shadowImage = nil
    }
}
