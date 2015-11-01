//
//  EditFavoriteGenreViewController.swift
//  labs
//
//  Created by Jungho Bang on 2015. 9. 23..
//  Copyright © 2015년 dropbeat. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

class GenreTableViewCell: UITableViewCell {
    @IBOutlet weak var genreView: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        let selectedBgView = UIView(frame: self.bounds)
        selectedBgView.autoresizingMask = [UIViewAutoresizing.FlexibleHeight, UIViewAutoresizing.FlexibleWidth]
        selectedBgView.backgroundColor = UIColor(netHex: 0xdddddd)
        self.selectedBackgroundView = selectedBgView
    }
}

class EditFavoriteGenreViewController: GAITrackedViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var discoverBtn: UIButton!
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var footerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var doneBtn: UIButton!
    @IBOutlet weak var selectStatus: UILabel!
    
    private var genres:[Genre] = [Genre]()
    private var selectedGenreIds:Set<String> = Set<String>()
    private var remoteSelectedGenreIds:Set<String> = Set<String>()
    private var isLoading:Bool = false
    private var progressHud:MBProgressHUD?

    var fromStartup = false

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:" ", style:.Plain, target:nil, action:nil)

        footerView.hidden = true
        footerViewHeightConstraint.constant = -60.0
        
        discoverBtn.layer.borderWidth = 1
        discoverBtn.layer.borderColor = UIColor.dropbeatColor().CGColor
        discoverBtn.layer.cornerRadius = 3.0
        
        doneBtn.layer.borderWidth = 1
        doneBtn.layer.borderColor = UIColor.dropbeatColor().CGColor
        doneBtn.layer.cornerRadius = 3.0
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.screenName = "FavoriteGenreTutorialViewScreen"
        loadFavorites()
        
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "onTrackFinished:", name: AVPlayerItemDidPlayToEndTimeNotification, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(
            self, name: AVPlayerItemDidPlayToEndTimeNotification, object: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "discover" {
            let vc = segue.destinationViewController as! GenreDiscoveryViewController
            for id in remoteSelectedGenreIds {
                vc.remoteFavoriteIds.insert(id)
            }
            vc.fromStartup = self.fromStartup
        }
    }
    
    @IBAction func onDoneBtnClicked(sender: AnyObject) {
        if selectedGenreIds.count == 0 {
            return
        }
        onSaveGenreClicked()
    }
    
    @IBAction func cancelAction(sender: AnyObject) {
        self.performSegueWithIdentifier("unwindFromEditFavoriteGenres", sender: nil)
    }
    
    func onSaveGenreClicked() {
        if selectedGenreIds.count == 0 {
            return
        }
        let idsToRemove = remoteSelectedGenreIds.subtract(selectedGenreIds)
        let idsToAdd = selectedGenreIds.subtract(remoteSelectedGenreIds)
        
        let progressHud = ViewUtils.showProgress(self, message: "")
        var doneRemove = false
        var doneAdd = false
        var firedError = false
        
        let handler = { (error:NSError?) -> Void in
            if error != nil {
                if firedError {
                    return
                }
                firedError = true
                progressHud.hide(true)
                
                if (error != nil && error!.domain == NSURLErrorDomain &&
                    error!.code == NSURLErrorNotConnectedToInternet) {
                        
                        ViewUtils.showConfirmAlert(self,
                            title: NSLocalizedString("Failed to save", comment:""),
                            message: NSLocalizedString("Internet is not connected", comment:""),
                            positiveBtnText: NSLocalizedString("Retry", comment: ""),
                            positiveBtnCallback: { () -> Void in
                                self.onSaveGenreClicked()
                        })
                        return
                }
                
                ViewUtils.showNoticeAlert(self,
                    title: NSLocalizedString("Failed to save", comment:""),
                    message: NSLocalizedString("Failed to save genere", comment:""))
                return
            }
            if !doneAdd || !doneRemove {
                return
            }
            let account = Account.getCachedAccount()
            account!.favoriteGenreIds.removeAll(keepCapacity: false)
            for id in self.selectedGenreIds {
                account!.favoriteGenreIds.insert(id)
            }
            
            progressHud.mode = MBProgressHUDMode.CustomView
            progressHud.customView = UIImageView(image: UIImage(named:"37x-Checkmark"))
            progressHud.hide(true, afterDelay: 1)
            
            
            if idsToAdd.count > 0 || idsToRemove.count > 0 {
                let defaultDb:NSUserDefaults = NSUserDefaults.standardUserDefaults()
                defaultDb.setObject(
                    NSDate(timeIntervalSinceNow: 60 * 60 * 2),
                    forKey: UserDataKey.maxFavoriteCacheExpireDate)
            }
            
            let popTime = dispatch_time(DISPATCH_TIME_NOW, Int64(1.0 * Double(NSEC_PER_SEC)));
            dispatch_after(popTime, dispatch_get_main_queue(), {() -> Void in
                if self.fromStartup {
                    self.performSegueWithIdentifier("unwindToStart", sender: nil)
                } else {
                    self.performSegueWithIdentifier("unwindFromEditFavoriteGenres", sender: nil)
                }
            })
            
        }
        
        if idsToRemove.count > 0 {
            var genreIds = [String]()
            for key:String in idsToRemove {
                genreIds.append(key)
            }
            Requests.delFavoriteGenre(genreIds) { (result, error) -> Void in
                if error != nil {
                    handler(error!)
                    return
                }
                doneRemove = true
                handler(nil)
            }
        } else {
            doneRemove = true
            handler(nil)
        }
        
        
        if idsToAdd.count > 0 {
            var genreIds = [String]()
            for key:String in idsToAdd {
                genreIds.append(key)
            }
            Requests.addFavoriteGenre(genreIds) { (result, error) -> Void in
                if error != nil {
                    handler(error!)
                    return
                }
                
                doneAdd = true
                handler(nil)
            }
        } else {
            doneAdd = true
            handler(nil)
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell:GenreTableViewCell = tableView.dequeueReusableCellWithIdentifier("GenreTableViewCell",
            forIndexPath: indexPath) as! GenreTableViewCell
        let genre = genres[indexPath.row]
        cell.genreView.text = genre.name
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return genres.count
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if tableView.respondsToSelector("separatorInset") {
            tableView.separatorInset = UIEdgeInsetsZero
        }
        
        tableView.layoutMargins = UIEdgeInsetsZero
        cell.layoutMargins = UIEdgeInsetsZero
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let genre = genres[indexPath.row]
        selectedGenreIds.insert(genre.key)
        if selectedGenreIds.count > 0 && footerView.hidden {
            self.view.layoutIfNeeded()
            footerView.hidden = false
            footerViewHeightConstraint.constant = 0
            UIView.animateWithDuration(0.3, animations: { () -> Void in
                self.view.layoutIfNeeded()
            })
        }
        selectStatus.text = NSString.localizedStringWithFormat(
            NSLocalizedString("%d genre is selected", comment:""), selectedGenreIds.count) as String
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        let genre = genres[indexPath.row]
        selectedGenreIds.remove(genre.key)
        if selectedGenreIds.count == 0 {
            self.view.layoutIfNeeded()
            footerViewHeightConstraint.constant = -60
            UIView.animateWithDuration(0.3, animations: { () -> Void in
                self.view.layoutIfNeeded()
                }, completion: { (finished:Bool) -> Void in
                    self.footerView.hidden = true
            })
        }
        selectStatus.text = NSString.localizedStringWithFormat(
            NSLocalizedString("%d genre is selected", comment:""), selectedGenreIds.count) as String
    }
    
    
    func loadFavorites() {
        if progressHud == nil {
            progressHud = ViewUtils.showProgress(self, message: "")
        }
        isLoading = true
        Requests.getFavoriteGenres { (result, error) -> Void in
            
            if error != nil || result == nil {
                self.progressHud?.hide(true)
                self.progressHud = nil
                self.isLoading = false
                self.showError(error, callback: { () -> Void in
                    self.loadFavorites()
                })
                return
            }
            
            for (_, s): (String, JSON) in result!["data"] {
                self.selectedGenreIds.insert(String(s.intValue))
                self.remoteSelectedGenreIds.insert(String(s.intValue))
            }
            if self.selectedGenreIds.count > 0 {
                self.footerView.hidden = false
                self.footerViewHeightConstraint.constant = 0
                self.selectStatus.text = NSString.localizedStringWithFormat(
                    NSLocalizedString("%d genre is selected", comment:""),
                    self.selectedGenreIds.count) as String
            }
            self.loadGenre()
        }
    }
    
    func loadGenre() {
        
        let genreHandler = {(genreMap:[String:[Genre]]) -> Void in
            self.progressHud?.hide(true)
            let genres = genreMap["dropbeat"]
            if genres == nil {
                return
            }
            self.genres.removeAll(keepCapacity: false)
            for genre:Genre in genres! {
                if genre.key.characters.count > 0 {
                    self.genres.append(genre)
                }
            }
            self.tableView.reloadData()
            for (idx, genre): (Int, Genre) in self.genres.enumerate() {
                if self.selectedGenreIds.contains(genre.key) {
                    self.tableView.selectRowAtIndexPath(NSIndexPath(forRow: idx, inSection: 0),
                        animated: false, scrollPosition: UITableViewScrollPosition.None)
                }
            }
        }
        
        if let cachedGenreMap = GenreList.cachedResult {
            genreHandler(cachedGenreMap)
            return
        }
        
        
        if progressHud == nil {
            progressHud = ViewUtils.showProgress(self, message: "")
        }
        isLoading = true
        Requests.getFeedGenre { (result, error) -> Void in
            self.progressHud?.hide(true)
            self.isLoading = false
            
            if error != nil || result == nil {
                self.showError(error, callback: { ()-> Void in
                    self.loadGenre()
                })
                return
            }
            
            let parseResult = GenreList.parseGenre(result!)
            if !parseResult.success {
                self.showError(nil, callback: { ()-> Void in
                    self.loadGenre()
                })
                return
            }
            genreHandler(parseResult.results!)
        }
    }
    
    func showError(error:NSError?, callback: () -> Void) {
        var message:String!
        if (error != nil && error!.domain == NSURLErrorDomain &&
            error!.code == NSURLErrorNotConnectedToInternet) {
                message = NSLocalizedString("Internet is not connected", comment:"")
                return
        } else {
            message = NSLocalizedString("Failed to load genre", comment:"")
        }
        ViewUtils.showConfirmAlert(self,
            title: NSLocalizedString("Failed to load", comment:""),
            message: message,
            positiveBtnText: NSLocalizedString("Retry", comment: ""),
            positiveBtnCallback: { () -> Void in
                self.loadGenre()
            },
            negativeBtnText: self.fromStartup ?
                NSLocalizedString("Skip", comment:"") :
                NSLocalizedString("Cancel", comment:""),
            negativeBtnCallback: { () -> Void in
                if self.fromStartup {
                    self.performSegueWithIdentifier("unwindToStart", sender: nil)
                } else {
                    self.performSegueWithIdentifier("unwindFromEditFavoriteGenres", sender: nil)
                }
        })
    }
}


