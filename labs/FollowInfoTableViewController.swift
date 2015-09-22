//
//  FollowInfoTableViewController.swift
//  
//
//  Created by Jungho Bang on 2015. 9. 20..
//
//

import UIKit

class FollowInfoTableViewCell: UITableViewCell {
    
    @IBOutlet var profileImageView: UIImageView!
    @IBOutlet var nameLabel: UILabel!
    
}

class FollowInfoTableViewController: UITableViewController, AXSubViewController {

    var user: User?
    var fetchFunc: (((users: [BaseUser]?, error: NSError?) -> Void) -> Void)?
    var userArray: [BaseUser] = []
    
    func subViewWillAppear() {
        if self.userArray.count == 0 {
            print("start fetching \(self.title!)")
            fetchFunc!({ (users, error) -> Void in
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
        return userArray.count + 1
    }
    
    let CELL_HIGHT:CGFloat = 76

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        var cellHeight: CGFloat = 0
        if (indexPath.row < userArray.count) {
            cellHeight = 76
        } else if let parentVc = self.parentViewController as? UserViewController {
            if let navigationBar = parentVc.navigationController?.navigationBar {
                let minHeight = parentVc.view.frame.size.height - (CGRectGetMaxY(navigationBar.frame)+CGRectGetHeight(parentVc.tabBar.bounds))
                let diff = minHeight - (CELL_HIGHT * CGFloat(userArray.count))
                if diff > 0 {
                    cellHeight = diff
                }
            }
        }
        return cellHeight
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if (indexPath.row >= userArray.count) {
            let identifier = "EmptyCell"
            var cell = tableView.dequeueReusableCellWithIdentifier(identifier)
            if (cell == nil) {
                cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: identifier)
            }
            cell?.backgroundColor = UIColor.whiteColor()
            cell?.userInteractionEnabled = false
            return cell!
        }
        
        let cell = tableView.dequeueReusableCellWithIdentifier("FollowInfoTableViewCell", forIndexPath: indexPath) as! FollowInfoTableViewCell
        let u = self.userArray[indexPath.row]
        cell.nameLabel.text = u.name
        if let image = u.image {
            cell.profileImageView.sd_setImageWithURL(NSURL(string: image), placeholderImage: UIImage(named: "default_profile"))
        } else {
            cell.profileImageView.image = UIImage(named: "default_profile")
        }
        
        cell.profileImageView.layer.cornerRadius = 10
        cell.profileImageView.layer.borderWidth = 2
        cell.profileImageView.layer.borderColor = UIColor(white: 0.95, alpha: 1.0).CGColor

        return cell
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ShowUserSegue" {
            let cell = sender as! FollowInfoTableViewCell
            let indexPath = self.tableView.indexPathForCell(cell)
            let u = self.userArray[indexPath!.row]
         
            let mySegue = segue as! JHImageTransitionSegue
            let sourceImageView = cell.profileImageView
            mySegue.setSourceImageView(sourceImageView)
            mySegue.sourceRect = sourceImageView.convertRect(sourceImageView.bounds, toView: self.view)
            mySegue.destinationRect = self.view.convertRect(CGRectMake(10, 157, 80, 80), fromView: nil)
            
            mySegue.setSourceLable(cell.nameLabel)
            mySegue.labelSourceRect = cell.nameLabel.convertRect(cell.nameLabel.bounds, toView: self.view)
            mySegue.labelDestinationRect = self.view.convertRect(CGRectMake(100, 169, 210, 22), fromView: nil)

            let uvc: UserViewController = segue.destinationViewController as! UserViewController
            uvc.resource = u.resourceName
            uvc.showUserFromFollowInfo = true
        }
    }
    
    /*
    
    
    - (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
    {
    if (![segue isKindOfClass:[JKImageTransitionSegue class]]) {
    return;
    }
    
    JKImageViewController *imageController = (JKImageViewController *)segue.destinationViewController;
    
    // provide destination with full image
    imageController.image = [UIImage imageNamed:@"BeachFull.jpg"];
    
    // configure segue
    UIButton *imageButton = (UIButton *)sender;
    JKImageTransitionSegue *imageSegue = (JKImageTransitionSegue *)segue;
    
    imageSegue.sourceRect = imageButton.frame;
    imageSegue.transitionImage = imageButton.imageView.image;
    
    imageButton.hidden = YES;
    }
    */
    
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
