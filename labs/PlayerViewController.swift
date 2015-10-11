//
//  PlayerViewController.swift
//  labs
//
//  Created by 방정호 on 2015. 10. 9..
//  Copyright © 2015년 dropbeat. All rights reserved.
//

import UIKit
import LNPopupController

class PlayerViewController: GAITrackedViewController {

    weak var main: MainTabBarController!
    private let player = DropbeatPlayer.defaultPlayer

    private var timer: NSTimer?
    private var duration: Double = 0.0
    
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
    
    private var popupPlayButton: UIBarButtonItem!
    private var popupPauseButton: UIBarButtonItem!
    private var popupLoadingView: UIBarButtonItem!
    private var popupNextButton: UIBarButtonItem!
    
    @IBOutlet weak var likeProgIndicator: UIActivityIndicatorView!
    @IBOutlet weak var likeBtn: UIButton!
    @IBOutlet weak var shareBtn: UIButton!
    @IBOutlet weak var repeatBtn: UIButton!
    @IBOutlet weak var shuffleBtn: UIButton!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        popupPlayButton = UIBarButtonItem(image: UIImage(named: "popup_play"), style: .Plain, target: self, action: "playBtnClicked:")
        popupPauseButton = UIBarButtonItem(image: UIImage(named: "popup_pause"), style: .Plain, target: self, action: "pauseBtnClicked:")
        popupNextButton = UIBarButtonItem(image: UIImage(named: "popup_next"), style: .Plain, target: self, action: "onNextBtnClicked:")
        
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        activityIndicator.startAnimating()
        activityIndicator.color = UIColor.dropbeatColor()
        activityIndicator.frame = CGRectMake(0, 0, 9, 10)
        popupLoadingView = UIBarButtonItem(customView: activityIndicator)
        
        self.popupItem.leftBarButtonItems = [popupLoadingView, popupNextButton]
        self.popupItem.rightBarButtonItems = [UIBarButtonItem(image: UIImage(named: "popup_playlist"), style: .Plain, target: self, action: "onPlaylistBtnClicked:")]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.progressSliderBar.setThumbImage(UIImage(named: "ic_slider-thumb"), forState: .Normal)
        
        if UIScreen.mainScreen().bounds.height == 480 {
            resizeViewUnder4inch()
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "trackChanged:",
            name: DropbeatPlayerTrackChangedNotification,
            object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "playerStateChanged:",
            name: DropbeatPlayerStateChangedNotification,
            object: nil)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        updateViewForState(self.player.state)
        updateViewForCurrentTrack()
        updateProgressView()
        updateLikeBtn()
        updateRepeatView()
        updateShuffleView()
    }
    
    func trackChanged(noti: NSNotification) {
        if let title = self.player.currentTrack?.title {
            self.popupItem.title = title
        }
        
        if .Open == main.popupPresentationState {
            updateViewForCurrentTrack()
        }
    }
    
    func playerStateChanged(noti: NSNotification) {
        if let newState = STKAudioPlayerState(rawValue: noti.object as! UInt) {
            self.duration = self.player.duration
            
            self.timer?.invalidate()
            self.timer = nil
            
            if newState == .Playing {
                self.timer = NSTimer(
                    timeInterval: 0.5,
                    target: self,
                    selector: "updateProgressView",
                    userInfo: nil,
                    repeats: true)
                NSRunLoop.currentRunLoop().addTimer(timer!, forMode: NSRunLoopCommonModes)
            }

            if .Open == main.popupPresentationState {
                updateViewForState(newState)
            }
            
            var firstItem: UIBarButtonItem!
            switch newState {
            case .Running, .Buffering:
                firstItem = self.popupLoadingView
            case .Paused:
                firstItem = self.popupPlayButton
            case .Playing:
                firstItem = self.popupPauseButton
            default:
                for item in self.popupItem.leftBarButtonItems! {
                    item.enabled = false
                }
                return
            }

            firstItem.enabled = (newState == .Paused) || (newState == .Playing)
            popupNextButton.enabled = firstItem.enabled
            
            self.popupItem.leftBarButtonItems = [firstItem, popupNextButton]
        }
    }
    
    // MARK: - Update UI
    
    func updateViewForCurrentTrack() {
        print("make time label to 00:00")
        progressSliderBar.value = 0
        progressTextView.text = getTimeFormatText(0)
        totalTextView.text = getTimeFormatText(0)

        if let track = self.player.currentTrack {
            self.playerTitle.text = track.title
            self.coverImageView.setImageForTrack(track, size: .LARGE)
        } else {
            self.coverImageView.image = UIImage(named: "default_cover_big")
        }
    }
    
    func updateViewForState(state: STKAudioPlayerState) {
        
        if state == .Error {
            let errMsg = NSLocalizedString("This track is not streamable", comment:"")
            ViewUtils.showToast(self, message: errMsg)
        }
        
        totalTextView.text = getTimeFormatText(self.duration)
        progressSliderBar.enabled = (state == .Playing)
        
        switch state {
        case .Ready:
            playerStatus.text = NSLocalizedString("CHOOSE TRACK", comment:"")
            break
        case .Running:
            playerStatus.text = NSLocalizedString("LOADING", comment:"")
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
        let total = self.duration
        if (total != 0) {
            let curr = self.player.progress
            let progress = Float(curr / total)
            self.popupItem.progress = progress
            
            if .Open == main.popupPresentationState {
                progressTextView.text = getTimeFormatText(curr)
                if false == progressSliderBar.highlighted {
                    progressSliderBar.value = progress
                }
            }
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
    
    func showToast(message: String) {
        let vc = (main.popupPresentationState == .Open) ? self : main
        ViewUtils.showToast(vc, message: message)
    }
    
    @IBAction func playBtnClicked(sender: UIView?) {
        self.player.resume()
    }
    
    @IBAction func pauseBtnClicked(sender: UIView?) {
        self.player.pause()
    }
    
    @IBAction func onNextBtnClicked(sender: UIView) {
        if self.player.next() == false {
            self.showToast(NSLocalizedString("Last track of playlist.", comment:""))
        }
    }
    
    @IBAction func onPrevBtnClicked(sender: UIView) {
        if self.player.prev() == false {
            self.showToast(NSLocalizedString("First track of playlist.", comment:""))
        }
    }
    
    @IBAction func onProgressValueChanged(sender: UISlider) {
        let curr = duration * Double(sender.value)
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
    
    @IBAction func onPlaylistBtnClicked(sender: UIView) {
        guard let playlist = self.player.currentPlaylist else {
            self.showToast(NSLocalizedString("Failed to find playlist", comment:""))
            return
        }
        
        if main.popupPresentationState == .Open {
            self.performSegueWithIdentifier("PlaylistSegue", sender: playlist)
        } else {
            main.performSegueWithIdentifier("PlaylistSegue", sender: playlist)
        }
        
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
            self.showToast(NSLocalizedString("No track selected", comment:""))
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
            self.showToast(NSLocalizedString("No track selected", comment:""))
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
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    @IBOutlet weak var coverView: UIView!
    @IBOutlet weak var playerTitleHeightConstaint: NSLayoutConstraint!
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
