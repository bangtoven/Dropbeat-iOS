//
//  UserViewController.swift
//  labs
//
//  Created by Jungho Bang on 2015. 9. 14..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

class BaseUserHeaderView: AXStretchableHeaderView {
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
        self.profileImageView.layer.cornerRadius = 10
        self.profileImageView.layer.borderWidth = 2
        self.profileImageView.layer.borderColor = UIColor.whiteColor().CGColor;
        self.profileImageView.clipsToBounds = true
    }
}

class UserViewController: BaseUserViewController {

    var user: BaseUser!
    var resource: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.headerView = BaseUserHeaderView.instantiate()

        let header = self.headerView as! BaseUserHeaderView
        header.maximumOfHeight = 260
        header.loadView()
        header.followInfoView.hidden = true
        header.followButton.addTarget(self, action: "followAction:", forControlEvents: UIControlEvents.TouchUpInside)
        header.showMoreButton.hidden = true
        
        Requests.resolveUser(self.resource) {(req, resp, result, error) -> Void in
            
            if (error != nil || JSON(result!)["success"] == false) {
                UIAlertView(title: "Error", message: JSON(result!)["error"].stringValue, delegate: nil, cancelButtonTitle: "I see").show()
                return
            }
            
            var baseUser : BaseUser?
            switch JSON(result!)["data"]["user_type"] {
            case "user":
                var user = User.parseUser(result!,key:"data",secondKey:"user")
                header.descriptionLabel.text = user.description
                header.followInfoView.hidden = false
                header.followersLabel.text = String(user.num_followers)
                header.followingLabel.text = String(user.num_following)
                baseUser = user
            case "artist":
                var artist = Artist.parseArtist(result!,key:"data",secondKey:"user")
                header.descriptionLabel.text = ""
                baseUser = artist
            case "channel":
                var channel = Channel.parseChannel(result!,key:"data",secondKey: "user")
                header.descriptionLabel.text = ", ".join(channel!.genre)
                baseUser = channel
            default:
                var message = "Unknown user_type"
                return
            }
            
            if let name = baseUser?.name {
                self.title = name
                header.nameLabel.text = name
            }
            if let profileImage = baseUser?.image {
                header.profileImageView.sd_setImageWithURL(NSURL(string: profileImage), placeholderImage: UIImage(named: "default_profile.png"))
            }
            if let coverImage = baseUser?.coverImage {
                header.coverImageView.sd_setImageWithURL(NSURL(string: coverImage), placeholderImage: UIImage(named: "default_cover_big.png"))
            }
            
            var descriptionHeight = self.calculateDescriptionContentSize()
            if descriptionHeight <= 32 {
                header.showMoreButton.hidden = true
            } else {
                self.headerView.maximumOfHeight += 32
                header.labelHeightConstraint.constant = 64
                self.selectedScrollView.setContentOffset(CGPointMake(0, self.selectedScrollView.contentOffset.y-32), animated: false)
                if descriptionHeight > 64 {
                    header.showMoreButton.hidden = false
                    header.showMoreButton.addTarget(self, action: "showMoreAction", forControlEvents: UIControlEvents.TouchUpInside)
                }
            }
        }
        
        var testing = true
        if testing {
            var vcArr: [UIViewController] = []
            for x in 0..<3 {
                var vc: UserDetailTableViewController = self.storyboard?.instantiateViewControllerWithIdentifier("UserDetailTableViewController") as! UserDetailTableViewController
                vc.arg = x
                vcArr.append(vc)
            }
            self.viewControllers = vcArr
        }
    }
    
    func followAction(sender: UIButton) {
 
    }
    
    func showMoreAction() {
        let header = self.headerView as! BaseUserHeaderView
        let label = header.descriptionLabel
        let currentHeight = label.frame.height
        let contentHeight = calculateDescriptionContentSize()
        var diff = contentHeight - currentHeight
        
        if diff > 0 {
            self.headerView.maximumOfHeight += diff
            header.labelHeightConstraint.constant = contentHeight
            self.selectedScrollView.setContentOffset(CGPointMake(0, self.selectedScrollView.contentOffset.y-diff), animated: false)
            self.layoutViewControllers()
        }
    }
    
    func calculateDescriptionContentSize() -> CGFloat {
        let header = self.headerView as! BaseUserHeaderView
        let label = header.descriptionLabel
        let attr = [NSFontAttributeName:label.font]
        let rect = label.text!.boundingRectWithSize(CGSizeMake(label.frame.width, CGFloat.max), options:NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: attr, context:nil)
        return ceil(rect.height)
    }
    
    override func didHeightRatioChange(ratio: CGFloat) {
        super.didHeightRatioChange(ratio)
        
        let header = self.headerView as! BaseUserHeaderView
//        switch ratio {
//        case 0.0...0.6:
//            header.profileImageHeight.constant = 40
//        case 0.6...1.0:
//            header.profileImageHeight.constant = 100*ratio - 20
//        default:
//            header.profileImageHeight.constant = 80
//        }
        
        var defaultDescriptionHeight: CGFloat = 64
        
        if ratio == 0.0 {
            let label = header.descriptionLabel
            let currentHeight = label.frame.height
            if currentHeight > defaultDescriptionHeight {
                header.labelHeightConstraint.constant = defaultDescriptionHeight
                self.headerView.maximumOfHeight -= (currentHeight-defaultDescriptionHeight)
                self.layoutViewControllers()
            }
        }
    }

}
