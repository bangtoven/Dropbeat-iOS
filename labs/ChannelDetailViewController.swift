//
//  ChannelDetailViewController.swift
//  labs
//
//  Created by vulpes on 2015. 7. 26..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

class ChannelDetailViewController: BaseViewController,
        UITableViewDelegate, UITableViewDataSource, AddableTrackCellDelegate,
        UIActionSheetDelegate {
    
    @IBOutlet var channelInfoView: UIView!
    @IBOutlet weak var sectionSelector: UIButton!
    @IBOutlet weak var sectionSelectorWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var bookmarkBtn: UIButton!
    @IBOutlet weak var genreView: UILabel!
    @IBOutlet weak var nameView: UILabel!
    @IBOutlet weak var thumbView: UIImageView!
    @IBOutlet weak var sectionSelectTableView: UITableView!
    @IBOutlet weak var loadMoreSpinnerWrapper: UIView!
    @IBOutlet weak var loadMoreSpinner: UIActivityIndicatorView!
    
    private var refreshControl:UIRefreshControl!
    private var actionSheetTargetTrack:Track?
    private var isLoading:Bool = false
    private var listEnd:Bool = false
    private var currSection:ChannelPlaylist?
    private var sectionSelectMode = false
    private var nextPageToken:String?
    private var channel:Channel?
    private var bookmarkedIds: [String] = [String]()
    private var tracks:[ChannelTrack] = [ChannelTrack]()
    private var dateFormatter:NSDateFormatter {
        var formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.000Z"
        return formatter
    }
    var channelUid:String?
    var channelName: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "updatePlay:", name: NotifyKey.updatePlay, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "sender", name: NotifyKey.playerPlay, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "appWillEnterForeground",
            name: UIApplicationWillEnterForegroundNotification, object: nil)
        
        refreshControl = UIRefreshControl()
        refreshControl.tintColor = UIColor(netHex:0xc380fc)
        refreshControl.addTarget(self, action: "refresh", forControlEvents: UIControlEvents.ValueChanged)
        
        let refreshControlTitle = NSAttributedString(
            string: NSLocalizedString("Pull to refresh", comment: ""),
            attributes: [NSForegroundColorAttributeName: UIColor(netHex: 0x909090)])
        refreshControl.attributedTitle = refreshControlTitle
        tableView.insertSubview(refreshControl, atIndex: 0)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.screenName = "ChannelDetailScreen"
        if channel == nil {
            loadChannel()
        } else {
            loadBookmarks()
        }
        updatePlay(PlayerContext.currentTrack, playlistId: PlayerContext.currentPlaylistId)
    }
    
    func appWillEnterForeground() {
        if channel != nil {
            loadBookmarks()
            if currSection != nil {
                selectSection(currSection!)
            }
        }
        self.updatePlay(PlayerContext.currentTrack, playlistId: PlayerContext.currentPlaylistId)
    }
    
    override func viewDidDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotifyKey.updatePlay, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotifyKey.playerPlay, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationWillEnterForegroundNotification, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func sender () {}
    
    func selectSection (playlist: ChannelPlaylist) {
        updateSectionSelectBtnView(playlist.name)
        currSection = playlist
        nextPageToken = nil
        listEnd = false
        tableView.setContentOffset(CGPointZero, animated:false)
        self.loadTracks(playlist.uid, pageToken: nextPageToken)
    }
    
    func loadChannel() {
        let progressHud = ViewUtils.showProgress(self, message: NSLocalizedString("loading channel info..", comment:""))
        Requests.getChannelDetail(channelUid!, respCb: {
                (req:NSURLRequest, resp: NSHTTPURLResponse?, result: AnyObject?, error:NSError?) -> Void in
            progressHud.hide(true)
            if (error != nil || result == nil) {
                if (error != nil && error!.domain == NSURLErrorDomain &&
                        error!.code == NSURLErrorNotConnectedToInternet) {
                    ViewUtils.showNoticeAlert(self,
                        title: NSLocalizedString("Failed to fetch channel info", comment:""),
                        message: NSLocalizedString("Internet is not connected", comment:""))
                    return
                }
                var message = NSLocalizedString("Failed to fetch channel info.", comment:"")
                ViewUtils.showNoticeAlert(self, title: NSLocalizedString("Failed to fetch", comment:""), message: message)
                return
            }
            
            self.channel = Channel.fromDetailJson(result!, key: "data")
            if (self.channel == nil) {
                var message = NSLocalizedString("Failed to fetch channel info.", comment:"")
                ViewUtils.showNoticeAlert(self, title: NSLocalizedString("Failed to fetch", comment:""), message: message)
                return
            }
            self.channel!.uid = self.channelUid
            self.genreView.text = ", ".join(self.channel!.genre)
            self.nameView.text = self.channel!.name
            if (self.channel!.thumbnail != nil) {
                self.thumbView.sd_setImageWithURL(NSURL(string:self.channel!.thumbnail!),
                    placeholderImage: UIImage(named: "default_artwork.png"))
            } else {
                self.thumbView.image = UIImage(named: "default_artwork.png")
            }
            self.channelInfoView.hidden = false
            self.loadBookmarks()
            if (self.channel!.playlists.count > 0) {
                self.selectSection(self.channel!.playlists[0])
            }
            self.sectionSelectTableView.reloadData()
        })
    }
    
    func loadBookmarks() {
        if (Account.getCachedAccount() == nil) {
            return
        }
        let progressHud = ViewUtils.showProgress(self, message: NSLocalizedString("loading bookmarks..", comment:""))
        Requests.getBookmarkList({ (req: NSURLRequest, resp:NSHTTPURLResponse?, result:AnyObject?, error: NSError?) -> Void in
            progressHud.hide(true)
            if (error != nil || result == nil) {
                if (error != nil && error!.domain == NSURLErrorDomain &&
                        error!.code == NSURLErrorNotConnectedToInternet) {
                    ViewUtils.showNoticeAlert(self,
                        title: NSLocalizedString("Failed to fetch bookmark", comment:""),
                        message: NSLocalizedString("Internet is not connected", comment:""))
                    return
                }
                var message = NSLocalizedString("Failed to fetch bookmarks.", comment:"")
                ViewUtils.showNoticeAlert(self, title: NSLocalizedString("Failed to fetch", comment:""), message: message)
                return
            }
            
            var json = JSON(result!)
            var data = json["bookmark"]
            self.bookmarkedIds.removeAll(keepCapacity: false)
            for (idx:String, s: JSON) in data {
                self.bookmarkedIds.append(s.stringValue)
            }
            self.channel!.isBookmarked = find(self.bookmarkedIds, self.channel!.uid!) != nil
            self.updateBookmarkBtn()
        })
    }
    
    func refresh() {
        selectSection(currSection!)
    }
    
    func loadTracks(playlistUid:String, pageToken:String?) {
        if isLoading {
            return
        }
        isLoading = true
        
        var progressHud:MBProgressHUD?
        if !refreshControl.refreshing && pageToken == nil {
            progressHud = ViewUtils.showProgress(self, message: nil)
        }
        Requests.getChannelPlaylist(playlistUid, pageToken: pageToken) { (req: NSURLRequest, resp: NSHTTPURLResponse?, result: AnyObject?, error :NSError?) -> Void in
            progressHud?.hide(true)
            if self.refreshControl.refreshing {
                self.refreshControl.endRefreshing()
            }
            self.isLoading = false
            if (error != nil || result == nil) {
                if (error != nil && error!.domain == NSURLErrorDomain &&
                        error!.code == NSURLErrorNotConnectedToInternet) {
                    ViewUtils.showNoticeAlert(self,
                        title: NSLocalizedString("Failed to load", comment:""),
                        message: NSLocalizedString("Internet is not connected", comment:""))
                    return
                }
                if result != nil {
                    println("result = \(result)")
                }
                var message = NSLocalizedString("Failed to load tracks.", comment:"")
                ViewUtils.showNoticeAlert(self, title: NSLocalizedString("Failed to load", comment:""), message: message)
                return
            }
            
            if pageToken == nil {
                self.tracks.removeAll(keepCapacity: false)
            }
            var json = JSON(result!)
            
            if json["nextPageToken"].error == nil {
                self.nextPageToken = json["nextPageToken"].stringValue
            } else {
                self.nextPageToken = nil
            }
            if self.nextPageToken == nil {
                self.listEnd = true
                self.loadMoreSpinnerWrapper.hidden = true
                self.loadMoreSpinner.stopAnimating()
            }
            
            for (idx: String, item:JSON) in json["items"] {
                if item["snippet"].error != nil {
                    continue
                }
                var snippet = item["snippet"]
                if snippet["resourceId"].error != nil {
                    continue
                }
                var resourceId = snippet["resourceId"]
                if resourceId["videoId"].error != nil {
                    continue
                }
                var id = resourceId["videoId"].stringValue
                
                if snippet["title"].error != nil {
                    continue
                }
                var title = snippet["title"].stringValue
                
                if snippet["description"].error != nil {
                    continue
                }
                var desc = snippet["description"].stringValue
                
                if snippet["publishedAt"].error != nil {
                    continue
                }
                var publishedAtStr = snippet["publishedAt"].stringValue
                var publishedAt = self.dateFormatter.dateFromString(publishedAtStr)
                self.tracks.append(ChannelTrack(id: id, title:title, publishedAt: publishedAt))
            }
            self.updatePlaylist(false)
            self.tableView.reloadData()
            self.updatePlay(PlayerContext.currentTrack, playlistId: PlayerContext.currentPlaylistId)
        }
    }
    
    func switchToSectionSelectMode() {
        sectionSelectMode = true
        self.tableView.hidden = true
        self.sectionSelectTableView.hidden = false
        sectionSelector.setImage(UIImage(named: "ic_arrow_up.png"), forState: UIControlState.Normal)
    }
    
    func switchToNonSectionSelectMode() {
        sectionSelectMode = false
        self.tableView.hidden = false
        self.sectionSelectTableView.hidden = true
        sectionSelector.setImage(UIImage(named: "ic_arrow_down.png"), forState: UIControlState.Normal)
    }
    
    @IBAction func onSectionSelectorClicked(sender: AnyObject) {
        if sectionSelectMode {
            switchToNonSectionSelectMode()
        } else {
            switchToSectionSelectMode()
        }
    }
    
    @IBAction func onBookmarkBtnClicked(sender: AnyObject) {
        if (Account.getCachedAccount() == nil) {
            performSegueWithIdentifier("need_auth", sender: nil)
            return
        }
        
        var newBookmarkedIds: [String] = []
        for id in bookmarkedIds {
            newBookmarkedIds.append(id)
        }
        
        var isAdding:Bool = true
        
        if (!channel!.isBookmarked) {
            if (find(newBookmarkedIds, channelUid!) == nil) {
                newBookmarkedIds.append(channelUid!)
            }
        } else {
            let idx = find(newBookmarkedIds, channelUid!)
            if (idx != nil) {
                newBookmarkedIds.removeAtIndex(idx!)
            }
            isAdding = false
        }
        let progressHud = ViewUtils.showProgress(self, message: NSLocalizedString("saving bookmark..", comment:""))
        Requests.updateBookmarkList(newBookmarkedIds, respCb:{
                (req:NSURLRequest, resp:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            progressHud.hide(true)
            if (error != nil || result == nil) {
                if (error != nil && error!.domain == NSURLErrorDomain &&
                        error!.code == NSURLErrorNotConnectedToInternet) {
                    ViewUtils.showNoticeAlert(self,
                        title: NSLocalizedString("Failed to update bookmarks", comment:""),
                        message: NSLocalizedString("Internet is not connected", comment:""))
                    return
                }
                var message = NSLocalizedString("Failed to update bookmarks.", comment:"")
                ViewUtils.showNoticeAlert(self,
                    title: NSLocalizedString("Failed to update", comment:""), message: message)
                return
            }
            if (isAdding && find(self.bookmarkedIds, self.channel!.uid!) == nil) {
                self.bookmarkedIds.append(self.channel!.uid!)
            } else if (!isAdding) {
                let idx = find(self.bookmarkedIds, self.channel!.uid!)
                if idx != nil {
                    self.bookmarkedIds.removeAtIndex(idx!)
                }
            }
            self.channel!.isBookmarked = isAdding
            self.updateBookmarkBtn()
        })
    }
    
    func updateSectionSelectBtnView(sectionName: String) {
        var image = sectionSelector.imageView!.image
        var titleLabel = sectionSelector.titleLabel
        var genreStr:NSString = sectionName as NSString
        sectionSelector.setTitle(sectionName, forState: UIControlState.Normal)
        
        var attr:[String : UIFont] = [String: UIFont]()
        attr[ NSFontAttributeName] = UIFont.systemFontOfSize(12)
        var textSize:CGSize = genreStr.sizeWithAttributes(attr)
        var textWidth = textSize.width;
        
        //or whatever font you're using
        var frame = sectionSelector.frame
        var origin = sectionSelector.frame.origin
        sectionSelector.frame = CGRectMake(origin.x, origin.y, textWidth + 50, frame.height)
        sectionSelectorWidthConstraint.constant = textWidth + 50
        sectionSelector.layer.cornerRadius = 4
        sectionSelector.imageEdgeInsets = UIEdgeInsetsMake(2, textWidth + 50 - (image!.size.width + 15), 0, 0);
        sectionSelector.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 0, image!.size.width + 15);
    }
    
    func updateBookmarkBtn() {
        if channel!.isBookmarked {
            bookmarkBtn.setImage(UIImage(named: "ic_star_filled.png"), forState: UIControlState.Normal)
        } else {
            bookmarkBtn.setImage(UIImage(named: "ic_star.png"), forState: UIControlState.Normal)
        }
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if tableView != self.tableView || tracks.count == 0 {
            return
        }
        if indexPath.row == tracks.count - 1 {
            if listEnd || nextPageToken == nil || currSection == nil {
                return
            }
            loadMoreSpinnerWrapper.hidden = false
            loadMoreSpinner.startAnimating()
            loadTracks(currSection!.uid, pageToken: nextPageToken)
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if tableView == self.tableView {
            let cell:AddableChannelTrackTableViewCell = tableView.dequeueReusableCellWithIdentifier(
                    "AddableTrackTableViewCell", forIndexPath: indexPath) as!AddableChannelTrackTableViewCell
            let track:ChannelTrack = tracks[indexPath.row]
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
            if track.publishedAt != nil {
                var formatter = NSDateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                cell.publishedAt.text = formatter.stringFromDate(track.publishedAt!)
            } else {
                cell.publishedAt.hidden = true
            }
            return cell
        } else {
            let cell:SectionTableViewCell = sectionSelectTableView.dequeueReusableCellWithIdentifier(
                    "SectionItem", forIndexPath: indexPath) as! SectionTableViewCell
            let section = self.channel!.playlists[indexPath.row]
            cell.sectionNameView.text = section.name
            return cell
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if tableView == self.tableView {
            onPlayBtnClicked(tracks[indexPath.row])
        } else {
            switchToNonSectionSelectMode()
            selectSection(self.channel!.playlists[indexPath.row])
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.tableView {
            return tracks.count
        }
        return self.channel?.playlists.count ?? 0
    }
    
    func getPlaylistId() -> String? {
        if channel == nil || currSection == nil {
            return nil
        }
        return "channel_playlist_\(channel!.uid)_\(currSection!.uid)"
    }
    
    func updatePlaylist(forceUpdate:Bool) {
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
                    name: "\(channel!.name) - \(currSection!.name)",
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
    
    func onPlayBtnClicked(track:Track) {
        var playlistId:String?
        if tracks.count == 0 || getPlaylistId() == nil{
            playlistId = nil
        } else {
            updatePlaylist(true)
            playlistId = PlayerContext.externalPlaylist!.id
        }
        var params: [String: AnyObject] = [
            "track": track,
        ]
        if playlistId != nil {
            params["playlistId"] = playlistId
        }
        NSNotificationCenter.defaultCenter().postNotificationName(
            NotifyKey.playerPlay, object: params)
    }
    
    func onShareBtnClicked(track:Track) {
        let progressHud = ViewUtils.showProgress(self, message: NSLocalizedString("Loading..", comment:""))
        track.shareTrack("channel_detail", afterShare: { (error, uid) -> Void in
            progressHud.hide(true)
            if error != nil {
                if (error!.domain == NSURLErrorDomain &&
                        error!.code == NSURLErrorNotConnectedToInternet) {
                    ViewUtils.showConfirmAlert(self, title: NSLocalizedString("Failed to share", comment:""),
                        message: NSLocalizedString("Internet is not connected.", comment:""),
                        positiveBtnText: NSLocalizedString("Retry", comment:""), positiveBtnCallback: { () -> Void in
                            self.onShareBtnClicked(track)
                        }, negativeBtnText: NSLocalizedString("Cancel", comment:""), negativeBtnCallback: nil)
                    return
                }
                ViewUtils.showConfirmAlert(self, title: NSLocalizedString("Failed to share", comment:""),
                    message: NSLocalizedString("Failed to share track", comment:""),
                    positiveBtnText: NSLocalizedString("Retry", comment:""), positiveBtnCallback: { () -> Void in
                        self.onShareBtnClicked(track)
                    }, negativeBtnText: NSLocalizedString("Cancel", comment:""), negativeBtnCallback: nil)
                return
            }
            let shareUrl = "http://dropbeat.net/?track=" + uid!
            let shareTitle = track.title
            
            var items:[AnyObject] = [shareTitle, shareUrl]
            
            let activityController = UIActivityViewController(
                    activityItems: items, applicationActivities: nil)
            activityController.excludedActivityTypes = [
                    UIActivityTypePrint,
                    UIActivityTypeSaveToCameraRoll,
                    UIActivityTypeAirDrop,
                    UIActivityTypeAssignToContact
                ]
            if activityController.respondsToSelector("popoverPresentationController:") {
                activityController.popoverPresentationController?.sourceView = self.view
            }
            self.presentViewController(activityController, animated:true, completion: nil)
        })
    }
    
    func onLikeBtnClicked(track:Track) {
        if (Account.getCachedAccount() == nil) {
            performSegueWithIdentifier("need_auth", sender: nil)
            return
        }
        let progressHud = ViewUtils.showProgress(self, message: nil)
        if track.isLiked {
            track.doUnlike({ (error) -> Void in
                if error != nil {
                    progressHud.hide(true)
                    ViewUtils.showConfirmAlert(self,
                        title: NSLocalizedString("Failed to save", comment: ""),
                        message: NSLocalizedString("Failed to save unlike info.", comment:""),
                        positiveBtnText:  NSLocalizedString("Retry", comment: ""),
                        positiveBtnCallback: { () -> Void in
                            self.onLikeBtnClicked(track)
                    })
                    return
                }
                progressHud.mode = MBProgressHUDMode.CustomView
                progressHud.customView = UIImageView(image: UIImage(named:"ic_hud_unlike.png"))
                progressHud.hide(true, afterDelay: 1)
                
            })
        } else {
            track.doLike({ (error) -> Void in
                if error != nil {
                    progressHud.hide(true)
                    ViewUtils.showConfirmAlert(self,
                        title: NSLocalizedString("Failed to save", comment: ""),
                        message: NSLocalizedString("Failed to save like info.", comment:""),
                        positiveBtnText:  NSLocalizedString("Retry", comment: ""),
                        positiveBtnCallback: { () -> Void in
                            self.onLikeBtnClicked(track)
                    })
                    return
                }
                progressHud.mode = MBProgressHUDMode.CustomView
                progressHud.customView = UIImageView(image: UIImage(named:"ic_hud_like.png"))
                progressHud.hide(true, afterDelay: 1)
            })
        }
    }
    
    func onAddBtnClicked(track:Track) {
        if (Account.getCachedAccount() == nil) {
            performSegueWithIdentifier("need_auth", sender: nil)
            return
        }
        performSegueWithIdentifier("PlaylistSelectSegue", sender: track)
    }
    
    func onMenuBtnClicked(sender: AddableTrackTableViewCell) {
        let indexPath:NSIndexPath = tableView.indexPathForCell(sender)!
        let track = tracks[indexPath.row]
        actionSheetTargetTrack = track
        
        let actionSheet = UIActionSheet()
        if track.isLiked {
            actionSheet.addButtonWithTitle(NSLocalizedString("Liked", comment:""))
        } else {
            actionSheet.addButtonWithTitle(NSLocalizedString("Like", comment:""))
        }
        actionSheet.addButtonWithTitle(NSLocalizedString("Add to playlist", comment:""))
        actionSheet.addButtonWithTitle(NSLocalizedString("Share", comment:""))
        actionSheet.addButtonWithTitle(NSLocalizedString("Cancel", comment:""))
        actionSheet.cancelButtonIndex = 3
        actionSheet.delegate = self
        
        var appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        actionSheet.showFromTabBar(appDelegate.centerContainer!.tabBar)
    }
    
    func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
    }
    
    func actionSheet(actionSheet: UIActionSheet, didDismissWithButtonIndex buttonIndex: Int) {
        var track:Track? = actionSheetTargetTrack
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
            ViewUtils.showToast(self, message: NSLocalizedString("Track is not in feed", comment:""))
            return
        }
        
        switch(buttonIndex) {
        case 0:
            onLikeBtnClicked(track!)
            break
        case 1:
            onAddBtnClicked(track!)
            break
        case 2:
            onShareBtnClicked(track!)
            break
        default:
            break
        }
        actionSheetTargetTrack = nil
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
        var indexPath = tableView.indexPathForSelectedRow()
        if (indexPath != nil) {
            var preSelectedTrack = tracks[indexPath!.row]
            if (preSelectedTrack.id != track!.id ||
                (playlistId != nil && playlistId!.toInt() >= 0)) {
                tableView.deselectRowAtIndexPath(indexPath!, animated: false)
            }
        }
        
        
        if (playlistId != getPlaylistId()) {
            return
        }
        
        for (idx, t) in enumerate(tracks) {
            if (t.id == track!.id) {
                tableView.selectRowAtIndexPath(NSIndexPath(forRow: idx, inSection: 0),
                    animated: false, scrollPosition: UITableViewScrollPosition.None)
                break
            }
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "PlaylistSelectSegue" {
            let playlistSelectVC:PlaylistSelectViewController = segue.destinationViewController as! PlaylistSelectViewController
            playlistSelectVC.targetTrack = sender as? Track
            playlistSelectVC.fromSection = "feed"
            playlistSelectVC.caller = self
        }
    }
}
