//
//  ChannelViewController.swift
//  labs
//
//  Created by vulpes on 2015. 7. 25..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

class ChannelViewController: BaseViewController,
        UITableViewDelegate, UITableViewDataSource, ScrollPagerDelegate, ChannelTableViewCellDelegate, AddableTrackCellDelegate,
            UIActionSheetDelegate {
    
    var tracks: [ChannelFeedTrack] = [ChannelFeedTrack]()
    var allChannels : [String:Channel] = [String:Channel]()
    var channels : [Channel] = [Channel]()
    var bookmarkedChannels : [Channel] = [Channel]()
    var genres : [Genre] = []
    
    var selectedTabIdx = 0
    var channelLoaded = false
    var genreLoaded = false
    var isGenreSelectMode = false
    var selectedGenre:Genre?
    var actionSheetTargetTrack:Track?
    var nextPage:Int = 0
    var isLoading:Bool = false
    var bookmarkListHeader:UIView?
    
    var dateFormatter:NSDateFormatter {
        var formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.000Z"
        return formatter
    }
    
    @IBOutlet weak var signinBtn: UIButton!
    @IBOutlet weak var noBookmarkView: UIView!
    @IBOutlet weak var needSigninView: UIView!
    @IBOutlet weak var loadMoreSpinner: UIActivityIndicatorView!
    @IBOutlet weak var loadMoreSpinnerWrapper: UIView!
    @IBOutlet weak var genreSelectBtn: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var genreTableView: UITableView!
    @IBOutlet weak var genreSelectorWrapper: UIView!
    @IBOutlet weak var pager: ScrollPager!
    @IBOutlet weak var genreSelectorConstraint: NSLayoutConstraint!
    @IBOutlet weak var genreSelectorWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var emptyChannelView: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var signinBgImage = UIImage(named: "facebook_btn_bg.png")
        signinBgImage = signinBgImage!.resizableImageWithCapInsets(UIEdgeInsetsMake(14, 14, 14, 14))
        signinBtn.setBackgroundImage(signinBgImage, forState: UIControlState.Normal)
        
        pager.font = UIFont.systemFontOfSize(11)
        pager.selectedFont = UIFont.systemFontOfSize(11)
        
        pager.delegate = self
        pager.addSegmentsWithTitles(["FEED", "CHANNELS"])
        pager.reloadInputViews()
        
        genreSelectorConstraint.constant = 0
        genreSelectorWrapper.hidden = true
        
        needSigninView.hidden = Account.getCachedAccount() != nil
        
        bookmarkListHeader = createBookmarkListHeader()
    }
    
    func updateGenreSelectBtnView(genre: String) {
        var image = genreSelectBtn.imageView!.image
        var titleLabel = genreSelectBtn.titleLabel
        var genreStr:NSString = genre as NSString
        genreSelectBtn.setTitle(genre, forState: UIControlState.Normal)
        
        var attr:[String : UIFont] = [String: UIFont]()
        attr[ NSFontAttributeName] = UIFont.systemFontOfSize(12)
        var textSize:CGSize = genreStr.sizeWithAttributes(attr)
        var textWidth = textSize.width;
        
        //or whatever font you're using
        var frame = genreSelectBtn.frame
        var origin = genreSelectBtn.frame.origin
        genreSelectBtn.frame = CGRectMake(origin.x, origin.y, textWidth + 50, frame.height)
        genreSelectorWidthConstraint.constant = textWidth + 50
        genreSelectBtn.layer.cornerRadius = 4
        genreSelectBtn.imageEdgeInsets = UIEdgeInsetsMake(2, textWidth + 50 - (image!.size.width + 15), 0, 0);
        genreSelectBtn.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 0, image!.size.width + 15);
    }
    
    func scrollPager(scrollPager: ScrollPager, changedIndex: Int) {
        selectedTabIdx = changedIndex
        toNonGenreSelectMode()
        
        if selectedTabIdx == 0 {
            genreSelectorConstraint.constant = 0
            genreSelectorWrapper.hidden = true
            if Account.getCachedAccount() == nil {
                tableView.tableHeaderView = nil
            }
            loadBookmarks(refreshFeed: true)
        } else {
            genreSelectorConstraint.constant = 40
            genreSelectorWrapper.hidden = false
            noBookmarkView.hidden = true
            if (channelLoaded) {
                loadBookmarks()
            } else {
                loadChannels(genres[0], initialLoad: true)
            }
            tableView.tableHeaderView = nil
        }
        loadMoreSpinnerWrapper.hidden = true
        loadMoreSpinner.stopAnimating()
        tableView.reloadData()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.screenName = "ChannelViewScreen"
        
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "updatePlay:", name: NotifyKey.updatePlay, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "sender", name: NotifyKey.playerPlay, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "appWillEnterForeground",
            name: UIApplicationWillEnterForegroundNotification, object: nil)
        
        if tableView.indexPathForSelectedRow() != nil {
            tableView.deselectRowAtIndexPath(tableView.indexPathForSelectedRow()!, animated: false)
        }
        
        if !genreLoaded {
           loadGenres({ (error) -> Void in
                if error != nil {
                    ViewUtils.showNoticeAlert(self, title: "Failed to load", message: "Failed to initalize genre")
                    return
                }
                if (self.channelLoaded) {
                    self.loadBookmarks()
                } else {
                    self.loadChannels(self.genres[0], initialLoad: true)
                }
                self.genreLoaded = true
           })
        } else {
            if (channelLoaded) {
                loadBookmarks()
            } else {
                loadChannels(genres[0], initialLoad: true)
            }
        }
        updatePlay(PlayerContext.currentTrack, playlistId: PlayerContext.currentPlaylistId)
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotifyKey.updatePlay, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotifyKey.playerPlay, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationWillEnterForegroundNotification, object: nil)
    }
    
    func appWillEnterForeground() {
        if (channelLoaded) {
            loadBookmarks(refreshFeed: true)
        } else {
            loadChannels(genres[0], initialLoad: true)
        }
        updatePlay(PlayerContext.currentTrack, playlistId: PlayerContext.currentPlaylistId)
    }
    
    func sender () {}
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getChannelInfoCell(indexPath:NSIndexPath) -> UITableViewCell {
        let cell:ChannelTableViewCell = tableView.dequeueReusableCellWithIdentifier(
                "ChannelTableViewCell", forIndexPath: indexPath) as! ChannelTableViewCell
        cell.delegate = self
        
        var channel: Channel = channels[indexPath.row]
        if (channel.thumbnail != nil) {
            cell.thumbView.sd_setImageWithURL(
                NSURL(string: channel.thumbnail!),
                placeholderImage: UIImage(named :"default_artwork.png"), completed: {
                    (image: UIImage!, error: NSError!, cacheType:SDImageCacheType, imageURL: NSURL!) -> Void in
                    
                if (error != nil) {
                    cell.thumbView.image = UIImage(named: "default_artwork.png")
                }
                    
            })
        } else {
            cell.thumbView.image = UIImage(named: "default_artwork.png")
        }
        
        cell.nameView.text = channel.name
        if channel.isBookmarked {
            cell.bookmarkBtn.setImage(
                UIImage(named: "ic_star_filled.png"), forState: UIControlState.Normal)
        } else {
            cell.bookmarkBtn.setImage(
                UIImage(named: "ic_star.png"), forState: UIControlState.Normal)
        }
        
        return cell
    }
    
    func getChannelFeedCell(indexPath:NSIndexPath) -> UITableViewCell {
        let cell:AddableChannelFeedTrackTableViewCell = tableView.dequeueReusableCellWithIdentifier(
                "AddableTrackTableViewCell", forIndexPath: indexPath) as!AddableChannelFeedTrackTableViewCell
        let track:ChannelFeedTrack = tracks[indexPath.row]
        cell.delegate = self
        cell.channelName.text = track.channelTitle
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
    }
    
    func getGenreSelectCell(indexPath:NSIndexPath) -> UITableViewCell {
        let cell:GenreTableViewCell = genreTableView.dequeueReusableCellWithIdentifier(
            "GenreItem", forIndexPath: indexPath) as! GenreTableViewCell
        let genre = genres[indexPath.row]
        cell.genreView.text = genre.name
        return cell
    }
    
    func tableView(tableView: UITableView,
            cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
                
        if tableView == self.tableView {
            if selectedTabIdx == 0 {
                return getChannelFeedCell(indexPath)
            } else {
                return getChannelInfoCell(indexPath)
            }
        } else {
            return getGenreSelectCell(indexPath)
        }
    }
    
    func didChannelFeedCellSelected(indexPath: NSIndexPath) {
        let track:Track = tracks[indexPath.row]
        onTrackPlayBtnClicked(track)
    }
    
    func didChannelInfoCellSelected(indexPath: NSIndexPath) {
        performSegueWithIdentifier("ShowChannelSegue", sender: nil)
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if tableView == self.tableView {
            if selectedTabIdx == 0 {
                return 90.0
            } else {
                return 80.0
            }
        } else {
            return 60.0
        }
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if tableView != self.tableView || selectedTabIdx != 0 || tracks.count == 0 {
            return
        }
        if indexPath.row == tracks.count - 1 {
            if nextPage <= 0{
                return
            }
            loadMoreSpinnerWrapper.hidden = false
            loadMoreSpinner.startAnimating()
            loadChannelFeed(nextPage)
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if tableView == self.genreTableView {
            var genre = self.genres[indexPath.row]
            loadChannels(genre, initialLoad: false)
            toNonGenreSelectMode()
            return
        }
        if selectedTabIdx == 0 {
            didChannelFeedCellSelected(indexPath)
        } else {
            didChannelInfoCellSelected(indexPath)
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.tableView {
            var count = 0
            if selectedTabIdx == 0 {
                count = tracks.count
            } else {
                count = channels.count
            }
            return count
        } else {
            return genres.count
        }
    }
    
    func getPlaylistId() -> String? {
        var seed = ""
        for channel in bookmarkedChannels {
            seed += channel.uid!
        }
        return "seed_\(seed.md5)"
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
                    name: "Channel Feed",
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
    
    func onTrackPlayBtnClicked(track:Track) {
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
    
    func onTrackShareBtnClicked(track:Track) {
        let progressHud = ViewUtils.showProgress(self, message: "Loading..")
        track.shareTrack("channel_feed", afterShare: { (error, uid) -> Void in
            progressHud.hide(false)
            if error != nil {
                if (error!.domain == NSURLErrorDomain &&
                        error!.code == NSURLErrorNotConnectedToInternet) {
                    ViewUtils.showConfirmAlert(self, title: "Failed to share",
                        message: "Internet is not connected.",
                        positiveBtnText: "Retry", positiveBtnCallback: { () -> Void in
                            self.onTrackShareBtnClicked(track)
                        }, negativeBtnText: "Cancel", negativeBtnCallback: nil)
                    return
                }
                ViewUtils.showConfirmAlert(self, title: "Failed to share",
                    message: "Failed to share track",
                    positiveBtnText: "Retry", positiveBtnCallback: { () -> Void in
                        self.onTrackShareBtnClicked(track)
                    }, negativeBtnText: "Cancel", negativeBtnCallback: nil)
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
            if UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiom.Phone {
                if activityController.respondsToSelector("popoverPresentationController:") {
                    activityController.popoverPresentationController?.sourceView = self.view
                }
            }
            self.presentViewController(activityController, animated:true, completion: nil)
        })
    }
    
    func onTrackAddBtnClicked(track:Track) {
        if (Account.getCachedAccount() == nil) {
            var appDelegate:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            var centerViewController = appDelegate.centerContainer!
            centerViewController.showSigninView()
            return
        }
        performSegueWithIdentifier("PlaylistSelectSegue", sender: track)
    }
    
    func onMenuBtnClicked(sender: AddableTrackTableViewCell) {
        var actionSheet = UIActionSheet()
        actionSheet.addButtonWithTitle("Add to playlist")
        actionSheet.addButtonWithTitle("Share")
        actionSheet.addButtonWithTitle("Cancel")
        actionSheet.cancelButtonIndex = 2
        actionSheet.delegate = self
        actionSheet.showInView(self.view.window)
        
        let indexPath = tableView.indexPathForCell(sender)
        actionSheetTargetTrack = tracks[indexPath!.row]
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
        
        if buttonIndex < 3 && track == nil || foundIdx == -1 {
            ViewUtils.showToast(self, message: "Track is not in feed")
            return
        }
        
        switch(buttonIndex) {
        case 0:
            onTrackAddBtnClicked(track!)
            break
        case 1:
            onTrackShareBtnClicked(track!)
            break
        default:
            break
        }
        actionSheetTargetTrack = nil
    }
    
    func loadGenres(callback:(error:NSError?) -> Void) {
        let progressHud = ViewUtils.showProgress(self, message: "Loading..")
        Requests.getFeedGenre({ (req: NSURLRequest, resp:NSHTTPURLResponse?, result:AnyObject?, error: NSError?) -> Void in
            progressHud.hide(true)
            if (error != nil || result == nil) {
                callback(error:error != nil ? error : NSError(domain:"loadGenre", code:0, userInfo:nil))
                return
            }
            
            let parser = Parser()
            let genreList = parser.parseGenre(result!)
            if !genreList.success {
                callback(error:NSError(domain: "initGenre", code:0, userInfo:nil))
                return
            }
            
            self.genres.removeAll(keepCapacity: false)
            for genre in genreList.results!["channel"]! {
                self.genres.append(genre)
            }
            self.genreTableView.reloadData()
            callback(error:nil)
        })
    }
    
    func loadBookmarks(refreshFeed:Bool=false) {
        if (Account.getCachedAccount() == nil) {
            return
        }
        let progressHud = ViewUtils.showProgress(self, message: "Loading..")
        Requests.getBookmarkList({ (req: NSURLRequest, resp:NSHTTPURLResponse?, result:AnyObject?, error: NSError?) -> Void in
            
            progressHud.hide(true)
            if (error != nil || result == nil) {
                if (error != nil && error!.domain == NSURLErrorDomain &&
                        error!.code == NSURLErrorNotConnectedToInternet) {
                    ViewUtils.showNoticeAlert(self, title: "Failed to fetch bookmark", message: "Internet is not connected")
                    return
                }
                var message = "Failed to fetch bookmarks."
                ViewUtils.showNoticeAlert(self, title: "Failed to fetch", message: message)
                return
            }
            
            var json = JSON(result!)
            var data = json["bookmark"]
            var bookmarkIds = Set<String>()
            for (idx:String, s: JSON) in data {
                bookmarkIds.insert(s.stringValue)
            }
            
            self.bookmarkedChannels.removeAll(keepCapacity: false)
            for (uid:String, channel:Channel) in self.allChannels {
                if bookmarkIds.contains(channel.uid!) {
                    channel.isBookmarked = true
                    self.bookmarkedChannels.append(channel)
                } else {
                    channel.isBookmarked = false
                }
            }
            
            if self.selectedTabIdx == 0 {
                self.noBookmarkView.hidden = self.bookmarkedChannels.count != 0
                if self.bookmarkedChannels.count != 0 {
                    self.tableView.tableHeaderView = self.bookmarkListHeader
                } else {
                    self.tableView.tableHeaderView = nil
                }
                if refreshFeed && self.bookmarkedChannels.count != 0 {
                    self.nextPage = 0
                    self.tracks.removeAll(keepCapacity: false)
                    self.tableView.reloadData()
                    self.loadChannelFeed(self.nextPage)
                }
            } else {
                self.tableView.reloadData()
            }
        })
    }
    
    func createBookmarkListHeader() -> UIView {
        let cellWidth:CGFloat = self.view.bounds.width
        let cellHeight:CGFloat = 60.0
        let btnWidth:CGFloat = 200.0
        let btnHeight:CGFloat = 32.0
        let frame = UIView(frame: CGRectMake(0, 0, cellWidth, cellHeight))
        let btn:UIButton = UIButton(frame: CGRectMake((cellWidth - btnWidth) / 2,
            (cellHeight - btnHeight) / 2, btnWidth, btnHeight))
        btn.layer.cornerRadius = 3.0
        btn.layer.borderWidth = 1.0
        btn.layer.borderColor = UIColor(netHex: 0x8F2CEF).CGColor
        btn.setTitle("MY BOOKMARK LIST", forState: UIControlState.Normal)
        btn.setTitleColor(UIColor(netHex: 0x8F2CEF), forState: UIControlState.Normal)
        btn.titleLabel?.textAlignment = NSTextAlignment.Center
        btn.titleLabel?.font = UIFont.systemFontOfSize(14.0)
        btn.addTarget(self, action: "onBookmarkListBtnClicked:", forControlEvents: UIControlEvents.TouchUpInside)
        
        frame.addSubview(btn)
        return frame
    }
    
    func loadChannels(genre: Genre, initialLoad:Bool) {
        let progressHud = ViewUtils.showProgress(self, message: "Loading..")
        
        selectedGenre = genre
        
        emptyChannelView.hidden = true
        updateGenreSelectBtnView(genre.name)
        
        var genreKey = genre.name.lowercaseString
        if count(genreKey) == 0 {
            genreKey = "all"
        }
        
        Requests.getChannelList(genreKey, respCb: {
                (req: NSURLRequest, resp:NSHTTPURLResponse?, result:AnyObject?, error: NSError?) -> Void in
            progressHud.hide(true)
            if (error != nil || result == nil) {
                if (error != nil && error!.domain == NSURLErrorDomain &&
                        error!.code == NSURLErrorNotConnectedToInternet) {
                    ViewUtils.showNoticeAlert(self, title: "Failed to fetch channels", message: "Internet is not connected")
                    return
                }
                var message = "Failed to fetch channels."
                ViewUtils.showNoticeAlert(self, title: "Failed to fetch", message: message)
                return
            }
            self.channels.removeAll(keepCapacity: false)
            var channels = Channel.fromListJson(result!, key: "data")
            if initialLoad {
                for channel in channels {
                    self.allChannels[channel.uid!] = channel
                }
            }
            
            for channel in channels {
                if let c = self.allChannels[channel.uid!] {
                    self.channels.append(c)
                }
            }
            
            self.channelLoaded = true
            
            if initialLoad {
                if Account.getCachedAccount() != nil {
                    self.loadBookmarks(refreshFeed: true)
                } else if self.selectedTabIdx == 0 {
                    self.needSigninView.hidden = false
                }
            } else if self.selectedTabIdx == 1{
                self.tableView.reloadData()
            }
            if !self.isGenreSelectMode && self.selectedTabIdx == 1 {
                self.emptyChannelView.hidden = self.channels.count != 0
            }
        })
    }
    
    @IBAction func onSigninBtnClicked(sender: AnyObject) {
        var appDelegate:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        var centerViewController = appDelegate.centerContainer!
        centerViewController.showSigninView()
    }
    
    @IBAction func onGenreSelectBtnClicked(sender: AnyObject) {
        if isGenreSelectMode {
            toNonGenreSelectMode()
        } else {
            toGenreSelectMode()
        }
    }
    
    @IBAction func onFindChannelBtnClicked(sender: AnyObject) {
        pager.setSelectedIndex(1, animated: true, moveScrollView: true)
        scrollPager(pager, changedIndex: 1)
    }
    
    func onBookmarkListBtnClicked(sender: AnyObject) {
        performSegueWithIdentifier("BookmarkListSegue", sender: nil)
    }
    
    func toGenreSelectMode() {
        isGenreSelectMode = true
        tableView.hidden = true
        genreTableView.hidden = false
        emptyChannelView.hidden = true
        genreSelectBtn.setImage(UIImage(named:"ic_arrow_up.png"), forState: UIControlState.Normal)
    }
    
    func toNonGenreSelectMode() {
        isGenreSelectMode = false
        tableView.hidden = false
        genreTableView.hidden = true
        emptyChannelView.hidden = selectedTabIdx == 0 || channels.count != 0
        needSigninView.hidden = selectedTabIdx != 0 || Account.getCachedAccount() != nil
        genreSelectBtn.setImage(UIImage(named:"ic_arrow_down.png"), forState: UIControlState.Normal)
    }
    
    func onBookmarkBtnClicked(sender: ChannelTableViewCell) {
        let indexPath:NSIndexPath = tableView.indexPathForCell(sender)!
        if (Account.getCachedAccount() == nil) {
            var appDelegate:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            var centerViewController = appDelegate.centerContainer!
            centerViewController.showSigninView()
            return
        }
        var channel = channels[indexPath.row]
        var newBookmarkedIds: [String]?
        var newChannels = [Channel]()
        if (channel.isBookmarked) {
            for c in bookmarkedChannels {
                if (c.uid != channel.uid) {
                    newChannels.append(c)
                }
            }
        } else {
            for c in bookmarkedChannels {
                newChannels.append(c)
            }
            newChannels.append(channel)
        }
        newBookmarkedIds = newChannels.map({ (c:Channel) -> String in
            return c.uid!
        })
        let progressHud = ViewUtils.showProgress(self, message: "Saving..")
        Requests.updateBookmarkList(newBookmarkedIds!, respCb:{
                (req:NSURLRequest, resp:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            progressHud.hide(false)
            if (error != nil || result == nil) {
                if (error != nil && error!.domain == NSURLErrorDomain &&
                        error!.code == NSURLErrorNotConnectedToInternet) {
                    ViewUtils.showNoticeAlert(self, title: "Failed to update bookmarks", message: "Internet is not connected")
                    return
                }
                var message = "Failed to update bookmarks."
                ViewUtils.showNoticeAlert(self, title: "Failed to update", message: message)
                return
            }
            self.bookmarkedChannels = newChannels
            for channel in self.channels {
                channel.isBookmarked = false
            }
            for channel in self.bookmarkedChannels {
                channel.isBookmarked = true
            }
            
            if self.selectedTabIdx == 1 {
                self.tableView.reloadData()
            }
        })
    }
    
    func loadChannelFeed(pageIdx: Int) {
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
        if pageIdx == 0 {
            progressHud = ViewUtils.showProgress(self, message: "Loading..")
            tableView.scrollsToTop = true
        }
        Requests.fetchChannelFeed(pageIdx, respCb: {
                (req:NSURLRequest, resp:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            progressHud?.hide(false)
            self.isLoading = false
            if (error != nil || result == nil) {
                if (error != nil && error!.domain == NSURLErrorDomain &&
                        error!.code == NSURLErrorNotConnectedToInternet) {
                    ViewUtils.showNoticeAlert(self, title: "Failed to load", message: "Internet is not connected")
                    return
                }
                var message = "Failed to load channel feed."
                ViewUtils.showNoticeAlert(self, title: "Failed to load", message: message)
                return
            }
            
            let respObj = JSON(result!)
            if !(respObj["success"].bool ?? false) {
                var message = "Failed to load channel feed."
                ViewUtils.showNoticeAlert(self, title: "Failed to load", message: message)
                return
            }
            
            var particals = [ChannelFeedTrack]()
            for (idx:String, s:JSON) in respObj["data"] {
                if s["video_id"].string == nil {
                    continue
                }
                let id = s["video_id"].stringValue
                
                if s["title"].string == nil {
                    continue
                }
                let title = s["title"].stringValue
                
                if s["channel_title"].string == nil {
                    continue
                }
                let channelTitle = s["channel_title"].stringValue
                
                if s["published_at"].string == nil {
                    continue
                }
                var publishedAt = self.dateFormatter.dateFromString(s["published_at"].stringValue)
                if publishedAt == nil {
                    continue
                }
                
                let track = ChannelFeedTrack(
                    id: id, title: title, publishedAt: publishedAt,
                    channelTitle: channelTitle)
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
            
            for track in particals {
                self.tracks.append(track)
            }
            self.updatePlaylist(false)
            
            if self.selectedTabIdx == 0 {
                self.tableView.reloadData()
                self.updatePlay(PlayerContext.currentTrack, playlistId: PlayerContext.currentPlaylistId)
            }
        })
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ShowChannelSegue" {
            if let destination = segue.destinationViewController as? ChannelDetailViewController {
                if let idx = tableView.indexPathForSelectedRow()?.row {
                    let channel = channels[idx]
                    destination.channelUid = channel.uid
                    destination.channelName = channel.name
                }
            }
        }
        if segue.identifier == "PlaylistSelectSegue" {
            let playlistSelectVC:PlaylistSelectViewController = segue.destinationViewController as! PlaylistSelectViewController
            playlistSelectVC.targetTrack = sender as? Track
            playlistSelectVC.fromSection = "search"
            playlistSelectVC.caller = self
        }
        
        if segue.identifier == "BookmarkListSegue" {
            let bookmarkListVC:BookmarkListViewController = segue.destinationViewController as! BookmarkListViewController
            bookmarkListVC.channels = self.allChannels
        }
    }
    
    func updatePlay(noti: NSNotification) {
        var params = noti.object as! Dictionary<String, AnyObject>
        var track = params["track"] as! Track
        var playlistId:String? = params["playlistId"] as? String
        
        updatePlay(track, playlistId: playlistId)
    }
    
    func updatePlay(track:Track?, playlistId: String?) {
        if (track == nil || selectedTabIdx != 0) {
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
    
}
