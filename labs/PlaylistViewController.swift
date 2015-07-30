//
//  PlaylistViewController.swift
//  labs
//
//  Created by vulpes on 2015. 5. 18..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

class PlaylistViewController: BaseViewController,
        UITableViewDelegate, UITableViewDataSource, PlaylistTableViewDelegate, UIActionSheetDelegate{

    
    @IBOutlet weak var editBtn: UIBarButtonItem!
    @IBOutlet weak var playlistTableView: UITableView!
    @IBOutlet weak var playlistTrackCountView: UILabel!
    @IBOutlet weak var playlistNameView: UILabel!
    
    var currentPlaylist:Playlist?
    var tracks:[Track] = [Track]()
    var playlistActionSheet:UIActionSheet?
    var menuSelectedTrack:Track?
    var fromPlayer:Bool = false
    
    static func addTrack(playlist: Playlist, track:Track, section:String, afterAdd: (error:NSError?) -> Void) {
        var tracks = playlist.tracks
        
        var dummyTracks = [[String:AnyObject]]()
        for t in tracks {
            if (track.id == t.id) {
                afterAdd(error: NSError(domain: "addTrack", code:101, userInfo: nil))
                return
            }
            dummyTracks.append(["title": t.title, "id": t.id, "type": t.type])
        }
        dummyTracks.append(["title": track.title, "id": track.id, "type": track.type])
        
        // Log to us
        Requests.logTrackAdd(track.title)
        // Log to GA
        let tracker = GAI.sharedInstance().defaultTracker
        let event = GAIDictionaryBuilder.createEventWithCategory(
                "playlist-add-from-\(section)",
                action: "add-\(track.type)",
                label: track.title,
                value: nil
            ).build()
        
        tracker.send(event as [NSObject: AnyObject]!)
        
        Requests.setPlaylist(playlist.id, data: dummyTracks) {
                (request:NSURLRequest, response:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            
            if (error != nil) {
                afterAdd(error: error)
                return
            }
            var changedPlaylist:Playlist? = nil
            for p in PlayerContext.playlists {
                if (p.id == playlist.id) {
                    changedPlaylist = p
                    break
                }
            }
            if (changedPlaylist == nil) {
                afterAdd(error: nil)
                return
            }
            for t in changedPlaylist!.tracks {
                if (t.id == track.id) {
                    afterAdd(error: nil)
                    return
                }
            }
            changedPlaylist!.tracks.append(track)
            afterAdd(error: nil)
        }
    }
    
    static func deleteTrack(selectedPlaylist:Playlist, selectedTrack:Track, afterDelete:(error:NSError?) -> Void) {
        var tracks = selectedPlaylist.tracks
        
        var dummyTracks = [[String:AnyObject]]()
        for t in tracks {
            if (t.id != selectedTrack.id) {
                dummyTracks.append(["title": t.title, "id": t.id, "type": t.type])
            }
        }
        
        Requests.setPlaylist(selectedPlaylist.id, data: dummyTracks) {
            (request:NSURLRequest, response:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            if (error != nil) {
                afterDelete(error: error)
                return
            }
            var playlist:Playlist? = nil
            for p in PlayerContext.playlists {
                if (p.id == selectedPlaylist.id) {
                    playlist = p
                    break
                }
            }
            if (playlist == nil) {
                afterDelete(error: nil)
                return
            }
            var foundIdx:Int?
            for (idx, track) in enumerate(playlist!.tracks) {
                if (track.id == selectedTrack.id) {
                    foundIdx = idx
                }
            }
            if (foundIdx == nil) {
                afterDelete(error: nil)
                return
            }
            playlist!.tracks.removeAtIndex(foundIdx!)
            
            // Update current PlayerContext with new index
            let playingTrack:Track? = PlayerContext.currentTrack
            if (playingTrack != nil &&
                    PlayerContext.currentPlaylistId != nil &&
                    PlayerContext.currentPlaylistId == selectedPlaylist.id) {
                for (idx, track) in enumerate(playlist!.tracks) {
                    if (track.id == playingTrack!.id) {
                        PlayerContext.currentTrackIdx = idx
                        break
                    }
                }
            }
            afterDelete(error: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.screenName = "PlaylistViewScreen"
        
        updatePlaylistInfo()
        if currentPlaylist != nil {
            tracks.removeAll(keepCapacity: false)
            for track in currentPlaylist!.tracks {
                tracks.append(track)
            }
            playlistTableView.reloadData()
        }
        
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "sender", name: NotifyKey.playerStop, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "sender", name: NotifyKey.playerPlay, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "sender", name: NotifyKey.updateShuffleState, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "updatePlayTrack:", name: NotifyKey.updatePlay, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "appWillEnterForeground",
            name: UIApplicationWillEnterForegroundNotification, object: nil)
        
        loadPlaylist()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotifyKey.playerStop, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotifyKey.playerPlay, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotifyKey.updateShuffleState, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotifyKey.updatePlay, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationWillEnterForegroundNotification, object: nil)
    }
    
    func updatePlaylistInfo() {
        playlistNameView.text = currentPlaylist!.name
        switch(currentPlaylist!.tracks.count) {
        case 0:
            playlistTrackCountView.text = "Empty playlist"
            break
        case 1:
            playlistTrackCountView.text = "1 track"
            break
        default:
            playlistTrackCountView.text = "\(currentPlaylist!.tracks.count) tracks"
            break
        }
    }
    
    func appWillEnterForeground () {
        loadPlaylist()
    }
    
    func sender() {}
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentPlaylist!.tracks.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let track:Track = tracks[indexPath.row]
        var cell:PlaylistTableViewCell = tableView.dequeueReusableCellWithIdentifier(
                "PlaylistTableViewCell", forIndexPath: indexPath) as! PlaylistTableViewCell
        if (currentPlaylist!.id == PlayerContext.currentPlaylistId &&
                PlayerContext.currentTrack != nil &&
                PlayerContext.currentTrack!.id == track.id) {
            cell.setSelected(true, animated: false)
        }
        cell.trackTitle.text = track.title
        cell.delegate = self
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var selectedTrack: Track = tracks[indexPath.row] as Track
        onPlayTrackBtnClicked(selectedTrack)
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
    
    func loadPlaylist() {
        let currPlaylist = currentPlaylist!
        var foundPlaylistIdx:Int = -1
        for (idx:Int, playlist:Playlist) in enumerate(PlayerContext.playlists) {
            if (currPlaylist.id == playlist.id) {
                foundPlaylistIdx = idx
                break
            }
        }
        if (foundPlaylistIdx == -1) {
            ViewUtils.showToast(self, message: "Failed to find current playlist")
            return
        }
        let progressHud = ViewUtils.showProgress(self, message: "Loading playlist..")
        fetchPlaylist(foundPlaylistIdx, callback: {(success:Bool, newIdx:Int, error:NSError?) -> Void in
            progressHud.hide(false)
            if (!success) {
                var message:String?
                if (error != nil && error!.domain == NSURLErrorDomain &&
                        error!.code == NSURLErrorNotConnectedToInternet) {
                    message = "Internet is not connected. Please try again."
                } else {
                    message = "Failed to fetch playlist"
                }
                ViewUtils.showNoticeAlert(self, title: "Failed to fetch", message: message!, btnText: "Retry", callback: { () -> Void in
                    self.loadPlaylist()
                })
                return
            }
            
            if (newIdx == -1) {
                ViewUtils.showToast(self, message: "Failed to find current playlist")
                return
            }
            
            self.updatePlaylistInfo()
            self.playlistTableView.reloadData()
            self.updatePlayTrack(PlayerContext.currentTrack, playlistId: PlayerContext.currentPlaylistId)
        })
    }
    
    func fetchPlaylist(idx:Int, callback:(success:Bool, newIdx:Int, error:NSError?) -> Void) {
        var nextPlaylist = PlayerContext.playlists[idx]
        Requests.getPlaylist(nextPlaylist.id, respCb: { (request:NSURLRequest, response:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            if (error != nil || result == nil) {
                callback(success: false, newIdx: -1, error: error)
                return
            }
            var foundPlaylistIdx = -1
            for (idx:Int, playlist:Playlist) in enumerate(PlayerContext.playlists) {
                if (nextPlaylist.id == playlist.id) {
                    foundPlaylistIdx = idx
                    break
                }
            }
            
            if (foundPlaylistIdx == -1) {
                callback(success: false, newIdx: -1, error: nil)
                return
            }
           
            var res = JSON(result!)
            if !res["success"].boolValue {
                callback(success: false, newIdx: -1, error: nil)
                return
            }
            var playlist:Playlist? = Playlist.fromJson(res["playlist"].rawValue)
            if (playlist == nil) {
                callback(success: false, newIdx: -1, error: nil)
                return
            }
            
            var original = PlayerContext.playlists[foundPlaylistIdx]
            original.name = playlist!.name
            original.tracks.removeAll(keepCapacity: false)
            self.tracks.removeAll(keepCapacity: false)
            for track:Track in playlist!.tracks {
                original.tracks.append(track)
                self.tracks.append(track)
            }
            callback(success: true, newIdx: foundPlaylistIdx, error: nil)
        })
    }
    
    @IBAction func onPlayPlaylistBtnClicked(sender: AnyObject) {
        if tracks.count == 0 {
            ViewUtils.showToast(self, message: "Playlist empty")
            return
        }
        
        var selectedTrack: Track = tracks[0] as Track
        
        PlayerContext.shuffleState = ShuffleState.NOT_SHUFFLE
        
        var params: Dictionary<String, AnyObject> = [
            "track": selectedTrack,
            "playlistId": currentPlaylist!.id
        ]
        
        NSNotificationCenter.defaultCenter().postNotificationName(
            NotifyKey.playerPlay, object: params)
        NSNotificationCenter.defaultCenter().postNotificationName(
            NotifyKey.updateShuffleState, object: nil)
    }
    
    @IBAction func onPlaylistMenuBtnClicked(sender: AnyObject) {
        playlistActionSheet = UIActionSheet()
        playlistActionSheet!.addButtonWithTitle("Shuffle Play")
        playlistActionSheet!.addButtonWithTitle("Share")
        playlistActionSheet!.addButtonWithTitle("Rename")
        playlistActionSheet!.addButtonWithTitle("Delete")
        playlistActionSheet!.addButtonWithTitle("Cancel")
        playlistActionSheet!.destructiveButtonIndex = 3
        playlistActionSheet!.cancelButtonIndex = 4
        playlistActionSheet!.showInView(self.view)
        playlistActionSheet!.delegate = self
    }
    
    func actionSheet(actionSheet: UIActionSheet, didDismissWithButtonIndex buttonIndex: Int) {
        if actionSheet != playlistActionSheet {
            menuSelectedTrack = nil
        }
    }
    
    func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
        if actionSheet == playlistActionSheet {
            switch(buttonIndex) {
            case 0:
                onShufflePlayPlaylistBtnClicked()
                break
            case 1:
                onSharePlaylistBtnClicked()
                break
            case 2:
                onRenamePlaylistBtnClicked()
                break
            case 3:
                onDeletePlaylistBtnClicked()
                break
            default:
                break
            }
            return
        } else {
            let track = menuSelectedTrack
            var foundIdx = -1
            if track != nil {
                for (idx, track) in enumerate(tracks) {
                    if track.id == track.id {
                        foundIdx = idx
                        break
                    }
                }
            }
            if foundIdx == -1 {
                ViewUtils.showToast(self, message: "Track is not in playlist")
                return
            }
            
            switch(buttonIndex) {
            case 0:
                onPlayTrackBtnClicked(menuSelectedTrack!)
                break
            case 1:
                onShareTrackBtnClicked(menuSelectedTrack!)
                break
            case 2:
                onTrackAddToOtherPlaylistBtnClicked(menuSelectedTrack!)
                break
            case 3:
                onDeleteTrackBtnClicked(menuSelectedTrack!)
                break
            default:
                break
            }
        }
    }
    
    func onPlayTrackBtnClicked(track: Track) {
        var params: Dictionary<String, AnyObject> = [
            "track": track,
            "playlistId": currentPlaylist!.id
        ]
        
        NSNotificationCenter.defaultCenter().postNotificationName(
            NotifyKey.playerPlay, object: params)
        
        if fromPlayer {
            navigationController?.popToRootViewControllerAnimated(true)
        }
    }
    
    func onShareTrackBtnClicked(track: Track) {
        // TODO
    }
    
    func onTrackAddToOtherPlaylistBtnClicked(track: Track) {
        // TODO
    }
    
    func onDeleteTrackBtnClicked(track:Track) {
        PlaylistViewController.deleteTrack(currentPlaylist!, selectedTrack: track, afterDelete: { (error) -> Void in
            if error != nil {
                if (error!.domain == NSURLErrorDomain &&
                        error!.code == NSURLErrorNotConnectedToInternet) {
                    ViewUtils.showConfirmAlert(self, title: "Failed to delete", message: "Internet is not connected.",
                        positiveBtnText: "Retry", positiveBtnCallback: { () -> Void in
                            self.onDeleteTrackBtnClicked(track)
                        }, negativeBtnText: "Cancel", negativeBtnCallback: nil)
                    return
                }
                ViewUtils.showConfirmAlert(self, title: "Failed to delete", message: "Failed to delete track",
                    positiveBtnText: "Retry", positiveBtnCallback: { () -> Void in
                        self.onDeleteTrackBtnClicked(track)
                    }, negativeBtnText: "Cancel", negativeBtnCallback: nil)
                return
            }
            self.loadPlaylist()
        })
    }
    
    func onShufflePlayPlaylistBtnClicked() {
        if tracks.count == 0 {
            ViewUtils.showToast(self, message: "Playlist empty")
            return
        }
        
        let randomIndex = Int(arc4random_uniform(UInt32(tracks.count)))
        var selectedTrack: Track = tracks[randomIndex] as Track
        
        PlayerContext.shuffleState = ShuffleState.SHUFFLE
        
        var params: Dictionary<String, AnyObject> = [
            "track": selectedTrack,
            "playlistId": currentPlaylist!.id
        ]
        
        NSNotificationCenter.defaultCenter().postNotificationName(
            NotifyKey.playerPlay, object: params)
        NSNotificationCenter.defaultCenter().postNotificationName(
            NotifyKey.updateShuffleState, object: nil)
    }
    
    func onSharePlaylistBtnClicked() {
        // TODO
    }
    
    func onDeletePlaylistBtnClicked() {
        let playlists = PlayerContext.playlists
        if (playlists.count == 1) {
            ViewUtils.showNoticeAlert(self, title: "Failed to delete", message: "At least one playlist should exist")
            return
        }
        let removePlaylist = currentPlaylist!
        
        ViewUtils.showConfirmAlert(
            self, title: "Are you sure?",
            message: "Are you sure you want do delete \'\(removePlaylist.name)' playlist with \(removePlaylist.tracks.count) songs?",
            positiveBtnText: "Delete", positiveBtnCallback: {
                
                let progressHud = ViewUtils.showProgress(self, message: "Deleting..")
                
                Requests.deletePlaylist(removePlaylist.id, respCb: {
                        (request:NSURLRequest, response: NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
                    
                    progressHud.hide(true)
                    if (error != nil || result == nil) {
                        var message:String?
                        if (error != nil && error!.domain == NSURLErrorDomain &&
                                error!.code == NSURLErrorNotConnectedToInternet) {
                            message = "Internet is not connected"
                        }
                        if (message == nil) {
                            message = "undefined error (\(error!.domain),\(error!.code))"
                        }
                        ViewUtils.showNoticeAlert(self, title: "Failed to update playlist", message: message!)
                        return
                    }
                    let res = result as! NSDictionary
                    var success:Bool = res.objectForKey("success") as! Bool? ?? false
                    if (!success) {
                        let errorMsg = res.objectForKey("error") as? String ?? "undefined error"
                        ViewUtils.showNoticeAlert(self, title: "Failed to delete", message: errorMsg)
                        return
                    }
                    if PlayerContext.currentPlaylistId == removePlaylist.id {
                        NSNotificationCenter.defaultCenter().postNotificationName(
                            NotifyKey.playerStop, object: nil)
                        PlayerContext.shuffleState = ShuffleState.NOT_SHUFFLE
                        NSNotificationCenter.defaultCenter().postNotificationName(
                            NotifyKey.updateShuffleState, object: nil)
                    }
                    
                    self.navigationController!.popViewControllerAnimated(true)
                })
            })
    }
    
    func onRenamePlaylistBtnClicked() {
        let targetPlaylist = currentPlaylist!
        
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
                    progressHud.hide(true)
                    if (error != nil) {
                        var message:String?
                        if (error != nil && error!.domain == NSURLErrorDomain &&
                                error!.code == NSURLErrorNotConnectedToInternet) {
                            message = "Internet is not connected"
                        }
                        if (message == nil) {
                            message = "undefined error (\(error!.domain),\(error!.code))"
                        }
                        ViewUtils.showNoticeAlert(self, title: "Failed to change", message: message!)
                        return
                    }
                        
                    self.loadPlaylist()
                })
            })
    }
    
    func onMenuBtnClicked(sender: PlaylistTableViewCell) {
        let indexPath:NSIndexPath = playlistTableView.indexPathForCell(sender)!
        menuSelectedTrack = tracks[indexPath.row]
        
        let actionSheet = UIActionSheet()
        actionSheet.addButtonWithTitle("Play")
        actionSheet.addButtonWithTitle("Share")
        actionSheet.addButtonWithTitle("Add to other playlist")
        actionSheet.addButtonWithTitle("Delete")
        actionSheet.addButtonWithTitle("Cancel")
        actionSheet.destructiveButtonIndex = 3
        actionSheet.cancelButtonIndex = 4
        actionSheet.showInView(self.view)
        actionSheet.delegate = self
    }
    
    func updatePlayTrack(noti: NSNotification) {
        var params = noti.object as! Dictionary<String, AnyObject>
        var track = params["track"] as! Track
        var playlistId:String? = params["playlistId"] as? String
        updatePlayTrack(track, playlistId: playlistId)
    }
    
    func updatePlayTrack(track:Track?, playlistId:String?) {
        var indexPath = playlistTableView.indexPathForSelectedRow()
        if (indexPath != nil) {
            var preSelectedTrack:Track = tracks[indexPath!.row]
            if (preSelectedTrack.id != track!.id ||
                (playlistId == nil && playlistId != currentPlaylist!.id)) {
                playlistTableView.deselectRowAtIndexPath(indexPath!, animated: false)
            }
        }
        
        if (playlistId == nil || playlistId != currentPlaylist!.id) {
            return
        }
        
        for (idx, t) in enumerate(currentPlaylist!.tracks) {
            if (t.id == track!.id) {
                playlistTableView.selectRowAtIndexPath(NSIndexPath(forRow: idx, inSection: 0),
                    animated: true, scrollPosition: UITableViewScrollPosition.None)
                break
            }
        }
    }
}
