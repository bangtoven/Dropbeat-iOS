//
//  SelfProfileViewController.swift
//  labs
//
//  Created by Jungho Bang on 2015. 9. 22..
//  Copyright © 2015년 dropbeat. All rights reserved.
//

import UIKit

class SelfProfileViewController: UserViewController {
    
    override func fetchUserInfo() {
        self.baseUser = Account.getCachedAccount()?.user

        self.headerView = ProfileHeaderView.instantiate()
        let header = self.headerView as! ProfileHeaderView
        header.maximumOfHeight = 144
        header.loadView()
        header.nameLabel.hidden = false
        header.profileImageView.hidden = false
        
        header.editNicknameButton.addTarget(self, action: "editNickname:", forControlEvents: .TouchUpInside)
        header.editAboutMeButton.addTarget(self, action: "editAboutMe:", forControlEvents: .TouchUpInside)
        
        self.applyFetchedInfoToView()
        self.setAboutMeLabel()
    }
    
    func setAboutMeLabel() {
        let header = self.headerView as! ProfileHeaderView
        if header.aboutMeLabel.text == "" {
            header.aboutMeLabel.text = "(about me)"
        } else {
            header.aboutMeLabel.text = Account.getCachedAccount()?.user?.aboutMe
        }
    }
    
    func editAboutMe(sender: UIButton) {
        self.performSegueWithIdentifier("editAboutMe", sender: nil)
    }
    
    @IBAction func unwindFromEditAboutMe(sender: UIStoryboardSegue) {
        self.setAboutMeLabel()
    }
    
    func editNickname(sender: UIButton) {
        self.performSegueWithIdentifier("editNickname", sender: nil)
    }
    
    @IBAction func unwindFromEditNickname(sender: UIStoryboardSegue) {
        let header = self.headerView as! ProfileHeaderView
        header.nameLabel.text = baseUser.name
    }
}

class ProfileHeaderView: UserHeaderView {
    
    @IBOutlet weak var editNicknameButton: UIButton!
    @IBOutlet weak var editAboutMeButton: UIButton!
    
    func setButtonSetting(button: UIButton) {
        button.tintColor = UIColor.dropbeatColor()
        button.layer.cornerRadius = 5
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.dropbeatColor().CGColor
        button.clipsToBounds = true
    }
    
    override func loadView() {
        super.loadView()
        
        self.setButtonSetting(self.editNicknameButton)
        self.setButtonSetting(self.editAboutMeButton)
    }
    
    override func interactiveSubviews() -> [AnyObject]! {
        return [self.editNicknameButton, self.editAboutMeButton]
    }
}