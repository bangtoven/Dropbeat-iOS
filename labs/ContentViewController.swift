//
//  ContentViewController.swift
//  labs
//
//  Created by vulpes on 2015. 5. 16..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

class ContentViewController: UIViewController {
    let segueIdentifierFeed: String = "embedFeed"
    let segueIdentifierSearch: String = "embedSearch"
    let segueIdentifierSettings: String = "embedSettings"
    
    var currentSegueIdentifier:String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.currentSegueIdentifier = segueIdentifierFeed
        performSegueWithIdentifier(self.currentSegueIdentifier, sender: nil)
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == segueIdentifierFeed {
            if childViewControllers.count > 0 {
                selectMenu(childViewControllers[0] as! UIViewController,
                    toViewController:segue.destinationViewController as! UIViewController)
            } else {
                var destViewController = segue.destinationViewController as! UIViewController
                addChildViewController(destViewController)
                destViewController.view.frame = CGREctMake(0, 0, view.frame.size.width, view.frame.height)
                view.addSubview(destViewController.view)
                segue.destinationViewController.didMoveToParentViewController(self)
            }
        } else if segue.identifier == segueIdentifierSearch {
            selectMenu(childViewControllers[1] as! UIViewController,
                toViewController: segue.destinationViewController as! UIViewController)
        }
    }
    
    func selectMenu(fromViewController:UIViewController, toViewController: UIViewController) {
        toViewController.view.frame == CGRectMake(0, 0, view.frame.size.width,  view.frame.size.height)
        fromViewController.willMoveToParentViewController(nil)
        addChildViewController(toViewController)
        transitionFromViewController(fromViewController, toViewController, duration:1.0, options: UIViewAnimationTransition, animations: nil, completion: func (finished:Bool) {
            fromViewController.removeFromParentViewController()
            toViewController.didMoveToParentViewController(self)
        })
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