class GenreDiscoveryViewController: GAITrackedViewController, GenreSampleTableViewCellDelegate, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var footerBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var footerView: UIView!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var doneBtn: UIButton!
    
    private var currPlayer:AVPlayer?
    private var currItem:AVPlayerItem?
    private var samples:[GenreSample] = [GenreSample]()
    private var likedSampleIds:Set<Int> = Set<Int>()
    private var currPlayingSampleIdx:Int?
    private var isPlaying = false
    private var playerPreloadObserver:AnyObject?
    
    var remoteFavoriteIds:Set<String> = Set<String>()
    
    var fromStartup = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        doneBtn.layer.borderWidth = 1
        doneBtn.layer.borderColor = UIColor(netHex:0x8F2CEF).CGColor
        doneBtn.layer.cornerRadius = 3.0
        
        footerBottomConstraint.constant = -60.0
        footerView.hidden = true
        loadSamples()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.screenName = "GenreDiscoveryViewScreen"
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "appDidEnterBackground",
            name: UIApplicationDidEnterBackgroundNotification, object: nil)
        
//        let noti = NSNotification(name: NotifyKey.playerPause, object: nil)
//        NSNotificationCenter.defaultCenter().postNotification(noti)
        DropbeatPlayer.defaultPlayer.pause()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidEnterBackgroundNotification, object: nil)
        stopPlayer()
    }
    
    func appDidEnterBackground() {
        stopPlayer()
    }
    
    func stopPlayer() {
        if currPlayer != nil {
            currPlayer!.pause()
            if playerPreloadObserver != nil {
                currPlayer!.removeTimeObserver(playerPreloadObserver!)
            }
            playerPreloadObserver = nil
            currPlayer = nil
        }
    }
    
    @IBAction func onBackBtnClicked(sender: AnyObject) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func onDoneBtnClicked(sender: AnyObject) {
        
        var selectedGenreIds = Set<String>()
        for sample in samples {
            if likedSampleIds.contains(sample.id) {
                for id in sample.genreIds {
                    selectedGenreIds.insert(id)
                }
            }
        }
        if selectedGenreIds.count == 0 {
            ViewUtils.showToast(self, message: NSLocalizedString("Nothing selected!", comment:""))
            return
        }
        
        let idsToRemove = remoteFavoriteIds.subtract(selectedGenreIds)
        let idsToAdd = selectedGenreIds.subtract(remoteFavoriteIds)
        
        let progressHud = ViewUtils.showProgress(self, message: "")
        var doneRemove = false
        var doneAdd = false
        var firedError = false
        
        let handler = { (error:NSError?) -> Void in
            if error != nil {
                if firedError {
                    return
                }
                firedError = true
                progressHud.hide(true)
                
                if (error != nil && error!.domain == NSURLErrorDomain &&
                    error!.code == NSURLErrorNotConnectedToInternet) {
                        
                        ViewUtils.showConfirmAlert(self,
                            title: NSLocalizedString("Failed to save", comment:""),
                            message: NSLocalizedString("Internet is not connected", comment:""),
                            positiveBtnText: NSLocalizedString("Retry", comment: ""),
                            positiveBtnCallback: { () -> Void in
                                self.onDoneBtnClicked(sender)
                        })
                        return
                }
                
                ViewUtils.showNoticeAlert(self,
                    title: NSLocalizedString("Failed to save", comment:""),
                    message: NSLocalizedString("Failed to save genere", comment:""))
                return
            }
            if !doneAdd || !doneRemove {
                return
            }
            let account = Account.getCachedAccount()
            account!.favoriteGenreIds.removeAll(keepCapacity: false)
            for id in selectedGenreIds {
                account!.favoriteGenreIds.insert(id)
            }
            
            progressHud.mode = MBProgressHUDMode.CustomView
            progressHud.customView = UIImageView(image: UIImage(named:"37x-Checkmark"))
            progressHud.hide(true, afterDelay: 1)
            
            if idsToAdd.count > 0 || idsToRemove.count > 0 {
                let defaultDb:NSUserDefaults = NSUserDefaults.standardUserDefaults()
                defaultDb.setObject(
                    NSDate(timeIntervalSinceNow: 60 * 60 * 2),
                    forKey: UserDataKey.maxFavoriteCacheExpireDate)
            }
            
            let popTime = dispatch_time(DISPATCH_TIME_NOW, Int64(1.0 * Double(NSEC_PER_SEC)));
            dispatch_after(popTime, dispatch_get_main_queue(), {() -> Void in
                if self.fromStartup {
                    self.performSegueWithIdentifier("unwindToStart", sender: nil)
                } else {
                    self.performSegueWithIdentifier("unwindFromEditFavoriteGenres", sender: nil)
                }
            })
        }
        
        if idsToRemove.count > 0 {
            var genreIds = [String]()
            for key:String in idsToRemove {
                genreIds.append(key)
            }
            Requests.delFavoriteGenre(genreIds) { (result, error) -> Void in
                if error != nil {
                    handler(error!)
                    return
                }
                doneRemove = true
                handler(nil)
            }
        } else {
            doneRemove = true
            handler(nil)
        }
        
        
        if idsToAdd.count > 0 {
            var genreIds = [String]()
            for key:String in idsToAdd {
                genreIds.append(key)
            }
            Requests.addFavoriteGenre(genreIds) { (result, error) -> Void in
                if error != nil {
                    handler(error!)
                    return
                }
                
                doneAdd = true
                handler(nil)
            }
        } else {
            doneAdd = true
            handler(nil)
        }
        
    }
    func playDrop(url:NSURL) {
        stopPlayer()
        
        let sharedInstance:AVAudioSession = AVAudioSession.sharedInstance()
        do {
            try sharedInstance.setCategory(AVAudioSessionCategoryPlayback)
        } catch let audioSessionError as NSError {
            print("Audio session error \(audioSessionError) \(audioSessionError.userInfo)")
        }
        
        do {
            try sharedInstance.setActive(true)
        } catch _ {
        }
        currItem = AVPlayerItem(URL: url)
        
        currPlayer = AVPlayer(playerItem: currItem!)
        let player = currPlayer!
        playerPreloadObserver = currPlayer!.addBoundaryTimeObserverForTimes(
            [NSValue(CMTime: CMTimeMake(1, 3))],
            queue: nil,
            usingBlock: { () -> Void in
                self.receivePlaybackStarted()
                if self.playerPreloadObserver != nil {
                    player.removeTimeObserver(self.playerPreloadObserver!)
                    self.playerPreloadObserver = nil
                }
        })
        currPlayer!.play()
    }
    
    func onTrackFinished(noti:NSNotification) {
        NSNotificationCenter.defaultCenter().removeObserver(
            self, name: AVPlayerItemDidPlayToEndTimeNotification, object: currItem!)
        
        if currPlayingSampleIdx == nil {
            return
        }
        tableView.reloadData()
        currPlayingSampleIdx = nil
    }
    
    func onPlayBtnClicked(sender: GenreSampleTableViewCell) {
        let indexPath = tableView.indexPathForCell(sender)
        if indexPath == nil {
            return
        }
        let sample = samples[indexPath!.row]
        currPlayingSampleIdx = indexPath!.row
        isPlaying = false
        tableView.reloadData()
        playDrop(NSURL(string: sample.streamUrl)!)
    }
    
    func onLikeBtnClicked(sender: GenreSampleTableViewCell) {
        let indexPath = tableView.indexPathForCell(sender)
        if indexPath == nil {
            return
        }
        let sample = samples[indexPath!.row]
        if likedSampleIds.contains(sample.id) {
            likedSampleIds.remove(sample.id)
        } else {
            likedSampleIds.insert(sample.id)
        }
        if likedSampleIds.count > 0 && footerView.hidden {
            self.view.layoutIfNeeded()
            footerView.hidden = false
            footerBottomConstraint.constant = 0
            UIView.animateWithDuration(0.3, animations: { () -> Void in
                self.view.layoutIfNeeded()
                }, completion: { (finished:Bool) -> Void in
                    
            })
        } else if likedSampleIds.count == 0 {
            self.view.layoutIfNeeded()
            footerBottomConstraint.constant = -60.0
            UIView.animateWithDuration(0.3, animations: { () -> Void in
                self.view.layoutIfNeeded()
                }, completion: { (finished:Bool) -> Void in
                    self.footerView.hidden = true
            })
        }
        tableView.reloadData()
    }
    
    func onPauseBtnClicked(sender: GenreSampleTableViewCell) {
        currPlayer?.pause()
        isPlaying = false
        currPlayingSampleIdx = nil
        tableView.reloadData()
    }
    
    func receivePlaybackStarted() {
        isPlaying = true
        tableView.reloadData()
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell:GenreSampleTableViewCell = tableView.dequeueReusableCellWithIdentifier("GenreSampleTableViewCell",
            forIndexPath: indexPath) as! GenreSampleTableViewCell
        
        let sample = samples[indexPath.row]
        if let thumbUrl = sample.thumbnailUrl {
            cell.thumbnailView.sd_setImageWithURL(
                NSURL(string:thumbUrl),
                placeholderImage: UIImage(named:"default_cover_big"),
                completed: { (image:UIImage!, error:NSError!, type:SDImageCacheType, url:NSURL!) -> Void in
                    if error != nil {
                        cell.thumbnailView.image = UIImage(named:"default_cover_big")
                    }
            })
        } else {
            cell.thumbnailView.image = UIImage(named:"default_cover_big")
        }
        if currPlayingSampleIdx != nil && currPlayingSampleIdx == indexPath.row {
            if isPlaying {
                cell.loaderView.stopAnimating()
                cell.playBtn.hidden = true
                cell.pauseBtn.hidden = false
            } else {
                cell.loaderView.startAnimating()
                cell.playBtn.hidden = true
                cell.pauseBtn.hidden = true
            }
        } else {
            cell.loaderView.stopAnimating()
            cell.playBtn.hidden = false
            cell.pauseBtn.hidden = true
        }
        if likedSampleIds.contains(sample.id) {
            cell.likeBtn.setTitle("LIKED", forState: UIControlState.Normal)
            cell.likeBtn.setImage(UIImage(named:"ic_like"), forState: UIControlState.Normal)
            cell.likeBtn.backgroundColor = UIColor(netHex:0x8F2CEF)
        } else {
            cell.likeBtn.setTitle("LIKE ", forState: UIControlState.Normal)
            cell.likeBtn.setImage(UIImage(named:"ic_dislike"), forState: UIControlState.Normal)
            cell.likeBtn.backgroundColor = UIColor(netHex:0xC87EF4)
        }
        cell.delegate = self
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return samples.count
    }
    
    func loadSamples() {
        let progressHud = ViewUtils.showProgress(self, message: "")
        Requests.getGenreSamples { (result, error) -> Void in
            progressHud.hide(true)
            if error != nil || result == nil {
                ViewUtils.showConfirmAlert(self,
                    title: NSLocalizedString("Failed to load", comment:""),
                    message: NSLocalizedString("Failed to load genre samples", comment:""),
                    positiveBtnText: "Retry",
                    positiveBtnCallback: { () -> Void in
                        self.loadSamples()
                })
                return
            }
            
            let samples = GenreSample.parseGenreSamples(result!)
            self.samples.removeAll(keepCapacity: false)
            for sample in samples {
                self.samples.append(sample)
            }
            self.tableView.reloadData()
        }
    }
}


protocol GenreSampleTableViewCellDelegate {
    func onPlayBtnClicked(sender:GenreSampleTableViewCell)
    func onPauseBtnClicked(sender:GenreSampleTableViewCell)
    func onLikeBtnClicked(sender:GenreSampleTableViewCell)
}

class GenreSampleTableViewCell: UITableViewCell {
    
    @IBOutlet weak var loaderView: UIActivityIndicatorView!
    @IBOutlet weak var thumbnailView: UIImageView!
    @IBOutlet weak var likeBtn: UIButton!
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var pauseBtn: UIButton!
    var delegate:GenreSampleTableViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.likeBtn.tintColor = UIColor.whiteColor()
        self.likeBtn.layer.cornerRadius = 3.0
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    @IBAction func onPauseBtnClicked(sender: AnyObject) {
        delegate?.onPauseBtnClicked(self)
    }
    @IBAction func onPlayBtnClicked(sender: AnyObject) {
        delegate?.onPlayBtnClicked(self)
    }
    @IBAction func onLikeBtnClicked(sender: AnyObject) {
        delegate?.onLikeBtnClicked(self)
    }
}
