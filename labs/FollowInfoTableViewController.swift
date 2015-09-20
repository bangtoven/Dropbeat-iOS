//
//  FollowInfoTableViewController.swift
//  
//
//  Created by Jungho Bang on 2015. 9. 20..
//
//

import UIKit

class FollowInfoTableViewController: UITableViewController, AXSubViewController {

    var user: User?
    var followInfoType: User.FollowInfoType?
    var userArray: [BaseUser] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
    }
    
    func subViewWillAppear() {
        if self.userArray.count == 0 {
            println("start fetching \(self.title)")
            user!.fetchFollowInfo(self.followInfoType!, callback: { (users, error) -> Void in
                self.userArray = users!
                self.tableView.reloadData()
                self.tableView.tableHeaderView = nil
            })
        } else {
            self.tableView.tableHeaderView = nil
        }
    }
    
    func subViewWillDisappear() {
        
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userArray.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("FollowInfoTableViewCell", forIndexPath: indexPath) as! UITableViewCell
        
        let u = self.userArray[indexPath.row]
        cell.textLabel?.text = u.name
        if let image = u.image {
            cell.imageView?.sd_setImageWithURL(NSURL(string: image), placeholderImage: UIImage(named: "default_profile"))
        } else {
            cell.imageView?.image = UIImage(named: "default_profile")
        }
        
        cell.imageView?.contentMode = UIViewContentMode.ScaleAspectFill
        cell.imageView!.layer.cornerRadius = 10
        cell.imageView!.layer.borderWidth = 5
        cell.imageView!.layer.borderColor = UIColor.whiteColor().CGColor;

        return cell
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ShowUserSegue" {
            let indexPath = self.tableView.indexPathForCell(sender as! UITableViewCell)
            let u = self.userArray[indexPath!.row]
            var uvc: UserViewController = segue.destinationViewController as! UserViewController
            uvc.resource = u.resourceName
        }
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
