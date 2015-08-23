//
//  GenreDiscoveryViewController.swift
//  labs
//
//  Created by vulpes on 2015. 8. 22..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

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
