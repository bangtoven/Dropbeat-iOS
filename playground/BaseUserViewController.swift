//
//  UserViewController.swift
//  labs
//
//  Created by Jungho Bang on 2015. 9. 13..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

class BaseUserViewController: AXStretchableHeaderTabViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tabBar.tintColor = UIColor(netHex: 0x982EF4)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "statusBarTapped", name: NotifyKey.statusBarTapped, object: nil)
        
        var testing = true
        if testing {
            self.headerView = BaseUserHeaderView.instantiate()
            
            var vcArr: [UIViewController] = []
            for x in 0..<3 {
                var vc: UserDetailTableViewController = self.storyboard?.instantiateViewControllerWithIdentifier("UserDetailTableViewController") as! UserDetailTableViewController
                vc.arg = x
                vcArr.append(vc)
            }
            self.viewControllers = vcArr
        }
    }
    
    func statusBarTapped() {
        self.selectedScrollView.setContentOffset(CGPointMake(0, -self.headerView.maximumOfHeight-44), animated: true)
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

        var ratio = ratio>1.0 ? 1.0 : ratio
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

// MARK: - For testing

class BaseUserHeaderView: AXStretchableHeaderView {
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

class UserDetailTableViewController: UITableViewController, AXSubViewController, DYAlertPickViewDataSource, DYAlertPickViewDelegate {
    
    var arg: Int!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var title: String = String()
        for i in 0...arg {
            title += "TAB "
        }
        title += String(arg)
        self.title = title
    }
    
    func subViewWillDisappear() {
        println(String(arg) + " subViewDidDisappear")
    }
    
    func subViewWillAppear() {
        println(String(arg) + " subViewWillAppear")
    }
    
    // MARK: -
    // MARK: DYAlertPickViewDataSource
    var selectedSection: Int = -1
    
    @IBOutlet weak var button: UIButton!
    @IBAction func buttonTapped(sender: AnyObject) {
        var picker: DYAlertPickView = DYAlertPickView(headerTitle: "Choose Section", cancelButtonTitle: nil, confirmButtonTitle: nil, switchButtonTitle: nil)
        picker.dataSource = self
        picker.delegate = self
        picker.tintColor = UIColor.redColor();
        picker.showAndSelectedIndex(self.selectedSection)
    }
    
    func titleForRowInDYAlertPickView(titleForRow: Int) -> NSAttributedString! {
        return NSAttributedString(string: "asdf"+String(titleForRow))
    }
    //
    func numberOfRowsInDYAlertPickerView(pickerView: DYAlertPickView) -> Int {
        return 10
    }
    
    func didConfirmWithItemAtRowInDYAlertPickView(row: Int) {
        self.selectedSection = row
        println(row)
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return 30
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath) as! UITableViewCell
        
        cell.textLabel?.text = String(arg) + " . " + String(indexPath.row)
        
        return cell
    }
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    // Return NO if you do not want the specified item to be editable.
    return true
    }
    */
    
    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    if editingStyle == .Delete {
    // Delete the row from the data source
    tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
    } else if editingStyle == .Insert {
    // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }
    }
    */
    
    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
    
    }
    */
    
    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    // Return NO if you do not want the item to be re-orderable.
    return true
    }
    */
    
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    }
    */
    
}
