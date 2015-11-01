//
//  ProfileViewController.swift
//  labs
//
//  Created by Jungho Bang on 2015. 9. 22..
//  Copyright © 2015년 dropbeat. All rights reserved.
//

import UIKit

class ProfileHeaderView: UserHeaderView {
    @IBOutlet weak var favoriteGenresLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.favoriteGenresLabel.text = ""
    }
    
    override func interactiveSubviews() -> [AnyObject]! {
        return [aboutMeLabel, showFollowInfoButton]
    }
}

class ProfileViewController: UserViewController {

    // hope there's a better way but....
    var presented = false
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if self.isMovingToParentViewController() == false && presented == true {
            self.fetchUserInfo()
            if let subVC = self.selectedViewController as? AXSubViewController {
                subVC.subViewWillAppear()
            }
        }
        
        presented = true
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return super.preferredStatusBarStyle()
    }

    override func fetchUserInfo() {
        let accountUser = Account.getCachedAccount()!.user

        let header = self.headerView as! ProfileHeaderView
        header.maximumOfHeight = self.view.bounds.width * 3/8 + 140
        
        header.nameLabel.hidden = false
        header.profileImageView.hidden = false
        
        let progressHud = ViewUtils.showProgress(self, message: nil)
        BaseUser.resolve(accountUser!.resourceName) { (user, error) -> Void in
            progressHud.hide(true)
            
            if (error != nil) {
                ViewUtils.showNoticeAlert(self, title: "Can't get user information", message: error?.localizedDescription ?? "", callback: { () -> Void in
                    self.fetchUserInfo()
                })
                return
            }
            
            self.user = user!
            self.applyFetchedInfoToView()
            self.setFavoriteGenreLabel()
            self.setAboutMeLabel()
            self.title = "Profile"
            self.screenName = "MyProfileScreen"
        }
        
    }
    
    @IBAction func moreAction(sender: UIBarButtonItem) {
        let actionSheet = UIAlertController(
            title: nil,
            message: nil,
            preferredStyle: .ActionSheet)
        actionSheet.addAction(UIAlertAction(
            title: NSLocalizedString("Cancel", comment: "Cancel"),
            style: .Cancel, handler: nil))
        actionSheet.addAction(UIAlertAction(
            title: "View as public",
            style: .Default,
            handler: { (action) -> Void in
                let userVC = self.storyboard?.instantiateViewControllerWithIdentifier("UserViewController") as! UserViewController
                userVC.resource = self.user.resourceName
                self.navigationController?.pushViewController(userVC, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(
            title: "Application info",
            style: .Default,
            handler: { (action) -> Void in
                self.performSegueWithIdentifier("ShowSettings", sender: sender)
        }))
        actionSheet.addAction(UIAlertAction(
            title: "Sign out",
            style: .Destructive,
            handler: { (action) -> Void in
                ViewUtils.showConfirmAlert(self,
                    title: NSLocalizedString("Are you sure?", comment:""),
                    message: NSLocalizedString("Are you sure you want to sign out?", comment:""),
                    positiveBtnText: NSLocalizedString("Sign out", comment:""), positiveBtnCallback: { () -> Void in
                        let keychainItemWrapper = KeychainItemWrapper(identifier: "net.dropbeat.spark", accessGroup:nil)
                        keychainItemWrapper.resetKeychainItem()
                        Account.account = nil

                        DropbeatPlayer.defaultPlayer.stop()

                        let appDelegate:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                        appDelegate.setRootViewToStartupViewController()
                })
        }))
        self.showDetailViewController(actionSheet, sender: sender)//presentViewController(actionSheet, animated: true, completion: nil)
    }
    
    @IBAction func unwindFromEditProfile(sender: UIStoryboardSegue) {
        print("unwindFromEditProfile")
    }
    
    func setAboutMeLabel() {
        let header = self.headerView as! ProfileHeaderView
        if header.aboutMeLabel.text == "" {
            header.aboutMeLabel.text = "(about me)"
        } else {
            header.aboutMeLabel.text = Account.getCachedAccount()?.user?.aboutMe
        }
    }
    
    private var genres:[String:Genre] = [String:Genre]()
    
    func setFavoriteGenreLabel() {
        let header = self.headerView as! ProfileHeaderView
        
        let handler = { () -> Void in
            guard let account = Account.getCachedAccount() else {
                header.favoriteGenresLabel.text =
                    NSLocalizedString("No favorite genre selected", comment: "")
                return
            }
            
            if account.favoriteGenreIds.count == 0 {
                header.favoriteGenresLabel.text =
                    NSLocalizedString("No favorite genre selected", comment: "")
            } else {
                var message:String = ""
                var count = 0
                var selectedGenres = [String]()
                for genreId:String in account.favoriteGenreIds {
                    let genre = self.genres[genreId]
                    selectedGenres.append(genre!.name)
                    count += 1
                    if count >= 3 {
                        break
                    }
                }
                message = selectedGenres.joinWithSeparator(", ")
                
                let total = account.favoriteGenreIds.count
                let selected = selectedGenres.count
                let remain = total - selected
                if remain > 0 {
                    message += NSString.localizedStringWithFormat(
                        NSLocalizedString(" and %d others", comment:""),
                        remain) as String
                }
                
                header.favoriteGenresLabel.text = message
            }
        }
        
        if self.genres.count > 0 {
            handler()
            return
        }
        
        let genreHandler = { (genreMap:[String:[Genre]]) -> Void in
            let genres = genreMap["dropbeat"]!
            self.genres.removeAll(keepCapacity: false)
            for genre:Genre in genres {
                self.genres[genre.key] = genre
            }
            
            handler()
        }
        
        if let cachedGenre = GenreList.cachedResult {
            genreHandler(cachedGenre)
            return
        }
        
        let progressHud = ViewUtils.showProgress(self, message: "")
        header.favoriteGenresLabel.text = ""
        Requests.getFeedGenre { (result, error) -> Void in
            progressHud.hide(true)
            
            var genreResult:GenreList?
            if result != nil {
                genreResult = GenreList.parseGenre(result!)
            }
            if error != nil || result == nil ||
                (genreResult != nil && !genreResult!.success) {
                    ViewUtils.showConfirmAlert(self, title: NSLocalizedString("Failed to load", comment:""),
                        message: NSLocalizedString("Failed to load favorite genres", comment:""),
                        positiveBtnText: NSLocalizedString("Retry", comment:""), positiveBtnCallback: { () -> Void in
                            self.setFavoriteGenreLabel()
                        }, negativeBtnText: NSLocalizedString("Cancel", comment:""))
                    return
            }
            
            genreHandler(genreResult!.results!)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)
        
        if segue.identifier == "ShowSettings" {
            let settings = segue.destinationViewController as! SettingsViewController
            settings.navigationItem.leftBarButtonItem = nil
        }
    }
}


// MARK: - Handle none account case

class BeforeProfileNavigationController: UINavigationController {
    
    override func popToRootViewControllerAnimated(animated: Bool) -> [UIViewController]? {
        if viewControllers.count > 2 {
            return self.popToViewController(viewControllers[1], animated: animated)
        } else {
            return nil
        }
    }
    
}

class BeforeProfileViewController: UIViewController {
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if Account.getCachedAccount() == nil {
            self.performSegueWithIdentifier("ShowSetting", sender: self)
        } else {
//            self.performSegueWithIdentifier("ShowProfile", sender: self)
            let vc = self.storyboard?.instantiateViewControllerWithIdentifier("ProfileViewController") as! ProfileViewController
            self.navigationController?.pushViewController(vc, animated: false)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let rbSegue = segue as? RBStoryboardSegue {
            rbSegue.animated = false
        }
    }
    
}
