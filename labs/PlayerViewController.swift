//
//  PlayerViewController.swift
//  labs
//
//  Created by 방정호 on 2015. 10. 9..
//  Copyright © 2015년 dropbeat. All rights reserved.
//

import UIKit

class PlayerViewController: GAITrackedViewController {

    private let player = DropbeatPlayer.defaultPlayer

    private var timer: NSTimer?
    private var duration: Double?

    @IBOutlet weak var hidePlayerButton: UIButton!
    
    @IBOutlet weak var playerTitleHeightConstaint: NSLayoutConstraint!
    
    @IBOutlet weak var coverView: UIView!
    @IBOutlet weak var coverImageView: UIImageView!

    @IBOutlet weak var playerTitle: MarqueeLabel!
    @IBOutlet weak var playerStatus: UILabel!
    
    @IBOutlet weak var progressSliderBar: UISlider!
    @IBOutlet weak var totalTextView: UILabel!
    @IBOutlet weak var progressTextView: UILabel!
    
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var pauseBtn: UIButton!
    @IBOutlet weak var loadingView: UIImageView!
    @IBOutlet weak var prevButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    
    @IBOutlet weak var likeProgIndicator: UIActivityIndicatorView!
    @IBOutlet weak var likeBtn: UIButton!
    @IBOutlet weak var shareBtn: UIButton!
    @IBOutlet weak var repeatBtn: UIButton!
    @IBOutlet weak var shuffleBtn: UIButton!
    

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "playerStateChanged:",
            name: DropbeatPlayerStateChangedNotification,
            object: nil)
        
        self.timer = NSTimer(
            timeInterval: 0.5,
            target: self,
            selector: "updateProgressView",
            userInfo: nil,
            repeats: true)
        NSRunLoop.currentRunLoop().addTimer(timer!, forMode: NSRunLoopCommonModes)
        
        self.duration = nil
        
        updatePlayView(self.player.state)
        updateCoverView()
        updateProgressView()
        updateLikeBtn()
        updateRepeatView()
        updateShuffleView()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self,
            name: DropbeatPlayerStateChangedNotification,
            object: nil)
        
        self.timer?.invalidate()
    }
    
    func playerStateChanged(noti: NSNotification) {
        if let state = STKAudioPlayerState(rawValue: noti.object as! UInt) {
            if state == .Error {
                let errMsg = NSLocalizedString("This track is not streamable", comment:"")
                ViewUtils.showToast(self, message: errMsg)
            }
            updatePlayView(state)
            updateCoverView()
        }
    }
    
    // MARK: - Update UI
    
    func updateCoverView() {
        if let track = self.player.currentTrack {
            coverImageView.setImageForTrack(track, size: .LARGE)
        } else {
            coverImageView.image = UIImage(named: "default_cover_big")
        }
    }
    
    func updatePlayView(state: STKAudioPlayerState) {
        
        if state != .Playing {
            self.duration = nil
        }
        
        playerTitle.text = self.player.currentTrack?.title
        
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
            playerStatus.text = NSLocalizedString("LOADING", comment:"")
            break
        case .Disposed:
            playerStatus.text = NSLocalizedString("CHOOSE TRACK", comment:"")
            break
        }
        
        switch state {
        case .Running, .Buffering:
            playBtn.hidden = true
            pauseBtn.hidden = true
            loadingView.hidden = false
            prevButton.enabled = false
            nextButton.enabled = false
            loadingView.setSpinEnabled(true, duration: 0.7)
        case .Paused, .Stopped:
            playBtn.hidden = false
            pauseBtn.hidden = true
            prevButton.enabled = true
            nextButton.enabled = true
            loadingView.hidden = true
        case .Playing:
            playBtn.hidden = true
            pauseBtn.hidden = false
            prevButton.enabled = true
            nextButton.enabled = true
            loadingView.hidden = true
        default:
            playerTitle.text = ""
            playBtn.hidden = false
            playBtn.enabled = false
            pauseBtn.hidden = true
            prevButton.enabled = false
            nextButton.enabled = false
            loadingView.hidden = true
        }
    }
    
    func updateProgressView() {
        if self.player.state == .Playing {
            progressSliderBar.enabled = true
            
            if false == progressSliderBar.highlighted {
                if self.duration == nil {
                    self.duration = self.player.duration
                }
                let total = self.duration!
                if (total == 0) {
                    progressSliderBar.enabled = false
                } else {
                    let curr = self.player.progress
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
    
    func updateLikeBtn() {
        if self.player.currentTrack?.isLiked == true {
            likeBtn.setImage(UIImage(named:"ic_player_heart_fill_btn"), forState: UIControlState.Normal)
        } else {
            likeBtn.setImage(UIImage(named:"ic_player_heart_btn"), forState: UIControlState.Normal)
        }
    }
    
    func updateShuffleView() {
        if (self.player.shuffleState == .NOT_SHUFFLE) {
            shuffleBtn.setImage(UIImage(named: "ic_shuffle_gray"), forState: UIControlState.Normal)
            prevButton.enabled = true
        } else {
            shuffleBtn.setImage(UIImage(named: "ic_shuffle"), forState: UIControlState.Normal)
            prevButton.enabled = false
        }
    }
    
    func updateRepeatView() {
        switch(self.player.repeatState) {
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
    
    // MARK: - User Interactions
    
    @IBAction func playBtnClicked(sender: UIButton?) {
        self.player.resume()
    }
    
    @IBAction func pauseBtnClicked(sender: UIButton?) {
        self.player.pause()
    }
    
    @IBAction func onNextBtnClicked(sender: UIButton) {
        if self.player.next() == false {
            let errMsg = NSLocalizedString("Last track of playlist.", comment:"")
            ViewUtils.showToast(self, message: errMsg)
        }
    }
    
    @IBAction func onPrevBtnClicked(sender: UIButton) {
        if self.player.prev() == false {
            let errMsg = NSLocalizedString("First track of playlist.", comment:"")
            ViewUtils.showToast(self, message: errMsg)
        }
    }
    
    @IBAction func onProgressValueChanged(sender: UISlider) {
        let curr = duration! * Double(sender.value / 100.0)
        progressTextView.text = getTimeFormatText(curr)
    }
    
    @IBAction func onProgressActionFinished(sender: UISlider) {
        self.player.seekTo(sender.value)
    }
    
    @IBAction func onRepeatBtnClicked(sender: UIButton) {
        self.player.changeRepeatState()
        updateRepeatView()
    }
    
    @IBAction func onShuffleBtnClicked(sender: UIButton) {
        self.player.changeShuffleState()
        updateShuffleView()
    }
    
    @IBAction func onPlaylistBtnClicked(sender: UIButton) {
        guard let playlist = self.player.currentPlaylist else {
            ViewUtils.showToast(self,
                message: NSLocalizedString("Failed to find playlist", comment:""))
            return
        }
        
        performSegueWithIdentifier("PlaylistSegue", sender: playlist)
    }
    
    @IBAction func onAddToPlaylistBtnClicked(sender: UIButton) {
        if (Account.getCachedAccount() == nil) {
            NeedAuthViewController.showNeedAuthViewController(self)
            return
        }
        let track = self.player.currentTrack
        performSegueWithIdentifier("PlaylistSelectSegue", sender: track)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "PlaylistSegue" {
            let playlistVC = segue.destinationViewController as! PlaylistViewController
            playlistVC.currentPlaylist = sender as! Playlist
            playlistVC.fromPlayer = true
        } else if segue.identifier == "PlaylistSelectSegue" {
            let playlistSelectVC = segue.destinationViewController as! PlaylistSelectViewController
            playlistSelectVC.targetTrack = sender as? Track
            playlistSelectVC.fromSection = "player"
            playlistSelectVC.caller = self
        }
    }
    
    @IBAction func onLikeBtnClicked(sender: AnyObject) {
        guard let track = self.player.currentTrack else {
            ViewUtils.showToast(self, message: NSLocalizedString("No track selected", comment:""))
            return
        }
        
        if (Account.getCachedAccount() == nil) {
            NeedAuthViewController.showNeedAuthViewController(self)
            return
        }
        
        likeBtn.hidden = true
        likeProgIndicator.startAnimating()
        let likeFunc = track.isLiked ? Like.unlikeTrack : Like.likeTrack
        likeFunc(track) { (error) -> Void in
            self.likeProgIndicator.stopAnimating()
            self.likeBtn.hidden = false
            
            if error == nil {
                if error!.domain == NeedAuthViewController.NeedAuthErrorDomain {
                    NeedAuthViewController.showNeedAuthViewController(self)
                }
                
                ViewUtils.showConfirmAlert(self,
                    title: NSLocalizedString("Failed to save", comment: ""),
                    message: NSLocalizedString("Failed to save like info.", comment: ""))
                return
            }
            self.updateLikeBtn()
        }
    }
    
    @IBAction func onTrackShareBtnClicked(sender: UIButton) {
        guard let track = self.player.currentTrack else {
            ViewUtils.showToast(self,
                message: NSLocalizedString("No track selected", comment:""))
            return
        }
        
        let progressHud = ViewUtils.showProgress(self,
            message: NSLocalizedString("Loading..", comment:""))
        track.shareTrack("player") { (error, sharedURL) -> Void in
            progressHud.hide(true)
            if error != nil {
                if (error!.domain == NSURLErrorDomain && error!.code == NSURLErrorNotConnectedToInternet) {
                    ViewUtils.showConfirmAlert(self,
                        title: NSLocalizedString("Failed to share", comment:""),
                        message: NSLocalizedString("Internet is not connected", comment:""))
                } else {
                    ViewUtils.showConfirmAlert(self,
                        title: NSLocalizedString("Failed to share", comment:""),
                        message: NSLocalizedString("Failed to share track", comment:""))
                }
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
            activityController.popoverPresentationController?.sourceView = self.shareBtn
            self.presentViewController(activityController, animated:true, completion: nil)
        }
    }
    
    // MARK: -
    
    override func viewDidLoad() {
        super.viewDidLoad()

        hidePlayerButton.layer.cornerRadius = 10.0
        progressSliderBar.setThumbImage(UIImage(named: "ic_slider-thumb"), forState: .Normal)
        
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
