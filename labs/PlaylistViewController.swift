//
//  PlaylistViewController.swift
//  labs
//
//  Created by vulpes on 2015. 5. 18..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit
import SwiftyJSON

class PlaylistViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, PlaylistSelectTableViewDelegate, PlaylistTableViewDelegate{

    @IBOutlet weak var playerStatus: UILabel!
    @IBOutlet weak var playerTitle: UILabel!
    @IBOutlet weak var progressBar: UISlider!
    @IBOutlet weak var totalTextView: UILabel!
    @IBOutlet weak var progressTextView: UILabel!
    @IBOutlet weak var createPlaylistBtn: UIButton!
    @IBOutlet weak var nextBtn: UIButton!
    @IBOutlet weak var prevBtn: UIButton!
    @IBOutlet weak var shuffleBtn: UIButton!
    @IBOutlet weak var repeatBtn: UIButton!
    @IBOutlet weak var loadingView: UIImageView!
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var pauseBtn: UIButton!
    @IBOutlet weak var playlistView: UITableView!
    @IBOutlet weak var playlistSelectView: UITableView!
    @IBOutlet weak var playlistNameView: UILabel!
    
    var prevShuffleBtnState:Int?
    var prevRepeatBtnState:Int?
    var isProgressUpdatable = true
    
    // Prevent outside configuration of currentPlaylist
    // currentPlaylist can only be updated with updateCurrentPlaylist() from outside
    static private var _currentPlaylist:Playlist?
    
    static var currentPlaylist:Playlist? {
        get {
            return _currentPlaylist
        }
    }
    
    static func updateCurrentPlaylist() {
        let playlists = PlayerContext.playlists
        if (PlaylistViewController.currentPlaylist != nil) {
            let lastPlaylistId = PlaylistViewController.currentPlaylist!.id
            PlaylistViewController._currentPlaylist = nil
            for playlist in playlists {
                if (playlist.id == lastPlaylistId) {
                    PlaylistViewController._currentPlaylist = playlist
                    break
                }
            }
        }
        if (PlaylistViewController.currentPlaylist == nil && playlists.count > 0) {
            PlaylistViewController._currentPlaylist = playlists[0]
        }
    }
    
