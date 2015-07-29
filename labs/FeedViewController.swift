//
//  ViewController.swift
//  labs
//
//  Created by Park Il Su on 2015. 5. 14..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit


class FeedViewController: BaseViewController,
        UITableViewDelegate, UITableViewDataSource, AddableTrackCellDelegate, UIActionSheetDelegate{
    var tracks:Array<Track> = []
    
    @IBOutlet weak var feedTableView: UITableView!
    var selectedTrack:Track?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadFeed()
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "updatePlay:", name: NotifyKey.updatePlay, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "sender", name: NotifyKey.playerPlay, object: nil)
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.screenName = "FeedViewScreen"
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotifyKey.updatePlay, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotifyKey.playerPlay, object: nil)
    }
    
    func sender () {}
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell:AddableTrackTableViewCell = tableView.dequeueReusableCellWithIdentifier("AddableTrackTableViewCell", forIndexPath: indexPath) as! AddableTrackTableViewCell
        let track:Track = tracks[indexPath.row]
        cell.delegate = self
        cell.nameView.text = track.title
        if (track.thumbnailUrl != nil) {
            cell.thumbView.sd_setImageWithURL(NSURL(string: track.thumbnailUrl!),
                    placeholderImage: UIImage(named: "default_artwork.png"), completed: {
                    (image: UIImage!, error: NSError!, cacheType:SDImageCacheType, imageURL: NSURL!) -> Void in
                if (error != nil) {
                    cell.thumbView.image = UIImage(named: "default_artwork.png")
                }
            })
        } else {
            cell.thumbView.image = UIImage(named: "default_artwork.png")
        }
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        onPlayBtnClicked(tracks[indexPath.row])
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tracks.count
    }
    
    func onPlayBtnClicked(track:Track) {
        var params: Dictionary<String, AnyObject> = [
            "track": track,
            "playlistId": "-1"
        ]
        NSNotificationCenter.defaultCenter().postNotificationName(
            NotifyKey.playerPlay, object: params)
    }
    
    func onShareBtnClicked(track:Track) {
        // TODO
    }
    
    func onAddBtnClicked(track:Track) {
        if (Account.getCachedAccount() == nil) {
            var appDelegate:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            var centerViewController = appDelegate.centerContainer!
            centerViewController.showSigninView()
            return
        }
        // TODO show playlist select
    }
    
    func onMenuBtnClicked(sender: AddableTrackTableViewCell) {
        let indexPath:NSIndexPath = feedTableView.indexPathForCell(sender)!
        let track = tracks[indexPath.row]
        selectedTrack = track
        
        let actionSheet = UIActionSheet()
        actionSheet.title = "Track menu"
        actionSheet.addButtonWithTitle("Add to playlist")
        actionSheet.addButtonWithTitle("Play")
        actionSheet.addButtonWithTitle("Share")
        actionSheet.addButtonWithTitle("Cancel")
        actionSheet.cancelButtonIndex = 3
        actionSheet.delegate = self
        actionSheet.showInView(self.view)
    }
    
    func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
        var track:Track? = selectedTrack
        var foundIdx = -1
        if track != nil {
            for (idx, t)  in enumerate(tracks) {
                if t.id == track!.id {
                    foundIdx = idx
                    break
                }
            }
        }
        if track == nil || foundIdx == -1 {
            ViewUtils.showToast(self, message: "Track is not in feed")
            return
        }
        
        switch(buttonIndex) {
        case 1:
            onPlayBtnClicked(track!)
            break
        case 0:
            onAddBtnClicked(track!)
            break
        case 2:
            onShareBtnClicked(track!)
            break
        default:
            break
        }
    }
    
    func actionSheet(actionSheet: UIActionSheet, didDismissWithButtonIndex buttonIndex: Int) {
        selectedTrack = nil
    }
    
    func loadFeed() {
        let progressHud = ViewUtils.showProgress(self, message: "loading feed..")
        Requests.fetchFeed({(request:NSURLRequest, response:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            progressHud.hide(true)
            if (error != nil || result == nil) {
                if (error != nil && error!.domain == NSURLErrorDomain &&
                        error!.code == NSURLErrorNotConnectedToInternet) {
                    ViewUtils.showNoticeAlert(self, title: "Failed to fetch feed", message: "Internet is not connected")
                    return
                }
                var message = "Failed to fetch feed caused by undefined error."
                if (error != nil) {
                    message += " (\(error!.domain):\(error!.code))"
                }
                ViewUtils.showNoticeAlert(self, title: "Failed to fetch feed", message: message)
                return
            }
            let parser = Parser()
            var fetchedTracks = parser.parseFeed(result!)
            self.tracks = fetchedTracks.result
            self.feedTableView.reloadData()
            self.updatePlay(PlayerContext.currentTrack, playlistId: PlayerContext.currentPlaylistId)
        })
    }
    
    func updatePlay(noti: NSNotification) {
        var params = noti.object as! Dictionary<String, AnyObject>
        var track = params["track"] as! Track
        var playlistId:String? = params["playlistId"] as? String
        
        updatePlay(track, playlistId: playlistId)
    }
    
    func updatePlay(track:Track?, playlistId: String?) {
        if (track == nil) {
            return
        }
        var indexPath = feedTableView.indexPathForSelectedRow()
        if (indexPath != nil) {
            var preSelectedTrack = tracks[indexPath!.row]
            if (preSelectedTrack.id != track!.id ||
                (playlistId != nil && playlistId!.toInt() >= 0)) {
                feedTableView.deselectRowAtIndexPath(indexPath!, animated: false)
            }
        }
        
        
        if (playlistId == nil || playlistId!.toInt() >= 0) {
            return
        }
        
        for (idx, t) in enumerate(tracks) {
            if (t.id == track!.id) {
                feedTableView.selectRowAtIndexPath(NSIndexPath(forRow: idx, inSection: 0),
                    animated: false, scrollPosition: UITableViewScrollPosition.None)
                break
            }
        }
    }
    
}
