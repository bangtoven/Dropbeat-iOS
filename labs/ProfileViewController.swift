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
//    @IBOutlet weak var editNicknameButton: UIButton!
//    @IBOutlet weak var editGenresButton: UIButton!
//    @IBOutlet weak var editAboutMeButton: UIButton!
//    
//    override func interactiveSubviews() -> [AnyObject]! {
//        return [self.editNicknameButton, self.editGenresButton, self.editAboutMeButton]
//    }
//    
//    override func awakeFromNib() {
//        super.awakeFromNib()
//        
//        for button:UIButton in [editNicknameButton,editGenresButton,editAboutMeButton] {
//            button.tintColor = UIColor.dropbeatColor()
//            button.backgroundColor = UIColor.whiteColor()
//            button.layer.cornerRadius = 5
//            button.layer.borderWidth = 1
//            button.layer.borderColor = UIColor.dropbeatColor().CGColor
//            button.clipsToBounds = true
//        }
//    }
}

class ProfileViewController: UserViewController {

    private var genres:[String:Genre] = [String:Genre]()
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "likeUpdated", name: NotifyKey.likeUpdated, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotifyKey.likeUpdated, object: nil)
    }

    override func fetchUserInfo() {
        let user = Account.getCachedAccount()?.user
        self.baseUser = user

        let header = self.headerView as! ProfileHeaderView
        header.maximumOfHeight = (320-64)
        header.nameLabel.hidden = false
        header.profileImageView.hidden = false
        
        self.applyFetchedInfoToView()
        self.setFavoriteGenreLabel()
        self.setAboutMeLabel()
        
        self.title = "Profile"
    }
    
    func likeUpdated() {
        print("like updated")
        if let likesSubView: TrackSubViewController = self.viewControllers[self.viewControllers.count-3] as? TrackSubViewController {
            likesSubView.tracks.removeAll()
            likesSubView.subViewWillAppear()
        }
    }
    
    override func didHeightRatioChange(ratio: CGFloat) {
        super.didHeightRatioChange(0.0)
    }
    
    @IBAction func unwindFromEditProfile(sender: UIStoryboardSegue) {
        print("I am back.")
    }
    
    func setAboutMeLabel() {
        let header = self.headerView as! ProfileHeaderView
        if header.aboutMeLabel.text == "" {
            header.aboutMeLabel.text = "(about me)"
        } else {
            header.aboutMeLabel.text = Account.getCachedAccount()?.user?.aboutMe
        }
    }
    
    func setFavoriteGenreLabel() {
        let header = self.headerView as! ProfileHeaderView
        
        let handler = { () -> Void in
            let account = Account.getCachedAccount()!
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
        Requests.getFeedGenre { (req:NSURLRequest, resp:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
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
}