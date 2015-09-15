//
//  ChannelViewController.swift
//  labs
//
//  Created by vulpes on 2015. 7. 25..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

class ChannelViewController: AddableTrackListViewController,
        UITableViewDelegate, UITableViewDataSource, ScrollPagerDelegate, ChannelTableViewCellDelegate, AddableTrackCellDelegate,
            UIActionSheetDelegate,
            UIScrollViewDelegate{
    
    @IBOutlet weak var signinBtn: UIButton!
    @IBOutlet weak var signupBtn: UIButton!
    @IBOutlet weak var needSigninScrollInnerConstaint: NSLayoutConstraint!
    @IBOutlet weak var needSigninScrollView: UIScrollView!
    @IBOutlet weak var noBookmarkView: UIView!
    @IBOutlet weak var loadMoreSpinner: UIActivityIndicatorView!
    @IBOutlet weak var loadMoreSpinnerWrapper: UIView!
    @IBOutlet weak var genreSelectBtn: UIButton!
    @IBOutlet weak var genreTableView: UITableView!
    @IBOutlet weak var genreSelectorWrapper: UIView!
    @IBOutlet weak var pager: ScrollPager!
    @IBOutlet weak var genreSelectorConstraint: NSLayoutConstraint!
    @IBOutlet weak var genreSelectorWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var emptyChannelView: UILabel!
    
    private var allChannels : [String:Channel] = [String:Channel]()
    private var channels : [Channel] = [Channel]()
    private var bookmarkedChannels : [Channel] = [Channel]()
    private var genres : [Genre] = []
    
    private var selectedTabIdx = 0
    private var channelLoaded = false
    private var genreLoaded = false
    private var isGenreSelectMode = false
    private var selectedGenre:Genre?
    private var nextPage:Int = 0
    private var isLoading:Bool = false
    private var bookmarkListHeader:UIView?
    private var refreshControl:UIRefreshControl!
    
    private var dateFormatter:NSDateFormatter {
        var formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.000Z"
        return formatter
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pager.font = UIFont.systemFontOfSize(11)
        pager.selectedFont = UIFont.systemFontOfSize(11)
        
        needSigninScrollInnerConstaint.constant = self.view.bounds.width
        
        pager.delegate = self
        pager.addSegmentsWithTitles(["FEED", "CHANNELS"])
        pager.reloadInputViews()
        
        genreSelectorConstraint.constant = 0
        genreSelectorWrapper.hidden = true
        
        signinBtn.layer.cornerRadius = 3.0
        signinBtn.layer.borderWidth = 1
        signinBtn.layer.borderColor = UIColor.dropbeatColor().CGColor
        
        signupBtn.layer.cornerRadius = 3.0
        signupBtn.layer.borderWidth = 1
        signupBtn.layer.borderColor = UIColor.dropbeatColor().CGColor
        
        
        needSigninScrollView.hidden = Account.getCachedAccount() != nil
        
        bookmarkListHeader = createBookmarkListHeader()
        
        refreshControl = UIRefreshControl()
        refreshControl.tintColor = UIColor(netHex:0xc380fc)
        refreshControl.addTarget(self, action: "refresh", forControlEvents: UIControlEvents.ValueChanged)
        
        let refreshControlTitle = NSAttributedString(
            string: NSLocalizedString("Pull to refresh", comment: ""),
            attributes: [NSForegroundColorAttributeName: UIColor(netHex: 0x909090)])
        refreshControl.attributedTitle = refreshControlTitle
        trackTableView.insertSubview(refreshControl, atIndex: 0)
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        scrollView.contentOffset = CGPointMake(0, scrollView.contentOffset.y)
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
                trackTableView.tableHeaderView = nil
            }
            loadBookmarks(refreshFeed: true)
            if refreshControl.superview == nil {
                trackTableView.insertSubview(refreshControl, atIndex: 0)
            }
        } else {
            genreSelectorConstraint.constant = 40
            genreSelectorWrapper.hidden = false
            noBookmarkView.hidden = true
            if (channelLoaded) {
                loadBookmarks()
            } else {
                loadChannels(genres[0], initialLoad: true)
            }
            trackTableView.tableHeaderView = nil
            refreshControl.removeFromSuperview()
        }
        loadMoreSpinnerWrapper.hidden = true
        loadMoreSpinner.stopAnimating()
        trackTableView.reloadData()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.screenName = "ChannelViewScreen"
        
        if trackTableView.indexPathForSelectedRow() != nil {
            trackTableView.deselectRowAtIndexPath(trackTableView.indexPathForSelectedRow()!, animated: false)
        }
        
        if !genreLoaded {
           loadGenres({ (error) -> Void in
                if error != nil {
                    ViewUtils.showNoticeAlert(self,
                        title: NSLocalizedString("Failed to load", comment:""),
                        message: NSLocalizedString("Failed to initalize genre", comment:""))
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
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func appWillEnterForeground() {
        if (channelLoaded) {
            loadBookmarks(refreshFeed: true)
        } else {
            loadChannels(genres[0], initialLoad: true)
        }
        super.appWillEnterForeground()
    }
    
    func sender () {}
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getChannelInfoCell(indexPath:NSIndexPath) -> UITableViewCell {
        let cell:ChannelTableViewCell = trackTableView.dequeueReusableCellWithIdentifier(
                "ChannelTableViewCell", forIndexPath: indexPath) as! ChannelTableViewCell
        cell.delegate = self
        
        var channel: Channel = channels[indexPath.row]
        if (channel.image != nil) {
            cell.thumbView.sd_setImageWithURL(
                NSURL(string: channel.image!),
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
        let cell:AddableChannelFeedTrackTableViewCell = trackTableView.dequeueReusableCellWithIdentifier(
                "AddableTrackTableViewCell", forIndexPath: indexPath) as!AddableChannelFeedTrackTableViewCell
        let track:ChannelFeedTrack = tracks[indexPath.row] as! ChannelFeedTrack
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
                
        if tableView == self.trackTableView {
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
        if tableView == self.trackTableView {
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
        if tableView != self.trackTableView || selectedTabIdx != 0 || tracks.count == 0 {
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
        if tableView == self.trackTableView {
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
    
    override func getPlaylistId() -> String? {
        var seed = ""
        for channel in bookmarkedChannels {
            seed += channel.id!
        }
        return "seed_\(seed.md5)"
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
    
    override func getSectionName() -> String {
        return "channel_feed"
    }
    
    func refresh() {
        nextPage = 0
        loadChannelFeed(nextPage, forceRefresh: true)
    }
    
    func loadGenres(callback:(error:NSError?) -> Void) {
        let genreHandler = { (genreMap:[String:[Genre]]) -> Void in
            self.genres.removeAll(keepCapacity: false)
            for genre in genreMap["channel"]! {
                self.genres.append(genre)
            }
            self.genreTableView.reloadData()
            callback(error:nil)
        }
        
        if let cachedGenreMap = GenreList.cachedResult {
            genreHandler(cachedGenreMap)
            return
        }
        
        let progressHud = ViewUtils.showProgress(self, message: NSLocalizedString("Loading..", comment:""))
        Requests.getFeedGenre({ (req: NSURLRequest, resp:NSHTTPURLResponse?, result:AnyObject?, error: NSError?) -> Void in
            progressHud.hide(true)
            if (error != nil || result == nil) {
                callback(error:error != nil ? error : NSError(domain:"loadGenre", code:0, userInfo:nil))
                return
            }
            
            let genreList = GenreList.parseGenre(result!)
            if !genreList.success {
                callback(error:NSError(domain: "initGenre", code:0, userInfo:nil))
                return
            }
            genreHandler(genreList.results!)
        })
    }
    
    func loadBookmarks(refreshFeed:Bool=false) {
        if (Account.getCachedAccount() == nil) {
            return
        }
        let progressHud = ViewUtils.showProgress(self, message: NSLocalizedString("Loading..", comment:""))
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
                var message = NSLocalizedString("Failed to fetch bookmark", comment:"")
                ViewUtils.showNoticeAlert(self, title: NSLocalizedString("Failed to fetch", comment:""), message: message)
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
                if bookmarkIds.contains(channel.id!) {
                    channel.isBookmarked = true
                    self.bookmarkedChannels.append(channel)
                } else {
                    channel.isBookmarked = false
                }
            }
            
            if self.selectedTabIdx == 0 {
                self.noBookmarkView.hidden = self.bookmarkedChannels.count != 0
                if self.bookmarkedChannels.count != 0 {
                    self.trackTableView.beginUpdates()
                    self.trackTableView.tableHeaderView = self.bookmarkListHeader
                    self.trackTableView.endUpdates()
                } else {
                    self.trackTableView.tableHeaderView = nil
                }
                if refreshFeed && self.bookmarkedChannels.count != 0 {
                    self.nextPage = 0
                    self.tracks.removeAll(keepCapacity: false)
                    self.trackTableView.reloadData()
                    self.loadChannelFeed(self.nextPage)
                }
            } else {
                self.trackTableView.reloadData()
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
        btn.setTitle(NSLocalizedString("MY BOOKMARK LIST", comment:""), forState: UIControlState.Normal)
        btn.setTitleColor(UIColor(netHex: 0x8F2CEF), forState: UIControlState.Normal)
        btn.titleLabel?.textAlignment = NSTextAlignment.Center
        btn.titleLabel?.font = UIFont.systemFontOfSize(14.0)
        btn.addTarget(self, action: "onBookmarkListBtnClicked:", forControlEvents: UIControlEvents.TouchUpInside)
        
        frame.addSubview(btn)
        frame.backgroundColor = UIColor.whiteColor()
        return frame
    }
    
    func loadChannels(genre: Genre, initialLoad:Bool) {
        let progressHud = ViewUtils.showProgress(self, message: NSLocalizedString("Loading..", comment:""))
        
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
                    ViewUtils.showNoticeAlert(self,
                        title: NSLocalizedString("Failed to fetch channels", comment:""),
                        message: NSLocalizedString("Internet is not connected", comment:""))
                    return
                }
                var message = NSLocalizedString("Failed to fetch channels.", comment:"")
                ViewUtils.showNoticeAlert(self, title: NSLocalizedString("Failed to fetch", comment:""), message: message)
                return
            }
            self.channels.removeAll(keepCapacity: false)
            var channels = Channel.parseChannelList(result!)
            if initialLoad {
                for channel in channels {
                    self.allChannels[channel.id!] = channel
                }
            }
            
            for channel in channels {
                if let c = self.allChannels[channel.id!] {
                    self.channels.append(c)
                }
            }
            
            self.channelLoaded = true
            
            if initialLoad {
                if Account.getCachedAccount() != nil {
                    self.loadBookmarks(refreshFeed: true)
                } else if self.selectedTabIdx == 0 {
                    self.needSigninScrollView.hidden = false
                }
            } else if self.selectedTabIdx == 1{
                self.trackTableView.reloadData()
            }
            if !self.isGenreSelectMode && self.selectedTabIdx == 1 {
                self.emptyChannelView.hidden = self.channels.count != 0
            }
        })
    }
    
    @IBAction func onGenreSelectBtnClicked(sender: AnyObject) {
        if isGenreSelectMode {
            toNonGenreSelectMode()
        } else {
            toGenreSelectMode()
        }
    }
    
    @IBAction func onFindChannelBtnClicked(sender: AnyObject) {
        pager.setSelectedIndex(1, animated: true)
        scrollPager(pager, changedIndex: 1)
    }
    
    func onBookmarkListBtnClicked(sender: AnyObject) {
        performSegueWithIdentifier("BookmarkListSegue", sender: nil)
    }
    
    func toGenreSelectMode() {
        isGenreSelectMode = true
        trackTableView.hidden = true
        genreTableView.hidden = false
        emptyChannelView.hidden = true
        genreSelectBtn.setImage(UIImage(named:"ic_arrow_up.png"), forState: UIControlState.Normal)
    }
    
    func toNonGenreSelectMode() {
        isGenreSelectMode = false
        trackTableView.hidden = false
        genreTableView.hidden = true
        emptyChannelView.hidden = selectedTabIdx == 0 || channels.count != 0
        needSigninScrollView.hidden = selectedTabIdx != 0 || Account.getCachedAccount() != nil
        genreSelectBtn.setImage(UIImage(named:"ic_arrow_down.png"), forState: UIControlState.Normal)
    }
    
    func onBookmarkBtnClicked(sender: ChannelTableViewCell) {
        let indexPath:NSIndexPath = trackTableView.indexPathForCell(sender)!
        if (Account.getCachedAccount() == nil) {
            NeedAuthViewController.showNeedAuthViewController(self)
            return
        }
        var channel = channels[indexPath.row]
        var newBookmarkedIds: [String]?
        var newChannels = [Channel]()
        if (channel.isBookmarked) {
            for c in bookmarkedChannels {
                if (c.id != channel.id) {
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
            return c.id!
        })
        let progressHud = ViewUtils.showProgress(self, message: NSLocalizedString("Saving..", comment:""))
        Requests.updateBookmarkList(newBookmarkedIds!, respCb:{
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
                var message = "Failed to update bookmarks."
                ViewUtils.showNoticeAlert(self,
                    title: NSLocalizedString("Failed to update", comment:""), message: message)
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
                self.trackTableView.reloadData()
            }
        })
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
        Requests.fetchChannelFeed(pageIdx, respCb: {
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
                var message = "Failed to load channel feed."
                ViewUtils.showNoticeAlert(self, title: NSLocalizedString("Failed to load", comment:""), message: message)
                return
            }
            
            let respObj = JSON(result!)
            if !(respObj["success"].bool ?? false) {
                var message = NSLocalizedString("Failed to load channel feed.", comment:"")
                ViewUtils.showNoticeAlert(self, title: NSLocalizedString("Failed to load", comment:""), message: message)
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
            
            if forceRefresh {
                self.tracks.removeAll(keepCapacity: false)
            }
            
            for track in particals {
                self.tracks.append(track)
            }
            self.updatePlaylist(false)
            
            if self.selectedTabIdx == 0 {
                self.trackTableView.reloadData()
                self.updatePlay(PlayerContext.currentTrack, playlistId: PlayerContext.currentPlaylistId)
            }
        })
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ShowChannelSegue" {
            if let destination = segue.destinationViewController as? ChannelDetailViewController {
                if let idx = trackTableView.indexPathForSelectedRow()?.row {
                    let channel = channels[idx]
                    destination.channelUid = channel.id
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
    
}


//
//  ChannelDetailViewController.swift
//  labs
//
//  Created by vulpes on 2015. 7. 26..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

class ChannelDetailViewController: AddableTrackListViewController,
        UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var channelInfoView: UIView!
    @IBOutlet weak var sectionSelector: UIButton!
    @IBOutlet weak var sectionSelectorWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var bookmarkBtn: UIButton!
    @IBOutlet weak var genreView: UILabel!
    @IBOutlet weak var nameView: UILabel!
    @IBOutlet weak var thumbView: UIImageView!
    @IBOutlet weak var sectionSelectTableView: UITableView!
    @IBOutlet weak var loadMoreSpinnerWrapper: UIView!
    @IBOutlet weak var loadMoreSpinner: UIActivityIndicatorView!
    
    private var refreshControl:UIRefreshControl!
    private var isLoading:Bool = false
    private var listEnd:Bool = false
    private var currSection:ChannelPlaylist?
    private var sectionSelectMode = false
    private var nextPageToken:String?
    private var channel:Channel?
    private var bookmarkedIds: [String] = [String]()
    private var dateFormatter:NSDateFormatter {
        var formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.000Z"
        return formatter
    }
    var channelUid:String?
    var channelName: String?

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
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.screenName = "ChannelDetailScreen"
        if channel == nil {
            loadChannel()
        } else {
            loadBookmarks()
        }
    }
    
    override func appWillEnterForeground() {
        if channel != nil {
            loadBookmarks()
            if currSection != nil {
                selectSection(currSection!)
            }
        }
        super.appWillEnterForeground()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func getPlaylistId() -> String? {
        if channel == nil || currSection == nil {
            return nil
        }
        return "channel_playlist_\(channel!.id)_\(currSection!.uid)"
    }
    
    override func getPlaylistName() -> String? {
        return channel?.name ?? NSLocalizedString("Channel", comment:"")
    }
    
    override func getSectionName() -> String {
        return "channel_detail"
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "PlaylistSelectSegue" {
            let playlistSelectVC:PlaylistSelectViewController = segue.destinationViewController as! PlaylistSelectViewController
            playlistSelectVC.targetTrack = sender as? Track
            playlistSelectVC.fromSection = "feed"
            playlistSelectVC.caller = self
        }
    }
    
    func sender () {}
    
    func selectSection (playlist: ChannelPlaylist) {
        updateSectionSelectBtnView(playlist.name)
        currSection = playlist
        nextPageToken = nil
        listEnd = false
        trackTableView.setContentOffset(CGPointZero, animated:false)
        self.loadTracks(playlist.uid, pageToken: nextPageToken)
    }
    
    func loadChannel() {
        self.channelInfoView.hidden = true
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
            
            self.channel = Channel.parseChannel(result!)
            if (self.channel == nil) {
                var message = NSLocalizedString("Failed to fetch channel info.", comment:"")
                ViewUtils.showNoticeAlert(self, title: NSLocalizedString("Failed to fetch", comment:""), message: message)
                return
            }
            self.channel!.id = self.channelUid
            self.genreView.text = ", ".join(self.channel!.genre)
            self.nameView.text = self.channel!.name
            if (self.channel!.image != nil) {
                self.thumbView.sd_setImageWithURL(NSURL(string:self.channel!.image!),
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
                var message = NSLocalizedString("Failed to fetch bookmark", comment:"")
                ViewUtils.showNoticeAlert(self, title: NSLocalizedString("Failed to fetch", comment:""), message: message)
                return
            }
            
            var json = JSON(result!)
            var data = json["bookmark"]
            self.bookmarkedIds.removeAll(keepCapacity: false)
            for (idx:String, s: JSON) in data {
                self.bookmarkedIds.append(s.stringValue)
            }
            self.channel!.isBookmarked = find(self.bookmarkedIds, self.channel!.id!) != nil
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
            self.trackTableView.reloadData()
            self.updatePlay(PlayerContext.currentTrack, playlistId: PlayerContext.currentPlaylistId)
        }
    }
    
    func switchToSectionSelectMode() {
        sectionSelectMode = true
        self.trackTableView.hidden = true
        self.sectionSelectTableView.hidden = false
        sectionSelector.setImage(UIImage(named: "ic_arrow_up.png"), forState: UIControlState.Normal)
    }
    
    func switchToNonSectionSelectMode() {
        sectionSelectMode = false
        self.trackTableView.hidden = false
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
            NeedAuthViewController.showNeedAuthViewController(self)
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
            if (isAdding && find(self.bookmarkedIds, self.channel!.id!) == nil) {
                self.bookmarkedIds.append(self.channel!.id!)
            } else if (!isAdding) {
                let idx = find(self.bookmarkedIds, self.channel!.id!)
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
        if tableView != self.trackTableView || tracks.count == 0 {
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
        if tableView == self.trackTableView {
            let cell:AddableChannelTrackTableViewCell = trackTableView.dequeueReusableCellWithIdentifier(
                    "AddableTrackTableViewCell", forIndexPath: indexPath) as!AddableChannelTrackTableViewCell
            let track:ChannelTrack = tracks[indexPath.row] as! ChannelTrack
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
        if tableView == self.trackTableView {
            onTrackPlayBtnClicked(tracks[indexPath.row])
        } else {
            switchToNonSectionSelectMode()
            selectSection(self.channel!.playlists[indexPath.row])
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.trackTableView {
            return tracks.count
        }
        return self.channel?.playlists.count ?? 0
    }
}


//
//  BookmarkListViewController.swift
//  labs
//
//  Created by vulpes on 2015. 8. 1..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

class BookmarkListViewController: BaseViewController,
UITableViewDelegate, UITableViewDataSource, ChannelTableViewCellDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var noBookmarkView: UILabel!
    
    var channels : [String:Channel]!
    var bookmarkedChannels : [Channel] = [Channel]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.screenName = "bookmarkListScreen"
        
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "appWillEnterForeground",
            name: UIApplicationWillEnterForegroundNotification, object: nil)
        
        loadBookmarks()
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self,
            name: UIApplicationWillEnterForegroundNotification, object: nil)
    }
    
    func appWillEnterForeground() {
        loadBookmarks()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ShowChannelSegue" {
            if let destination = segue.destinationViewController as? ChannelDetailViewController {
                if let idx = tableView.indexPathForSelectedRow()?.row {
                    let channel = bookmarkedChannels[idx]
                    destination.channelUid = channel.id
                    destination.channelName = channel.name
                }
            }
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell:ChannelTableViewCell = tableView.dequeueReusableCellWithIdentifier(
            "ChannelTableViewCell", forIndexPath: indexPath) as! ChannelTableViewCell
        cell.delegate = self
        
        var channel: Channel = bookmarkedChannels[indexPath.row]
        if (channel.image != nil) {
            cell.thumbView.sd_setImageWithURL(
                NSURL(string: channel.image!),
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
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bookmarkedChannels.count
    }
    
    func loadBookmarks(refreshFeed:Bool=false) {
        if (Account.getCachedAccount() == nil) {
            return
        }
        
        let progressHud = ViewUtils.showProgress(self, message: NSLocalizedString("Loading..", comment:""))
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
                var message = NSLocalizedString("Failed to fetch bookmark", comment:"")
                ViewUtils.showNoticeAlert(self, title: NSLocalizedString("Failed to fetch", comment:""), message: message)
                return
            }
            
            var json = JSON(result!)
            var data = json["bookmark"]
            var bookmarkIds = Set<String>()
            for (idx:String, s: JSON) in data {
                bookmarkIds.insert(s.stringValue)
            }
            
            self.bookmarkedChannels.removeAll(keepCapacity: false)
            for (uid:String, channel:Channel) in self.channels! {
                channel.isBookmarked = bookmarkIds.contains(channel.id!)
                if channel.isBookmarked {
                    self.bookmarkedChannels.append(channel)
                }
            }
            self.bookmarkedChannels.sort({ (lhs:Channel, rhs:Channel) -> Bool in
                return lhs.idx! < rhs.idx!
            })
            self.noBookmarkView.hidden = self.bookmarkedChannels.count != 0
            self.tableView.reloadData()
        })
    }
    
    func onBookmarkBtnClicked(sender: ChannelTableViewCell) {
        let indexPath:NSIndexPath = tableView.indexPathForCell(sender)!
        if (Account.getCachedAccount() == nil) {
            NeedAuthViewController.showNeedAuthViewController(self)
            return
        }
        var channel = bookmarkedChannels[indexPath.row]
        var newBookmarkedIds = Set<String>()
        var newChannels = [Channel]()
        if (channel.isBookmarked) {
            for c in bookmarkedChannels {
                if (c.id != channel.id) {
                    newBookmarkedIds.insert(c.id!)
                }
            }
        } else {
            for c in bookmarkedChannels {
                newBookmarkedIds.insert(c.id!)
            }
            newBookmarkedIds.insert(channel.id!)
        }
        let progressHud = ViewUtils.showProgress(self, message: NSLocalizedString("Saving..", comment:""))
        Requests.updateBookmarkList(Array(newBookmarkedIds), respCb:{
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
                ViewUtils.showNoticeAlert(self, title: NSLocalizedString("Failed to update", comment:""), message: message)
                return
            }
            self.bookmarkedChannels.removeAll(keepCapacity: false)
            for (uid:String, channel:Channel) in self.channels! {
                channel.isBookmarked = newBookmarkedIds.contains(uid)
                if channel.isBookmarked {
                    self.bookmarkedChannels.append(channel)
                }
            }
            self.bookmarkedChannels.sort({ (lhs:Channel, rhs:Channel) -> Bool in
                return lhs.idx! < rhs.idx!
            })
            self.tableView.reloadData()
        })
    }
}
