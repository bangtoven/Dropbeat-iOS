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
        self.nameLabel.text = " "
        self.descriptionLabel.text = "\n\n"
        
        self.followInfoView.hidden = true
        self.showMoreButton.hidden = true
        
        self.profileImageView.layer.cornerRadius = 10
        self.profileImageView.layer.borderWidth = 2
        self.profileImageView.layer.borderColor = UIColor.whiteColor().CGColor;
        self.profileImageView.clipsToBounds = true
    }
}

class UserViewController: AXStretchableHeaderTabViewController {
    var user: BaseUser!
    var resource: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.tintColor = UIColor.dropbeatColor()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "statusBarTapped", name: NotifyKey.statusBarTapped, object: nil)

        self.headerView = UserHeaderView.instantiate()

        let header = self.headerView as! UserHeaderView
        header.maximumOfHeight = 260
        
        header.loadView()
        header.followButton.addTarget(self, action: "followAction:", forControlEvents: UIControlEvents.TouchUpInside)
        
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
                
                user.fetchLikeList({ (u, likes, error) -> Void in
                    var tlvc: TrackListViewController = self.storyboard?.instantiateViewControllerWithIdentifier("TrackListViewController") as! TrackListViewController
                    tlvc.tracks = user.tracks
                    tlvc.title = "Uploads"
                    tlvc.user = user
                    
                    var tlvc2: TrackListViewController = self.storyboard?.instantiateViewControllerWithIdentifier("TrackListViewController") as! TrackListViewController
                    if likes!.count != 0 {
                        var tracks:[Track] = []
                        for i in 0..<likes!.count {
                            tracks.append(likes![i].track)
                        }
                        tlvc2.tracks = tracks
                    }
                    tlvc2.title = "Likes"
                    tlvc2.user = user
                    
                    self.viewControllers = [tlvc2, tlvc]
                })
                
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
 
    }
    
    func showMoreAction() {
        let header = self.headerView as! UserHeaderView
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
        self.selectedScrollView.setContentOffset(CGPointMake(0, -self.headerView.maximumOfHeight-44), animated: true)
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


//var vcArr: [UIViewController] = []
//for x in 0..<3 {
//    var vc: UserDetailTableViewController = self.storyboard?.instantiateViewControllerWithIdentifier("UserDetailTableViewController") as! UserDetailTableViewController
//    vc.arg = x
//    vcArr.append(vc)
//}
//self.viewControllers = vcArr

//class UserDetailTableViewController: UITableViewController, AXSubViewController, DYAlertPickViewDataSource, DYAlertPickViewDelegate {
//    
//    var arg: Int!
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        var title: String = String()
//        for i in 0...arg {
//            title += "TAB "
//        }
//        title += String(arg)
//        self.title = title
//    }
//    
//    func subViewWillDisappear() {
//        println(String(arg) + " subViewDidDisappear")
//    }
//    
//    func subViewWillAppear() {
//        println(String(arg) + " subViewWillAppear")
//    }
//    
//    // MARK: -
//    // MARK: DYAlertPickViewDataSource
//    var selectedSection: Int = -1
//    
//    @IBOutlet weak var button: UIButton!
//    @IBAction func buttonTapped(sender: AnyObject) {
//        var picker: DYAlertPickView = DYAlertPickView(headerTitle: "Choose Section", cancelButtonTitle: nil, confirmButtonTitle: nil, switchButtonTitle: nil)
//        picker.dataSource = self
//        picker.delegate = self
//        picker.tintColor = UIColor.redColor();
//        picker.showAndSelectedIndex(self.selectedSection)
//    }
//    
//    func titleForRowInDYAlertPickView(titleForRow: Int) -> NSAttributedString! {
//        return NSAttributedString(string: "asdf"+String(titleForRow))
//    }
//    //
//    func numberOfRowsInDYAlertPickerView(pickerView: DYAlertPickView) -> Int {
//        return 10
//    }
//    
//    func didConfirmWithItemAtRowInDYAlertPickView(row: Int) {
//        self.selectedSection = row
//        println(row)
//    }
//    
//    // MARK: - Table view data source
//    
//    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
//        // #warning Potentially incomplete method implementation.
//        // Return the number of sections.
//        return 1
//    }
//    
//    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        // #warning Incomplete method implementation.
//        // Return the number of rows in the section.
//        return 30
//    }
//    
//    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath) as! UITableViewCell
//        
//        cell.textLabel?.text = String(arg) + " . " + String(indexPath.row)
//        
//        return cell
//    }
//    
//}