    static func addTrack(track:Track, afterAdd: (needRefresh:Bool, error:NSError?) -> Void) {
        if (PlaylistViewController.currentPlaylist == nil) {
            afterAdd(needRefresh: true, error: NSError(domain: "addTrack", code:100, userInfo: nil))
            return
        }
        let currentPlaylist:Playlist = PlaylistViewController.currentPlaylist!
        var tracks = currentPlaylist.tracks
        
        var dummyTracks = [[String:AnyObject]]()
        for t in tracks {
            if (track.id == t.id) {
                afterAdd(needRefresh: false, error: NSError(domain: "addTrack", code:101, userInfo: nil))
                return
            }
            dummyTracks.append(["title": t.title, "id": t.id, "type": t.type])
        }
        dummyTracks.append(["title": track.title, "id": track.id, "type": track.type])
        
        Requests.setPlaylist(currentPlaylist.id, data: dummyTracks) {
                (request:NSURLRequest, response:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            
            if (error != nil) {
                afterAdd(needRefresh: true, error: error)
                return
            }
            var playlist:Playlist? = nil
            for p in PlayerContext.playlists {
                if (p.id == currentPlaylist.id) {
                    playlist = p
                    break
                }
            }
            if (playlist == nil) {
                afterAdd(needRefresh: false, error: nil)
                return
            }
            for t in playlist!.tracks {
                if (t.id == track.id) {
                    afterAdd(needRefresh: false, error: nil)
                    return
                }
            }
            playlist!.tracks.append(track)
            afterAdd(needRefresh: true, error: nil)
        }
    }
    
    static func deleteTrack(selectedTrack:Track, afterDelete:(needRefresh:Bool, error:NSError?) -> Void) {
        if (PlaylistViewController.currentPlaylist == nil) {
            afterDelete(needRefresh: true, error: NSError(domain: "deleteTrack", code:100, userInfo: nil))
            return
        }
        let currentPlaylist:Playlist = PlaylistViewController.currentPlaylist!
        var tracks = currentPlaylist.tracks
        
        var dummyTracks = [[String:AnyObject]]()
        for t in tracks {
            if (t.id != selectedTrack.id) {
                dummyTracks.append(["title": t.title, "id": t.id, "type": t.type])
            }
        }
        
        Requests.setPlaylist(currentPlaylist.id, data: dummyTracks) {
            (request:NSURLRequest, response:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            if (error != nil) {
                afterDelete(needRefresh: true, error: error)
                return
            }
            var playlist:Playlist? = nil
            for p in PlayerContext.playlists {
                if (p.id == currentPlaylist.id) {
                    playlist = p
                    break
                }
            }
            if (playlist == nil) {
                afterDelete(needRefresh: false, error: nil)
                return
            }
            var foundIdx:Int?
            for (idx, track) in enumerate(playlist!.tracks) {
                if (track.id == selectedTrack.id) {
                    foundIdx = idx
                }
            }
            if (foundIdx == nil) {
                afterDelete(needRefresh: false, error: nil)
                return
            }
            playlist!.tracks.removeAtIndex(foundIdx!)
            
            // Update current PlayerContext with new index
            let playingTrack:Track? = PlayerContext.currentTrack
            if (playingTrack != nil &&
                    PlayerContext.currentPlaylistId != nil &&
                    PlayerContext.currentPlaylistId == currentPlaylist.id) {
                for (idx, track) in enumerate(playlist!.tracks) {
                    if (track.id == playingTrack!.id) {
                        PlayerContext.currentTrackIdx = idx
                        break
                    }
                }
            }
            let needRefresh = PlaylistViewController.currentPlaylist == nil ||
                    currentPlaylist.id == PlaylistViewController.currentPlaylist!.id
            afterDelete(needRefresh: needRefresh, error: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createPlaylistBtn.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        if (PlayerContext.playlists.count == 0) {
            if (Account.getCachedAccount() != nil) {
                reloadPlaylist(true, callback:nil)
            } else {
                reloadInitialPlaylist(true, callback:nil)
            }
        } else {
            PlaylistViewController.updateCurrentPlaylist()
            playlistNameView.text = PlaylistViewController.currentPlaylist?.name
            playlistView.reloadData()
            playlistSelectView.reloadData()
            updatePlayTrack(PlayerContext.currentTrack, playlistId: PlayerContext.currentPlaylistId)
        }
        
        // Notify player actions to CenterViewController
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "sender", name: NotifyKey.playerPlay, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "sender", name: NotifyKey.playerPrev, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "sender", name: NotifyKey.playerPause, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "sender", name: NotifyKey.playerNext, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "sender", name: NotifyKey.playerSeek, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "updatePlayerViews", name: NotifyKey.updatePlaylistView, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "updatePlayTrack:", name: NotifyKey.updatePlay, object: nil)
               
        updatePlayerViews()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
        becomeFirstResponder()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.sharedApplication().endReceivingRemoteControlEvents()
        resignFirstResponder()
    }
    
    func sender() {}
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func updatePlayerViews() {
        updateRepeatView()
        updateShuffleView()
        updatePlayView()
        updateProgressView()
        updateStatusView()
    }
    
    func updateStatusView() {
        let defaultText = "CHOOSE TRACK"
        if (PlayerContext.playState == PlayState.LOADING) {
            playerStatus.text = "LOADING"
            playerTitle.text = PlayerContext.currentTrack?.title ?? defaultText
        } else if (PlayerContext.playState == PlayState.PAUSED) {
            playerStatus.text = "PAUSED"
            playerTitle.text = PlayerContext.currentTrack?.title ?? defaultText
        } else if (PlayerContext.playState == PlayState.PLAYING) {
            playerStatus.text = "PLAYING"
            playerTitle.text = PlayerContext.currentTrack?.title ?? defaultText
        } else if (PlayerContext.playState == PlayState.STOPPED) {
            playerStatus.text = "STOPPED"
            playerTitle.text = defaultText
        }
    }
    
    func updateRepeatView() {
        if (prevRepeatBtnState != nil &&
                prevRepeatBtnState == PlayerContext.repeatState) {
            return
        }
        prevRepeatBtnState = PlayerContext.repeatState
        switch(PlayerContext.repeatState) {
        case RepeatState.NOT_REPEAT:
            var image:UIImage = UIImage(named: "btn_repeat_disabled.png")!
            repeatBtn.setImage(image, forState: UIControlState.Normal)
            break
        case RepeatState.REPEAT_ONE:
            repeatBtn.setImage(UIImage(named: "btn_repeat_one.png"), forState: UIControlState.Normal)
            break
        case RepeatState.REPEAT_PLAYLIST:
            repeatBtn.setImage(UIImage(named: "btn_repeat_normal.png"), forState: UIControlState.Normal)
            break
        default:
            break
        }
    }
    
    func updatePlayView() {
        if (PlayerContext.playState == PlayState.LOADING) {
            playBtn.hidden = true
            pauseBtn.hidden = true
            loadingView.hidden = false
            loadingView.rotate360Degrees(duration: 0.7, completionDelegate: self)
        } else if (PlayerContext.playState == PlayState.PAUSED) {
            playBtn.hidden = false
            pauseBtn.hidden = true
            loadingView.hidden = true
        } else if (PlayerContext.playState == PlayState.PLAYING) {
            playBtn.hidden = true
            pauseBtn.hidden = false
            loadingView.hidden = true
        } else if (PlayerContext.playState == PlayState.STOPPED) {
            playBtn.hidden = false
            pauseBtn.hidden = true
            loadingView.hidden = true
        }
    }
    
    override func animationDidStop(anim: CAAnimation!, finished flag: Bool) {
        if (PlayerContext.playState == PlayState.LOADING) {
            loadingView.rotate360Degrees(duration: 1.0, completionDelegate: self)
        }
    }
    
    func updateProgressView() {
        if (!isProgressUpdatable) {
            return
        }
        var total:Float = Float(PlayerContext.correctDuration ?? 0)
        var curr:Float = Float(PlayerContext.currentPlaybackTime ?? 0)
        if (total == 0) {
            progressBar.value = 0
            progressBar.enabled = false
            progressTextView.text = getTimeFormatText(0)
            totalTextView.text = getTimeFormatText(0)
        } else {
            progressBar.value = (curr * 100) / total
            if (PlayerContext.playState == PlayState.PLAYING) {
                progressBar.enabled = true
            } else {
                progressBar.enabled = false
            }
            progressTextView.text = getTimeFormatText(PlayerContext.currentPlaybackTime ?? 0)
            totalTextView.text = getTimeFormatText(PlayerContext.correctDuration ?? 0)
        }
    }
    
    func getTimeFormatText(time:NSTimeInterval) -> String {
        let ti = Int(time)
        let seconds = ti % 60
        let minutes = ti / 60
        var text = minutes < 10 ? "0\(minutes):" : String(minutes)
        text += seconds < 10 ? "0\(seconds)" : String(seconds)
        return text
    }
    
    func updateShuffleView() {
        if (prevShuffleBtnState == PlayerContext.shuffleState) {
            return
        }
        prevShuffleBtnState = PlayerContext.shuffleState
        if (PlayerContext.shuffleState == ShuffleState.NOT_SHUFFLE) {
            shuffleBtn.setImage(UIImage(named: "btn_shuffle_disabled.png"), forState: UIControlState.Normal)
        } else {
            shuffleBtn.setImage(UIImage(named: "btn_shuffle_normal.png"), forState: UIControlState.Normal)
        }
    }
    
    func reloadPlaylist(forceRefresh:Bool, callback: ((error:NSError?) -> Void)?) {
        Requests.fetchAllPlaylists({ (request:NSURLRequest, response:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            if (error != nil || result == nil) {
                ViewUtils.showNoticeAlert(self, title: "Failed to fetch playlists", message: error!.description)
                callback?(error: error ?? NSError(domain: "releadPlaylist", code:100, userInfo: nil))
                return
            }
            let playlists = Parser().parsePlaylists(result!).reverse()
            if (playlists.count == 0) {
                ViewUtils.showNoticeAlert(self, title: "Failed to fetch playlists", message: "At least one playlist should exist")
                callback?(error: NSError(domain: "reloadPlaylist", code: 101, userInfo: nil))
                return
            }
            PlayerContext.playlists.removeAll(keepCapacity: false)
            for playlist in playlists {
                PlayerContext.playlists.append(playlist)
            }
            if (forceRefresh) {
                PlaylistViewController.updateCurrentPlaylist()
                self.playlistNameView.text = PlaylistViewController.currentPlaylist?.name
                self.playlistView.reloadData()
                self.playlistSelectView.reloadData()
                self.updatePlayTrack(PlayerContext.currentTrack, playlistId: PlayerContext.currentPlaylistId)
            }
            
            callback?(error: nil)
        })
    }
    
    func reloadInitialPlaylist(forceRefresh:Bool, callback: ((error:NSError?) -> Void)?) {
        Requests.fetchInitialPlaylist({ (request:NSURLRequest, response:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            if (error != nil || result == nil) {
                ViewUtils.showNoticeAlert(self, title: "Failed to fetch playlists", message: error!.description)
                callback?(error: error ?? NSError(domain: "releadPlaylist", code:100, userInfo: nil))
                return
            }
            
            let json = JSON(result!)
            let playlistJson = json["playlist"]
            var playlists = [Playlist]()
            playlists.append(Playlist.fromJson(playlistJson.rawValue))
            
            PlayerContext.playlists.removeAll(keepCapacity: false)
            for playlist in playlists {
                PlayerContext.playlists.append(playlist)
            }
            if (forceRefresh) {
                PlaylistViewController.updateCurrentPlaylist()
                self.playlistNameView.text = PlaylistViewController.currentPlaylist?.name
                self.playlistView.reloadData()
                self.playlistSelectView.reloadData()
                self.updatePlayTrack(PlayerContext.currentTrack, playlistId: PlayerContext.currentPlaylistId)
            }
            callback?(error: nil)
        })
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (tableView == playlistView) {
            return PlaylistViewController.currentPlaylist?.tracks.count ?? 0
        } else {
            return PlayerContext.playlists.count
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if (tableView == playlistView) {
            let track:Track = PlaylistViewController.currentPlaylist!.tracks[indexPath.row]
            var cell:PlaylistTableViewCell = tableView.dequeueReusableCellWithIdentifier(
                    "PlaylistTableViewCell", forIndexPath: indexPath) as! PlaylistTableViewCell
            if (Account.getCachedAccount() == nil) {
                cell.deleteBtn.hidden = true
            } else {
                cell.deleteBtn.hidden = false
            }
            if (PlayerContext.currentPlaylistId != nil &&
                    PlaylistViewController.currentPlaylist!.id == PlayerContext.currentPlaylistId &&
                    PlayerContext.currentTrack != nil &&
                    PlayerContext.currentTrack!.id == track.id) {
                    
            }
            cell.trackTitle.text = track.title
            cell.delegate = self
            return cell
        } else {
            let playlist = PlayerContext.playlists[indexPath.row]
            var cell:PlaylistSelectTableViewCell = tableView.dequeueReusableCellWithIdentifier(
                    "PlaylistSelectTableViewCell", forIndexPath: indexPath) as! PlaylistSelectTableViewCell
            cell.delegate = self
            cell.nameView.text = playlist.name
            if (Account.getCachedAccount() == nil) {
                cell.renameBtn.hidden = true
                cell.deleteBtn.hidden = true
            } else {
                cell.renameBtn.hidden = false
                cell.deleteBtn.hidden = false
            }
            return cell
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if (tableView == playlistView) {
            var selectedTrack: Track = PlaylistViewController.currentPlaylist!.tracks[indexPath.row] as Track
            // DO SOMETHING with selected track
            var params: Dictionary<String, AnyObject> = [
                "track": selectedTrack,
                "playlistId": PlaylistViewController.currentPlaylist!.id
            ]
            NSNotificationCenter.defaultCenter().postNotificationName(
                NotifyKey.playerPlay, object: params)
        } else {
            PlaylistViewController._currentPlaylist = PlayerContext.playlists[indexPath.row]
            playlistNameView.text = PlaylistViewController.currentPlaylist?.name
            playlistView.reloadData()
            updatePlayTrack(PlayerContext.currentTrack, playlistId: PlayerContext.currentPlaylistId)
            playlistSelectView.hidden = true
            playlistView.hidden = false
        }
    }
    
    func onDeleteBtnClicked(sender: PlaylistSelectTableViewCell, btn: UIButton) {
        let indexPath:NSIndexPath = playlistSelectView.indexPathForCell(sender)!
        if (Account.getCachedAccount() == nil) {
            return
        }
        
        
        let playlists = PlayerContext.playlists
        let removePlaylist = playlists[indexPath.row]
        
        ViewUtils.showConfirmAlert(
            self, title: "Are you sure?",
            message: "Are you sure you want do delete \'\(removePlaylist.name)' playlist with \(removePlaylist.tracks.count) songs?",
            positiveBtnText: "Delete", positiveBtnCallback: {
                let progressHud = ViewUtils.showProgress(self, message: "Deleting..")
                Requests.deletePlaylist(removePlaylist.id, respCb: {
                        (request:NSURLRequest, response: NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
                    if (error != nil || result == nil) {
                        progressHud.hide(true)
                        let errorMsg = error?.description ?? "undefined error"
                        ViewUtils.showNoticeAlert(self, title: "Failed to delete", message: errorMsg)
                        return
                    }
                    let res = result as! NSDictionary
                    var success:Bool = res.objectForKey("success") as! Bool? ?? false
                    if (!success) {
                        progressHud.hide(true)
                        let errorMsg = res.objectForKey("error") as? String ?? "undefined error"
                        ViewUtils.showNoticeAlert(self, title: "Failed to delete", message: errorMsg)
                        return
                    }
                    self.reloadPlaylist(true, callback: { (error:NSError?) -> Void in
                        progressHud.hide(true)
                    })
                })
            })
    }
    
    func onRenameBtnClicked(sender: PlaylistSelectTableViewCell, btn: UIButton) {
        let indexPath:NSIndexPath = playlistSelectView.indexPathForCell(sender)!
        if (Account.getCachedAccount() == nil) {
            return
        }
        let playlists = PlayerContext.playlists
        let targetPlaylist = playlists[indexPath.row]
        
        ViewUtils.showTextInputAlert(
            self, title: "Change playlist name", message: "Type new playlist name", placeholder: "Playlist 01",
            positiveBtnText: "Change",
            positiveBtnCallback: { (result) -> Void in
                if (count(result) == 0) {
                    return
                }
                let progressHud = ViewUtils.showProgress(self, message: "Changing..")
                Requests.changePlaylistName(
                    targetPlaylist.id, name: result, respCb: {
                        (request:NSURLRequest, response:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
                    if (error != nil) {
                        progressHud.hide(true)
                        ViewUtils.showNoticeAlert(self, title: "Failed to change", message: error!.description)
                        return
                    }
                    self.reloadPlaylist(true, callback: { (error:NSError?) -> Void in
                        progressHud.hide(true)
                    })
                })
            })
    }
    
    func onDeleteBtnClicked(sender: PlaylistTableViewCell) {
        let indexPath:NSIndexPath = playlistView.indexPathForCell(sender)!
        if (Account.getCachedAccount() == nil) {
            return
        }
        let currentPlaylist:Playlist = PlaylistViewController.currentPlaylist!
        var tracks = currentPlaylist.tracks
        let selectedTrack = tracks[indexPath.row]
        PlaylistViewController.deleteTrack(selectedTrack, afterDelete: { (needRefresh:Bool, error:NSError?) -> Void in
            if (error != nil) {
                ViewUtils.showNoticeAlert(self, title: "Failed to update playlist", message: error!.description)
                return
            }
            if (needRefresh) {
                self.playlistView.reloadData()
                self.updatePlayTrack(PlayerContext.currentTrack, playlistId: PlayerContext.currentPlaylistId)
            }
        })
    }
    
    @IBAction func progressBarChanged(sender: UISlider) {
        var total:Double = PlayerContext.correctDuration ?? 0
        if (total == 0) {
            return
        }
        let newPlaybackTime:Double = (Double(progressBar.value) * total) / 100
        progressTextView.text = getTimeFormatText(newPlaybackTime)
    }
    
    @IBAction func onProgressBarDown(sender: UISlider) {
        self.isProgressUpdatable = false
    }
    
    
    @IBAction func onProgressBarUpInside(sender: UISlider) {
        onProgressBarUp(sender)
    }
    
    @IBAction func onProgressBarUpOutside(sender: UISlider) {
        onProgressBarUp(sender)
    }
    
    func onProgressBarUp(sender: UISlider) {
        
        // update progress after 1 sec
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(1 * Double(NSEC_PER_SEC)))
        dispatch_after(time, dispatch_get_main_queue()) {
            self.isProgressUpdatable = true
        }
        
        var params: Dictionary<String, AnyObject> = [
            "value": sender.value,
        ]
        NSNotificationCenter.defaultCenter().postNotificationName(
            NotifyKey.playerSeek, object: params)
    }
    
    @IBAction func onCreatePlaylistBtnClicked(sender: UIButton) {
        if (Account.getCachedAccount() == nil) {
            let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            var signinVC = mainStoryboard.instantiateViewControllerWithIdentifier("SigninViewController") as! SigninViewController
            
            signinVC.modalTransitionStyle = UIModalTransitionStyle.CoverVertical
            presentViewController(signinVC, animated: true, completion: nil)
            return
        }
        ViewUtils.showTextInputAlert(
            self, title: "Create new playlist", message: "Type new playlist name", placeholder: "Playlist 01",
            positiveBtnText: "Create",
            positiveBtnCallback: { (result) -> Void in
                if (count(result) == 0) {
                    return
                }
                let progressHud = ViewUtils.showProgress(self, message: "Creating playlist..")
                Requests.createPlaylist(result, respCb: {
                        (request:NSURLRequest, response:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
                    if (error != nil) {
                        progressHud.hide(true)
                        ViewUtils.showNoticeAlert(self, title: "Failed to create playlist", message: error!.description)
                        return
                    }
                    self.reloadPlaylist(false, callback: { (error:NSError?) -> Void in
                        progressHud.hide(true)
                        if (error != nil) {
                            return
                        }
                        PlaylistViewController._currentPlaylist = nil
                        PlaylistViewController.updateCurrentPlaylist()
                        self.playlistView.reloadData()
                        self.playlistSelectView.reloadData()
                        self.updatePlayTrack(PlayerContext.currentTrack, playlistId: PlayerContext.currentPlaylistId)
                    })
                })
            })
    }
    
    func dismiss() {
        presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func onCloseBtnClicked(sender: UIButton) {
        if (!playlistSelectView.hidden) {
            playlistSelectView.hidden = true
            playlistView.hidden = false
            return
        }
        dismiss()
    }
    
    @IBAction func onPlaylistChangeBtnClicked(sender: UIButton) {
        if (playlistSelectView.hidden) {
            
            if (PlaylistViewController.currentPlaylist != nil) {
                for (idx, playlist) in enumerate(PlayerContext.playlists) {
                    if (playlist.id == PlaylistViewController.currentPlaylist!.id) {
                        playlistSelectView.selectRowAtIndexPath(
                            NSIndexPath(forRow: idx, inSection: 0), animated: false,
                            scrollPosition: UITableViewScrollPosition.None)
                        break
                    }
                }
            }
            playlistSelectView.hidden = false
            playlistView.hidden = true
        } else {
            playlistSelectView.hidden = true
            playlistView.hidden = false
        }
    }
    
    @IBAction func onPrevBtnClicked(sender: UIButton) {
        println("prev")
        NSNotificationCenter.defaultCenter().postNotificationName(
            NotifyKey.playerPrev, object: nil)
    }
    
    @IBAction func onNextBtnClicked(sender: UIButton) {
        println("next")
        NSNotificationCenter.defaultCenter().postNotificationName(
            NotifyKey.playerNext, object: nil)
    }
    
    @IBAction func onPlayBtnClicked(sender: UIButton) {
        if (PlayerContext.currentTrack != nil) {
            var params: Dictionary<String, AnyObject> = [
                "track": PlayerContext.currentTrack!,
                "playlistId": PlaylistViewController.currentPlaylist!.id
            ]
            
            NSNotificationCenter.defaultCenter().postNotificationName(
                NotifyKey.playerPlay, object: params)
        }
    }
    
    @IBAction func onPauseBtnClicked(sender: UIButton) {
        NSNotificationCenter.defaultCenter().postNotificationName(
            NotifyKey.playerPause, object: nil)
    }
    
    @IBAction func onShuffleBtnClicked(sender: UIButton) {
        PlayerContext.changeShuffleState()
        updateShuffleView()
        println(PlayerContext.shuffleState)
    }
    
    @IBAction func onRepeatBtnClicked(sender: UIButton) {
        PlayerContext.changeRepeatState()
        updateRepeatView()
        println(PlayerContext.repeatState)
    }
    
    func updatePlayTrack(noti: NSNotification) {
        var params = noti.object as! Dictionary<String, AnyObject>
        var track = params["track"] as! Track
        var playlistId:String? = params["playlistId"] as? String
        updatePlayTrack(track, playlistId: playlistId)
    }
    
    func updatePlayTrack(track:Track?, playlistId:String?) {
        var currentPlaylist = PlaylistViewController.currentPlaylist
        if (currentPlaylist == nil) {
            return
        }
        var indexPath = playlistView.indexPathForSelectedRow()
        if (indexPath != nil) {
            var tracks = currentPlaylist!.tracks
            var preSelectedTrack:Track = tracks[indexPath!.row]
            if (preSelectedTrack.id != track!.id ||
                (playlistId == nil && playlistId != currentPlaylist!.id)) {
                playlistView.deselectRowAtIndexPath(indexPath!, animated: false)
            }
        }
        
        if (playlistId == nil || playlistId != currentPlaylist!.id) {
            return
        }
        
        for (idx, t) in enumerate(currentPlaylist!.tracks) {
            if (t.id == track!.id) {
                playlistView.selectRowAtIndexPath(NSIndexPath(forRow: idx, inSection: 0),
                    animated: true, scrollPosition: UITableViewScrollPosition.None)
                break
            }
        }
    }
}
