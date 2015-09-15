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
        self.view.tintColor = UIColor.dropbeatColor()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "statusBarTapped", name: NotifyKey.statusBarTapped, object: nil)
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

        var navBar = self.navigationController?.navigationBar
        switch ratio {
        case 0..<0.3:
            navBar!.lt_setBackgroundColor(UIColor(white: 1.0, alpha: 1))
            navBar!.tintColor = UIColor.dropbeatColor()
            navBar!.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.dropbeatColor()]
        case 0.3...1.0:
            var r = 10/7 * (1-ratio)
            navBar!.lt_setBackgroundColor(UIColor(white: 1.0, alpha: r))
            navBar!.tintColor = UIColor.dropbeatColor(saturation: r)
            navBar!.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.dropbeatColor(alpha: r, saturation: r)]
        default:
            navBar!.lt_setBackgroundColor(UIColor(white: 1.0, alpha: 0))
            navBar!.tintColor = UIColor.dropbeatColor(saturation: 0)
            navBar!.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.dropbeatColor(alpha: 0, saturation: 0)]
        }
        
//        switch ratio {
//        case 0.0...0.3:
//            navBar!.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.dropbeatColor()]
//        case 0.3...0.4:
//            var r = (ratio-0.3)*10.0
//            println(r)
//            navBar!.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.dropbeatColor(alpha: 1-ratio)]
//        default:
//            navBar!.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.clearColor()]
//        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        var navBar = self.navigationController?.navigationBar
        navBar!.barTintColor = UIColor.clearColor()
        navBar!.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        navBar!.tintColor = UIColor.whiteColor()
        navBar!.shadowImage = UIImage()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        var navBar = self.navigationController?.navigationBar
        navBar!.barTintColor = nil
        navBar!.tintColor = nil
        navBar!.shadowImage = nil
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.Default, animated: false)
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
