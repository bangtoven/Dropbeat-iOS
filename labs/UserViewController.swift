//
//  UserViewController.swift
//  labs
//
//  Created by Jungho Bang on 2015. 9. 14..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

class UserHeaderView: AXStretchableHeaderView {
    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var profileImageHeight: NSLayoutConstraint!

    @IBOutlet weak var followInfoView: UIView!
    @IBOutlet weak var followersLabel: UILabel!
    @IBOutlet weak var followingLabel: UILabel!
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var labelHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var showMoreButton: UIButton!
    @IBOutlet weak var followButton: UIButton!
    
    override func interactiveSubviews() -> [AnyObject]! {
        return [self.showMoreButton, self.followButton]
    }
    
    func loadView () {
        self.nameLabel.text = ""
        self.descriptionLabel.text = ""
        
        self.followInfoView.hidden = true
        
        self.profileImageView.layer.cornerRadius = 10
        self.profileImageView.layer.borderWidth = 2
        self.profileImageView.layer.borderColor = UIColor(white: 0.95, alpha: 1.0).CGColor
        self.profileImageView.clipsToBounds = true
        
        self.coverImageView.clipsToBounds = true
    }
}

class UserViewController: AXStretchableHeaderTabViewController {
    var baseUser: BaseUser!
    var resource: String!
    
    func instantiateSubVC () -> UserSubViewController {
        return self.storyboard?.instantiateViewControllerWithIdentifier("UserSubViewController") as! UserSubViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.tintColor = UIColor.dropbeatColor()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:" ", style:.Plain, target:nil, action:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "statusBarTapped", name: NotifyKey.statusBarTapped, object: nil)
        
        self.headerView = UserHeaderView.instantiate()
        let header = self.headerView as! UserHeaderView
        header.maximumOfHeight = 224
        header.loadView()
        
