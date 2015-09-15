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
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var labelHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var showMoreButton: UIButton!
    @IBOutlet weak var followButton: UIButton!
    
    override func interactiveSubviews() -> [AnyObject]! {
        return [self.showMoreButton]
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
        
        self.title = "adfasdf"

        self.headerView = BaseUserHeaderView.instantiate()
        self.headerView.maximumOfHeight = 260;
        
        let header = self.headerView as! BaseUserHeaderView
        header.loadView()

        
        Requests.resolveUser(self.resource) {(req, resp, result, error) -> Void in
            
            if (error != nil || JSON(result!)["success"] == false) {
                UIAlertView(title: "Error", message: JSON(result!)["error"].stringValue, delegate: nil, cancelButtonTitle: "I see").show()
                return
            }
            
            switch JSON(result!)["data"]["user_type"] {
            case "user":
                var user = User.parseUser(result!,key:"data",secondKey:"user")
                let header = self.headerView as! BaseUserHeaderView
                let label = header.descriptionLabel
                label.text = user.description
                break
            case "artist":
                var artist = Artist.parseArtist(result!,key:"data",secondKey:"user")
                break
            case "channel":
                var channel = Channel.parseChannel(result!,key:"data",secondKey: "user")
                break
            default:
                var message = "Unknown user_type"
                return
            }
        }
        var testing = true
        if testing {
            
            //            var header = self.headerView as! BaseUserHeaderView
            header.showMoreButton.addTarget(self, action: "buttonAction", forControlEvents: UIControlEvents.TouchUpInside)
            
            var vcArr: [UIViewController] = []
            for x in 0..<3 {
                var vc: UserDetailTableViewController = self.storyboard?.instantiateViewControllerWithIdentifier("UserDetailTableViewController") as! UserDetailTableViewController
                vc.arg = x
                vcArr.append(vc)
            }
            self.viewControllers = vcArr
        }
    }
    
    func buttonAction() {
        let header = self.headerView as! BaseUserHeaderView
        let label = header.descriptionLabel
        let currentHeight = label.frame.height
        
        let attr = [NSFontAttributeName:label.font]
        let rect = label.text!.boundingRectWithSize(CGSizeMake(label.frame.width, CGFloat.max), options:NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: attr, context:nil)
        let contentHeight = ceil(rect.height)
        
        var diff = contentHeight - currentHeight
        
        if diff > 0 {
            self.headerView.maximumOfHeight += diff
            header.labelHeightConstraint.constant = contentHeight
            self.layoutViewControllers()
            
            self.selectedScrollView.setContentOffset(CGPointMake(0, self.selectedScrollView.contentOffset.y-diff), animated: false)
            self.layoutViewControllers()
        }
    }
    
    override func didHeightRatioChange(ratio: CGFloat) {
        super.didHeightRatioChange(ratio)
        
        if ratio == 0.0 {
            let header = self.headerView as! BaseUserHeaderView
            let label = header.descriptionLabel
            let currentHeight = label.frame.height
            if currentHeight > 70 {
                header.labelHeightConstraint.constant = 70
                self.headerView.maximumOfHeight -= (currentHeight-70)
                self.layoutViewControllers()
            }
        }
    }

}
