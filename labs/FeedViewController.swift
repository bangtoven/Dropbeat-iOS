//
//  ViewController.swift
//  labs
//
//  Created by Park Il Su on 2015. 5. 14..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

enum FeedType: String {
    case NEW_UPLOADS = "new_uploads"
    case POPULAR_NOW = "popular_now"
    case NEW_RELEASE = "new_release"
    case DAILY_CHART = "daily_chart"
    case FOLLOWING_TRACKS = "following_tracks"
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

extension FeedViewController: ScrollPagerDelegate {
    @IBAction func likeAction(sender: UIButton) {
        let indexPath = self.trackTableView.indexPathOfCellContains(sender)
        let track = self.tracks[indexPath!.row]
        
        self.onTrackLikeBtnClicked(track) {
            let likeImage = track.isLiked ? UIImage(named:"ic_like") : UIImage(named:"ic_dislike")
            sender.setImage(likeImage, forState: UIControlState.Normal)
        }
    }
    
    @IBAction func addToPlaylistAction(sender: UIButton) {
        let indexPath = self.trackTableView.indexPathOfCellContains(sender)
        let track = self.tracks[indexPath!.row]
        
        self.onTrackAddBtnClicked(track)
    }
    
    @IBAction func shareAction(sender: UIButton) {
        let indexPath = self.trackTableView.indexPathOfCellContains(sender)
        let track = self.tracks[indexPath!.row]
        
        self.onTrackShareBtnClicked(track)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch segue.identifier! {
        case "PlaylistSelectSegue":
            let playlistSelectVC:PlaylistSelectViewController = segue.destinationViewController as! PlaylistSelectViewController
            playlistSelectVC.targetTrack = sender as? Track
            playlistSelectVC.fromSection = "feed_" + selectedFeedMenu.type.rawValue
            playlistSelectVC.caller = self
        case "showUserInfo":
            let indexPath = self.trackTableView.indexPathOfCellContains(sender as! UIButton)
            let track = self.tracks[indexPath!.row]
            
            let mySegue = segue as! JHImageTransitionSegue
            let sourceImageView = (self.trackTableView.cellForRowAtIndexPath(indexPath!) as! DropbeatTrackTableViewCell).userProfileImageView
            
            mySegue.setSourceImageView(sourceImageView)
            mySegue.sourceRect = sourceImageView.convertRect(sourceImageView.bounds, toView: self.view)
            mySegue.destinationRect = self.view.convertRect(UserHeaderView.profileImageRect(self), fromView: nil)
            
            let uvc = segue.destinationViewController as! UserViewController
            uvc.resource = track.user?.resourceName
            uvc.passedImage = sourceImageView.image
            
        default:
            break
        }
    }
    
    func updateTrackCellImageOffset(cell: DropbeatTrackTableViewCell) {
        let imageOverflowHeight = cell.thumbView.frame.size.height / 3
        let cellOffset = CGRectGetMaxY(cell.frame) - self.trackTableView.contentOffset.y
        let maxOffset = self.trackTableView.frame.height + cell.frame.height
        let verticalOffset = imageOverflowHeight * (0.5 - cellOffset/maxOffset)
        
        cell.thumnailCenterConstraint.constant = verticalOffset
    }
    
    func getDropbeatTrackCell(indexPath:NSIndexPath) -> AddableTrackTableViewCell {
        let cell = trackTableView.dequeueReusableCellWithIdentifier(
            "DropbeatTrackTableViewCell", forIndexPath: indexPath) as! DropbeatTrackTableViewCell
        
        cell.delegate = self
        
        let track = tracks[indexPath.row]
        cell.nameView.text = track.title
        cell.releaseDateLabel.text = track.releaseDate?.timeAgoSinceNow()
        
        cell.thumbView.setImageForTrack(track, size: .LARGE, needsHighDef: false)
        
        cell.userNameView.text = track.user?.name
        if let imageUrl = track.user?.image {
            cell.userProfileImageView.sd_setImageWithURL(NSURL(string: imageUrl), placeholderImage: UIImage(named: "default_profile"))
        } else {
            cell.userProfileImageView.image = UIImage(named: "default_profile")
        }
        
        let likeImage = track.isLiked ? UIImage(named:"ic_like") : UIImage(named:"ic_dislike")
        cell.likeButton.setImage(likeImage, forState: UIControlState.Normal)
    
        if let dropbeatTrack = track as? DropbeatTrack {
            cell.genreView.hidden = false
            cell.genreView.text = dropbeatTrack.genre
        } else {
            cell.genreView.hidden = true
        }
        
        return cell
    }
    
