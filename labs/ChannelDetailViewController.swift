//
//  ChannelDetailViewController.swift
//  labs
//
//  Created by vulpes on 2015. 7. 26..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

class ChannelTrack : Track {
    var publishedAt : NSDate?
    init (id:String, title:String, publishedAt:NSDate?) {
        super.init(id: id, title: title, type: "youtube", tag: nil,
            thumbnailUrl: "http://img.youtube.com/vi/\(id)/mqdefault.jpg",
            drop: nil, dref: nil, topMatch: false)
        self.publishedAt = publishedAt
    }
}


class ChannelDetailViewController: BaseViewController,
        UITableViewDelegate, UITableViewDataSource, AddableTrackCellDelegate{
    
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
    
    var isLoading:Bool = false
    var listEnd:Bool = false
    var currSection:ChannelPlaylist?
    var sectionSelectMode = false
    var nextPageToken:String?
    var channelUid:String?
    var channelName: String?
    var channel:Channel?
    var bookmarkedIds: [String] = [String]()
    var tracks:[ChannelTrack] = [ChannelTrack]()
    var dateFormatter:NSDateFormatter {
        var formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.000Z"
        return formatter
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "updatePlay:", name: NotifyKey.updatePlay, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "sender", name: NotifyKey.playerPlay, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "appWillEnterForeground",
            name: UIApplicationWillEnterForegroundNotification, object: nil)
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
    
    func appWillEnterForeground() {
        if channel != nil {
            loadBookmarks()
            if currSection != nil {
                selectSection(currSection!)
            }
        }
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
        let progressHud = ViewUtils.showProgress(self, message: "loading channel info..")
        Requests.getChannelDetail(channelUid!, respCb: {
                (req:NSURLRequest, resp: NSHTTPURLResponse?, result: AnyObject?, error:NSError?) -> Void in
            progressHud.hide(false)
            if (error != nil || result == nil) {
                if (error != nil && error!.domain == NSURLErrorDomain &&
                        error!.code == NSURLErrorNotConnectedToInternet) {
                    ViewUtils.showNoticeAlert(self, title: "Failed to fetch channel info", message: "Internet is not connected")
                    return
                }
                var message = "Failed to fetch channel info caused by undefined error."
                ViewUtils.showNoticeAlert(self, title: "Failed to fetch", message: message)
                return
            }
            
            self.channel = Channel.fromDetailJson(result!, key: "data")
            if (self.channel == nil) {
                var message = "Failed to fetch channel info caused by undefined error."
                ViewUtils.showNoticeAlert(self, title: "Failed to fetch", message: message)
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
        let progressHud = ViewUtils.showProgress(self, message: "loading bookmarks..")
        Requests.getBookmarkList({ (req: NSURLRequest, resp:NSHTTPURLResponse?, result:AnyObject?, error: NSError?) -> Void in
            progressHud.hide(true)
            if (error != nil || result == nil) {
                if (error != nil && error!.domain == NSURLErrorDomain &&
                        error!.code == NSURLErrorNotConnectedToInternet) {
                    ViewUtils.showNoticeAlert(self, title: "Failed to fetch bookmark", message: "Internet is not connected")
                    return
                }
                var message = "Failed to fetch bookmarks caused by undefined error."
                ViewUtils.showNoticeAlert(self, title: "Failed to fetch", message: message)
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
    
    func loadTracks(playlistUid:String, pageToken:String?) {
        if isLoading {
            return
        }
        isLoading = true
        
        var progressHud:MBProgressHUD?
        if pageToken == nil {
            progressHud = ViewUtils.showProgress(self, message: "loading..")
        }
        Requests.getChannelPlaylist(playlistUid, pageToken: pageToken) { (req: NSURLRequest, resp: NSHTTPURLResponse?, result: AnyObject?, error :NSError?) -> Void in
            if progressHud != nil {
                progressHud!.hide(false)
            }
            self.isLoading = false
            if (error != nil || result == nil) {
                if (error != nil && error!.domain == NSURLErrorDomain &&
                        error!.code == NSURLErrorNotConnectedToInternet) {
                    ViewUtils.showNoticeAlert(self, title: "Failed to load", message: "Internet is not connected")
                    return
                }
                if result != nil {
                    println("result = \(result)")
                }
                var message = "Failed to load tracks."
                ViewUtils.showNoticeAlert(self, title: "Failed to load", message: message)
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
            self.tableView.reloadData()
        }
    }
    
    func switchToSectionSelectMode() {
        sectionSelectMode = true
        self.tableView.hidden = true
        self.sectionSelectTableView.hidden = false
        sectionSelector.setImage(UIImage(named: "ic_arrow_reverse.png"), forState: UIControlState.Normal)
    }
    
    func switchToNonSectionSelectMode() {
        sectionSelectMode = false
        self.tableView.hidden = false
        self.sectionSelectTableView.hidden = true
        sectionSelector.setImage(UIImage(named: "ic_arrow.png"), forState: UIControlState.Normal)
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
            var appDelegate:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            var centerViewController = appDelegate.centerContainer!.centerViewController as! CenterViewController
            centerViewController.showSigninView()
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
        let progressHud = ViewUtils.showProgress(self, message: "saving bookmark..")
        Requests.updateBookmarkList(newBookmarkedIds, respCb:{
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
            var params: Dictionary<String, AnyObject> = [
                "track": tracks[indexPath.row],
                "playlistId": "-1"
            ]
            NSNotificationCenter.defaultCenter().postNotificationName(
                NotifyKey.playerPlay, object: params)
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
    
    func onAddBtnClicked(sender: AddableTrackTableViewCell) {
        let indexPath:NSIndexPath = tableView.indexPathForCell(sender)!
        let track = tracks[indexPath.row]
        if (Account.getCachedAccount() == nil) {
            var appDelegate:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            var centerViewController = appDelegate.centerContainer!.centerViewController as! CenterViewController
            centerViewController.showSigninView()
            return
        }
        
        PlaylistViewController.addTrack(track, section: "feed", afterAdd: { (needRefresh, error) -> Void in
            if (error != nil) {
                if (error!.domain == "addTrack") {
                    if (error!.code == 100) {
                        ViewUtils.showNoticeAlert(self, title: "Failed to add", message: "Failed to find playlist")
                        return
                    }
                    ViewUtils.showToast(self, message: "Already in playlist")
                    return
                }
                var message:String?
                if (error != nil && error!.domain == NSURLErrorDomain &&
                        error!.code == NSURLErrorNotConnectedToInternet) {
                    message = "Internet is not connected"
                }
                if (message == nil) {
                    message = "undefined error (\(error!.domain),\(error!.code))"
                }
                ViewUtils.showNoticeAlert(self, title: "Failed to add", message: message!)
                return
            }

            ViewUtils.showToast(self, message: "Track added")
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
        var indexPath = tableView.indexPathForSelectedRow()
        if (indexPath != nil) {
            var preSelectedTrack = tracks[indexPath!.row]
            if (preSelectedTrack.id != track!.id ||
                (playlistId != nil && playlistId!.toInt() >= 0)) {
                tableView.deselectRowAtIndexPath(indexPath!, animated: false)
            }
        }
        
        
        if (playlistId == nil || playlistId!.toInt() >= 0) {
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
