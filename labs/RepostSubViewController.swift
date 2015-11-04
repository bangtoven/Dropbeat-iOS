//
//  RepostSubViewController.swift
//  labs
//
//  Created by 방정호 on 2015. 11. 2..
//  Copyright © 2015년 dropbeat. All rights reserved.
//

import UIKit

class RepostTrackTableViewwCell: TrackSubTableViewwCell {
    
    @IBOutlet weak var authorNameButton: UIButton!
    
//    @IBOutlet weak var authorProfileImageView: UIImageView!
//    @IBOutlet weak var authorNameLabel: UILabel!
//    
//    override func awakeFromNib() {
//        super.awakeFromNib()
//        
//        authorProfileImageView.layer.cornerRadius = 3
//        authorProfileImageView.layer.borderWidth = 0.5
//        authorProfileImageView.layer.borderColor = UIColor(white: 0.95, alpha: 1.0).CGColor
//    }
}

class RepostSubViewController: TrackSubViewController {
    
    @IBAction func showUserInfo(sender: UIButton) {
        if let indexPath = self.trackTableView.indexPathOfCellContains(sender),
            resourceName = tracks[indexPath.row].user?.resourceName {
                let userVC = self.storyboard?.instantiateViewControllerWithIdentifier("UserViewController") as! UserViewController
                userVC.resource = resourceName
                self.parentViewController?.navigationController?.pushViewController(userVC, animated: true)
        }
    }
    
    override func allowedMenuActionsForTrack(track: Track) -> [MenuAction] {
        return [.Like, .Share, .Add]
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if (indexPath.row >= tracks.count) {
            return super.tableView(tableView, cellForRowAtIndexPath: indexPath)
        }
        
        let track = tracks[indexPath.row]
        if let author = track.user {
            let cell = tableView.dequeueReusableCellWithIdentifier("RepostTrackTableViewwCell", forIndexPath: indexPath) as! RepostTrackTableViewwCell
            let attrString = NSMutableAttributedString(
                string: "\(author.name)'s track",
                attributes: [
                    NSForegroundColorAttributeName:UIColor.darkGrayColor(),
                    NSFontAttributeName:UIFont.systemFontOfSize(12)
                ])
            attrString.setAttributes([
                NSForegroundColorAttributeName:UIColor.dropbeatColor(),
                NSFontAttributeName:UIFont.boldSystemFontOfSize(14)
                ], range: NSMakeRange(0, author.name.length))
            
            cell.authorNameButton.setAttributedTitle(attrString, forState: .Normal)
            
            cell.delegate = self
            cell.nameView.text = track.title
            
            cell.thumbView.setImageForTrack(track, size: .SMALL)
            
            self.setDropButtonForCellWithTrack(cell, track: track)
            cell.dropButtonWidthConstraint.constant = cell.dropBtn.hidden ? 0 : 44
            
            return cell
        } else {
            return super.tableView(tableView, cellForRowAtIndexPath: indexPath)
        }
    }
}
