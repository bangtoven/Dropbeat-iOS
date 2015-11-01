//
//  EditProfileViewController.swift
//  labs
//
//  Created by Jungho Bang on 2015. 10. 1..
//  Copyright © 2015년 dropbeat. All rights reserved.
//

import UIKit

enum ProfileDataType: Int {
    case IMAGE = 0
    case NICKNAME
    case ABOUT_ME
    case FAVORITE_GENRE
}

class EditImageTableViewCell: UITableViewCell {
    
    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var profileImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.coverImageView.clipsToBounds = true
        
        self.profileImageView.layer.cornerRadius = 10
        self.profileImageView.layer.borderWidth = 2
        self.profileImageView.layer.borderColor = UIColor(white: 0.95, alpha: 1.0).CGColor
        self.profileImageView.clipsToBounds = true
    }
}

class EditProfileViewController: UITableViewController, ACEExpandableTableViewDelegate, GKImagePickerDelegate {

    var nickname: String!
    var aboutMe: String!
    var profileImage: UIImage?
    var coverImage: UIImage?
    var isProfileImageChanged = false {
        didSet { self.saveBarButton.enabled = true }
    }
    var isCoverImageChanged = false {
        didSet { self.saveBarButton.enabled = true }
    }
    
    @IBOutlet weak var saveBarButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:" ", style:.Plain, target:nil, action:nil)
        
        self.saveBarButton.enabled = false
        
        let account = Account.getCachedAccount()?.user
        self.nickname = account!.nickname
        self.aboutMe = account!.aboutMe
        
        let imageManager = SDWebImageManager.sharedManager()
        if let profileImage = account!.image {
            imageManager.downloadImageWithURL(NSURL(string: profileImage), options: .HighPriority, progress: nil) {
                (image, error, cacheType, finished, imageURL) -> Void in
                self.profileImage = image
                self.tableView.reloadData()
            }
        }
        if let coverImage = account!.coverImage {
            imageManager.downloadImageWithURL(NSURL(string: coverImage), options: .HighPriority, progress: nil) {
                (image, error, cacheType, finished, imageURL) -> Void in
                self.coverImage = image
                self.tableView.reloadData()
            }
        }
    }
    
    // MARK: - images
    
    private var imagePicker: GKImagePicker?
    
    func imagePicker(imagePicker: GKImagePicker!, pickedImage image: UIImage!) {
        let resized = image.imageWithScaledToSize(imagePicker.cropSize)

        switch resized.size.height {
        case 600: // Profile
            self.profileImage = resized
            self.isProfileImageChanged = true
        case 300: // Cover
            self.coverImage = resized
            self.isCoverImageChanged = true
        default:
            print("image picker size error: \(resized.size.height)")
            break
        }
        
        print(resized)
        self.imagePicker = nil
        self.tableView.reloadData()
    }
    
    @IBAction func changeProfileImage(sender: UIButton) {
        let imagePicker = GKImagePicker()
        imagePicker.cropSize = CGSize(width: 600, height: 600)
        imagePicker.delegate = self
        imagePicker.useFrontCameraAsDefault = true
     
        imagePicker.showActionSheetOnViewController(self, onPopoverFromView: sender)
        
        self.imagePicker = imagePicker
    }
    
    @IBAction func changeCoverImage(sender: UIButton) {
        let imagePicker = GKImagePicker()
        imagePicker.cropSize = CGSize(width: 1200, height: 300)
        imagePicker.delegate = self
        
        imagePicker.showActionSheetOnViewController(self, onPopoverFromView: sender)

        self.imagePicker = imagePicker
    }
    
    // MARK: - save changes
    
    private var isSubmitting = false
    
    @IBAction func saveAction(sender: UIBarButtonItem) {
        self.view.endEditing(true)
        
        if isSubmitting == false {
            syncProfileData()
        }
    }
    
    func syncProfileData() {
        let account = Account.getCachedAccount()?.user
        if self.nickname != account!.nickname {
            self.submitNickname()
        } else if self.aboutMe != account!.aboutMe {
            self.submitAboutMe()
        } else if self.isProfileImageChanged {
            self.updateImage(.Profile)
        } else if self.isCoverImageChanged {
            self.updateImage(.Cover)
        } else {
            self.performSegueWithIdentifier("unwindFromEditProfile", sender: nil)
        }
    }
    
    private var progressHud: MBProgressHUD!
    
    func updateImage(type: ImageType) {
        
        self.isSubmitting = true
        self.progressHud = ViewUtils.showProgress(self, message: "Uploading image")

        let image = type == .Profile ? self.profileImage : self.coverImage
        ImageUploader.uploadImage(image!, type: type) {
            (url, error) -> Void in
            if url == nil {
                self.progressHud.hide(true)
                self.isSubmitting = false
                ViewUtils.showNoticeAlert(self,
                    title: NSLocalizedString("Failed to upload image", comment:""),
                    message: error!.localizedDescription)
                return
            }
            
            self.progressHud.mode = MBProgressHUDMode.CustomView
            self.progressHud.customView = UIImageView(image: UIImage(named:"37x-Checkmark"))
            self.progressHud.hide(true, afterDelay: 1)
            self.isSubmitting = false
            let popTime = dispatch_time(DISPATCH_TIME_NOW, Int64(1.0 * Double(NSEC_PER_SEC)));
            dispatch_after(popTime, dispatch_get_main_queue(), {() -> Void in
                
                let account = Account.getCachedAccount()?.user
                switch type {
                case .Profile:
                    self.isProfileImageChanged = false
                    account!.image = url
                case .Cover:
                    self.isCoverImageChanged = false
                    account!.coverImage = url
                }
                
                self.syncProfileData()
                
            })
        }
    }
    
    func submitNickname() {
        let newNickname = self.nickname
        if newNickname.characters.count == 0 {
            ViewUtils.showNoticeAlert(self,
                title: NSLocalizedString("Failed to change", comment:""),
                message: NSLocalizedString("Required Field", comment:""))
            return
        }
        if newNickname.characters.count > 25 {
            ViewUtils.showNoticeAlert(self,
                title: NSLocalizedString("Failed to change", comment:""),
                message:  NSString.localizedStringWithFormat(
                    NSLocalizedString("Must be less than %d characters long", comment:""), 25) as String)
            return
        }
        
        self.isSubmitting = true
        self.progressHud = ViewUtils.showProgress(self, message: "Nickname")
        
        Requests.changeNickname(newNickname, handler: self.responseHandlerWith(
            onSuccess: {
                Account.getCachedAccount()!.user!.nickname = newNickname
            }, onFailure: {
                ViewUtils.showNoticeAlert(self,
                    title: NSLocalizedString("Failed to change", comment:""),
                    message: NSLocalizedString("Nickname already exists", comment:""))
        }))
    }
    
    func submitAboutMe () {
        let newAboutMe = self.aboutMe
        
        self.isSubmitting = true
        self.progressHud = ViewUtils.showProgress(self, message: "About me")

        Requests.changeAboutMe(newAboutMe, handler: self.responseHandlerWith(
            onSuccess: {
                Account.getCachedAccount()!.user!.aboutMe = newAboutMe
        }))
    }
    
    private func responseHandlerWith(onSuccess onSuccess:(Void->Void), onFailure:(Void->Void)? = nil) -> ResponseHandler {
            return { (result, error) -> Void in
                
                if error != nil || result == nil {
                    self.progressHud.hide(true)
                    self.isSubmitting = false
                    if (error!.domain == NSURLErrorDomain && error!.code == NSURLErrorNotConnectedToInternet) {
                        ViewUtils.showConfirmAlert(self,
                            title: NSLocalizedString("Failed to change", comment:""),
                            message: NSLocalizedString("Internet is not connected", comment:""))
                    } else {
                        ViewUtils.showNoticeAlert(self,
                            title: NSLocalizedString("Failed to change", comment:""),
                            message: NSLocalizedString("Failed to change", comment:""))
                    }
                    return
                }
                
                if !(JSON(result!)["success"].bool ?? false) {
                    self.progressHud.hide(true)
                    self.isSubmitting = false
                    onFailure?()
                    return
                }
                
                self.progressHud.mode = MBProgressHUDMode.CustomView
                self.progressHud.customView = UIImageView(image: UIImage(named:"37x-Checkmark"))
                self.progressHud.hide(true, afterDelay: 1)
                self.isSubmitting = false
                let popTime = dispatch_time(DISPATCH_TIME_NOW, Int64(1.0 * Double(NSEC_PER_SEC)));
                dispatch_after(popTime, dispatch_get_main_queue(), {() -> Void in
                    
                    onSuccess()
                    self.syncProfileData()
                    
                })
            }
    }
    
    // MARK: - cancel changes
    
    @IBAction func cancelAction(sender: UIBarButtonItem) {
        self.view.endEditing(true)
        
        let account = Account.getCachedAccount()?.user
        if self.nickname == account!.nickname && self.aboutMe == account!.aboutMe {
            self.navigationController?.popViewControllerAnimated(true)
        } else {
            let actionSheet = UIAlertController(
                title: NSLocalizedString("Your changes will be lost if you don’t save them.", comment:""),
                message: nil,
                preferredStyle: .ActionSheet)
            actionSheet.addAction(UIAlertAction(
                title: NSLocalizedString("Cancel", comment:""),
                style: .Cancel, handler: nil))
            actionSheet.addAction(UIAlertAction(
                title: NSLocalizedString("Don't save", comment:""),
                style: .Destructive, handler: { (action) -> Void in
                self.navigationController?.popViewControllerAnimated(true)
            }))
            self.showDetailViewController(actionSheet, sender: sender)// presentViewController(actionSheet, animated: true, completion: nil)
        }
    }
    
    // MARK: - contents
    
    func tableView(tableView: UITableView!, updatedText text: String!, atIndexPath indexPath: NSIndexPath!) {
        switch ProfileDataType(rawValue: indexPath.section)! {
        case .NICKNAME:
            if text.length <= 25 {
                self.nickname = text
            } else {
                self.nickname = text.subString(0, length: 25)
            }
        case .ABOUT_ME:
            self.aboutMe = text
        default:
            return
        }
        
        let account = Account.getCachedAccount()?.user
        if self.nickname != account!.nickname || self.aboutMe != account!.aboutMe {
            self.saveBarButton.enabled = true
        }
    }

    @IBAction func unwindFromEditFavoriteGenres(sender: UIStoryboardSegue) {
        self.saveBarButton.enabled = true
        self.tableView.reloadData()
    }
    
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 4
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch ProfileDataType(rawValue: section)! {
        case .IMAGE:
            return "Profile & cover images"
        case .NICKNAME:
            return "Nickname"
        case .ABOUT_ME:
            return "About me"
        case .FAVORITE_GENRE:
            return "Favorite genres"
        }
    }
    
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == ProfileDataType.IMAGE.rawValue {
            return "You can see full cover image @ dropbeat.net website."
        } else {
            return nil
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch ProfileDataType(rawValue: indexPath.section)! {
        case .IMAGE:
            let cell = tableView.dequeueReusableCellWithIdentifier("image", forIndexPath: indexPath) as! EditImageTableViewCell
            cell.profileImageView.image = self.profileImage ?? UIImage(named: "default_profile")
            cell.coverImageView.image = self.coverImage ?? UIImage(named: "default_cover_big")
            return cell
        case .NICKNAME:
            let cell = tableView.expandableTextCellWithId("Nickname")
            cell.textView.placeholder = "Nickname"
            cell.text = self.nickname
            return cell
        case .ABOUT_ME:
            let cell = tableView.expandableTextCellWithId("AboutMe")
            cell.textView.placeholder = "About me"
            cell.text = self.aboutMe
            return cell
        case .FAVORITE_GENRE:
            let cell = tableView.dequeueReusableCellWithIdentifier("normalCell", forIndexPath: indexPath)
            cell.textLabel?.textColor = UIColor.grayColor()
            cell.textLabel?.text = NSString.localizedStringWithFormat(
                NSLocalizedString("%d genre is selected", comment:""), Account.getCachedAccount()?.favoriteGenreIds.count ?? 0) as String
            return cell
        }
        
    }
    
    var aboutMeCellHeight: CGFloat = 50
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch ProfileDataType(rawValue: indexPath.section)! {
        case .IMAGE:
            return self.view.bounds.width * 3/8
        case .ABOUT_ME:
            return max(self.aboutMeCellHeight, 50)
        default:
            return 50
        }
    }
    
    func tableView(tableView: UITableView!, updatedHeight height: CGFloat, atIndexPath indexPath: NSIndexPath!) {
        if indexPath.section == ProfileDataType.ABOUT_ME.rawValue {
            self.aboutMeCellHeight = height
        }
    }
}
