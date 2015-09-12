//
//  UserProfileViewController.swift
//  labs
//
//  Created by Jungho Bang on 2015. 9. 13..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

class UserProfileViewController: UIViewController,UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var headerView: HeaderView!
    
    var headerViewTopConstraintConstant: CGFloat!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        headerViewTopConstraintConstant = self.headerView.topConstraint.constant
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.barTintColor = UIColor.clearColor()
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        println("viewDidLayoutSubviews")
        
        self.headerView.topConstraint.constant = self.headerViewTopConstraintConstant + self.tableView.contentInset.top
        self.headerView.frame = CGRectMake(0, 0, self.view.bounds.width, self.headerView.maximumOfHeight + self.tableView.contentInset.top)
        
        self.tableView.contentInset = UIEdgeInsetsMake(CGRectGetMaxY(self.headerView.frame), 0, 0, 0)
        
        self.tableView.setContentOffset(CGPointMake(0, -self.headerView.frame.height), animated: false)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.navigationController?.navigationBar.barTintColor = nil
        self.navigationController?.navigationBar.tintColor = nil
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        var headerViewHeight = 333.0 - (scrollView.contentOffset.y + scrollView.contentInset.top)
        println(self.tableView.contentInset.top)
        println(scrollView.contentInset.bottom)
//        headerViewHeight = max(headerViewHeight, self.headerView.minimumOfHeight);
        self.headerView.frame = CGRectMake(0, 0, CGRectGetWidth(self.headerView.frame), headerViewHeight)
        
        self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(CGRectGetMaxY(self.headerView.frame)-self.tableView.contentInset.top, 0, 0, 0)
    }
    
    // MARK: - Table view data source
    
     func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }
    
     func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return 20
    }
    
    
     func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath) as! UITableViewCell
        cell.textLabel!.text = String(indexPath.row)
        return cell
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
