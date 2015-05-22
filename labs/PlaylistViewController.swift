//
//  PlaylistViewController.swift
//  labs
//
//  Created by vulpes on 2015. 5. 18..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit
import SwiftyJSON

class PlaylistViewController: UIViewController, UITableViewDelegate, UITableViewDataSource{

    @IBOutlet weak var nextBtn: UIButton!
    @IBOutlet weak var prevBtn: UIButton!
    @IBOutlet weak var shuffleBtn: UIButton!
    @IBOutlet weak var repeatBtn: UIButton!
    @IBOutlet weak var loadingView: UILabel!
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var pauseBtn: UIButton!
    @IBOutlet weak var playlistView: UITableView!
    @IBOutlet weak var playlistSelectView: UITableView!
    
    var currentPlaylist:Playlist!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if (PlayerContext.playlists.count == 0) {
            if (Account.getCachedAccount() != nil) {
                loadPlaylist()
            } else {
                loadInitialPlaylist()
            }
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
            self, selector: "updatePlayView", name: NotifyKey.updatePlaylistView, object: nil)
               
        updatePlayerView()
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
    
    func updatePlayerView() {
        updateRepeatView()
        updateShuffleView()
        updatePlayView()
    }
    
    func updateRepeatView() {
        switch(PlayerContext.repeatState) {
        case RepeatState.NOT_REPEAT:
            repeatBtn.titleLabel?.text = "no repeat"
            break
        case RepeatState.REPEAT_ONE:
            repeatBtn.titleLabel?.text = "repeat one"
            break
        case RepeatState.REPEAT_PLAYLIST:
            repeatBtn.titleLabel?.text = "repeat"
            break
        default:
            break
        }
    }
    
    func updateShuffleView() {
        if (PlayerContext.shuffleState == ShuffleState.NOT_SHUFFLE) {
            shuffleBtn.titleLabel?.text = "no shuffle"
        } else {
            shuffleBtn.titleLabel?.text = "shuffle"
        }
    }
    
    func updatePlayView() {
        if (PlayerContext.playState == PlayState.LOADING) {
            playBtn.hidden = true
            pauseBtn.hidden = true
            loadingView.hidden = false
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
    
    func loadPlaylist() {
        Requests.fetchAllPlaylists({ (request:NSURLRequest, response:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            if (error != nil || result == nil) {
                ViewUtils.showNoticeAlert(self, title: "Failed to fetch playlists", message: error!.description)
                return
            }
            let playlists = Parser().parsePlaylists(result!).reverse()
            if (playlists.count == 0) {
                ViewUtils.showNoticeAlert(self, title: "Failed to fetch playlists", message: "At least one playlist should exist")
                return
            }
            PlayerContext.playlists.removeAll(keepCapacity: false)
            for playlist in playlists {
                PlayerContext.playlists.append(playlist)
            }
            self.currentPlaylist = playlists[0]
            self.playlistView.reloadData()
            self.playlistSelectView.reloadData()
        })
    }
    
    func loadInitialPlaylist() {
        Requests.fetchInitialPlaylist({ (request:NSURLRequest, response:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            if (error != nil || result == nil) {
                ViewUtils.showNoticeAlert(self, title: "Failed to fetch playlists", message: error!.description)
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
            self.currentPlaylist = playlists[0]
            self.playlistView.reloadData()
            self.playlistSelectView.reloadData()
        })
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (tableView == playlistView) {
            return currentPlaylist?.tracks.count ?? 0
        } else {
            return PlayerContext.playlists.count
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if (tableView == playlistView) {
            let track = currentPlaylist?.tracks[indexPath.row]
            var cell:PlaylistTableViewCell = tableView.dequeueReusableCellWithIdentifier(
                    "PlaylistTableViewCell", forIndexPath: indexPath) as! PlaylistTableViewCell
            cell.trackTitle.text = track?.title
            return cell
        } else {
            let playlist = PlayerContext.playlists[indexPath.row]
            var cell:PlaylistSelectTableViewCell = tableView.dequeueReusableCellWithIdentifier(
                    "PlaylistSelectTableViewCell", forIndexPath: indexPath) as! PlaylistSelectTableViewCell
            cell.nameView.text = playlist.name
            return cell
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if (tableView == playlistView) {
            var selectedTrack: Track = currentPlaylist!.tracks[indexPath.row] as Track
            // DO SOMETHING with selected track
            var params: Dictionary<String, AnyObject> = [
                "track": selectedTrack,
                "playlistId": currentPlaylist!.id
            ]
            NSNotificationCenter.defaultCenter().postNotificationName(
                NotifyKey.playerPlay, object: params)
        } else {
            currentPlaylist = PlayerContext.playlists[indexPath.row]
            playlistView.reloadData()
            playlistSelectView.hidden = true
            playlistView.hidden = false
        }
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
        var params: Dictionary<String, AnyObject> = [
            "track": PlayerContext.currentTrack!,
            "playlistId": currentPlaylist!.id
        ]
        
        NSNotificationCenter.defaultCenter().postNotificationName(
            NotifyKey.playerPlay, object: params)
    }
    
    @IBAction func onPauseBtnClicked(sender: UIButton) {
        NSNotificationCenter.defaultCenter().postNotificationName(
            NotifyKey.playerPause, object: nil)
    }
    
    @IBAction func onShuffleBtnClicked(sender: UIButton) {
        PlayerContext.changeShuffleState()
    }
    
    @IBAction func onRepeatBtnClicked(sender: UIButton) {
        PlayerContext.changeRepeatState()
    }
}
