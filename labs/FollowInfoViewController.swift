//
//  FollowInfoViewController.swift
//  labs
//
//  Created by 방정호 on 2015. 10. 31..
//  Copyright © 2015년 dropbeat. All rights reserved.
//

import UIKit

class FollowInfoTableViewCell: UITableViewCell {
    
    @IBOutlet var profileImageView: UIImageView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet weak var isFollowedImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        profileImageView.layer.cornerRadius = 10
        profileImageView.layer.borderWidth = 2
        profileImageView.layer.borderColor = UIColor(white: 0.95, alpha: 1.0).CGColor
    }
}

class FollowInfoViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, ScrollPagerDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var infoTypeSegment: ScrollPager!
    
    var user: User!
    var userArray: [BaseUser] = []
    var followInfoType = FollowInfoType.FOLLOWING
    
    func scrollPager(scrollPager: ScrollPager, changedIndex: Int) {
        if changedIndex == 0 {
            self.followInfoType = .FOLLOWING
        } else {
            self.followInfoType = .FOLLOWERS
        }
        loadUserArray()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .Plain, target: nil, action: nil)

        infoTypeSegment.delegate = self
        infoTypeSegment.addSegmentsWithTitles(["Following","Followers"])
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        loadUserArray()
    }
    
    func loadUserArray() {
        var fetchFunc: ((users: [BaseUser]?, error: NSError?) -> Void) -> Void
        switch followInfoType {
        case .FOLLOWERS:
            fetchFunc = user.fetchFollowers
        case .FOLLOWING:
            fetchFunc = user.fetchFollowing
        }
        
        let progressHud = ViewUtils.showProgress(self, message: nil)
        fetchFunc({ (users, error) -> Void in
            progressHud.hide(true)
            if error != nil {
                var message: String?
                if (error != nil && error!.domain == NSURLErrorDomain &&
                    error!.code == NSURLErrorNotConnectedToInternet) {
                        message = NSLocalizedString("Internet is not connected. Please try again.", comment:"")
                } else {
                    message = ""
                }
                ViewUtils.showConfirmAlert(self,
                    title: NSLocalizedString("Failed to fetch", comment:""),
                    message: message!,
                    positiveBtnText: NSLocalizedString("Retry", comment:""),
                    positiveBtnCallback: { () -> Void in
                        self.loadUserArray()
                    }, negativeBtnText: NSLocalizedString("Cancel", comment:""), negativeBtnCallback: nil)
                return
            }
            
            self.userArray = users!
            self.tableView.reloadData()
        })
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let insets = UIEdgeInsetsMake(0, 0, 44, 0)
        tableView.contentInset = insets
    }
    
    // MARK: - Table view data source
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userArray.count
    }
    
    let CELL_HIGHT:CGFloat = 76
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return CELL_HIGHT
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("FollowInfoTableViewCell", forIndexPath: indexPath) as! FollowInfoTableViewCell
        let u = self.userArray[indexPath.row]
        cell.nameLabel.text = u.name
        if let image = u.image {
            cell.profileImageView.sd_setImageWithURL(NSURL(string: image), placeholderImage: UIImage(named: "default_profile"))
        } else {
            cell.profileImageView.image = UIImage(named: "default_profile")
        }
        
        cell.isFollowedImageView.hidden = (self.followInfoType == .FOLLOWING) || (u.isFollowed() == false)
        
        return cell
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ShowUserSegue" {
            let cell = sender as! FollowInfoTableViewCell
            let indexPath = self.tableView.indexPathForSelectedRow
            let u = self.userArray[indexPath!.row]
            
            let mySegue = segue as! JHImageTransitionSegue
            let sourceImageView = cell.profileImageView
            mySegue.setSourceImageView(sourceImageView)
            mySegue.sourceRect = sourceImageView.convertRect(sourceImageView.bounds, toView: self.view)
            mySegue.destinationRect = self.view.convertRect(UserHeaderView.profileImageRect(self), fromView: nil)
            
            mySegue.setSourceLable(cell.nameLabel)
            mySegue.labelSourceRect = cell.nameLabel.convertRect(cell.nameLabel.bounds, toView: self.view)
            let coverHeight = self.view.bounds.width * 5/8
            mySegue.labelDestinationRect = self.view.convertRect(CGRectMake(100, coverHeight-28, 210, 22), fromView: nil)
            
            let uvc = segue.destinationViewController as! UserViewController
            uvc.resource = u.resourceName
            uvc.passedName = cell.nameLabel.text
            uvc.passedImage = sourceImageView.image
        }
    }
}
