//
//  MainTabBarController.swift
//  labs
//
//  Created by 방정호 on 2015. 10. 11..
//  Copyright © 2015년 dropbeat. All rights reserved.
//

import UIKit

class MainTabBarController: UITabBarController, UITabBarControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        self.delegate = self
        self.tabBar.tintColor = UIColor.dropbeatColor()
        
        let navBar = UINavigationBar.appearance()
        navBar.barTintColor = UIColor.whiteColor()
        navBar.tintColor = nil
        navBar.shadowImage = nil
        navBar.setBackgroundImage(nil, forBarMetrics: UIBarMetrics.Default)
        navBar.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.blackColor()]

        
        if Account.getCachedAccount() == nil {
            var exceptPlaylistTab = self.viewControllers
            exceptPlaylistTab?.removeAtIndex(3)
            self.setViewControllers(exceptPlaylistTab, animated: true)
        }
    }

    func tabBarController(tabBarController: UITabBarController, shouldSelectViewController viewController: UIViewController) -> Bool {
        if viewController == self.viewControllers?.last && Account.getCachedAccount() == nil {
            NeedAuthViewController.showNeedAuthViewController(self)
            return false
        }
        return true
    }
}
