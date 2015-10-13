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
//    private var popupNextButton: UIBarButtonItem!
    
    @IBOutlet weak var likeProgIndicator: UIActivityIndicatorView!
    @IBOutlet weak var likeBtn: UIButton!
    @IBOutlet weak var shareBtn: UIButton!
    @IBOutlet weak var repeatBtn: UIButton!
    @IBOutlet weak var shuffleBtn: UIButton!
    
    private var isOpened: Bool {
        get {
            let state = main.popupPresentationState
            return (state == .Open || state == .Transitioning)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        popupPlayButton = UIBarButtonItem(image: UIImage(named: "popup_big_play"), style: .Plain, target: self, action: "playBtnClicked:")
        popupPauseButton = UIBarButtonItem(image: UIImage(named: "popup_big_pause"), style: .Plain, target: self, action: "pauseBtnClicked:")
//        popupNextButton = UIBarButtonItem(image: UIImage(named: "popup_next"), style: .Plain, target: self, action: "onNextBtnClicked:")
        
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        activityIndicator.startAnimating()
        activityIndicator.color = UIColor.dropbeatColor()
        activityIndicator.frame = CGRectMake(0, 0, 24, 24)
        popupLoadingView = UIBarButtonItem(customView: activityIndicator)
        
        self.popupItem.leftBarButtonItems = [popupLoadingView]
//        self.popupItem.rightBarButtonItems = [UIBarButtonItem(image: UIImage(named: "popup_palylist"), style: .Plain, target: self, action: "onPlaylistBtnClicked:")]
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
        updateProgressView(true)
        updateLikeBtn()
        updateRepeatView()
        updateShuffleView()
    }
    
    func trackChanged(noti: NSNotification) {
        if let title = self.player.currentTrack?.title {
            self.popupItem.title = title
        }
        
        if self.isOpened {
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
                    selector: "updateProgressView:",
                    userInfo: nil,
                    repeats: true)
                NSRunLoop.currentRunLoop().addTimer(timer!, forMode: NSRunLoopCommonModes)
            }

            if self.isOpened {
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
            self.popupItem.leftBarButtonItems = [firstItem]
            
//            popupNextButton.enabled = firstItem.enabled
//            self.popupItem.leftBarButtonItems = [firstItem, popupNextButton]
        }
    }
    
    // MARK: - Update UI
    
    func updateViewForCurrentTrack() {
        print("make time label to 00:00")
        progressSliderBar.value = 0
        progressTextView.text = getTimeFormatText(0)
        totalTextView.text = getTimeFormatText(0)

        if let track = self.player.currentTrack {
            playerTitle.text = track.title
            coverImageView.setImageForTrack(track, size: .LARGE)
            totalTextView.text = getTimeFormatText(self.duration)
        } else {
            coverImageView.image = UIImage(named: "default_cover_big")
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
    
    func updateProgressView(force: Bool = false) {
        let total = self.duration
        if (total != 0) {
            let curr = self.player.progress
            let progress = Float(curr / total)
            self.popupItem.progress = progress
            
            if self.isOpened || force == true {
                if false == progressSliderBar.highlighted {
                    progressTextView.text = getTimeFormatText(curr)
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
        var image: UIImage!
        if self.player.currentTrack?.isLiked == true {
            image = UIImage(named:"ic_player_heart_fill_btn")
        } else {
            image = UIImage(named:"ic_player_heart_btn")
        }
        likeBtn.setImage(image, forState: UIControlState.Normal)
    }
    
    func updateShuffleView() {
        var image: UIImage!
        switch self.player.shuffleState {
        case .NOT_SHUFFLE:
            image = UIImage(named: "ic_shuffle_gray")
        case .SHUFFLE:
            image = UIImage(named: "ic_shuffle")
        }
        shuffleBtn.setImage(image, forState: UIControlState.Normal)
    }
    
    func updateRepeatView() {
        var image: UIImage!
        switch(self.player.repeatState) {
        case .NOT_REPEAT:
            image = UIImage(named: "ic_repeat_gray")
        case .REPEAT_ONE:
            image = UIImage(named: "ic_repeat_one")
        case .REPEAT_PLAYLIST:
            image = UIImage(named: "ic_repeat")
        }
        repeatBtn.setImage(image, forState: UIControlState.Normal)
    }
    
    // MARK: - User Interactions
    
    func showToast(message: String) {
        let vc = self.isOpened ? self : main
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
        guard Account.getCachedAccount() != nil else {
            main.showAuthViewController()
            return
        }
        
        guard let playlist = self.player.currentPlaylist else {
            self.showToast(NSLocalizedString("Failed to find playlist", comment:""))
            return
        }
        
        main.performSegueWithIdentifier("PlaylistSegue", sender: playlist)
    }
    
    @IBAction func onAddToPlaylistBtnClicked(sender: UIButton) {
        guard Account.getCachedAccount() != nil else {
            main.showAuthViewController()
            return
        }
        
        guard let track = self.player.currentTrack else {
            self.showToast(NSLocalizedString("No track selected", comment:""))
            return
        }
        
        main.performSegueWithIdentifier("PlaylistSelectSegue", sender: track)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        print(segue.identifier)
    }
    
    @IBAction func onLikeBtnClicked(sender: AnyObject) {
        guard Account.getCachedAccount() != nil else {
            main.showAuthViewController()
            return
        }
        
        guard let track = self.player.currentTrack else {
            self.showToast(NSLocalizedString("No track selected", comment:""))
            return
        }
        
        likeBtn.hidden = true
        likeProgIndicator.startAnimating()
        let likeFunc = track.isLiked ? Like.unlikeTrack : Like.likeTrack
        likeFunc(track) { (error) -> Void in
            self.likeProgIndicator.stopAnimating()
            self.likeBtn.hidden = false
            
            if error != nil {
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
