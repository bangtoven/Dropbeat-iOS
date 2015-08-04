//
//  ViewController.swift
//  labs
//
//  Created by Park Il Su on 2015. 5. 14..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

enum FeedType {
    case TRENDING
    case FOLLOWING
    case NEW_RELEASE
    case BEATPORT_CHART
}

enum ViewMode {
    case Normal
    case Filter
    case MenuSelect
}

class FeedMenu {
    var type:FeedType
    var title:String
    init (title:String, type:FeedType) {
        self.title = title
        self.type = type
    }
}

class FeedViewController: BaseViewController,
        UITableViewDelegate, UITableViewDataSource,
        AddableTrackCellDelegate, UIActionSheetDelegate, FollowingFeedHeaderViewDelegate,
        FollowManageViewControllerDelegate {
    
    @IBOutlet weak var loadMoreSpinner: UIActivityIndicatorView!
    @IBOutlet weak var loadMoreSpinnerWrapper: UIView!
    @IBOutlet weak var feedTypeSelectBtn: UIButton!
    @IBOutlet weak var feedTableView: UITableView!
    @IBOutlet weak var feedTypeSelectBtnWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var feedTypeSelectTableView: UITableView!
    @IBOutlet weak var genreTableView: UITableView!
    
    var genres:[FeedType:[Genre]] = [FeedType:[Genre]]()
    var tracks:Array<Track> = []
    var selectedTrack:Track?
    var feedTypeSelectMode:Int = 0
    var viewMode:ViewMode = ViewMode.Normal
    var nextPage:Int = 0
    var isLoading:Bool = false
            
    var genreSelectBtn: UIBarButtonItem!
    var selectedGenre:Genre?
    
    var selectedFeedMenu:FeedMenu!
    var genreInitialized:Bool = false
    
    var feedMenus:[FeedMenu] = {
        var types = [FeedMenu]()
        types.append(FeedMenu(title: "Trending Tracks", type: FeedType.TRENDING))
        types.append(FeedMenu(title: "Followed Artists", type: FeedType.FOLLOWING))
        types.append(FeedMenu(title: "New Releases", type: FeedType.NEW_RELEASE))
        types.append(FeedMenu(title: "Beatport Charts", type: FeedType.BEATPORT_CHART))
        return types
    }()
    
    var dateFormatter:NSDateFormatter {
        var formatter = NSDateFormatter()
        formatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        formatter.dateFormat = "MMMM dd, yyyy"
        return formatter
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        genreSelectBtn = UIBarButtonItem(title: "Genre", style: .Plain, target: self, action: "onGenreBtnClicked:")
        genreSelectBtn.tintColor = UIColor(netHex: 0x8F2CEF)
        
        selectedFeedMenu = feedMenus[0]
        feedTypeSelectTableView.selectRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), animated: false,
            scrollPosition: UITableViewScrollPosition.Top)
        initialize()
    }
    
    func initialize() {
        let progressHud = ViewUtils.showProgress(self, message: "Loading..")
        initGenres { (error) -> Void in
            progressHud.hide(false)
            if error != nil {
                var message:String = "Failed to initalize feed."
                
                if (error!.domain == NSURLErrorDomain &&
                        error!.code == NSURLErrorNotConnectedToInternet) {
                    message += "Internet is not connected."
                }
                
                ViewUtils.showConfirmAlert(self, title: "Failed to load", message: message, positiveBtnText: "Retry", positiveBtnCallback: { () -> Void in
                    self.initialize()
                }, negativeBtnText: "Cancel", negativeBtnCallback: nil)
                return
            }
            self.switchFeed(self.selectedFeedMenu)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.screenName = "FeedViewScreen"
        
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "updatePlay:", name: NotifyKey.updatePlay, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "sender", name: NotifyKey.playerPlay, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "appWillEnterForeground",
            name: UIApplicationWillEnterForegroundNotification, object: nil)
        
        updatePlay(PlayerContext.currentTrack, playlistId: PlayerContext.currentPlaylistId)
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotifyKey.updatePlay, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotifyKey.playerPlay, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationWillEnterForegroundNotification, object: nil)
    }
    
    func onFollowManageCloseWithResult(isChanged: Bool) {
        if selectedFeedMenu.type == FeedType.FOLLOWING {
            switchFeed(selectedFeedMenu, genre: selectedGenre)
        }
    }
    
    func appWillEnterForeground() {
        if genreInitialized {
            switchFeed(selectedFeedMenu, genre:selectedGenre)
        }
        updatePlay(PlayerContext.currentTrack, playlistId: PlayerContext.currentPlaylistId)
    }
    
    func getFollowingHeaderView(followings:[Following]) -> UIView {
        if followings.count == 0 {
            var view:FollowingFeedHeaderView = FollowingFeedHeaderView(frame: CGRectMake(0, 0, self.feedTableView.bounds.width, 200))
            view.delegate = self
            return view
        }
        let view:FollowingFeedHeaderWithFollowingView = FollowingFeedHeaderWithFollowingView(frame: CGRectMake(0, 0, self.feedTableView.bounds.width, 100))
        var text = "You are following \(followings.count) artist"
        if followings.count > 1 {
            text += "s"
        }
        view.followingInfoView.text = text
        view.delegate = self
        return view
    }
    
    func onManageFollowBtnClicked(sender: FollowingFeedHeaderView) {
        if (Account.getCachedAccount() == nil) {
            var appDelegate:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            var centerViewController = appDelegate.centerContainer!
            centerViewController.showSigninView()
            return
        }
        performSegueWithIdentifier("ManageFollowSegue", sender: nil)
    }
    
    func sender () {}
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func initGenres(callback:(error:NSError?) -> Void) {
        genres[FeedType.FOLLOWING] = [
            Genre(key: "shuffle", name: "SHUFFLE"),
            Genre(key: "recent", name: "RECENT")
        ]
        
        Requests.getFeedGenre {
                (req:NSURLRequest, resp:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            if error != nil || result == nil {
                callback(error:error != nil ? error : NSError(domain: "initGenre", code:0, userInfo:nil))
                return
            }
            
            let parser = Parser()
            let genreList = parser.parseGenre(result!)
            if !genreList.success {
                callback(error:NSError(domain: "initGenre", code:0, userInfo:nil))
                return
            }
            
            self.genres[FeedType.BEATPORT_CHART] = genreList.results!["default"]
            self.genres[FeedType.NEW_RELEASE] = genreList.results!["default"]
            self.genres[FeedType.TRENDING] = genreList.results!["trending"]
            
            self.genreInitialized = true
            callback(error: nil)
        }
    }
    
    func updateFeedTypeSelectBtn(typeName:String) {
        var image = feedTypeSelectBtn.imageView!.image
        var titleLabel = feedTypeSelectBtn.titleLabel
        var genreStr:NSString = typeName as NSString
        feedTypeSelectBtn.setTitle(typeName, forState: UIControlState.Normal)
        
        var attr:[String : UIFont] = [String: UIFont]()
        if SYSTEM_VERSION_LESS_THAN("8.2") {
            attr[ NSFontAttributeName] = UIFont.systemFontOfSize(18)
        } else {
            attr[ NSFontAttributeName] = UIFont.systemFontOfSize(18, weight: UIFontWeightBold)
        }
        var textSize:CGSize = genreStr.sizeWithAttributes(attr)
        var textWidth = textSize.width;
        
        //or whatever font you're using
        var frame = feedTypeSelectBtn.frame
        var origin = feedTypeSelectBtn.frame.origin
        feedTypeSelectBtn.frame = CGRectMake(origin.x, origin.y, textWidth + 55, frame.height)
        feedTypeSelectBtnWidthConstraint.constant = textWidth + 55
        feedTypeSelectBtn.imageEdgeInsets = UIEdgeInsetsMake(2, textWidth + 55 - (image!.size.width + 20), 0, 0)
        feedTypeSelectBtn.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 0, image!.size.width + 20)
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if tableView != self.feedTableView || tracks.count == 0 {
            return
        }
        if indexPath.row == tracks.count - 1 {
            if nextPage <= 0 || isLoading {
                return
            }
            loadMoreSpinnerWrapper.hidden = false
            loadMoreSpinner.startAnimating()
            loadFeed(selectedFeedMenu.type)
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if tableView == feedTypeSelectTableView {
            
            let cell:FeedSelectTableViewCell = tableView.dequeueReusableCellWithIdentifier("FeedSelectTableViewCell",
                forIndexPath: indexPath) as! FeedSelectTableViewCell
            cell.name.text = feedMenus[indexPath.row].title
            return cell
            
        } else if tableView == genreTableView {
            let cell:GenreTableViewCell = tableView.dequeueReusableCellWithIdentifier("GenreTableViewCell",
                forIndexPath: indexPath) as! GenreTableViewCell
            let menuGenres:[Genre]? = genres[selectedFeedMenu.type]
            if menuGenres != nil {
                cell.genreView.text = menuGenres![indexPath.row].name
            }
            return cell
        } else {
            switch (selectedFeedMenu.type) {
            case .BEATPORT_CHART:
                return getBeatportChartCell(indexPath)
            case .NEW_RELEASE:
                return getNewReleaseCell(indexPath)
            case .TRENDING:
                return selectedGenre != nil && count(selectedGenre!.key) > 0 ?
                    getBeatportTrendingCell(indexPath) : getTrendingCell(indexPath)
            case .FOLLOWING:
                return getFollowingCell(indexPath)
            default:
                // not reach
                return UITableViewCell()
            }
        }
    }
    
    func getBeatportChartCell(indexPath:NSIndexPath) -> UITableViewCell{
        let cell:BpChartTrackTableViewCell = feedTableView.dequeueReusableCellWithIdentifier(
            "BpChartTrackTableViewCell", forIndexPath: indexPath) as! BpChartTrackTableViewCell
        let track:BeatportTrack = tracks[indexPath.row] as! BeatportTrack
        cell.delegate = self
        cell.nameView.text = track.trackName
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
        cell.genreName.text = track.genre
        cell.genreName.hidden = track.genre == nil
        cell.artistName.text = track.artist
        cell.rank.text = "\(indexPath.row + 1)"
        return cell
    }
    
    func getTrendingCell(indexPath:NSIndexPath) -> UITableViewCell{
        let cell:TrendingTrackTableViewCell = feedTableView.dequeueReusableCellWithIdentifier(
            "TrendingTrackTableViewCell", forIndexPath: indexPath) as! TrendingTrackTableViewCell
        let track:TrendingTrack = tracks[indexPath.row] as! TrendingTrack
        cell.delegate = self
        cell.nameView.text = track.trackName
        if (track.thumbnailUrl != nil) {
            cell.thumbView.sd_setImageWithURL(NSURL(string: track.thumbnailUrl!),
                    placeholderImage: UIImage(named: "default_cover_big.png"), completed: {
                    (image: UIImage!, error: NSError!, cacheType:SDImageCacheType, imageURL: NSURL!) -> Void in
                if (error != nil) {
                    cell.thumbView.image = UIImage(named: "default_cover_big.png")
                }
            })
        } else {
            cell.thumbView.image = UIImage(named: "default_cover_big.png")
        }
        cell.snippet.text = track.snippet
        cell.artistName.text = track.artist
        cell.rank.text = "\(indexPath.row + 1)"
        return cell
    }
    
    func getBeatportTrendingCell(indexPath:NSIndexPath) -> UITableViewCell {
        let cell:BpTrendingTrackTableViewCell = feedTableView.dequeueReusableCellWithIdentifier(
            "BpTrendingTrackTableViewCell", forIndexPath: indexPath) as! BpTrendingTrackTableViewCell
        let track:BeatportTrack = tracks[indexPath.row] as! BeatportTrack
        cell.delegate = self
        cell.nameView.text = track.trackName
        if (track.thumbnailUrl != nil) {
            cell.thumbView.sd_setImageWithURL(NSURL(string: track.thumbnailUrl!),
                    placeholderImage: UIImage(named: "default_cover_big.png"), completed: {
                    (image: UIImage!, error: NSError!, cacheType:SDImageCacheType, imageURL: NSURL!) -> Void in
                if (error != nil) {
                    cell.thumbView.image = UIImage(named: "default_cover_big.png")
                }
            })
        } else {
            cell.thumbView.image = UIImage(named: "default_cover_big.png")
        }
        cell.releasedAt.hidden = track.releasedAt == nil
        if track.releasedAt != nil {
            cell.releasedAt.text = "Released on \(self.dateFormatter.stringFromDate(track.releasedAt!))"
        }
        cell.artistName.text = track.artist
        cell.rank.text = "\(indexPath.row + 1)"
        return cell
    }
    
    func getNewReleaseCell(indexPath:NSIndexPath) -> UITableViewCell{
        let cell:NewReleasedTrackTableViewCell = feedTableView.dequeueReusableCellWithIdentifier(
            "NewReleasedTrackTableViewCell", forIndexPath: indexPath) as! NewReleasedTrackTableViewCell
        let track:NewReleaseTrack = tracks[indexPath.row] as! NewReleaseTrack
        cell.delegate = self
        cell.nameView.text = track.trackName
        if (track.thumbnailUrl != nil) {
            cell.thumbView.sd_setImageWithURL(NSURL(string: track.thumbnailUrl!),
                    placeholderImage: UIImage(named: "default_cover_big.png"), completed: {
                    (image: UIImage!, error: NSError!, cacheType:SDImageCacheType, imageURL: NSURL!) -> Void in
                if (error != nil) {
                    cell.thumbView.image = UIImage(named: "default_cover_big.png")
                }
            })
        } else {
            cell.thumbView.image = UIImage(named: "default_cover_big.png")
        }
        cell.releasedAt.hidden = track.releasedAt == nil
        if track.releasedAt != nil {
            cell.releasedAt.text = "Released on \(self.dateFormatter.stringFromDate(track.releasedAt!))"
        }
        cell.artistName.text = track.artist
        return cell
    }
    
    func getFollowingCell(indexPath:NSIndexPath) -> UITableViewCell{
        let cell:NewReleasedTrackTableViewCell = feedTableView.dequeueReusableCellWithIdentifier(
            "NewReleasedTrackTableViewCell", forIndexPath: indexPath) as! NewReleasedTrackTableViewCell
        let track:FollowingArtistTrack = tracks[indexPath.row] as! FollowingArtistTrack
        cell.delegate = self
        cell.nameView.text = track.trackName
        if (track.thumbnailUrl != nil) {
            cell.thumbView.sd_setImageWithURL(NSURL(string: track.thumbnailUrl!),
                    placeholderImage: UIImage(named: "default_cover_big.png"), completed: {
                    (image: UIImage!, error: NSError!, cacheType:SDImageCacheType, imageURL: NSURL!) -> Void in
                if (error != nil) {
                    cell.thumbView.image = UIImage(named: "default_cover_big.png")
                }
            })
        } else {
            cell.thumbView.image = UIImage(named: "default_cover_big.png")
        }
        cell.releasedAt.hidden = track.releasedAt == nil
        if track.releasedAt != nil {
            cell.releasedAt.text = "Released on \(self.dateFormatter.stringFromDate(track.releasedAt!))"
        }
        cell.artistName.text = track.artist
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if tableView == feedTypeSelectTableView {
            let feedMenu = feedMenus[indexPath.row]
            selectedFeedMenu = feedMenu
            switchFeed(selectedFeedMenu, genre: nil)
            toFeedView(feedMenu.title)
        } else if tableView == genreTableView {
            let menuGenres:[Genre]? = genres[selectedFeedMenu.type]
            if menuGenres != nil {
                filterAsGenre(menuGenres![indexPath.row])
            }
        } else {
            onPlayBtnClicked(tracks[indexPath.row])
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == feedTypeSelectTableView {
            return feedMenus.count
        } else if tableView == genreTableView {
            return genres[selectedFeedMenu.type] == nil ? 0 :
                    genres[selectedFeedMenu.type]!.count
        } else {
            return tracks.count
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if tableView == feedTypeSelectTableView {
            return 60
        }
        if tableView == genreTableView {
            return 60
        }
        switch(selectedFeedMenu.type) {
        case .TRENDING :
            return (17 * self.view.bounds.width / 30) + 60
        case .NEW_RELEASE:
            return (17 * self.view.bounds.width / 30) + 60
        case .BEATPORT_CHART:
            return 76
        case .FOLLOWING:
            return (17 * self.view.bounds.width / 30) + 60
        default:
            break
        }
        return 60
    }
    
    func filterAsGenre(genre:Genre) {
        switchFeed(selectedFeedMenu, genre: genre)
        toFeedView(selectedFeedMenu.title)
    }
    
    func onGenreBtnClicked(sender: AnyObject) {
        if viewMode == ViewMode.Filter {
            toFeedView(selectedFeedMenu.title)
        } else {
            toGenreSelectView()
        }
    }
    
    func getPlaylistId() -> String? {
        if selectedGenre == nil {
            return nil
        }
        switch (selectedFeedMenu.type) {
        case .BEATPORT_CHART:
            return "beatport_chart_\(selectedGenre!.key)"
        case .FOLLOWING:
            return "followed_artist_feed_\(selectedGenre!.key)"
        case .NEW_RELEASE:
            return "new_release_\(selectedGenre!.key)"
        case .TRENDING:
            return "trending_\(selectedGenre!.key)"
        default:
            break
        }
        return nil
    }
    
    func getPlaylistName() -> String? {
        if selectedGenre == nil {
            return nil
        }
        
        switch (selectedFeedMenu.type) {
        case .BEATPORT_CHART:
            return "Beatport Chart - \(selectedGenre!.name)"
        case .FOLLOWING:
            return "Followed Artists Feed"
        case .NEW_RELEASE:
            return "New Release - \(selectedGenre!.name)"
        case .TRENDING:
            return "Trending - \(selectedGenre!.name)"
        default:
            break
        }
        return nil
    }
    
    func updatePlaylist(forceUpdate:Bool) {
        if !forceUpdate &&
                (getPlaylistId() == nil || getPlaylistName() == nil ||
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
                    name: getPlaylistName()!,
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
        let progressHud = ViewUtils.showProgress(self, message: "Loading..")
        var section = "feed_"
        if selectedFeedMenu != nil {
            section += "_" + selectedFeedMenu.title.lowercaseString.replace(" ", withString: "_")
        }
        if selectedGenre != nil {
            section += "_" + selectedGenre!.name
        }
        track.shareTrack(section, afterShare: { (error, uid) -> Void in
            progressHud.hide(false)
            if error != nil {
                if (error!.domain == NSURLErrorDomain &&
                        error!.code == NSURLErrorNotConnectedToInternet) {
                    ViewUtils.showConfirmAlert(self, title: "Failed to share",
                        message: "Internet is not connected.",
                        positiveBtnText: "Retry", positiveBtnCallback: { () -> Void in
                            self.onShareBtnClicked(track)
                        }, negativeBtnText: "Cancel", negativeBtnCallback: nil)
                    return
                }
                ViewUtils.showConfirmAlert(self, title: "Failed to share",
                    message: "Failed to share track",
                    positiveBtnText: "Retry", positiveBtnCallback: { () -> Void in
                        self.onShareBtnClicked(track)
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
    
    func onAddBtnClicked(track:Track) {
        if (Account.getCachedAccount() == nil) {
            var appDelegate:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            var centerViewController = appDelegate.centerContainer!
            centerViewController.showSigninView()
            return
        }
        performSegueWithIdentifier("PlaylistSelectSegue", sender: track)
    }
    
    func onMenuBtnClicked(sender: AddableTrackTableViewCell) {
        let indexPath:NSIndexPath = feedTableView.indexPathForCell(sender)!
        let track = tracks[indexPath.row]
        selectedTrack = track
        
        let actionSheet = UIActionSheet()
        actionSheet.addButtonWithTitle("Add to playlist")
        actionSheet.addButtonWithTitle("Share")
        actionSheet.addButtonWithTitle("Cancel")
        actionSheet.cancelButtonIndex = 2
        actionSheet.delegate = self
        actionSheet.showInView(self.view.window)
    }
    
    func actionSheet(actionSheet: UIActionSheet, didDismissWithButtonIndex buttonIndex: Int) {
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
        case 0:
            onAddBtnClicked(track!)
            break
        case 1:
            onShareBtnClicked(track!)
            break
        default:
            break
        }
        selectedTrack = nil
    }
    
    func switchFeed(menu:FeedMenu, genre:Genre?=nil) {
        updateFeedTypeSelectBtn(menu.title)
        nextPage = menu.type == FeedType.BEATPORT_CHART ? -1 : 0
        tracks.removeAll(keepCapacity: false)
        feedTableView.reloadData()
        genreTableView.reloadData()
        
        loadMoreSpinnerWrapper.hidden = true
        loadMoreSpinner.stopAnimating()
        
        if menu.type == FeedType.FOLLOWING {
            genreSelectBtn.title = "Order"
        } else {
            genreSelectBtn.title = "Genre"
        }
        
        if genres[menu.type] != nil {
            navigationItem.leftBarButtonItem = genreSelectBtn
        } else {
            navigationItem.leftBarButtonItem = nil
        }
        
        if menu.type != FeedType.FOLLOWING {
            feedTableView.tableHeaderView = nil
        }
        
        if genreTableView.indexPathForSelectedRow() != nil {
            let selectedIndexPath = genreTableView.indexPathForSelectedRow()!
            genreTableView.deselectRowAtIndexPath(selectedIndexPath, animated: false)
        }
        
        let menuGenres = genres[menu.type]
        if menuGenres != nil {
            if genre != nil {
                selectedGenre = genre
            } else if genre == nil && menuGenres != nil && menuGenres!.count > 0 {
                selectedGenre = menuGenres![0]
            } else {
                selectedGenre = nil
            }
        }
        
        if selectedGenre != nil && menuGenres != nil {
            var foundIdx = -1
            for (idx:Int, g:Genre) in enumerate(menuGenres!) {
                if g.name == selectedGenre!.name {
                    foundIdx = idx
                    break
                }
            }
            if foundIdx >= 0 {
                genreTableView.selectRowAtIndexPath(NSIndexPath(forRow: foundIdx, inSection: 0), animated: false, scrollPosition: UITableViewScrollPosition.None)
            }
        }
        
        if feedTableView.indexPathForSelectedRow() != nil {
            let selectedIndexPath = feedTableView.indexPathForSelectedRow()!
            feedTableView.deselectRowAtIndexPath(selectedIndexPath, animated: false)
        }
        
        if menu.type == .FOLLOWING {
            if Account.getCachedAccount() == nil {
                self.feedTableView.tableHeaderView = self.getFollowingHeaderView([Following]())
                self.loadFollowingFeed()
                return
            }
            let progressHud = ViewUtils.showProgress(self, message: "Loading..")
            loadFollowingList({ (following, error) -> Void in
                progressHud.hide(false)
                if error != nil {
                    if error!.domain == NSURLErrorDomain &&
                            error!.code == NSURLErrorNotConnectedToInternet {
                        ViewUtils.showNoticeAlert(self, title: "Failed to load", message: "Internet is not connected")
                        return
                    }
                    var message = "Failed to load trending."
                    ViewUtils.showNoticeAlert(self, title: "Failed to load", message: message)
                    return
                }
                self.feedTableView.tableHeaderView = self.getFollowingHeaderView(following!)
                self.loadFollowingFeed()
            })
            return
        }
        
        loadFeed(menu.type)
    }
    
    func loadFeed(type:FeedType) {
        var action:String = "none"
        switch(type) {
        case .TRENDING:
            loadTrendingFeed()
            action = "trending"
            break
        case .FOLLOWING:
            loadFollowingFeed()
            action = "following"
            break
        case .BEATPORT_CHART:
            loadBeatportChartFeed()
            action = "beatport_chart"
            break
        case .NEW_RELEASE:
            loadNewReleaseFeed()
            action = "new_release"
            break
        default:
            break
        }
        
        if selectedGenre != nil {
            action += "_" + selectedGenre!.name.lowercaseString.replace(" ", withString: "_")
        }
        
        let tracker = GAI.sharedInstance().defaultTracker
        let event = GAIDictionaryBuilder.createEventWithCategory(
                "load_feed",
                action: action,
                label: "feed",
                value: 1
            ).build()
        tracker.send(event as [NSObject: AnyObject]!)
    }
    
    func loadTrendingFeed() {
        if selectedGenre == nil {
            selectedGenre = genres[FeedType.TRENDING]![0]
        }
        
        if isLoading {
            return
        }
        
        var progressHud:MBProgressHUD?
        if nextPage == 0 {
            progressHud = ViewUtils.showProgress(self, message: "Loading..")
        }
        Requests.getStreamTrending(selectedGenre!.key, pageIdx: nextPage, respCb: {
            (req:NSURLRequest, resp:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            self.isLoading = false
            progressHud?.hide(false)
            if (error != nil || result == nil) {
                if (error != nil && error!.domain == NSURLErrorDomain &&
                        error!.code == NSURLErrorNotConnectedToInternet) {
                    ViewUtils.showNoticeAlert(self, title: "Failed to load", message: "Internet is not connected")
                    return
                }
                var message = "Failed to load trending."
                ViewUtils.showNoticeAlert(self, title: "Failed to load", message: message)
                return
            }
            
            let parser = Parser()
            var resultTracks:[Track]!
            
            if count(self.selectedGenre!.key) == 0 {
                let streamTrending = parser.parseStreamTrending(result!)
                if !streamTrending.success {
                    var message = "Failed to load trending."
                    ViewUtils.showNoticeAlert(self, title: "Failed to load", message: message)
                    return
                }
                resultTracks = streamTrending.results
            } else {
                let beatportTrending = parser.parseStreamBeatportTrending(result!)
                if !beatportTrending.success {
                    var message = "Failed to load trending."
                    ViewUtils.showNoticeAlert(self, title: "Failed to load", message: message)
                    return
                }
                resultTracks = beatportTrending.results
            }
            
            if resultTracks.count == 0 {
                self.nextPage = -1
                self.loadMoreSpinner.stopAnimating()
                self.loadMoreSpinnerWrapper.hidden = true
            } else {
                self.nextPage += 1
            }
            for track in resultTracks {
                self.tracks.append(track)
            }
            self.updatePlaylist(false)
            self.feedTableView.reloadData()
            
            self.updatePlay(PlayerContext.currentTrack, playlistId: PlayerContext.currentPlaylistId)
        })
    }
    
    func loadBeatportChartFeed() {
        if selectedGenre == nil {
            selectedGenre = genres[FeedType.BEATPORT_CHART]![0]
        }
        
        let progressHud = ViewUtils.showProgress(self, message: "Loading..")
        var genreKey = selectedGenre!.name
        if count(selectedGenre!.key) == 0{
            genreKey = "TOP100"
        }
        Requests.fetchBeatportChart(genreKey, respCb: {
                (request:NSURLRequest, response:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            progressHud.hide(false)
            
            if (error != nil || result == nil) {
                if (error != nil && error!.domain == NSURLErrorDomain &&
                        error!.code == NSURLErrorNotConnectedToInternet) {
                    ViewUtils.showNoticeAlert(self, title: "Failed to load", message: "Internet is not connected")
                    return
                }
                var message = "Failed to load chart."
                ViewUtils.showNoticeAlert(self, title: "Failed to load", message: message)
                return
            }
            
            var parser:Parser = Parser()
            var chart = parser.parseBeatportChart(result!)
            
            if !chart.success {
                var message = "Failed to load chart."
                ViewUtils.showNoticeAlert(self, title: "Failed to load", message: message)
                return
            }
            self.tracks.removeAll(keepCapacity: false)
            for track in chart.results! {
                self.tracks.append(track)
            }
            
            self.updatePlaylist(false)
            self.feedTableView.reloadData()
            self.updatePlay(PlayerContext.currentTrack, playlistId: PlayerContext.currentPlaylistId)
        })
    }
        
    func loadFollowingList(callback:(following:[Following]?, error:NSError?) -> Void) {
        if isLoading {
            return
        }
        
        Requests.following { (req:NSURLRequest, resp:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            self.isLoading = false
            if (error != nil || result == nil) {
                callback(following: nil, error: error != nil ? error :
                    NSError(domain: "loadFollowingList", code:0, userInfo: nil))
                return
            }
            
            let parser = Parser()
            let info = parser.parseFollowing(result!)
            if !info.success {
                callback(following: nil, error: NSError(domain: "loadFollowingList", code:0, userInfo: nil))
                return
            }
            
            callback(following: info.results!, error:nil)
        }
    }
    
    func loadFollowingFeed() {
        if selectedGenre == nil {
            selectedGenre = genres[FeedType.FOLLOWING]![0]
        }
        
        if isLoading {
            return
        }
        
        var progressHud:MBProgressHUD?
        if nextPage == 0 {
            progressHud = ViewUtils.showProgress(self, message: "Loading..")
        }
        
        Requests.getStreamFollowing(nextPage, order:selectedGenre!.key, respCb: {
            (req:NSURLRequest, resp:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            self.isLoading = false
            progressHud?.hide(false)
            if (error != nil || result == nil) {
                if (error != nil && error!.domain == NSURLErrorDomain &&
                        error!.code == NSURLErrorNotConnectedToInternet) {
                    ViewUtils.showNoticeAlert(self, title: "Failed to load", message: "Internet is not connected")
                    return
                }
                var message = "Failed to load following feed."
                ViewUtils.showNoticeAlert(self, title: "Failed to load", message: message)
                return
            }
            
            
            let parser = Parser()
            let streamFollowing = parser.parseStreamFollowing(result!)
            if !streamFollowing.success {
                var message = "Failed to load following feed."
                ViewUtils.showNoticeAlert(self, title: "Failed to load", message: message)
                return
            }
            
            if streamFollowing.results!.count == 0 {
                self.nextPage = -1
                self.loadMoreSpinner.stopAnimating()
                self.loadMoreSpinnerWrapper.hidden = true
            } else {
                self.nextPage += 1
            }
            for track in streamFollowing.results! {
                self.tracks.append(track)
            }
            self.updatePlaylist(false)
            self.feedTableView.reloadData()
            self.updatePlay(PlayerContext.currentTrack, playlistId: PlayerContext.currentPlaylistId)
        })
    }
    
    func loadNewReleaseFeed() {
        if selectedGenre == nil {
            selectedGenre = genres[FeedType.NEW_RELEASE]![0]
        }
        
        if isLoading {
            return
        }
        
        var progressHud:MBProgressHUD?
        if nextPage == 0 {
            progressHud = ViewUtils.showProgress(self, message: "Loading..")
        }
        Requests.getStreamNew(selectedGenre!.key, pageIdx: nextPage, respCb: {
            (req:NSURLRequest, resp:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            self.isLoading = false
            progressHud?.hide(false)
            if (error != nil || result == nil) {
                if (error != nil && error!.domain == NSURLErrorDomain &&
                        error!.code == NSURLErrorNotConnectedToInternet) {
                    ViewUtils.showNoticeAlert(self, title: "Failed to load", message: "Internet is not connected")
                    return
                }
                var message = "Failed to load new release."
                ViewUtils.showNoticeAlert(self, title: "Failed to load", message: message)
                return
            }
            
            
            let parser = Parser()
            let streamNew = parser.parseStreamNew(result!)
            if !streamNew.success {
                var message = "Failed to load new release."
                ViewUtils.showNoticeAlert(self, title: "Failed to load", message: message)
                return
            }
            
            if streamNew.results!.count == 0 {
                self.nextPage = -1
                self.loadMoreSpinner.stopAnimating()
                self.loadMoreSpinnerWrapper.hidden = true
            } else {
                self.nextPage += 1
            }
            for track in streamNew.results! {
                self.tracks.append(track)
            }
            self.updatePlaylist(false)
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
        
        
        if (playlistId == nil || playlistId != getPlaylistId()) {
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
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "PlaylistSelectSegue" {
            let playlistSelectVC:PlaylistSelectViewController = segue.destinationViewController as! PlaylistSelectViewController
            playlistSelectVC.targetTrack = sender as? Track
            playlistSelectVC.fromSection = "feed"
            playlistSelectVC.caller = self
        }
        
        if segue.identifier == "ManageFollowSegue" {
            let manageFollowVC:FollowManageViewController = segue.destinationViewController as! FollowManageViewController
            manageFollowVC.delegate = self
        }
    }
    
    @IBAction func onFeedTypeSelectorClicked(sender: AnyObject) {
        if viewMode == ViewMode.Normal{
            toFeedTypeSelectView()
        } else {
            toFeedView(selectedFeedMenu.title)
        }
    }
    
    func toFeedTypeSelectView() {
        viewMode = ViewMode.MenuSelect
        feedTableView.hidden = true
        feedTypeSelectTableView.hidden = false
        genreTableView.hidden = true
        feedTypeSelectBtn.setImage(UIImage(named:"ic_arrow_up.png"), forState: UIControlState.Normal)
        if selectedFeedMenu.type == FeedType.FOLLOWING {
            genreSelectBtn.title = "Order"
        } else {
            genreSelectBtn.title = "Genre"
        }
    }
    
    func toFeedView(selected:String) {
        viewMode = ViewMode.Normal
        feedTableView.hidden = false
        feedTypeSelectTableView.hidden = true
        genreTableView.hidden = true
        feedTypeSelectBtn.setImage(UIImage(named:"ic_arrow_down.png"), forState: UIControlState.Normal)
        updateFeedTypeSelectBtn(selected)
        if selectedFeedMenu.type == FeedType.FOLLOWING {
            genreSelectBtn.title = "Order"
        } else {
            genreSelectBtn.title = "Genre"
        }
    }
    
    func toGenreSelectView() {
        viewMode = ViewMode.Filter
        feedTableView.hidden = true
        feedTypeSelectTableView.hidden = true
        genreTableView.hidden = false
        feedTypeSelectBtn.setImage(UIImage(named:"ic_arrow_down.png"), forState: UIControlState.Normal)
        genreSelectBtn.title = "Close"
    }
}