        var isSelf = false
        let progressHud = ViewUtils.showProgress(self, message: nil)
        Requests.resolveUser(self.resource) {(req, resp, result, error) -> Void in
            progressHud.hide(true)
            
            if (error != nil || JSON(result!)["success"] == false) {
                ViewUtils.showNoticeAlert(self, title: "Error", message: (error?.description)!)
                return
            }
            
            let type: String = JSON(result!)["data"]["user_type"].stringValue
            switch type {
            case "user":
                let user = User.parseUser(result!,key:"data",secondKey:"user")
                header.descriptionLabel.text = user.description
                header.followInfoView.hidden = false
                header.followersLabel.text = String(user.num_followers)
                header.followingLabel.text = String(user.num_following)

                let uploads = self.instantiateSubVC()
                uploads.title = "Uploads"
                uploads.tracks = user.tracks
                uploads.baseUser = user

                let likes = self.instantiateSubVC()
                likes.title = "Likes"
                likes.baseUser = user
                likes.fetchFunc = user.fetchTracksFromLikeList
                
                let f1 = self.storyboard?.instantiateViewControllerWithIdentifier("FollowInfoTableViewController") as! FollowInfoTableViewController
                f1.title = "Followers"
                f1.user = user
                f1.fetchFunc = user.fetchFollowers
                
                let f2 = self.storyboard?.instantiateViewControllerWithIdentifier("FollowInfoTableViewController") as! FollowInfoTableViewController
                f2.title = "Following"
                f2.user = user
                f2.fetchFunc = user.fetchFollowing
                
                if user.tracks.count == 0 {
                    self.viewControllers = [likes, f1, f2]
                } else {
                    self.viewControllers = [uploads, likes, f1, f2]
                }
                
                if user.id == Account.getCachedAccount()?.user?.id {
                    isSelf = true
                }

                self.baseUser = user
            case "artist":
                let artist = Artist.parseArtist(result!,key:"data",secondKey:"user")
                
                var subViewArr = [UserSubViewController]()
                for (section, tracks): (String, [Track]) in artist.sectionedTracks {
                    let subView = self.instantiateSubVC()
                    subView.title = section.capitalizedString
                    subView.tracks = tracks
                    subView.baseUser = artist
                    subViewArr.append(subView)
                }
                
                if artist.hasLiveset {
                    let subView = self.instantiateSubVC()
                    subView.title = "Liveset"
                    subView.baseUser = artist
                    subView.fetchFunc = artist.fetchLiveset
                    subViewArr.append(subView)
                }
                
                if artist.hasPodcast {
                    let subView = self.instantiateSubVC()
                    subView.title = "Podcast"
                    subView.baseUser = artist
                    subView.fetchFunc = artist.fetchPodcast
                    subViewArr.append(subView)
                }
                
                self.viewControllers = subViewArr
                self.baseUser = artist
            case "channel":
                let channel = Channel.parseChannel(result!,key:"data",secondKey: "user")
                header.descriptionLabel.text = channel!.genre.joinWithSeparator(", ")
                if header.descriptionLabel.text?.length == 0 {
                    header.descriptionLabel.text = "\n"
                }
                
                var subViewArr = [ChannelSubViewController]()
                let recent = self.storyboard?.instantiateViewControllerWithIdentifier("ChannelSubViewController") as! ChannelSubViewController
                recent.title = "Recent"
                recent.channel = channel
                subViewArr.append(recent)
                
                if channel?.playlists.count > 1 {
                    let sections = self.storyboard?.instantiateViewControllerWithIdentifier("ChannelSubViewController") as! ChannelSubViewController
                    sections.title = "Sections"
                    sections.channel = channel
                    sections.isSectioned = true
                    subViewArr.append(sections)
                }
                
                self.viewControllers = subViewArr
                self.baseUser = channel
            default:
                ViewUtils.showNoticeAlert(self, title: "Error", message: "Unknown user type: \(type)")
                return
            }
            
            if let name = self.baseUser?.name {
                self.title = name
                header.nameLabel.text = name
            }
            if let profileImage = self.baseUser?.image {
                header.profileImageView.sd_setImageWithURL(NSURL(string: profileImage), placeholderImage: UIImage(named: "default_profile"))
            }
            if let coverImage = self.baseUser?.coverImage {
                header.coverImageView.sd_setImageWithURL(NSURL(string: coverImage), placeholderImage: UIImage(named: "default_cover_big"),
                    forMinimumHeight: self.headerView!.maximumOfHeight*1.5)
            }
            
            if isSelf {
                header.followButton.enabled = false
            } else {
                if let followed = self.baseUser?.isFollowed() {
                    header.followButton.selected = followed
                }
                header.followButton.addTarget(self, action: "followAction:", forControlEvents: UIControlEvents.TouchUpInside)
            }
            
            let descriptionHeight = self.calculateDescriptionContentSize()
            if descriptionHeight <= 32 {
                header.showMoreButton.hidden = true
                self.headerView!.maximumOfHeight -= (32-descriptionHeight)
                header.labelHeightConstraint.constant = descriptionHeight
            } else {
                self.headerView!.maximumOfHeight += 32
                header.labelHeightConstraint.constant = 64
                if let scrollView = self.selectedScrollView {
                    scrollView.setContentOffset(CGPointMake(0, scrollView.contentOffset.y-32), animated: false)
                }
                if descriptionHeight > 64 {
                    header.showMoreButton.hidden = false
                    header.showMoreButton.addTarget(self, action: "showMoreAction", forControlEvents: UIControlEvents.TouchUpInside)
                }
            }
        }
    }
    
    func followAction(sender: UIButton) {
        let progressHud = ViewUtils.showProgress(self, message: nil)
        let handler = { (error: NSError?) -> Void in
            progressHud.hide(true)
            if (error == nil) {
                sender.selected = self.baseUser.isFollowed()
                
                if let user = self.baseUser as? User {
                    user.num_followers += user.isFollowed() ? 1 : -1
                    let header = self.headerView as! UserHeaderView
                    header.followersLabel.text = String(user.num_followers)
                    
                    if let followerView = self.viewControllers[self.viewControllers.count-2] as? FollowInfoTableViewController {
                        followerView.userArray = []
                        followerView.subViewWillAppear()
                    }
                }
            }
        }
        if sender.selected {
            self.baseUser.unfollow(handler)
        } else {
            self.baseUser.follow(handler)
        }   
    }
    
    func showMoreAction() {
        let header = self.headerView as! UserHeaderView
        let label = header.descriptionLabel
        let currentHeight = label.frame.height
        let contentHeight = calculateDescriptionContentSize()
        let diff = contentHeight - currentHeight
        
        if diff > 0 {
            self.headerView!.maximumOfHeight += diff
            header.labelHeightConstraint.constant = contentHeight
            self.selectedScrollView.setContentOffset(CGPointMake(0, self.selectedScrollView.contentOffset.y-diff), animated: false)
            self.layoutViewControllers()
        }
    }
    
    func calculateDescriptionContentSize() -> CGFloat {
        let header = self.headerView as! UserHeaderView
        let label = header.descriptionLabel
        let attr = [NSFontAttributeName:label.font]
        let rect = label.text!.boundingRectWithSize(CGSizeMake(label.frame.width, CGFloat.max), options:NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: attr, context:nil)
        return ceil(rect.height)
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
        
        if let navBar = self.navigationController?.navigationBar {
            let transitionPoint: CGFloat = 0.6
            switch ratio {
            case 0..<transitionPoint:
                navBar.lt_setBackgroundColor(UIColor(white: 1.0, alpha: 1))
                navBar.tintColor = UIColor.dropbeatColor()
            case transitionPoint...1.0:
                let r = 1/(1-transitionPoint) * (1-ratio)
                navBar.lt_setBackgroundColor(UIColor(white: 1.0, alpha: r))
                navBar.tintColor = UIColor.dropbeatColor(saturation: r)
            default:
                navBar.lt_setBackgroundColor(UIColor(white: 1.0, alpha: 0))
                navBar.tintColor = UIColor.dropbeatColor(saturation: 0)
            }
            
            switch ratio {
            case 0..<0.5:
                navBar.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.dropbeatColor()]
            case 0.5..<0.6:
                let r = 6 - 10*ratio
                navBar.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.dropbeatColor(r, saturation: r)]
            default:
                navBar.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.dropbeatColor(0, saturation: 0)]
            }
        }
        
//        if ratio == 0.0 {
//            let header = self.headerView as! UserHeaderView
//            var defaultDescriptionHeight: CGFloat = 64
//            let label = header.descriptionLabel
//            let currentHeight = label.frame.height
//            if currentHeight > defaultDescriptionHeight {
//                header.labelHeightConstraint.constant = defaultDescriptionHeight
//                self.headerView.maximumOfHeight -= (currentHeight-defaultDescriptionHeight)
//                self.layoutViewControllers()
//            }
//        }
    }
    
    func statusBarTapped() {
        self.selectedScrollView.setContentOffset(CGPointMake(0, -self.headerView!.maximumOfHeight-44), animated: true)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navBar = self.navigationController?.navigationBar {
            navBar.barTintColor = UIColor.clearColor()
            navBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
            navBar.tintColor = UIColor.whiteColor()
            navBar.shadowImage = UIImage()
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        self.didHeightRatioChange(self.headerViewHeightRatio)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
//        var navBar = self.navigationController?.navigationBar
//        navBar!.barTintColor = nil
//        navBar!.tintColor = nil
//        navBar!.shadowImage = nil
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.Default, animated: false)
    }

}
