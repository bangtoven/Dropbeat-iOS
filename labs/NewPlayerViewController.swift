//
//  PlayerViewController.swift
//  labs
//
//  Created by 방정호 on 2015. 10. 9..
//  Copyright © 2015년 dropbeat. All rights reserved.
//

import UIKit

class PlayerViewController: GAITrackedViewController {

    var timer: NSTimer?
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "playerStateChanged:", name: DropbeatPlayerStateChangedNotification, object: nil)
        
        timer = NSTimer(timeInterval: 0.5, target: self, selector: "updateProgressView", userInfo: nil, repeats: true)
        NSRunLoop.currentRunLoop().addTimer(timer!, forMode: NSRunLoopCommonModes)
        
        updatePlayView(DropbeatPlayer.defaultPlayer.state)
        updateProgressView()
        updateCoverView()
        updateNextPrevBtn()
        updateRepeatView()
        updateShuffleView()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: DropbeatPlayerStateChangedNotification, object: nil)
        self.timer?.invalidate()
    }
    
    func playerStateChanged(noti: NSNotification) {
        guard let state = STKAudioPlayerState(rawValue: noti.object as! UInt) else {
            assertionFailure()
            return
        }
        
        updatePlayView(state)
    }
    
    private var isProgressUpdatable = true
    func updateProgressView() {
        if DropbeatPlayer.defaultPlayer.state == .Playing {
            progressSliderBar.enabled = true
            
            if isProgressUpdatable {
                let total = DropbeatPlayer.defaultPlayer.duration
                if (total == 0) {
                    progressSliderBar.enabled = false
                } else {
                    let curr = DropbeatPlayer.defaultPlayer.progress
                    if (progressSliderBar.enabled) {
                        progressSliderBar.value = Float(curr / total * 100.0)
                    }

                    progressTextView.text = getTimeFormatText(curr)
                    totalTextView.text = getTimeFormatText(total)
                }
            }
        } else {
            progressSliderBar.enabled = false
        }
    }
    
    func getTimeFormatText(time:NSTimeInterval) -> String {
        let ti = Int(time)
        let seconds = ti % 60
        let minutes = ti / 60
        var text = minutes < 10 ? "0\(minutes):" : "\(String(minutes)):"
        text += seconds < 10 ? "0\(seconds)" : String(seconds)
        return text
    }
    
    func updatePlayView(state: STKAudioPlayerState) {
        playerTitle.text = DropbeatPlayer.defaultPlayer.currentTrack?.title
        
        switch state {
        case .Ready:
            playerStatus.text = NSLocalizedString("CHOOSE TRACK", comment:"")
            break
        case .Running:
            playerStatus.text = NSLocalizedString("LOADING", comment:"")
            
            print("make time label to 00:00")
            progressSliderBar.value = 0
            progressTextView.text = getTimeFormatText(0)
            totalTextView.text = getTimeFormatText(0)
            
            break
        case .Playing:
            playerStatus.text = NSLocalizedString("PLAYING", comment:"")
            break
        case .Buffering:
            playerStatus.text = NSLocalizedString("BUFFERING", comment:"")
            break
        case .Paused:
            playerStatus.text = NSLocalizedString("PAUSED", comment:"")
            break
        case .Stopped:
            playerStatus.text = NSLocalizedString("READY", comment:"")
            break
        case .Error:
            playerStatus.text = "???Error"
            break
        case .Disposed:
            playerStatus.text = "???Disposed"
            break
        }
        
        switch state {
        case .Running, .Buffering:
            playBtn.hidden = true
            pauseBtn.hidden = true
            loadingView.hidden = false
            loadingView.rotate360Degrees(0.7, completionDelegate: self)
        case .Paused, .Stopped:
            playBtn.hidden = false
            pauseBtn.hidden = true
            loadingView.hidden = true
        case .Playing:
            playBtn.hidden = true
            pauseBtn.hidden = false
            loadingView.hidden = true
        default:
            playerTitle.text = ""
            playBtn.hidden = false
            playBtn.enabled = false
            pauseBtn.hidden = true
            loadingView.hidden = true
        }
    }
    
    func updateNextPrevBtn() {
        if DropbeatPlayer.defaultPlayer.pickNextTrack() != nil {
            nextBtn.enabled = true
            nextBtn.setImage(UIImage(named:"ic_forward"), forState: UIControlState.Normal)
        } else {
            nextBtn.enabled = false
            nextBtn.setImage(UIImage(named:"ic_forward_gray"), forState: UIControlState.Normal)
        }
        
        if DropbeatPlayer.defaultPlayer.pickPrevTrack() != nil {
            prevBtn.enabled = true
            prevBtn.setImage(UIImage(named:"ic_rewind"), forState: UIControlState.Normal)
        } else {
            prevBtn.enabled = false
            prevBtn.setImage(UIImage(named:"ic_rewind_gray"), forState: UIControlState.Normal)
        }
    }
    
    func updateCoverView() {
        let track = DropbeatPlayer.defaultPlayer.currentTrack
        if track == nil || DropbeatPlayer.defaultPlayer.state == .Stopped {
            videoView.hidden = true
            coverImageView.hidden = false
            coverBgImageView.image = UIImage(named: "player_bg")
            coverImageView.image = UIImage(named: "default_cover_big")
        } else {
            videoView.hidden = true
            coverImageView.hidden = false
            coverBgImageView.image = UIImage(named: "player_bg")
            if track!.hasHqThumbnail {
                coverImageView.sd_setImageWithURL(NSURL(string: track!.thumbnailUrl!),
                    placeholderImage: UIImage(named: "default_cover_big"), completed: {
                        (image: UIImage!, error: NSError!, cacheType:SDImageCacheType, imageURL: NSURL!) -> Void in
                        if (error != nil) {
                            self.coverImageView.image = UIImage(named: "default_cover_big")
                        }
                })
            } else {
                coverImageView.image = UIImage(named: "default_cover_big")!
            }
        }
    }
    
    func updateShuffleView() {
        if (DropbeatPlayer.defaultPlayer.shuffleState == ShuffleState.NOT_SHUFFLE) {
            shuffleBtn.setImage(UIImage(named: "ic_shuffle_gray"), forState: UIControlState.Normal)
        } else {
            shuffleBtn.setImage(UIImage(named: "ic_shuffle"), forState: UIControlState.Normal)
        }
    }
    
    func updateRepeatView() {
        switch(DropbeatPlayer.defaultPlayer.repeatState) {
        case RepeatState.NOT_REPEAT:
            let image:UIImage = UIImage(named: "ic_repeat_gray")!
            repeatBtn.setImage(image, forState: UIControlState.Normal)
            break
        case RepeatState.REPEAT_ONE:
            repeatBtn.setImage(UIImage(named: "ic_repeat_one"), forState: UIControlState.Normal)
            break
        case RepeatState.REPEAT_PLAYLIST:
            repeatBtn.setImage(UIImage(named: "ic_repeat"), forState: UIControlState.Normal)
            break
        }
    }
    
    @IBAction func playBtnClicked(sender: UIButton?) {
        DropbeatPlayer.defaultPlayer.resume()
    }
    
    @IBAction func pauseBtnClicked(sender: UIButton?) {
        DropbeatPlayer.defaultPlayer.pause()
    }
    
    @IBAction func onNextBtnClicked(sender: UIButton) {
        DropbeatPlayer.defaultPlayer.next()
    }
    
    @IBAction func onPrevBtnClicked(sender: UIButton) {
        DropbeatPlayer.defaultPlayer.prev()
    }
    
    @IBAction func onRepeatBtnClicked(sender: UIButton) {
        DropbeatPlayer.defaultPlayer.changeRepeatState()
        updateNextPrevBtn()
        updateRepeatView()
    }
    
    @IBAction func onShuffleBtnClicked(sender: UIButton) {
        DropbeatPlayer.defaultPlayer.changeShuffleState()
        updateNextPrevBtn()
        updateShuffleView()
    }
    
    @IBAction func onAddToPlaylistBtnClicked(sender: UIButton) {
        if (Account.getCachedAccount() == nil) {
            NeedAuthViewController.showNeedAuthViewController(self)
            return
        }
        let track = DropbeatPlayer.defaultPlayer.currentTrack
        performSegueWithIdentifier("PlaylistSelectSegue", sender: track)
    }
    
    @IBAction func onTrackShareBtnClicked(sender: UIButton) {
        guard let track = DropbeatPlayer.defaultPlayer.currentTrack else {
            ViewUtils.showToast(self, message: NSLocalizedString("No track selected", comment:""))
            return
        }
        onTrackShareBtnClicked(track)
    }
    
    func onTrackShareBtnClicked(track:Track) {
        let progressHud = ViewUtils.showProgress(self, message: NSLocalizedString("Loading..", comment:""))
        track.shareTrack("player") { (error, sharedURL) -> Void in
            progressHud.hide(true)
            if error != nil {
                if (error!.domain == NSURLErrorDomain &&
                    error!.code == NSURLErrorNotConnectedToInternet) {
                        ViewUtils.showConfirmAlert(self, title: NSLocalizedString("Failed to share", comment:""),
                            message: NSLocalizedString("Internet is not connected", comment:""),
                            positiveBtnText: NSLocalizedString("Retry", comment:""), positiveBtnCallback: { () -> Void in
                                self.onTrackShareBtnClicked(track)
                            }, negativeBtnText: NSLocalizedString("Cancel", comment:""), negativeBtnCallback: nil)
                        return
                }
                ViewUtils.showConfirmAlert(self, title: NSLocalizedString("Failed to share", comment:""),
                    message: NSLocalizedString("Failed to share track", comment:""),
                    positiveBtnText: NSLocalizedString("Retry", comment:""), positiveBtnCallback: { () -> Void in
                        self.onTrackShareBtnClicked(track)
                    }, negativeBtnText: NSLocalizedString("Cancel", comment:""), negativeBtnCallback: nil)
                return
            }
            
            let items:[AnyObject] = [track.title, sharedURL!]
            
            let activityController = UIActivityViewController(
                activityItems: items, applicationActivities: nil)
            activityController.excludedActivityTypes = [
                UIActivityTypePrint,
                UIActivityTypeSaveToCameraRoll,
                UIActivityTypeAirDrop,
                UIActivityTypeAssignToContact
            ]
            if #available(iOS 8.0, *) {
                activityController.popoverPresentationController?.sourceView = self.shareBtn
            }
            self.presentViewController(activityController, animated:true, completion: nil)
        }
    }
    
    @IBAction func onPlaylistBtnClicked(sender: UIButton) {
        var playlist:Playlist?
        if DropbeatPlayer.defaultPlayer.currentPlaylistId != nil {
            playlist = DropbeatPlayer.defaultPlayer.getPlaylist(DropbeatPlayer.defaultPlayer.currentPlaylistId)
        }
        if playlist == nil {
            ViewUtils.showToast(self,
                message: NSLocalizedString("Failed to find playlist", comment:""))
            return
        }
        performSegueWithIdentifier("PlaylistSegue", sender: playlist)
    }
    
    @IBAction func onProgressValueChanged(sender: UISlider) {
        DropbeatPlayer.defaultPlayer.seekTo(sender.value)
    }
    
    @IBAction func onProgressDown(sender: UISlider) {
        self.isProgressUpdatable = false
    }
    
    @IBAction func onProgressUpInside(sender: UISlider) {
        self.isProgressUpdatable = true
    }
    
    @IBAction func onProgressUpOutside(sender: UISlider) {
        self.isProgressUpdatable = true
    }
    
    @IBAction func onLikeBtnClicked(sender: AnyObject) {
        if !likeProgIndicator.hidden {
            return
        }
        if DropbeatPlayer.defaultPlayer.currentTrack == nil {
            ViewUtils.showToast(self, message: NSLocalizedString("No track selected", comment:""))
            return
        }
        if (Account.getCachedAccount() == nil) {
            NeedAuthViewController.showNeedAuthViewController(self)
            return
        }
        if DropbeatPlayer.defaultPlayer.currentTrack!.isLiked {
            doUnlike(DropbeatPlayer.defaultPlayer.currentTrack!)
        } else {
            doLike(DropbeatPlayer.defaultPlayer.currentTrack!)
        }
    }
    
    func doLike(track:Track) {
        likeBtn.hidden = true
        likeProgIndicator.startAnimating()
        Like.likeTrack(track) { (error) -> Void in
            self.likeProgIndicator.stopAnimating()
            self.likeBtn.hidden = false
            if error != nil {
                if error!.domain == NeedAuthViewController.NeedAuthErrorDomain {
                    NeedAuthViewController.showNeedAuthViewController(self)
                }
                
                ViewUtils.showConfirmAlert(self,
                    title: NSLocalizedString("Failed to save", comment: ""),
                    message: NSLocalizedString("Failed to save like info.", comment: ""),
                    positiveBtnText: NSLocalizedString("Retry", comment:""),
                    positiveBtnCallback: { () -> Void in
                        self.doLike(track)
                })
                return
            }
        }
    }
    
    func doUnlike(track:Track) {
        if !likeProgIndicator.hidden {
            return
        }
        
        likeBtn.hidden = true
        likeProgIndicator.startAnimating()
        Like.unlikeTrack(track) { (error) -> Void in
            self.likeProgIndicator.stopAnimating()
            self.likeBtn.hidden = false
            if error != nil {
                ViewUtils.showConfirmAlert(self,
                    title: NSLocalizedString("Failed to save", comment: ""),
                    message: NSLocalizedString("Failed to save unlike info.", comment: ""),
                    positiveBtnText: NSLocalizedString("Retry", comment:""),
                    positiveBtnCallback: { () -> Void in
                        self.doLike(track)
                })
                return
            }
        }
    }
    
    @IBOutlet weak var hidePlayerButton: UIButton!
    
    @IBOutlet weak var playerTitleHeightConstaint: NSLayoutConstraint!
    
    @IBOutlet weak var coverView: UIView!
    @IBOutlet weak var loadingView: UIImageView!
    @IBOutlet weak var progressSliderBar: UISlider!
    
    @IBOutlet weak var playerTitle: MarqueeLabel!
    @IBOutlet weak var playerStatus: UILabel!
    
    @IBOutlet weak var likeProgIndicator: UIActivityIndicatorView!
    @IBOutlet weak var likeBtn: UIButton!
    @IBOutlet weak var shareBtn: UIButton!
    @IBOutlet weak var repeatBtn: UIButton!
    @IBOutlet weak var shuffleBtn: UIButton!
    @IBOutlet weak var totalTextView: UILabel!
    @IBOutlet weak var progressTextView: UILabel!
    @IBOutlet weak var nextBtn: UIButton!
    @IBOutlet weak var prevBtn: UIButton!
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var pauseBtn: UIButton!
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var coverBgImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        hidePlayerButton.layer.cornerRadius = 10.0
        
        if UIScreen.mainScreen().bounds.height == 480 {
            resizeViewUnder4inch()
        }
    }
    
    func resizeViewUnder4inch() {
        playerTitleHeightConstaint.constant = 28
        let heightConstraint = NSLayoutConstraint(item: coverView,
            attribute: NSLayoutAttribute.Height,
            relatedBy: NSLayoutRelation.Equal,
            toItem: nil,
            attribute: NSLayoutAttribute.NotAnAttribute,
            multiplier: 1.0,
            constant: 200)
        coverView.addConstraint(heightConstraint)
    }

    @IBAction func closeButtonAction(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