    func loadNewUploadsFeed(forceRefresh:Bool=false) {
        if isLoading {
            return
        }
        
        let order = DropbeatTrack.Order(rawValue: newUploadsSelectedIndex)
        
        var progressHud:MBProgressHUD?
        if !refreshControl.refreshing && nextPage <= 0 {
            progressHud = ViewUtils.showProgress(self, message: NSLocalizedString("Loading..", comment:""))
        }
        DropbeatTrack.fetchNewUploads(order!, pageIdx: nextPage) { (tracks, error) -> Void in
            self.isLoading = false
            progressHud?.hide(true)
            if self.refreshControl.refreshing {
                self.refreshControl.endRefreshing()
            }
            if (error != nil || tracks == nil) {
                if (error != nil && error!.domain == NSURLErrorDomain &&
                    error!.code == NSURLErrorNotConnectedToInternet) {
                        ViewUtils.showNoticeAlert(self,
                            title: NSLocalizedString("Failed to load", comment:""),
                            message: NSLocalizedString("Internet is not connected", comment:""))
                        return
                }
                let message = NSLocalizedString("Failed to load new uploads feed.", comment:"")
                ViewUtils.showNoticeAlert(self, title: NSLocalizedString("Failed to load", comment:""), message: message)
                return
            }
            
            if tracks == nil || tracks!.count == 0 {
                if order == .POPULAR {
                    print("popular feed is empty.")
                    self.newUploadsSegment.setSelectedIndex(1, animated: true)
                    self.scrollPager(self.newUploadsSegment, changedIndex: 1)
                    self.newUploadsSegment.setEnableAtIndex(0, enable: false)
                    ViewUtils.showToast(self, message: "on preparing")
                    return
                }
                self.nextPage = -1
                self.loadMoreSpinner.stopAnimating()
                self.loadMoreSpinnerWrapper.hidden = true
            } else if order == .RECENT {
                self.nextPage += 1
            }
            
            if forceRefresh {
                self.tracks.removeAll(keepCapacity: true)
            }
            for track in tracks! {
                self.tracks.append(track)
            }
            self.updatePlaylist(false)
            self.trackTableView.reloadData()
            
            self.trackChanged()
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        switch (selectedFeedMenu.type) {
        case .NEW_UPLOADS, .FOLLOWING_TRACKS:
            for cell in self.trackTableView.visibleCells {
                self.updateTrackCellImageOffset(cell as! DropbeatTrackTableViewCell)
            }
            break
        default:
            break
        }
    }
    
    func scrollPager(scrollPager: ScrollPager, changedIndex: Int) {
        self.newUploadsSelectedIndex = changedIndex
        nextPage = 0
        self.lastContentOffset = CGPointZero
        loadNewUploadsFeed(true)
    }
    
    func setNavigationBarBorderHidden(hidden: Bool) {
        guard let navBar = self.navigationController?.navigationBar else {
            return
        }
        
        navBar.shadowImage = hidden ? UIImage() : nil
    }
}


class FeedViewController: AddableTrackListViewController, UITableViewDelegate, UITableViewDataSource {
 
    @IBOutlet var newUploadsSegment: ScrollPager!
    private var newUploadsSelectedIndex = 0
    var lastContentOffset: CGPoint = CGPointZero
    
    @IBOutlet var followGuideHeaderView: UIView!
    
    @IBOutlet weak var loadMoreSpinner: UIActivityIndicatorView!
    @IBOutlet weak var loadMoreSpinnerWrapper: UIView!
    @IBOutlet weak var feedTypeSelectBtn: UIButton!
    @IBOutlet weak var feedTypeSelectBtnWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var feedTypeSelectTableView: UITableView!
    @IBOutlet weak var genreTableView: UITableView!
    @IBOutlet var genreSelectBtn: UIBarButtonItem!
    
    private var refreshControl: UIRefreshControl!
    
    private var genres:[FeedType:[Genre]] = [FeedType:[Genre]]()
    private var feedTypeSelectMode:Int = 0
    private var viewMode:ViewMode = ViewMode.Normal
    private var nextPage:Int = 0
    private var isLoading:Bool = false
            
    private var selectedGenre:Genre?
    
    private var selectedFeedMenu:FeedMenu!
    private var genreInitialized:Bool = false
    
