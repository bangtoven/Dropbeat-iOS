//
//  ExploreViewController.swift
//  labs
//
//  Created by Jungho Bang on 2015. 9. 24..
//  Copyright © 2015년 dropbeat. All rights reserved.
//

import UIKit

class ExploreTableViewCell: AddableTrackTableViewCell {
    @IBOutlet weak var channelImageView: UIImageView!
    @IBOutlet weak var channelName: UILabel!
    @IBOutlet weak var publishedAt: UILabel!
}

class ExploreViewController: AddableTrackListViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var loadMoreSpinner: UIActivityIndicatorView!
    @IBOutlet weak var loadMoreSpinnerWrapper: UIView!
    
    private var nextPage:Int = 0
    private var isLoading:Bool = false
    private var refreshControl:UIRefreshControl!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl = UIRefreshControl()
        refreshControl.tintColor = UIColor(netHex:0xc380fc)
        refreshControl.addTarget(self, action: "refresh", forControlEvents: UIControlEvents.ValueChanged)
        
        let refreshControlTitle = NSAttributedString(
            string: NSLocalizedString("Pull to refresh", comment: ""),
            attributes: [NSForegroundColorAttributeName: UIColor(netHex: 0x909090)])
        refreshControl.attributedTitle = refreshControlTitle
        trackTableView.insertSubview(refreshControl, atIndex: 0)
    }
    
    func refresh() {
        nextPage = 0
        loadChannelFeed(nextPage, forceRefresh: true)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.screenName = "ExploreViewScreen"
        
        if trackTableView.indexPathForSelectedRow != nil {
            trackTableView.deselectRowAtIndexPath(trackTableView.indexPathForSelectedRow!, animated: false)
        }
        
        self.nextPage = 0
        self.loadChannelFeed(self.nextPage)
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tracks.count
    }
    
    func tableView(tableView: UITableView,
        cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
            let cell = trackTableView.dequeueReusableCellWithIdentifier(
                "ExploreTableViewCell", forIndexPath: indexPath) as! ExploreTableViewCell
            let track:ChannelFeedTrack = tracks[indexPath.row] as! ChannelFeedTrack
            cell.delegate = self
            cell.channelName.text = track.channelTitle
            cell.nameView.text = track.title
            if (track.thumbnailUrl != nil) {
                cell.thumbView.sd_setImageWithURL(NSURL(string: track.thumbnailUrl!),
                    placeholderImage: UIImage(named: "default_artwork"), completed: {
                        (image: UIImage!, error: NSError!, cacheType:SDImageCacheType, imageURL: NSURL!) -> Void in
                        if (error != nil) {
                            cell.thumbView.image = UIImage(named: "default_artwork")
                        }
                })
            } else {
                cell.thumbView.image = UIImage(named: "default_artwork")
            }
            if track.publishedAt != nil {
                let formatter = NSDateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                cell.publishedAt.text = formatter.stringFromDate(track.publishedAt!)
            } else {
                cell.publishedAt.hidden = true
            }
            
            cell.layer.borderWidth = 1.5
            cell.layer.borderColor = UIColor(white: 0.9, alpha: 1.0).CGColor

            return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let track:Track = tracks[indexPath.row]
        onTrackPlayBtnClicked(track)
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row == tracks.count - 1 {
            if nextPage <= 0{
                return
            }
            loadMoreSpinnerWrapper.hidden = false
            loadMoreSpinner.startAnimating()
            loadChannelFeed(nextPage)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "PlaylistSelectSegue" {
            let playlistSelectVC:PlaylistSelectViewController = segue.destinationViewController as! PlaylistSelectViewController
            playlistSelectVC.targetTrack = sender as? Track
            playlistSelectVC.fromSection = "explore"
            playlistSelectVC.caller = self
        }
    }
    
    func loadChannelFeed(pageIdx: Int, forceRefresh:Bool = false) {
        if isLoading {
            return
        }
        isLoading = true
        
        let tracker = GAI.sharedInstance().defaultTracker
        let event = GAIDictionaryBuilder.createEventWithCategory(
            "load_feed",
            action: "channel_feed",
            label: "feed",
            value: 1
            ).build()
        tracker.send(event as [NSObject: AnyObject]!)
        
        var progressHud:MBProgressHUD?
        if !refreshControl.refreshing && pageIdx == 0 {
            progressHud = ViewUtils.showProgress(self, message: NSLocalizedString("Loading..", comment:""))
            trackTableView.scrollsToTop = true
        }
        Requests.fetchExploreChannelFeed(pageIdx, respCb: {
            (req:NSURLRequest, resp:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            
            progressHud?.hide(true)
            self.refreshControl.endRefreshing()
            
            self.isLoading = false
            if (error != nil || result == nil) {
                if (error != nil && error!.domain == NSURLErrorDomain &&
                    error!.code == NSURLErrorNotConnectedToInternet) {
                        ViewUtils.showNoticeAlert(self,
                            title: NSLocalizedString("Failed to load", comment:""),
                            message: NSLocalizedString("Internet is not connected", comment:""))
                        return
                }
                let message = "Failed to load channel feed."
                ViewUtils.showNoticeAlert(self, title: NSLocalizedString("Failed to load", comment:""), message: message)
                return
            }
            
            let respObj = JSON(result!)
            if !(respObj["success"].bool ?? false) {
                let message = NSLocalizedString("Failed to load channel feed.", comment:"")
                ViewUtils.showNoticeAlert(self, title: NSLocalizedString("Failed to load", comment:""), message: message)
                return
            }
            
            var particals = [ChannelFeedTrack]()
            for (_, s): (String, JSON) in respObj["data"] {
                let track = ChannelFeedTrack(json: s)
                particals.append(track)
            }
            
            if particals.count == 0 {
                self.nextPage = -1
                self.loadMoreSpinnerWrapper.hidden = true
                self.loadMoreSpinner.stopAnimating()
                return
            } else {
                self.nextPage = pageIdx + 1
            }
            
            if forceRefresh {
                self.tracks.removeAll(keepCapacity: false)
            }
            
            for track in particals {
                self.tracks.append(track)
            }
            self.updatePlaylist(false)
            
            self.trackTableView.reloadData()
            self.updatePlay(PlayerContext.currentTrack, playlistId: PlayerContext.currentPlaylistId)
        })
        
    }
    
    override func getPlaylistId() -> String? {
        return "Explore"
    }
    
    override func getSectionName() -> String {
        return "explore"
    }
    
    override func updatePlaylist(forceUpdate:Bool) {
        if !forceUpdate &&
            (getPlaylistId() == nil ||
                PlayerContext.currentPlaylistId != getPlaylistId()) {
                    return
        }
        
        var playlist:Playlist!
        if PlayerContext.externalPlaylist != nil &&
            PlayerContext.externalPlaylist!.id == getPlaylistId() {
                playlist = PlayerContext.externalPlaylist!
                playlist.tracks.removeAll(keepCapacity: false)
                for track in tracks {
                    playlist.tracks.append(track)
                }
        } else {
            playlist = Playlist(
                id: getPlaylistId()!,
                name: "Explore",
                tracks: tracks)
            playlist.type = PlaylistType.EXTERNAL
            PlayerContext.externalPlaylist = playlist
        }
        
        if PlayerContext.currentPlaylistId == playlist.id {
            if PlayerContext.currentTrack == nil {
                PlayerContext.currentTrackIdx = -1
            } else {
                PlayerContext.currentTrackIdx = playlist.getTrackIdx(PlayerContext.currentTrack!)
            }
        }
        return
    }
}
