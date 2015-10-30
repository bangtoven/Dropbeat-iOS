//
//  UserViewController.swift
//  labs
//
//  Created by Jungho Bang on 2015. 9. 14..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

extension UINavigationController {
    override public func preferredStatusBarStyle() -> UIStatusBarStyle {
        if let userVC = self.topViewController as? UserViewController {
            return userVC.statusBarStyle
        } else {
            return .Default
        }
    }
}

class UserHeaderView: AXStretchableHeaderView {
    
    static func profileImageRect(vc: UIViewController) -> CGRect {
        let coverHeight = vc.view.bounds.width * 5/8
        return CGRectMake(10, coverHeight-40, 80, 80)
    }
    
    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var profileImageHeight: NSLayoutConstraint!

    @IBOutlet weak var followInfoView: UIView!
    @IBOutlet weak var followersNumberLabel: UILabel!
    @IBOutlet weak var followingNumberLabel: UILabel!
    @IBOutlet weak var showFollowInfoButton: UIButton!
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var aboutMeLabel: TTTAttributedLabel!
    @IBOutlet weak var labelHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var showMoreButton: UIButton!
    @IBOutlet weak var followButton: UIButton!
    
    override func interactiveSubviews() -> [AnyObject]! {
        return [showMoreButton, followButton, aboutMeLabel, showFollowInfoButton]
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.nameLabel.text = ""
        self.aboutMeLabel.enabledTextCheckingTypes = NSTextCheckingAllSystemTypes
        self.aboutMeLabel.linkAttributes = [
            NSUnderlineStyleAttributeName : true,
            NSForegroundColorAttributeName : UIColor.dropbeatColor().CGColor
        ]
        self.aboutMeLabel.text = ""
        
        self.coverImageView.clipsToBounds = true
        
        self.profileImageView.layer.cornerRadius = 10
        self.profileImageView.layer.borderWidth = 2
        self.profileImageView.layer.borderColor = UIColor(white: 0.95, alpha: 1.0).CGColor
        self.profileImageView.clipsToBounds = true
        
        self.followButton?.titleLabel!.numberOfLines = 1
        self.followButton?.titleLabel!.adjustsFontSizeToFitWidth = true
        self.followButton?.titleLabel!.lineBreakMode = .ByClipping
        
        self.nameLabel.hidden = true
        self.followInfoView.hidden = true
        self.profileImageView.hidden = true
    }
    
    override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
        let targetView = super.hitTest(point, withEvent: event)
        if let tttLabel = targetView as? TTTAttributedLabel {
            let converted = self.convertPoint(point, toView: tttLabel)
            if tttLabel.linkAtPoint(converted) != nil {
                return tttLabel
            } else {
                return nil
            }
        } else {
            return targetView
        }
    }
}

class UserViewController: AXStretchableHeaderTabViewController, TTTAttributedLabelDelegate {
    
    var baseUser: BaseUser!
    var resource: String!

    var passedName: String?
    var passedImage: UIImage?
    