    private let feedMenus:[FeedMenu] = {
        var types = [FeedMenu]()
        if let user = Account.getCachedAccount()?.user where user.num_following > 0 {
            types.append(FeedMenu(title: NSLocalizedString("Following Tracks", comment:""), type: FeedType.FOLLOWING_TRACKS))
        }
        types.append(FeedMenu(title: NSLocalizedString("New Uploads", comment:""), type: FeedType.NEW_UPLOADS))
        types.append(FeedMenu(title: NSLocalizedString("Popular Now", comment:""), type: FeedType.POPULAR_NOW))
        types.append(FeedMenu(title: NSLocalizedString("New Releases", comment:""), type: FeedType.NEW_RELEASE))
        types.append(FeedMenu(title: NSLocalizedString("Daily Chart", comment:""), type: FeedType.DAILY_CHART))
        return types
    }()
    
    private var userGroupSizingCell:DropbeatTrackTableViewCell! = nil;
    private var onceToken:dispatch_once_t = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.newUploadsSegment.addSegmentsWithTitles(["Popular","Recent"])
        self.newUploadsSegment.delegate = self
        
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
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        trackTableView.contentInset = UIEdgeInsetsZero
        
        let insets = UIEdgeInsetsMake(topLayoutGuide.length, 0, 44, 0)
        feedTypeSelectTableView.contentInset = insets
        genreTableView.contentInset = insets
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

        if selectedFeedMenu.type == .NEW_UPLOADS{
            self.setNavigationBarBorderHidden(true)
        }
        
