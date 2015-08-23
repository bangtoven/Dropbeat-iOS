import UIKit
import AVKit
import AVFoundation


//
//  FavoriteGenreTutorialViewController.swift
//  labs
//
//  Created by vulpes on 2015. 8. 20..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

class FavoriteGenreTutorialViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var discoverBtn: UIButton!
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var footerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var doneBtn: UIButton!
    @IBOutlet weak var selectStatus: UILabel!
    @IBOutlet weak var closeBtn: UIButton!
    
    private var genres:[Genre] = [Genre]()
    private var selectedGenreIds:Set<String> = Set<String>()
    private var remoteSelectedGenreIds:Set<String> = Set<String>()
    private var isLoading:Bool = false
    private var progressHud:MBProgressHUD?
    
    var fromStartup = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        footerView.hidden = true
        footerViewHeightConstraint.constant = -60.0
        
        discoverBtn.layer.borderWidth = 1
        discoverBtn.layer.borderColor = UIColor(netHex: 0x982EF4).CGColor
        discoverBtn.layer.cornerRadius = 3.0
        
        doneBtn.layer.borderWidth = 1
        doneBtn.layer.borderColor = UIColor(netHex: 0x982EF4).CGColor
        doneBtn.layer.cornerRadius = 3.0
        
        closeBtn.hidden = fromStartup
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.screenName = "FavoriteGenreTutorialViewScreen"
        loadFavorites()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "discover" {
            let vc = segue.destinationViewController as! GenreDiscoveryViewController
            for id in remoteSelectedGenreIds {
                vc.remoteFavoriteIds.insert(id)
            }
            vc.fromStartup = fromStartup
        }
    }
    
    @IBAction func onCloseBtnClicked(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func onDiscoverBtnClicked(sender: AnyObject) {
        
    }
    
    @IBAction func onDoneBtnClicked(sender: AnyObject) {
        if selectedGenreIds.count == 0 {
            return
        }
        onSaveGenreClicked()
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
            progressHud.customView = UIImageView(image: UIImage(named:"37x-Checkmark.png"))
            progressHud.hide(true, afterDelay: 1)
            let popTime = dispatch_time(DISPATCH_TIME_NOW, Int64(1.0 * Double(NSEC_PER_SEC)));
            
            dispatch_after(popTime, dispatch_get_main_queue(), {() -> Void in
                if self.fromStartup {
                    self.performSegueWithIdentifier("main", sender: nil)
                } else if self.navigationController != nil {
                    self.navigationController!.dismissViewControllerAnimated(true, completion: nil)
                } else {
                    self.dismissViewControllerAnimated(true, completion: nil)
                }
            })
            
        }
        
        if idsToRemove.count > 0 {
            var genreIds = [String]()
            for key:String in idsToRemove {
                genreIds.append(key)
            }
            Requests.delFavorite(genreIds, respCb: { (req:NSURLRequest, res:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
                if error != nil || result == nil ||
                        !(JSON(result!)["success"].bool ?? false) {
                    handler(error != nil ? error : NSError(domain: "addFavorite", code: 1, userInfo: nil))
                    return
                }
                doneRemove = true
                handler(nil)
            })
        } else {
            doneRemove = true
            handler(nil)
        }
        
        
        if idsToAdd.count > 0 {
            var genreIds = [String]()
            for key:String in idsToAdd {
                genreIds.append(key)
            }
            Requests.addFavorite(genreIds, respCb: { (req:NSURLRequest, res:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
                if error != nil || result == nil ||
                        !(JSON(result!)["success"].bool ?? false) {
                    handler(error != nil ? error : NSError(domain: "addFavorite", code: 1, userInfo: nil))
                    return
                }
                
                doneAdd = true
                handler(nil)
            })
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
        
        if tableView.respondsToSelector("layoutMargins") {
            tableView.layoutMargins = UIEdgeInsetsZero
        }
        
        if cell.respondsToSelector("layoutMargins") {
            cell.layoutMargins = UIEdgeInsetsZero
        }
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
            NSLocalizedString("%d genre selected", comment:""), selectedGenreIds.count) as String
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
            NSLocalizedString("%d genre selected", comment:""), selectedGenreIds.count) as String
    }
    
    
    func loadFavorites() {
        if progressHud == nil {
            progressHud = ViewUtils.showProgress(self, message: "")
        }
        isLoading = true
        Requests.getFavorites { (req:NSURLRequest, resp:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            
            if error != nil || result == nil {
                self.progressHud?.hide(true)
                self.progressHud = nil
                self.isLoading = false
                self.showError(error, callback: { () -> Void in
                    self.loadFavorites()
                })
                return
            }
            
            let json = JSON(result!)
            if !(json["success"].bool ?? false) || json["data"] == nil {
                self.progressHud?.hide(true)
                self.progressHud = nil
                self.isLoading = false
                self.showError(nil, callback: { () -> Void in
                    self.loadFavorites()
                })
                return
            }
            
            for (idx:String, s:JSON) in json["data"] {
                self.selectedGenreIds.insert(String(s.intValue))
                self.remoteSelectedGenreIds.insert(String(s.intValue))
            }
            if self.selectedGenreIds.count > 0 {
                self.footerView.hidden = false
                self.footerViewHeightConstraint.constant = 0
                self.selectStatus.text = NSString.localizedStringWithFormat(
                    NSLocalizedString("%d genre selected", comment:""),
                    self.selectedGenreIds.count) as String
            }
            self.loadGenre()
        }
    }
    
    func loadGenre() {
        
        let genreHandler = {(genreMap:[String:[Genre]]) -> Void in
            self.progressHud?.hide(true)
            let genres = genreMap["default"]
            if genres == nil {
                return
            }
            self.genres.removeAll(keepCapacity: false)
            for genre:Genre in genres! {
                if count(genre.key) > 0 {
                    self.genres.append(genre)
                }
            }
            self.tableView.reloadData()
            for (idx:Int, genre:Genre) in enumerate(self.genres) {
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
        Requests.getFeedGenre { (req:NSURLRequest, resp:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            self.progressHud?.hide(true)
            self.isLoading = false
            
            if error != nil || result == nil {
                var message:String!
                self.showError(error, callback: { ()-> Void in
                    self.loadGenre()
                })
                return
            }
            
            let parser = Parser()
            let parseResult = parser.parseGenre(result!)
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
                    self.performSegueWithIdentifier("main", sender: nil)
                } else {
                    self.dismissViewControllerAnimated(true, completion: nil)
                }
            })
    }
}



//
//  GenreDiscoveryViewController.swift
//  labs
//
//  Created by vulpes on 2015. 8. 22..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//


class GenreDiscoveryViewController: BaseViewController, GenreSampleTableViewCellDelegate, UITableViewDelegate, UITableViewDataSource {
    
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
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "sender", name:NotifyKey.playerStop , object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "receivePlaybackStarted:", name:"PlaybackStartedNotification", object: nil)
        
        let noti = NSNotification(name: NotifyKey.playerStop, object: nil)
        NSNotificationCenter.defaultCenter().postNotification(noti)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        if currPlayer != nil {
            currPlayer!.pause()
        }
        NSNotificationCenter.defaultCenter().removeObserver(self, name:NotifyKey.playerStop , object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name:"PlaybackStartedNotification", object: nil)
    }
    
    func sender() {}
    
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
            progressHud.customView = UIImageView(image: UIImage(named:"37x-Checkmark.png"))
            progressHud.hide(true, afterDelay: 1)
            let popTime = dispatch_time(DISPATCH_TIME_NOW, Int64(1.0 * Double(NSEC_PER_SEC)));
            
            dispatch_after(popTime, dispatch_get_main_queue(), {() -> Void in
                if self.fromStartup {
                    self.performSegueWithIdentifier("main", sender: nil)
                } else if self.navigationController != nil {
                    self.navigationController!.dismissViewControllerAnimated(true, completion: nil)
                } else {
                    self.dismissViewControllerAnimated(true, completion: nil)
                }
            })
        }
        
        if idsToRemove.count > 0 {
            var genreIds = [String]()
            for key:String in idsToRemove {
                genreIds.append(key)
            }
            Requests.delFavorite(genreIds, respCb: { (req:NSURLRequest, res:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
                if error != nil || result == nil ||
                        !(JSON(result!)["success"].bool ?? false) {
                    handler(error != nil ? error : NSError(domain: "addFavorite", code: 1, userInfo: nil))
                    return
                }
                doneRemove = true
                handler(nil)
            })
        } else {
            doneRemove = true
            handler(nil)
        }
        
        
        if idsToAdd.count > 0 {
            var genreIds = [String]()
            for key:String in idsToAdd {
                genreIds.append(key)
            }
            Requests.addFavorite(genreIds, respCb: { (req:NSURLRequest, res:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
                if error != nil || result == nil ||
                        !(JSON(result!)["success"].bool ?? false) {
                    handler(error != nil ? error : NSError(domain: "addFavorite", code: 1, userInfo: nil))
                    return
                }
                
                doneAdd = true
                handler(nil)
            })
        } else {
            doneAdd = true
            handler(nil)
        }
        
    }
    func playDrop(url:NSURL) {
        currPlayer?.pause()
        
        var sharedInstance:AVAudioSession = AVAudioSession.sharedInstance()
        var audioSessionError:NSError?
        if (!sharedInstance.setCategory(AVAudioSessionCategoryPlayback, error: &audioSessionError)) {
            println("Audio session error \(audioSessionError) \(audioSessionError?.userInfo)")
        }
        
        sharedInstance.setActive(true, error: nil)
        currItem = AVPlayerItem(URL: url)
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "onTrackFinished:", name: AVPlayerItemDidPlayToEndTimeNotification, object: currItem!)
        currPlayer = AVPlayer(playerItem: currItem!)
        let player = currPlayer!
        var ob: AnyObject!
        ob = currPlayer!.addBoundaryTimeObserverForTimes(
            [NSValue(CMTime: CMTimeMake(1, 3))],
            queue: nil,
            usingBlock: { () -> Void in
                    NSNotificationCenter.defaultCenter()
                        .postNotificationName("PlaybackStartedNotification", object: url)
                    player.removeTimeObserver(ob)
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
        sender.pauseBtn.hidden = true
        sender.playBtn.hidden = false
        isPlaying = false
    }
    
    func receivePlaybackStarted(noti:NSNotification) {
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
                placeholderImage: UIImage(named:"default_cover_big.png"),
                completed: { (image:UIImage!, error:NSError!, type:SDImageCacheType, url:NSURL!) -> Void in
                    if error != nil {
                        cell.thumbnailView.image = UIImage(named:"default_cover_big.png")
                    }
                })
        } else {
            cell.thumbnailView.image = UIImage(named:"default_cover_big.png")
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
            cell.likeBtn.setImage(UIImage(named:"ic_like.png"), forState: UIControlState.Normal)
            cell.likeBtn.backgroundColor = UIColor(netHex:0x8F2CEF)
        } else {
            cell.likeBtn.setTitle("LIKE", forState: UIControlState.Normal)
            cell.likeBtn.setImage(UIImage(named:"ic_dislike.png"), forState: UIControlState.Normal)
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
        Requests.getGenreSamples { (req:NSURLRequest, resp:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
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
            
            var samples:[GenreSample]? = Parser().parseGenreSamples(result)
            if samples == nil {
                ViewUtils.showNoticeAlert(self,
                    title: NSLocalizedString("Failed to load", comment:""),
                    message: NSLocalizedString("Failed to load genre samples", comment:""))
                return
            }
            self.samples.removeAll(keepCapacity: false)
            for sample in samples! {
                self.samples.append(sample)
            }
            self.tableView.reloadData()
        }
    }
}