    var statusBarStyle = UIStatusBarStyle.LightContent
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.tintColor = UIColor.dropbeatColor()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:" ", style:.Plain, target:nil, action:nil)

        self.view.addSubview(self.headerView!)
    }
    
    func fetchUserInfo() {
        let header = self.headerView as! UserHeaderView
        header.maximumOfHeight = self.view.bounds.width * 5/8 + 27
        
        header.nameLabel.hidden = (self.passedName != nil)
        header.profileImageView.hidden = (self.passedImage != nil)

        let progressHud = ViewUtils.showProgress(self, message: nil)
        BaseUser.resolve(self.resource) { (user, error) -> Void in
            progressHud.hide(true)
            
            if (error != nil) {
                ViewUtils.showNoticeAlert(self, title: "Can't get user information", message: error?.localizedDescription ?? "", btnText: "OK", callback: { () -> Void in
                    self.navigationController?.popViewControllerAnimated(true)
                })
                return
            }
            
            if let u = user {
                self.baseUser = u
                self.applyFetchedInfoToView()
            }
        }
    }
    
    func instantiateSubVC() -> TrackSubViewController {
        return self.storyboard?.instantiateViewControllerWithIdentifier("TrackSubViewController") as! TrackSubViewController
    }
    
    func applyFetchedInfoToView() {
        let header = self.headerView as! UserHeaderView
        header.aboutMeLabel.delegate = self
        
        var isSelf = false
        switch self.baseUser {
        case let user as User:
            let isDropbeat = (user.resourceName == "dropbeat")
            
            header.aboutMeLabel.text = user.aboutMe
            if isDropbeat {
                header.followInfoView.hidden = true
            } else {
                header.followInfoView.hidden = false
                header.followersNumberLabel.text = String(user.num_followers)
                header.followingNumberLabel.text = String(user.num_following)
            }
            
            if self.viewControllers == nil {
                if isDropbeat {
                    let recommends = instantiateSubVC()
                    recommends.title = "Recommends"
                    recommends.baseUser = user
                    recommends.fetchFunc = user.fetchTracksFromLikeList

                    self.viewControllers = [recommends]
                } else {
                    var viewControllers = [UIViewController]()

                    if user.tracks.count > 0 {
                        let uploads = instantiateSubVC()
                        uploads.title = "Uploads"
                        uploads.tracks = user.tracks
                        uploads.baseUser = user
                        viewControllers.append(uploads)
                    }
                    
                    let repost = instantiateSubVC()
                    repost.title = "Reposts"
                    repost.baseUser = user
                    repost.fetchFunc = user.fetchTracksFromLikeList
                    viewControllers.append(repost)
                    
                    let likes = instantiateSubVC()
                    likes.title = "Likes"
                    likes.baseUser = user
                    likes.fetchFunc = user.fetchTracksFromLikeList
                    viewControllers.append(likes)
                    
//                    let followers = self.storyboard?.instantiateViewControllerWithIdentifier("FollowInfoTableViewController") as! FollowInfoTableViewController
//                    followers.title = "Followers"
//                    followers.user = user
//                    followers.followInfoType = .FOLLOWERS
//                    viewControllers.append(followers)
//                    
//                    let following = self.storyboard?.instantiateViewControllerWithIdentifier("FollowInfoTableViewController") as! FollowInfoTableViewController
//                    following.title = "Following"
//                    following.user = user
//                    following.followInfoType = .FOLLOWING
//                    viewControllers.append(following)
                    
                    self.viewControllers = viewControllers
                }
            }
            
            if user.id == Account.getCachedAccount()?.user?.id {
                isSelf = true
            }
        case let artist as Artist:
            if self.viewControllers == nil {
                var subViewArr = [TrackSubViewController]()
                for (section, tracks): (String, [Track]) in artist.sectionedTracks {
                    let subView = instantiateSubVC()
                    subView.title = section.capitalizedString
                    subView.tracks = tracks
                    subView.baseUser = artist
                    subViewArr.append(subView)
                }
                
                if artist.hasLiveset {
                    let subView = instantiateSubVC()
                    subView.title = "Liveset"
                    subView.baseUser = artist
                    subView.fetchFunc = artist.fetchLiveset
                    subViewArr.append(subView)
                }
                
                if artist.hasPodcast {
                    let subView = instantiateSubVC()
                    subView.title = "Podcast"
                    subView.baseUser = artist
                    subView.fetchFunc = artist.fetchPodcast
                    subViewArr.append(subView)
                }
                
                self.viewControllers = subViewArr
            }
        case let channel as Channel:
            header.aboutMeLabel.text = channel.aboutMe ?? channel.genre.joinWithSeparator(", ")
            if header.aboutMeLabel.text?.length == 0 {
                header.aboutMeLabel.text = "\n"
            }
            
            if self.viewControllers == nil {
                var subViewArr = [ChannelSubViewController]()
                let recent = self.storyboard?.instantiateViewControllerWithIdentifier("ChannelSubViewController") as! ChannelSubViewController
                recent.title = "Recent"
                recent.baseUser = channel
                subViewArr.append(recent)
                
                if channel.playlists.count > 1 {
                    let sections = self.storyboard?.instantiateViewControllerWithIdentifier("ChannelSubViewController") as! ChannelSubViewController
                    sections.title = "Sections"
                    sections.baseUser = channel
                    sections.isSectioned = true
                    subViewArr.append(sections)
                }
                
                self.viewControllers = subViewArr
            }
            
            if channel.facebookId != nil {
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(
                    image: UIImage(named: "ic_facebook_line_small"),
                    style: .Plain,
                    target: self,
                    action: "showFacebookPage")
            }
        default:
            print("applyFetchedInfoToView: This should never happen.")
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
            header.followButton?.enabled = false
            header.followButton?.userInteractionEnabled = false
        } else {
            if let followed = self.baseUser?.isFollowed() {
                header.followButton.selected = followed
            }
        }
        
        if let showMoreButton = header.showMoreButton {
            showMoreButton.hidden = true
            let descriptionHeight = self.calculateDescriptionContentSize()
            if descriptionHeight <= 32 {
                self.headerView!.maximumOfHeight -= (32-descriptionHeight)
                header.labelHeightConstraint.constant = descriptionHeight
            } else {
                self.headerView!.maximumOfHeight += 32
                header.labelHeightConstraint.constant = 64
                if let scrollView = self.selectedScrollView {
                    scrollView.setContentOffset(CGPointMake(0, scrollView.contentOffset.y-32), animated: false)
                }
                if descriptionHeight > 64 {
                    showMoreButton.hidden = false
                    
                    let gradient = GradientView(frame: showMoreButton.bounds)
                    print(gradient.frame)
                    gradient.opaque = false
                    gradient.reverse = true
                    gradient.fillColor = UIColor.whiteColor()
                    gradient.userInteractionEnabled = false
                    showMoreButton.addSubview(gradient)
                }
            }
        }
    }
    
    func attributedLabel(label: TTTAttributedLabel!, didLongPressLinkWithURL url: NSURL!, atPoint point: CGPoint) {
        self.attributedLabel(label, didSelectLinkWithURL: url)
    }
    
    func attributedLabel(label: TTTAttributedLabel!, didSelectLinkWithURL url: NSURL!) {
        let actionSheet = UIAlertController(
            title: nil,
            message: url.absoluteString,
            preferredStyle: .ActionSheet)
        actionSheet.addAction(UIAlertAction(
            title: NSLocalizedString("Cancel", comment: "Cancel"),
            style: .Cancel, handler: nil))
        actionSheet.addAction(UIAlertAction(
            title: NSLocalizedString("Open Link", comment: "Open Link"),
            style: .Default, handler: { (action) -> Void in
            UIApplication.sharedApplication().openURL(url)
        }))
        self.presentViewController(actionSheet, animated: true, completion: nil)
    }
    
    func showFacebookPage() {
        guard let channel = self.baseUser as? Channel,
            facebookId = channel.facebookId else {
            return
        }
        
        let facebookURL = NSURL(string: "fb://profile/\(facebookId)")!
        if UIApplication.sharedApplication().canOpenURL(facebookURL) {
            UIApplication.sharedApplication().openURL(facebookURL)
        } else {
            let url = NSURL(string: "https://www.facebook.com/\(facebookId)")!
            UIApplication.sharedApplication().openURL(url)
        }
    }
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        if identifier == "ShowFollowInfo" {
            return (self.baseUser is User)
        } else {
            return super.shouldPerformSegueWithIdentifier(identifier, sender: sender)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ShowFollowInfo" {
            let followInfoVC = segue.destinationViewController as! FollowInfoViewController
            followInfoVC.user = self.baseUser as! User
        }
    }

    @IBAction func followAction(sender: UIButton) {
        if (Account.getCachedAccount() == nil) {
            NeedAuthViewController.showNeedAuthViewController(self)
            return
        }
        
        let progressHud = ViewUtils.showProgress(self, message: nil)
        let handler = { (error: NSError?) -> Void in
            progressHud.hide(true)
            if (error == nil) {
                sender.selected = self.baseUser.isFollowed()
                
                if let user = self.baseUser as? User {
                    user.num_followers += user.isFollowed() ? 1 : -1
                    let header = self.headerView as! UserHeaderView
                    header.followersNumberLabel.text = String(user.num_followers)
                    
                    guard self.viewControllers.count > 2 else {
                        return
                    }
                    
//                    if let followerView = self.viewControllers[self.viewControllers.count-2] as? FollowInfoTableViewController {
//                        followerView.userArray = []
//                        followerView.subViewWillAppear()
//                    }
                }
            }
        }
        if sender.selected {
            self.baseUser.unfollow(handler)
        } else {
            self.baseUser.follow(handler)
        }   
    }
    
    @IBAction func showMoreAction(sender: UIView) {
        let header = self.headerView as! UserHeaderView
        let label = header.aboutMeLabel
        let currentHeight = label.frame.height
        let contentHeight = calculateDescriptionContentSize()
        let diff = contentHeight - currentHeight
        
        if diff > 0 {
            self.headerView!.maximumOfHeight += diff
            header.labelHeightConstraint.constant = contentHeight
            self.selectedScrollView.setContentOffset(CGPointMake(0, self.selectedScrollView.contentOffset.y-diff), animated: false)
            self.layoutViewControllers()
            sender.hidden = true
        }
    }
    
    func calculateDescriptionContentSize() -> CGFloat {
        let header = self.headerView as! UserHeaderView
        let label = header.aboutMeLabel
        let attr = [NSFontAttributeName:label.font]
        let rect = label.text!.boundingRectWithSize(CGSizeMake(label.frame.width, CGFloat.max), options:NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: attr, context:nil)
        return ceil(rect.height)
    }
    
    override func didHeightRatioChange(ratio: CGFloat) {
        switch ratio {
        case 0..<0.75:
            self.statusBarStyle = .Default
        default:
            self.statusBarStyle = .LightContent
        }
        self.setNeedsStatusBarAppearanceUpdate()
        
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
                navBar.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.dropbeatColor(alpha: r, saturation: r)]
            default:
                navBar.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.dropbeatColor(alpha: 0, saturation: 0)]
            }
        }
    }
    
    func statusBarTapped() {
        self.selectedScrollView.setContentOffset(CGPointMake(0, -self.headerView!.maximumOfHeight-44), animated: true)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.fetchUserInfo()
        
        if let navBar = self.navigationController?.navigationBar {
            navBar.translucent = true
            navBar.lt_setBackgroundColor(UIColor(white: 1.0, alpha: 0))
            navBar.barTintColor = UIColor.clearColor()
            navBar.tintColor = UIColor.whiteColor()
            navBar.shadowImage = UIImage()
            navBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        }
        
        if self.isMovingToParentViewController() == false {
            // back from navigation stack. previous page was popped!!
            self.baseUser?.updateFollowInfo()
            let header = self.headerView as! UserHeaderView
            if let followed = self.baseUser?.isFollowed() {
                header.followButton?.selected = followed
            }
            
            self.didHeightRatioChange(self.headerViewHeightRatio)
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "statusBarTapped", name: NotifyKey.statusBarTapped, object: nil)
        
        let header = self.headerView as! UserHeaderView
        
        if let passedName = self.passedName {
            header.nameLabel.text = passedName
        }
        if let passedImage = self.passedImage {
            header.profileImageView.image = passedImage
        }
        
        header.nameLabel.hidden = false
        header.profileImageView.hidden = false
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotifyKey.statusBarTapped, object: nil)
        
        if let topVC = self.navigationController?.topViewController as? UserViewController
            where topVC != self {
            print("Pushed to another user view controller")
        } else {
            print("Back to none-user view controller")
            if let navBar = self.navigationController?.navigationBar {
                navBar.barTintColor = UIColor.whiteColor()
                navBar.tintColor = nil
                navBar.shadowImage = nil
                navBar.setBackgroundImage(nil, forBarMetrics: UIBarMetrics.Default)
                navBar.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.blackColor()]
            }
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

}