        if self.tabBarController?.selectedIndex != 0 {
            feedTypeSelectTableView.reloadData()
            
            if selectedFeedMenu.type == .FOLLOWING_TRACKS {
                self.nextPage = 0
                loadFollowingTracks(true)
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.setNavigationBarBorderHidden(false)
    }
    
    override func appWillEnterForeground() {
        if genreInitialized {
            switchFeed(selectedFeedMenu, genre:selectedGenre)
        }
        super.appWillEnterForeground()
    }
    
    override func getPlaylistId() -> String? {
        var prefix = selectedFeedMenu.type.rawValue
        if selectedGenre != nil{
            prefix += "_\(selectedGenre!.key)"
        }
        return prefix
    }
    
    override func getPlaylistName() -> String? {
        var prefix:String? = nil
        switch (selectedFeedMenu.type) {
        case .NEW_UPLOADS:
            prefix = NSLocalizedString("New Uploads", comment:"")
        case .DAILY_CHART:
            prefix = NSLocalizedString("Daily Chart", comment:"")
            break
        case .NEW_RELEASE:
            prefix = NSLocalizedString("New Releases", comment:"")
            break
        case .POPULAR_NOW:
            prefix = NSLocalizedString("Popular Now", comment:"")
            break
        case .FOLLOWING_TRACKS:
            prefix = NSLocalizedString("Following Tracks", comment:"")
            break
        }
        if prefix != nil && selectedGenre != nil {
            prefix! += " - \(selectedGenre!.name)"
        }
        return prefix
    }
    
    override func getSectionName() -> String {
        return "feed_" + selectedFeedMenu.type.rawValue
    }
    
    func initGenres(callback:(error:NSError?) -> Void) {
        let genreHandler = {(genreMap:[String:[Genre]]) -> Void in
            self.genres[FeedType.DAILY_CHART] = genreMap["default"]
            self.genres[FeedType.NEW_RELEASE] = genreMap["default"]
            self.genres[FeedType.POPULAR_NOW] = genreMap["trending"]
            
            self.genreInitialized = true
            callback(error: nil)
        }
        
        if let cachedGenreMap = GenreList.cachedResult {
            genreHandler(cachedGenreMap)
            return
        }
        
        Requests.getFeedGenre {
                (req, resp, result, error) -> Void in
            if error != nil || result == nil {
                callback(error:error != nil ? error : NSError(domain: "initGenre", code:0, userInfo:nil))
                return
            }
            
            let genreList = GenreList.parseGenre(result!)
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
        let image = feedTypeSelectBtn.imageView!.image
        let genreStr:NSString = typeName! as NSString
        feedTypeSelectBtn.setTitle(typeName!, forState: UIControlState.Normal)
        
        var attr:[String : UIFont] = [String: UIFont]()
        if SYSTEM_VERSION_LESS_THAN("8.2") {
            attr[ NSFontAttributeName] = UIFont.systemFontOfSize(18)
        } else {
            if #available(iOS 8.2, *) {
                attr[ NSFontAttributeName] = UIFont.systemFontOfSize(18, weight: UIFontWeightBold)
            } else {
                // Fallback on earlier versions
            }
        }
        let textSize:CGSize = genreStr.sizeWithAttributes(attr)
        let textWidth = textSize.width;
        
        //or whatever font you're using
        let frame = feedTypeSelectBtn.frame
        let origin = feedTypeSelectBtn.frame.origin
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
        
        switch selectedFeedMenu.type {
        case .NEW_RELEASE:
            let trackCell = cell as! NewReleasedTrackTableViewCell
            trackCell.titleWidthConstaint.constant = self.view.bounds.width - marginWidth
            trackCell.artistWidthConstraint.constant = self.view.bounds.width - marginWidth
        case .POPULAR_NOW:
            if selectedGenre != nil && selectedGenre!.key.characters.count > 0 {
                let trackCell = cell as! BpTrendingTrackTableViewCell
                trackCell.titleWidthConstaint.constant = self.view.bounds.width - marginWidth
                trackCell.artistWidthConstraint.constant = self.view.bounds.width - marginWidth
            } else {
                let trackCell = cell as! TrendingTrackTableViewCell
                trackCell.titleWidthConstaint.constant = self.view.bounds.width - marginWidth
                trackCell.artistWidthConstraint.constant = self.view.bounds.width - marginWidth
            }
        case .DAILY_CHART:
            break
        case .NEW_UPLOADS, .FOLLOWING_TRACKS:
            // for parallax effect
            let trackCell = cell as! DropbeatTrackTableViewCell
            self.updateTrackCellImageOffset(trackCell)
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
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if tableView == feedTypeSelectTableView {
            return 60
        }
        if tableView == genreTableView {
            return 60
        }
        switch(selectedFeedMenu.type) {
        case .FOLLOWING_TRACKS, .NEW_UPLOADS:
            return self.view.bounds.width * 0.5 + 60
        case .POPULAR_NOW :
            return (15 * self.view.bounds.width / 30) + 52
        case .NEW_RELEASE:
            return (15 * self.view.bounds.width / 30) + 52
        case .DAILY_CHART:
            return 76
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
            self.needsBigSizeDropButton = true

            var cell:AddableTrackTableViewCell!
            switch (selectedFeedMenu.type) {
            case .FOLLOWING_TRACKS:
                cell = getDropbeatTrackCell(indexPath)
            case .NEW_UPLOADS:
                cell = getDropbeatTrackCell(indexPath)
            case .DAILY_CHART:
                cell = getBeatportChartCell(indexPath)
                self.needsBigSizeDropButton = false
            case .NEW_RELEASE:
                cell = getNewReleaseCell(indexPath)
            case .POPULAR_NOW:
                cell = selectedGenre != nil && selectedGenre!.key.characters.count > 0 ?
                    getBeatportTrendingCell(indexPath) : getTrendingCell(indexPath)
            }
            let track = tracks[indexPath.row]
            if (getPlaylistId() == DropbeatPlayer.defaultPlayer.currentPlaylist?.id &&
                    DropbeatPlayer.defaultPlayer.currentTrack != nil &&
                    DropbeatPlayer.defaultPlayer.currentTrack!.id == track.id) {
                cell.setSelected(true, animated: false)
            }
            
            self.setDropButtonForCellWithTrack(cell, track: track)

            return cell
        }
    }
    
    func getBeatportChartCell(indexPath:NSIndexPath) -> AddableTrackTableViewCell{
        let cell:BpChartTrackTableViewCell = trackTableView.dequeueReusableCellWithIdentifier(
            "BpChartTrackTableViewCell", forIndexPath: indexPath) as! BpChartTrackTableViewCell
        let track:BeatportTrack = tracks[indexPath.row] as! BeatportTrack
        cell.delegate = self
        cell.nameView.text = track.trackName
        cell.genreName.text = track.genre
        cell.genreName.hidden = track.genre == nil
        cell.artistName.text = track.artist
        cell.rank.text = "\(indexPath.row + 1)"
        
        cell.thumbView.setImageForTrack(track, size: .SMALL)

        return cell
    }
    
    func getTrendingCell(indexPath:NSIndexPath) -> AddableTrackTableViewCell{
        let cell:TrendingTrackTableViewCell = trackTableView.dequeueReusableCellWithIdentifier(
            "TrendingTrackTableViewCell", forIndexPath: indexPath) as! TrendingTrackTableViewCell
        let track:TrendingTrack = tracks[indexPath.row] as! TrendingTrack
        cell.delegate = self
        cell.nameView.text = track.trackName
        cell.snippet.text = track.snippet
        cell.artistName.text = track.artist
        cell.rank.text = "\(indexPath.row + 1)"
        
        cell.thumbView.setImageForTrack(track, size: .LARGE, needsHighDef: false)
        
        return cell
    }
    
    func getBeatportTrendingCell(indexPath:NSIndexPath) -> AddableTrackTableViewCell {
        let cell:BpTrendingTrackTableViewCell = trackTableView.dequeueReusableCellWithIdentifier(
            "BpTrendingTrackTableViewCell", forIndexPath: indexPath) as! BpTrendingTrackTableViewCell
        let track:BeatportTrack = tracks[indexPath.row] as! BeatportTrack
        cell.delegate = self
        cell.nameView.text = track.trackName
        cell.artistName.text = track.artist
        cell.rank.text = "\(indexPath.row + 1)"
        
        cell.releasedAt.hidden = track.releasedAt == nil
        if track.releasedAt != nil {
            let dateString = track.releasedAt!.formattedDateWithFormat("MMMM dd, yyyy", locale: NSLocale(localeIdentifier: "en_US_POSIX"))
            cell.releasedAt.text = "Released on \(dateString)"
        }
        
        cell.thumbView.setImageForTrack(track, size: .LARGE, needsHighDef: false)
        
        return cell
    }
    
    func getNewReleaseCell(indexPath:NSIndexPath) -> AddableTrackTableViewCell{
        let cell:NewReleasedTrackTableViewCell = trackTableView.dequeueReusableCellWithIdentifier(
            "NewReleasedTrackTableViewCell", forIndexPath: indexPath) as! NewReleasedTrackTableViewCell
        let track:NewReleaseTrack = tracks[indexPath.row] as! NewReleaseTrack
        cell.delegate = self
        cell.nameView.text = track.trackName
        cell.artistName.text = track.artist

        cell.releasedAt.hidden = track.releasedAt == nil
        if track.releasedAt != nil {
            let dateString = track.releasedAt!.formattedDateWithFormat("MMMM dd, yyyy", locale: NSLocale(localeIdentifier: "en_US_POSIX"))
            cell.releasedAt.text = "Released on \(dateString)"
        }
        
        cell.thumbView.setImageForTrack(track, size: .LARGE, needsHighDef: false)
        
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
    
    func filterAsGenre(genre:Genre) {
        switchFeed(selectedFeedMenu, genre: genre)
        toFeedView(selectedFeedMenu.title)
    }
    
    @IBAction func onGenreBtnClicked(sender: AnyObject) {
        if viewMode == ViewMode.Filter {
            toFeedView(selectedFeedMenu.title)
        } else {
            toGenreSelectView()
        }
    }
    
    func switchFeed(menu:FeedMenu, genre:Genre?=nil, forceRefresh:Bool=false, remoteRefresh:Bool=false) {

        self.setNavigationBarBorderHidden(menu.type == .NEW_UPLOADS)
        
        updateDropPlayState(.Ready)
        updateFeedTypeSelectBtn(menu.title)
        switch menu.type {
        case .DAILY_CHART:
            nextPage = -1
        case .NEW_UPLOADS where self.newUploadsSelectedIndex == 0:
            nextPage = -1
        default:
            nextPage = 0
        }
        tracks.removeAll(keepCapacity: false)
        trackTableView.reloadData()
        genreTableView.reloadData()
        
        loadMoreSpinnerWrapper.hidden = true
        loadMoreSpinner.stopAnimating()
        
        trackTableView.backgroundColor = UIColor(netHex: 0xffffff)
        
//        genreSelectBtn.title = NSLocalizedString("Genre", comment:"")
        
        if genres[menu.type]?.count > 0 {
            genreSelectBtn.title = NSLocalizedString("Genre", comment:"")
            genreSelectBtn.enabled = true
//            navigationItem.leftBarButtonItems = [genreSelectBtn]
        } else {
            genreSelectBtn.title = ""
            genreSelectBtn.enabled = false
//            navigationItem.leftBarButtonItems = []
        }
        
        if genreTableView.indexPathForSelectedRow != nil {
            let selectedIndexPath = genreTableView.indexPathForSelectedRow!
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
            for (idx, g): (Int, Genre) in (menuGenres!).enumerate() {
                if g.name == selectedGenre!.name {
                    foundIdx = idx
                    break
                }
            }
            if foundIdx >= 0 {
                genreTableView.selectRowAtIndexPath(NSIndexPath(forRow: foundIdx, inSection: 0), animated: false, scrollPosition: UITableViewScrollPosition.None)
            }
        }
        
        if trackTableView.indexPathForSelectedRow != nil {
            let selectedIndexPath = trackTableView.indexPathForSelectedRow!
            trackTableView.deselectRowAtIndexPath(selectedIndexPath, animated: false)
        }
        
        switch menu.type {
        case .NEW_UPLOADS:
            trackTableView.tableHeaderView = self.newUploadsSegment
        default:
            trackTableView.tableHeaderView = nil
        }
        
        
        // log ga
        var action = menu.type.rawValue
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
    
    func refresh() {
        switch selectedFeedMenu.type {
        case .DAILY_CHART:
            nextPage = -1
        case .NEW_UPLOADS where self.newUploadsSelectedIndex == 0:
            nextPage = -1
        default:
            nextPage = 0
        }
        
        loadMoreSpinnerWrapper.hidden = true
        loadMoreSpinner.stopAnimating()
        
        loadFeed(selectedFeedMenu.type, forceRefresh: true)
    }
    
    override func trackChanged() {
        if self.nextPage > 1 {
            print("pagenation in same tab.")
        } else {
            super.trackChanged()
        }
    }
    
    func loadFeed(type:FeedType, forceRefresh:Bool=false) {
        self.lastContentOffset = CGPointZero
        
        switch(type) {
        case .FOLLOWING_TRACKS:
            loadFollowingTracks(forceRefresh)
        case .NEW_UPLOADS:
            loadNewUploadsFeed(forceRefresh)
        case .POPULAR_NOW:
            loadTrendingFeed(forceRefresh)
        case .DAILY_CHART:
            loadBeatportChartFeed(forceRefresh)
        case .NEW_RELEASE:
            loadNewReleaseFeed(forceRefresh)
        }
    }
    
    func loadFollowingTracks(forceRefresh:Bool=false) {
        if isLoading {
            return
        }
        
        var progressHud:MBProgressHUD?
        if !refreshControl.refreshing && nextPage <= 0 {
            progressHud = ViewUtils.showProgress(self, message: NSLocalizedString("Loading..", comment:""))
        }
        DropbeatTrack.fetchFollowingTracks(nextPage) { (tracks, error) -> Void in
            self.isLoading = false
            progressHud?.hide(true)
            if self.refreshControl.refreshing {
                self.refreshControl.endRefreshing()
            }
            if (error != nil || tracks == nil) {
                if (error != nil && error!.domain == NSURLErrorDomain &&
                    error!.code == NSURLErrorNotConnectedToInternet) {
                        ViewUtils.showNoticeAlert(self,
                            title: NSLocalizedString("Failed to load", comment:""),
                            message: NSLocalizedString("Internet is not connected", comment:""))
                        return
                }
                let message = NSLocalizedString("Failed to load following tracks feed.", comment:"")
                ViewUtils.showNoticeAlert(self, title: NSLocalizedString("Failed to load", comment:""), message: message)
                return
            }
            
            if tracks!.count == 0 {
                self.nextPage = -1
                self.loadMoreSpinner.stopAnimating()
                self.loadMoreSpinnerWrapper.hidden = true
                
                self.trackTableView.tableHeaderView = self.followGuideHeaderView
            } else {
                // when the user only follows Dropbeat official
                CheckOnlyFollowDropbeat: if (self.nextPage == 0) {
                    guard let user = Account.getCachedAccount()?.user
                        where user.num_following == 1 else {
                            break CheckOnlyFollowDropbeat
                    }
                    
                    guard let dropbeat = tracks![0].user as? User
                        where dropbeat.resourceName == "dropbeat" else {
                            break CheckOnlyFollowDropbeat
                    }
                    
                    self.trackTableView.tableHeaderView = self.followGuideHeaderView
                }

                self.nextPage += 1
            }
            
            if forceRefresh {
                self.tracks.removeAll(keepCapacity: true)
            }
            for track in tracks! {
                self.tracks.append(track)
            }
            self.updatePlaylist(false)
            self.trackTableView.reloadData()
            
            self.trackChanged()
        }
    }
    
    func loadTrendingFeed(forceRefresh:Bool=false) {
        if selectedGenre == nil {
            selectedGenre = genres[FeedType.POPULAR_NOW]![0]
        }
        
        if isLoading {
            return
        }
        
        var progressHud:MBProgressHUD?
        if !refreshControl.refreshing && nextPage == 0 {
            progressHud = ViewUtils.showProgress(self, message: NSLocalizedString("Loading..", comment:""))
        }
        Requests.getStreamTrending(selectedGenre!.key, pageIdx: nextPage, respCb: {
            (req, resp, result, error) -> Void in
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
                let message = NSLocalizedString("Failed to load trending.", comment:"")
                ViewUtils.showNoticeAlert(self, title: NSLocalizedString("Failed to load", comment:""), message: message)
                return
            }
            
            var resultTracks:[Track]!
            
            if self.selectedGenre!.key.characters.count == 0 {
                let streamTrending = StreamTrending.parseStreamTrending(result!)
                if !streamTrending.success {
                    let message = NSLocalizedString("Failed to load trending.", comment:"")
                    ViewUtils.showNoticeAlert(self,
                        title: NSLocalizedString("Failed to load", comment:""), message: message)
                    return
                }
                resultTracks = streamTrending.results
            } else {
                let beatportTrending = StreamBeatportTrending.parseStreamBeatportTrending(result!)
                if !beatportTrending.success {
                    let message = NSLocalizedString("Failed to load trending.", comment:"")
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
            
            self.trackChanged()
        })
    }
    
    func loadBeatportChartFeed(forceRefresh:Bool=false) {
        if selectedGenre == nil {
            selectedGenre = genres[FeedType.DAILY_CHART]![0]
        }
        
        var progressHud:MBProgressHUD?
        if !refreshControl.refreshing {
            progressHud = ViewUtils.showProgress(self, message: NSLocalizedString("Loading..", comment:""))
        }
        var genreKey = selectedGenre!.name
        if selectedGenre!.key.characters.count == 0 {
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
                let message = NSLocalizedString("Failed to load chart.", comment:"")
                ViewUtils.showNoticeAlert(self, title: NSLocalizedString("Failed to load", comment:""), message: message)
                return
            }
            
            let chart = BeatportChart.parseBeatportChart(result!)
            
            if !chart.success {
                let message = NSLocalizedString("Failed to load chart.", comment:"")
                ViewUtils.showNoticeAlert(self, title: NSLocalizedString("Failed to load", comment:""), message: message)
                return
            }
            self.tracks.removeAll(keepCapacity: false)
            for track in chart.results! {
                self.tracks.append(track)
            }
            
            self.updatePlaylist(false)
            self.trackTableView.reloadData()
            self.trackChanged()
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
            (req, resp, result, error) -> Void in
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
                let message = NSLocalizedString("Failed to load new release.", comment:"")
                ViewUtils.showNoticeAlert(self, title: NSLocalizedString("Failed to load", comment:""), message: message)
                return
            }
            
            
            let streamNew = StreamNew.parseStreamNew(result!)
            if !streamNew.success {
                let message = NSLocalizedString("Failed to load new release.", comment:"")
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
            self.trackChanged()
        })
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
        feedTypeSelectBtn.setImage(UIImage(named:"ic_arrow_up"), forState: UIControlState.Normal)
//        genreSelectBtn.title = NSLocalizedString("Genre", comment:"")
    }
    
    func toFeedView(selected:String) {
        viewMode = ViewMode.Normal
        trackTableView.hidden = false
        feedTypeSelectTableView.hidden = true
        genreTableView.hidden = true
        feedTypeSelectBtn.setImage(UIImage(named:"ic_arrow_down"), forState: UIControlState.Normal)
        updateFeedTypeSelectBtn(selected)
//        genreSelectBtn.title = NSLocalizedString("Genre", comment:"")
    }
    
    func toGenreSelectView() {
        viewMode = ViewMode.Filter
        trackTableView.hidden = true
        feedTypeSelectTableView.hidden = true
        genreTableView.hidden = false
        feedTypeSelectBtn.setImage(UIImage(named:"ic_arrow_down"), forState: UIControlState.Normal)
        genreSelectBtn.title = NSLocalizedString("Close", comment:"")
    }
}
