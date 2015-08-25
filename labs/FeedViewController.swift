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
    case USER_GROUP
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

class FeedViewController: AddableTrackListViewController,
        UITableViewDelegate, UITableViewDataSource,
        FollowingFeedHeaderViewDelegate,
        FollowManageViewControllerDelegate {
    
    @IBOutlet weak var loadMoreSpinner: UIActivityIndicatorView!
    @IBOutlet weak var loadMoreSpinnerWrapper: UIView!
    @IBOutlet weak var feedTypeSelectBtn: UIButton!
    @IBOutlet weak var feedTypeSelectBtnWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var feedTypeSelectTableView: UITableView!
    @IBOutlet weak var genreTableView: UITableView!
    
    private var refreshControl: UIRefreshControl!
    
    private var genres:[FeedType:[Genre]] = [FeedType:[Genre]]()
    private var selectedTrack:Track?
    private var feedTypeSelectMode:Int = 0
    private var viewMode:ViewMode = ViewMode.Normal
    private var nextPage:Int = 0
    private var isLoading:Bool = false
            
    private var genreSelectBtn: UIBarButtonItem!
    private var selectedGenre:Genre?
    
    private var selectedFeedMenu:FeedMenu!
    private var genreInitialized:Bool = false
    
    private var feedMenus:[FeedMenu] = {
        var types = [FeedMenu]()
        if Account.getCachedAccount() != nil {
            types.append(FeedMenu(title: NSLocalizedString("Social Feed", comment:""), type: FeedType.USER_GROUP))
        }
        types.append(FeedMenu(title: NSLocalizedString("Trending Tracks", comment:""), type: FeedType.TRENDING))
        types.append(FeedMenu(title: NSLocalizedString("Followed Artists", comment:""), type: FeedType.FOLLOWING))
        types.append(FeedMenu(title: NSLocalizedString("New Releases", comment:""), type: FeedType.NEW_RELEASE))
        types.append(FeedMenu(title: NSLocalizedString("Beatport Charts", comment:""), type: FeedType.BEATPORT_CHART))
        return types
    }()
    
    private var dateFormatter:NSDateFormatter {
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
        
       
        refreshControl = UIRefreshControl()
        refreshControl.tintColor = UIColor(netHex:0xc380fc)
        refreshControl.addTarget(self, action: "refresh", forControlEvents: UIControlEvents.ValueChanged)
        
        let refreshControlTitle = NSAttributedString(
            string: NSLocalizedString("Pull to refresh", comment: ""),
            attributes: [NSForegroundColorAttributeName: UIColor(netHex: 0x909090)])
        refreshControl.attributedTitle = refreshControlTitle
        trackTableView.insertSubview(refreshControl, atIndex: 0)
        
        updateFeedTypeSelectBtn(nil)
        initialize()
    }
    
    func initialize() {
        let progressHud = ViewUtils.showProgress(self, message: NSLocalizedString("Loading..", comment:""))
        initGenres { (error) -> Void in
            progressHud.hide(true)
            if error != nil {
                var message:String = NSLocalizedString("Failed to initalize feed.", comment:"")
                
                if (error!.domain == NSURLErrorDomain &&
                        error!.code == NSURLErrorNotConnectedToInternet) {
                    message += NSLocalizedString("Internet is not connected.", comment:"")
                }
                
                ViewUtils.showConfirmAlert(self,
                        title: NSLocalizedString("Failed to load", comment:""),
                        message: message,
                        positiveBtnText: NSLocalizedString("Retry", comment:""),
                        positiveBtnCallback: { () -> Void in
                    self.initialize()
                }, negativeBtnText: NSLocalizedString("Cancel", comment:""), negativeBtnCallback: nil)
                return
            }
            self.switchFeed(self.selectedFeedMenu)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.screenName = "FeedViewScreen"
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func appWillEnterForeground() {
        if genreInitialized {
            switchFeed(selectedFeedMenu, genre:selectedGenre)
        }
        super.appWillEnterForeground()
    }
    
    override func getPlaylistId() -> String? {
        var prefix:String? = nil
        switch (selectedFeedMenu.type) {
        case .BEATPORT_CHART:
            prefix = "beatport_chart"
            break
        case .FOLLOWING:
            prefix = "followed_artist_feed"
            break
        case .NEW_RELEASE:
            prefix = "new_release"
            break
        case .TRENDING:
            prefix = "trending"
            break
        case .USER_GROUP:
            prefix = "social_feed"
            break
        default:
            break
        }
        if prefix != nil && selectedGenre != nil{
            prefix! += "_\(selectedGenre!.key)"
        }
        return prefix
    }
    
    override func getPlaylistName() -> String? {
        var prefix:String? = nil
        switch (selectedFeedMenu.type) {
        case .BEATPORT_CHART:
            prefix = "Beatport Chart"
            break
        case .FOLLOWING:
            prefix = "Followed Artists Feed"
            break
        case .NEW_RELEASE:
            prefix = "New Release"
            break
        case .TRENDING:
            prefix = "Trending"
            break
        case .USER_GROUP:
            prefix = "Social Feed"
            break
        default:
            break
        }
        if prefix != nil && selectedGenre != nil {
            prefix! += " - \(selectedGenre!.name)"
        }
        return prefix
    }
    
    override func getSectionName() -> String {
        var section = "feed_"
        if selectedFeedMenu != nil {
            section += "_" + selectedFeedMenu.title.lowercaseString.replace(" ", withString: "_")
        }
        if selectedGenre != nil {
            section += "_" + selectedGenre!.name
        }
        return section
    }
    
    func onFollowManageCloseWithResult(isChanged: Bool) {
        if selectedFeedMenu.type == FeedType.FOLLOWING {
            switchFeed(selectedFeedMenu, genre: selectedGenre, forceRefresh: true, remoteRefresh:isChanged)
        }
    }
    
    func getFollowingHeaderView(followings:[Following]) -> UIView {
        if followings.count == 0 {
            var view:FollowingFeedHeaderView = FollowingFeedHeaderView(frame: CGRectMake(0, 0, self.trackTableView.bounds.width, 200))
            view.delegate = self
            return view
        }
        let view:FollowingFeedHeaderWithFollowingView =
            FollowingFeedHeaderWithFollowingView(frame: CGRectMake(0, 0, self.trackTableView.bounds.width, 100))
        var text = NSString.localizedStringWithFormat(
            NSLocalizedString("You are following %d artists", comment:""), followings.count)
        view.followingInfoView.text = text as String
        view.delegate = self
        return view
    }
    
    func getFriendFeedHeaderView() -> UIView {
        return FriendFeedHeaderView(frame: CGRectMake(0, 0, self.trackTableView.bounds.width, 110))
    }
    
    func onManageFollowBtnClicked(sender: FollowingFeedHeaderView) {
        if (Account.getCachedAccount() == nil) {
            performSegueWithIdentifier("need_auth", sender: nil)
            return
        }
        performSegueWithIdentifier("ManageFollowSegue", sender: nil)
    }
    
    func sender () {}
    
    func initGenres(callback:(error:NSError?) -> Void) {
        genres[FeedType.FOLLOWING] = [
            Genre(key: "shuffle", name: "SHUFFLE"),
            Genre(key: "recent", name: "RECENT")
        ]
        
        let genreHandler = {(genreMap:[String:[Genre]]) -> Void in
            self.genres[FeedType.BEATPORT_CHART] = genreMap["default"]
            self.genres[FeedType.NEW_RELEASE] = genreMap["default"]
            self.genres[FeedType.TRENDING] = genreMap["trending"]
            
            self.genreInitialized = true
            callback(error: nil)
        }
        
        if let cachedGenreMap = GenreList.cachedResult {
            genreHandler(cachedGenreMap)
            return
        }
        
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
            genreHandler(genreList.results!)
        }
    }
    
    func updateFeedTypeSelectBtn(typeName:String?) {
        if typeName == nil {
            feedTypeSelectBtn.hidden = true
            return
        }
        feedTypeSelectBtn.hidden = false
        var image = feedTypeSelectBtn.imageView!.image
        var titleLabel = feedTypeSelectBtn.titleLabel
        var genreStr:NSString = typeName! as NSString
        feedTypeSelectBtn.setTitle(typeName!, forState: UIControlState.Normal)
        
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
        if tableView != self.trackTableView || tracks.count == 0 {
            return
        }
        var marginWidth:CGFloat = 36.0
        let track = tracks[indexPath.row]
        if track.drop != nil {
            marginWidth += 64.0
        }
        
        var dropBtn:UIButton?
        var dropIcReadyName = "ic_drop.png"
        var dropIcLoadingName = "ic_drop_loading.png"
        var dropIcPlayingName = "ic_drop_pause.png"
        
        if selectedFeedMenu.type == FeedType.NEW_RELEASE {
            let trackCell = cell as! NewReleasedTrackTableViewCell
            trackCell.titleWidthConstaint.constant = self.view.bounds.width - marginWidth
            trackCell.artistWidthConstraint.constant = self.view.bounds.width - marginWidth
            dropBtn = trackCell.dropBtn
            
        } else if selectedFeedMenu.type == FeedType.TRENDING {
            if selectedGenre != nil && count(selectedGenre!.key) > 0 {
                let trackCell = cell as! BpTrendingTrackTableViewCell
                trackCell.titleWidthConstaint.constant = self.view.bounds.width - marginWidth
                trackCell.artistWidthConstraint.constant = self.view.bounds.width - marginWidth
                dropBtn = trackCell.dropBtn
            } else {
                let trackCell = cell as! TrendingTrackTableViewCell
                trackCell.titleWidthConstaint.constant = self.view.bounds.width - marginWidth
                trackCell.artistWidthConstraint.constant = self.view.bounds.width - marginWidth
                dropBtn = trackCell.dropBtn
            }
            
        } else if selectedFeedMenu.type == FeedType.FOLLOWING {
            let trackCell = cell as! NewReleasedTrackTableViewCell
            trackCell.titleWidthConstaint.constant = self.view.bounds.width - marginWidth
            trackCell.artistWidthConstraint.constant = self.view.bounds.width - marginWidth
            dropBtn = trackCell.dropBtn
            
        } else if selectedFeedMenu.type == FeedType.BEATPORT_CHART {
            let trackCell = cell as! BpChartTrackTableViewCell
            dropBtn = trackCell.dropBtn
            dropIcReadyName = "ic_drop_small.png"
            dropIcLoadingName = "ic_drop_loading_small.png"
            dropIcPlayingName = "ic_drop_pause_small.png"
            
        } else if selectedFeedMenu.type == FeedType.USER_GROUP {
            let trackCell = cell as! UserTrackTableViewCell
            dropBtn = trackCell.dropBtn
            dropIcReadyName = "ic_drop_small.png"
            dropIcLoadingName = "ic_drop_loading_small.png"
            dropIcPlayingName = "ic_drop_pause_small.png"
        }
        if dropBtn != nil {
            if track.drop != nil {
                var currDropTrack = dropPlayerContext.currentTrack
                
                if currDropTrack != nil &&
                    currDropTrack!.id == track.id &&
                    getSectionName() == dropPlayerContext.sectionName {
                    switch (dropPlayerContext.playStatus) {
                    case .Ready:
                        dropBtn!.setImage(UIImage(named:dropIcReadyName), forState: UIControlState.Normal)
                        break
                    case .Loading:
                        dropBtn!.setImage(UIImage(named:dropIcLoadingName), forState: UIControlState.Normal)
                        break
                    case .Playing:
                        dropBtn!.setImage(UIImage(named:dropIcPlayingName), forState: UIControlState.Normal)
                        break
                    }
                } else {
                    dropBtn!.setImage(UIImage(named:dropIcReadyName), forState: UIControlState.Normal)
                }
                dropBtn!.hidden = false
            } else {
                dropBtn!.hidden = true
            }
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
            var cell:UITableViewCell!
            switch (selectedFeedMenu.type) {
            case .BEATPORT_CHART:
                cell = getBeatportChartCell(indexPath)
                break
            case .NEW_RELEASE:
                cell = getNewReleaseCell(indexPath)
                break
            case .TRENDING:
                cell = selectedGenre != nil && count(selectedGenre!.key) > 0 ?
                    getBeatportTrendingCell(indexPath) : getTrendingCell(indexPath)
                break
            case .FOLLOWING:
                cell = getFollowingCell(indexPath)
                break
            case .USER_GROUP:
                cell = getUserGroupCell(indexPath)
                break
            default:
                // not reach
                cell = UITableViewCell()
            }
            let track = tracks[indexPath.row]
            if (getPlaylistId() == PlayerContext.currentPlaylistId &&
                    PlayerContext.currentTrack != nil &&
                    PlayerContext.currentTrack!.id == track.id) {
                cell.setSelected(true, animated: false)
            }
            return cell
        }
    }
    
    func getBeatportChartCell(indexPath:NSIndexPath) -> UITableViewCell{
        let cell:BpChartTrackTableViewCell = trackTableView.dequeueReusableCellWithIdentifier(
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
        let cell:TrendingTrackTableViewCell = trackTableView.dequeueReusableCellWithIdentifier(
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
        let cell:BpTrendingTrackTableViewCell = trackTableView.dequeueReusableCellWithIdentifier(
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
        let cell:NewReleasedTrackTableViewCell = trackTableView.dequeueReusableCellWithIdentifier(
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
        let cell:NewReleasedTrackTableViewCell = trackTableView.dequeueReusableCellWithIdentifier(
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
    
    func getUserGroupCell(indexPath:NSIndexPath) -> UITableViewCell {
        let cell:UserTrackTableViewCell = trackTableView.dequeueReusableCellWithIdentifier(
            "UserTrackTableViewCell", forIndexPath: indexPath) as! UserTrackTableViewCell
        let track:FriendTrack = tracks[indexPath.row] as! FriendTrack
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
        var listenDate = NSDate(timeIntervalSinceNow: -60.0 * Double(track.ts))
        cell.listenTimeView.text = listenDate.timeAgoSinceNow()
        cell.userNameView.text = track.nickname
        cell.artistName.text = track.artistName
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
            onTrackPlayBtnClicked(tracks[indexPath.row])
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
            return (15 * self.view.bounds.width / 30) + 52
        case .NEW_RELEASE:
            return (15 * self.view.bounds.width / 30) + 52
        case .BEATPORT_CHART:
            return 76
        case .FOLLOWING:
            return (15 * self.view.bounds.width / 30) + 52
        case .USER_GROUP:
            return 132
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
    
    func switchFeed(menu:FeedMenu, genre:Genre?=nil, forceRefresh:Bool=false, remoteRefresh:Bool=false) {
        onDropFinished()
        updateFeedTypeSelectBtn(menu.title)
        nextPage = menu.type == FeedType.BEATPORT_CHART ? -1 : 0
        tracks.removeAll(keepCapacity: false)
        trackTableView.reloadData()
        genreTableView.reloadData()
        
        loadMoreSpinnerWrapper.hidden = true
        loadMoreSpinner.stopAnimating()
        
        if menu.type == FeedType.USER_GROUP {
            trackTableView.backgroundColor = UIColor(netHex: 0xEFEFF4)
        } else {
            trackTableView.backgroundColor = UIColor(netHex: 0xffffff)
        }
        
        if menu.type == FeedType.FOLLOWING {
            genreSelectBtn.title = NSLocalizedString("Order", comment:"")
        } else {
            genreSelectBtn.title = NSLocalizedString("Genre", comment:"")
        }
        
        if genres[menu.type] != nil {
            navigationItem.leftBarButtonItem = genreSelectBtn
        } else {
            navigationItem.leftBarButtonItem = nil
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
        
        if trackTableView.indexPathForSelectedRow() != nil {
            let selectedIndexPath = trackTableView.indexPathForSelectedRow()!
            trackTableView.deselectRowAtIndexPath(selectedIndexPath, animated: false)
        }
        
        if menu.type == .FOLLOWING {
            if Account.getCachedAccount() == nil {
                self.trackTableView.tableHeaderView = self.getFollowingHeaderView([Following]())
                self.loadFollowingFeed()
                return
            }
            let progressHud = ViewUtils.showProgress(self, message: NSLocalizedString("Loading..", comment:""))
            loadFollowingList({ (following, error) -> Void in
                progressHud.hide(true)
                if error != nil {
                    if error!.domain == NSURLErrorDomain &&
                            error!.code == NSURLErrorNotConnectedToInternet {
                        ViewUtils.showNoticeAlert(self,
                            title: NSLocalizedString("Failed to load", comment:""),
                            message: NSLocalizedString("Internet is not connected", comment:""))
                        return
                    }
                    var message = NSLocalizedString("Failed to load trending.", comment:"")
                    ViewUtils.showNoticeAlert(self,
                        title: NSLocalizedString("Failed to load", comment:""), message: message)
                    return
                }
                self.trackTableView.tableHeaderView = self.getFollowingHeaderView(following!)
                self.loadFollowingFeed(forceRefresh: forceRefresh, remoteRefresh: remoteRefresh)
            })
            return
        } else if menu.type == .USER_GROUP {
            trackTableView.tableHeaderView = getFriendFeedHeaderView()
        } else {
            trackTableView.tableHeaderView = nil
        }
        
        
        // log ga
        var action:String = "none"
        switch(menu.type) {
        case .TRENDING:
            action = "trending"
            break
        case .FOLLOWING:
            action = "following"
            break
        case .BEATPORT_CHART:
            action = "beatport_chart"
            break
        case .NEW_RELEASE:
            action = "new_release"
            break
        case .NEW_RELEASE:
            action = "user_group"
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
        
        loadFeed(menu.type, forceRefresh: forceRefresh)
    }
    
    func loadFeed(type:FeedType, forceRefresh:Bool=false) {
        switch(type) {
        case .TRENDING:
            loadTrendingFeed(forceRefresh: forceRefresh)
            break
        case .FOLLOWING:
            loadFollowingFeed(forceRefresh: forceRefresh)
            break
        case .BEATPORT_CHART:
            loadBeatportChartFeed(forceRefresh: forceRefresh)
            break
        case .NEW_RELEASE:
            loadNewReleaseFeed(forceRefresh: forceRefresh)
            break
        case .USER_GROUP:
            loadUserGroupFeed(forceRefresh: forceRefresh)
            break
        default:
            break
        }
    }
    
    func refresh() {
        nextPage = selectedFeedMenu.type == FeedType.BEATPORT_CHART ? -1 : 0
        
        loadMoreSpinnerWrapper.hidden = true
        loadMoreSpinner.stopAnimating()
        
        loadFeed(selectedFeedMenu.type, forceRefresh: true)
    }
    
    func loadTrendingFeed(forceRefresh:Bool=false) {
        if selectedGenre == nil {
            selectedGenre = genres[FeedType.TRENDING]![0]
        }
        
        if isLoading {
            return
        }
        
        var progressHud:MBProgressHUD?
        if !refreshControl.refreshing && nextPage == 0 {
            progressHud = ViewUtils.showProgress(self, message: NSLocalizedString("Loading..", comment:""))
        }
        Requests.getStreamTrending(selectedGenre!.key, pageIdx: nextPage, respCb: {
            (req:NSURLRequest, resp:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            self.isLoading = false
            progressHud?.hide(true)
            if self.refreshControl.refreshing {
                self.refreshControl.endRefreshing()
            }
            if (error != nil || result == nil) {
                if (error != nil && error!.domain == NSURLErrorDomain &&
                        error!.code == NSURLErrorNotConnectedToInternet) {
                    ViewUtils.showNoticeAlert(self,
                        title: NSLocalizedString("Failed to load", comment:""),
                        message: NSLocalizedString("Internet is not connected", comment:""))
                    return
                }
                var message = NSLocalizedString("Failed to load trending.", comment:"")
                ViewUtils.showNoticeAlert(self, title: NSLocalizedString("Failed to load", comment:""), message: message)
                return
            }
            
            let parser = Parser()
            var resultTracks:[Track]!
            
            if count(self.selectedGenre!.key) == 0 {
                let streamTrending = parser.parseStreamTrending(result!)
                if !streamTrending.success {
                    var message = NSLocalizedString("Failed to load trending.", comment:"")
                    ViewUtils.showNoticeAlert(self,
                        title: NSLocalizedString("Failed to load", comment:""), message: message)
                    return
                }
                resultTracks = streamTrending.results
            } else {
                let beatportTrending = parser.parseStreamBeatportTrending(result!)
                if !beatportTrending.success {
                    var message = NSLocalizedString("Failed to load trending.", comment:"")
                    ViewUtils.showNoticeAlert(self, title: NSLocalizedString("Failed to load", comment:""), message: message)
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
            
            if forceRefresh {
                self.tracks.removeAll(keepCapacity: true)
            }
            for track in resultTracks {
                self.tracks.append(track)
            }
            self.updatePlaylist(false)
            self.trackTableView.reloadData()
            
            self.updatePlay(PlayerContext.currentTrack, playlistId: PlayerContext.currentPlaylistId)
        })
    }
    
    func loadBeatportChartFeed(forceRefresh:Bool=false) {
        if selectedGenre == nil {
            selectedGenre = genres[FeedType.BEATPORT_CHART]![0]
        }
        
        var progressHud:MBProgressHUD?
        if !refreshControl.refreshing {
            progressHud = ViewUtils.showProgress(self, message: NSLocalizedString("Loading..", comment:""))
        }
        var genreKey = selectedGenre!.name
        if count(selectedGenre!.key) == 0 {
            genreKey = "TOP100"
        }
        Requests.fetchBeatportChart(genreKey, respCb: {
                (request:NSURLRequest, response:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            progressHud?.hide(true)
            if self.refreshControl.refreshing {
                self.refreshControl.endRefreshing()
            }
            
            if (error != nil || result == nil) {
                if (error != nil && error!.domain == NSURLErrorDomain &&
                        error!.code == NSURLErrorNotConnectedToInternet) {
                    ViewUtils.showNoticeAlert(self,
                        title: NSLocalizedString("Failed to load", comment:""),
                        message: NSLocalizedString("Internet is not connected", comment:""))
                    return
                }
                var message = NSLocalizedString("Failed to load chart.", comment:"")
                ViewUtils.showNoticeAlert(self, title: NSLocalizedString("Failed to load", comment:""), message: message)
                return
            }
            
            var parser:Parser = Parser()
            var chart = parser.parseBeatportChart(result!)
            
            if !chart.success {
                var message = NSLocalizedString("Failed to load chart.", comment:"")
                ViewUtils.showNoticeAlert(self, title: NSLocalizedString("Failed to load", comment:""), message: message)
                return
            }
            self.tracks.removeAll(keepCapacity: false)
            for track in chart.results! {
                self.tracks.append(track)
            }
            
            self.updatePlaylist(false)
            self.trackTableView.reloadData()
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
                callback(following: nil,
                    error: NSError(domain: NSLocalizedString("loadFollowingList", comment:""), code:0, userInfo: nil))
                return
            }
            
            callback(following: info.results!, error:nil)
        }
    }
    
    func loadFollowingFeed(forceRefresh:Bool=false, remoteRefresh:Bool=false) {
        if selectedGenre == nil {
            selectedGenre = genres[FeedType.FOLLOWING]![0]
        }
        
        if isLoading {
            return
        }
        
        var progressHud:MBProgressHUD?
        if !refreshControl.refreshing && nextPage == 0 {
            progressHud = ViewUtils.showProgress(self, message: NSLocalizedString("Loading..", comment:""))
        }
        
        Requests.getStreamFollowing(remoteRefresh, pageIdx: nextPage, order:selectedGenre!.key, respCb: {
            (req:NSURLRequest, resp:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            self.isLoading = false
            progressHud?.hide(true)
            if self.refreshControl.refreshing {
                self.refreshControl.endRefreshing()
            }
            if (error != nil || result == nil) {
                if (error != nil && error!.domain == NSURLErrorDomain &&
                        error!.code == NSURLErrorNotConnectedToInternet) {
                    ViewUtils.showNoticeAlert(self,
                        title: NSLocalizedString("Failed to load", comment:""),
                        message: NSLocalizedString("Internet is not connected", comment:""))
                    return
                }
                var message = NSLocalizedString("Failed to load following feed.", comment:"")
                ViewUtils.showNoticeAlert(self, title: NSLocalizedString("Failed to load", comment:""), message: message)
                return
            }
            
            
            let parser = Parser()
            let streamFollowing = parser.parseStreamFollowing(result!)
            if !streamFollowing.success {
                var message = NSLocalizedString("Failed to load following feed.", comment:"")
                ViewUtils.showNoticeAlert(self, title: NSLocalizedString("Failed to load", comment:""), message: message)
                return
            }
            
            if streamFollowing.results!.count == 0 {
                self.nextPage = -1
                self.loadMoreSpinner.stopAnimating()
                self.loadMoreSpinnerWrapper.hidden = true
            } else {
                self.nextPage += 1
            }
            if forceRefresh {
                self.tracks.removeAll(keepCapacity: true)
            }
            for track in streamFollowing.results! {
                self.tracks.append(track)
            }
            self.updatePlaylist(false)
            self.trackTableView.reloadData()
            self.updatePlay(PlayerContext.currentTrack, playlistId: PlayerContext.currentPlaylistId)
        })
    }
    
    func loadNewReleaseFeed(forceRefresh:Bool=false) {
        if selectedGenre == nil {
            selectedGenre = genres[FeedType.NEW_RELEASE]![0]
        }
        
        if isLoading {
            return
        }
        
        var progressHud:MBProgressHUD?
        if !refreshControl.refreshing && nextPage == 0 {
            progressHud = ViewUtils.showProgress(self, message: NSLocalizedString("Loading..", comment:""))
        }
        Requests.getStreamNew(selectedGenre!.key, pageIdx: nextPage, respCb: {
            (req:NSURLRequest, resp:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            self.isLoading = false
            progressHud?.hide(true)
            if self.refreshControl.refreshing {
                self.refreshControl.endRefreshing()
            }
            if (error != nil || result == nil) {
                if (error != nil && error!.domain == NSURLErrorDomain &&
                        error!.code == NSURLErrorNotConnectedToInternet) {
                    ViewUtils.showNoticeAlert(self,
                        title: NSLocalizedString("Failed to load", comment:""),
                        message: NSLocalizedString("Internet is not connected", comment:""))
                    return
                }
                var message = NSLocalizedString("Failed to load new release.", comment:"")
                ViewUtils.showNoticeAlert(self, title: NSLocalizedString("Failed to load", comment:""), message: message)
                return
            }
            
            
            let parser = Parser()
            let streamNew = parser.parseStreamNew(result!)
            if !streamNew.success {
                var message = NSLocalizedString("Failed to load new release.", comment:"")
                ViewUtils.showNoticeAlert(self,
                    title: NSLocalizedString("Failed to load", comment:""), message: message)
                return
            }
            
            if streamNew.results!.count == 0 {
                self.nextPage = -1
                self.loadMoreSpinner.stopAnimating()
                self.loadMoreSpinnerWrapper.hidden = true
            } else {
                self.nextPage += 1
            }
            if forceRefresh {
                self.tracks.removeAll(keepCapacity: true)
            }
            for track in streamNew.results! {
                self.tracks.append(track)
            }
            self.updatePlaylist(false)
            self.trackTableView.reloadData()
            self.updatePlay(PlayerContext.currentTrack, playlistId: PlayerContext.currentPlaylistId)
        })
    }
    
    func loadUserGroupFeed(forceRefresh:Bool=false) {
        if isLoading {
            return
        }
        
        var progressHud:MBProgressHUD?
        if !refreshControl.refreshing && nextPage == 0 {
            progressHud = ViewUtils.showProgress(self, message: NSLocalizedString("Loading..", comment:""))
        }
        Requests.getStreamFriend({(req:NSURLRequest, resp:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            self.isLoading = false
            progressHud?.hide(true)
            if self.refreshControl.refreshing {
                self.refreshControl.endRefreshing()
            }
            if (error != nil || result == nil) {
                if (error != nil && error!.domain == NSURLErrorDomain &&
                        error!.code == NSURLErrorNotConnectedToInternet) {
                    ViewUtils.showNoticeAlert(self,
                        title: NSLocalizedString("Failed to load", comment:""),
                        message: NSLocalizedString("Internet is not connected", comment:""))
                    return
                }
                var message = NSLocalizedString("Failed to load friend feed.", comment:"")
                ViewUtils.showNoticeAlert(self, title: NSLocalizedString("Failed to load", comment:""), message: message)
                return
            }
            
            
            let parser = Parser()
            let streamUserGroup = parser.parseStreamFriend(result!)
            if !streamUserGroup.success {
                var message = NSLocalizedString("Failed to load friend feed.", comment:"")
                ViewUtils.showNoticeAlert(self,
                    title: NSLocalizedString("Failed to load", comment:""), message: message)
                return
            }
            
            if streamUserGroup.results!.count > 0 {
                self.nextPage = -1
                self.loadMoreSpinner.stopAnimating()
                self.loadMoreSpinnerWrapper.hidden = true
            }
            if forceRefresh {
                self.tracks.removeAll(keepCapacity: true)
            }
            for track in streamUserGroup.results! {
                self.tracks.append(track)
            }
            self.updatePlaylist(false)
            self.trackTableView.reloadData()
            self.updatePlay(PlayerContext.currentTrack, playlistId: PlayerContext.currentPlaylistId)
        })
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
        trackTableView.hidden = true
        feedTypeSelectTableView.hidden = false
        genreTableView.hidden = true
        feedTypeSelectBtn.setImage(UIImage(named:"ic_arrow_up.png"), forState: UIControlState.Normal)
        if selectedFeedMenu.type == FeedType.FOLLOWING {
            genreSelectBtn.title = NSLocalizedString("Order", comment:"")
        } else {
            genreSelectBtn.title = NSLocalizedString("Genre", comment:"")
        }
    }
    
    func toFeedView(selected:String) {
        viewMode = ViewMode.Normal
        trackTableView.hidden = false
        feedTypeSelectTableView.hidden = true
        genreTableView.hidden = true
        feedTypeSelectBtn.setImage(UIImage(named:"ic_arrow_down.png"), forState: UIControlState.Normal)
        updateFeedTypeSelectBtn(selected)
        if selectedFeedMenu.type == FeedType.FOLLOWING {
            genreSelectBtn.title = NSLocalizedString("Order", comment:"")
        } else {
            genreSelectBtn.title = NSLocalizedString("Genre", comment:"")
        }
    }
    
    func toGenreSelectView() {
        viewMode = ViewMode.Filter
        trackTableView.hidden = true
        feedTypeSelectTableView.hidden = true
        genreTableView.hidden = false
        feedTypeSelectBtn.setImage(UIImage(named:"ic_arrow_down.png"), forState: UIControlState.Normal)
        genreSelectBtn.title = NSLocalizedString("Close", comment:"")
    }
}
