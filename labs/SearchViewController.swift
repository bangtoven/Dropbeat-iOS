//
//  SearchViewController.swift
//  labs
//
//  Created by vulpes on 2015. 5. 15..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

class SearchResultSections {
    static var TOP_MATCH = "top_match"
    static var RELEASED = "released"
    static var PODCAST = "podcast"
    static var LIVESET = "liveset"
    static var RELEVANT = "relevant"
    static var allValues = [RELEASED, PODCAST, LIVESET, TOP_MATCH, RELEVANT]
}

class SearchViewController: AddableTrackListViewController,
    UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate,
    UISearchBarDelegate, UIActionSheetDelegate, AddableTrackCellDelegate, ScrollPagerDelegate{
    
    private static var sectionTitles = [
        SearchResultSections.RELEASED: NSLocalizedString("OFFICIAL", comment:""),
        SearchResultSections.PODCAST: NSLocalizedString("PODCASTS", comment:""),
        SearchResultSections.LIVESET: NSLocalizedString("LIVE SETS", comment:""),
        SearchResultSections.TOP_MATCH: NSLocalizedString("TOP MATCH", comment:""),
        SearchResultSections.RELEVANT: NSLocalizedString("OTHERS", comment:"")
    ]
    
    @IBOutlet weak var noSearchResultView: UILabel!
    @IBOutlet weak var scrollPagerConstraint: NSLayoutConstraint!
    @IBOutlet weak var searchResultView: UIView!
    @IBOutlet weak var scrollPager: ScrollPager!
    @IBOutlet weak var autocomTableView: UITableView!
    
    private var searchResult:Search?
    private var sectionedTracks = [String:[Track]]()
    private var currentSections:[String]?
    private var currentSection:String?
    private var showAsRowSection = false
    private var autocomKeywords:[String] = []
    private var autocomRequester:AutocompleteRequester?
    private var searchBar:UISearchBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Search bar initialize as code 
        // cause in storyboard cannot set searchbar with full width
        searchBar = UISearchBar()
        searchBar.delegate = self
        navigationItem.titleView = searchBar!
        searchBar.sizeToFit()
        searchBar.placeholder = "Artist or Track"
        searchBar.searchBarStyle = UISearchBarStyle.Minimal
        searchBar.barStyle = UIBarStyle.Default
        searchBar.translucent = false
        searchBar.returnKeyType = UIReturnKeyType.Search
        navigationItem.titleView!.autoresizingMask = UIViewAutoresizing.FlexibleWidth
        navigationItem.rightBarButtonItem = nil
        
        autocomRequester = AutocompleteRequester(handler: onHandleAutocomplete)
        
        scrollPager.font = UIFont.systemFontOfSize(11)
        scrollPager.selectedFont = UIFont.systemFontOfSize(11)
        
        autocomTableView.hidden = true
        searchResultView.hidden = true
        
        
        
        scrollPager.delegate = self
        for section in SearchResultSections.allValues {
            sectionedTracks[section] = [Track]()
        }
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.screenName = "SearchViewScreen"
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func getSectionName() -> String {
       return "search"
    }
    
    override func updatePlay(track:Track?, playlistId:String?) {
        if track == nil {
            return
        }
        var indexPath = trackTableView.indexPathForSelectedRow()
        if (indexPath != nil) {
            var preSelectedTrack:Track?
            preSelectedTrack = tracks[indexPath!.row]
            if (preSelectedTrack != nil &&
                (preSelectedTrack!.id != track!.id ||
                (playlistId != nil && playlistId!.toInt() >= 0))) {
                trackTableView.deselectRowAtIndexPath(indexPath!, animated: false)
            }
        }
        
        if playlistId != nil {
            return
        }
        
        for (idx, t) in enumerate(tracks) {
            if (t.id == track!.id) {
                trackTableView.selectRowAtIndexPath(NSIndexPath(forRow: idx, inSection: 0),
                    animated: false, scrollPosition: UITableViewScrollPosition.None)
                break
            }
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "PlaylistSelectSegue" {
            let playlistSelectVC:PlaylistSelectViewController = segue.destinationViewController as! PlaylistSelectViewController
            playlistSelectVC.targetTrack = sender as? Track
            playlistSelectVC.fromSection = "search"
            playlistSelectVC.caller = self
        }
    }

    @IBAction func onTabed(sender: AnyObject) {
        searchBar!.endEditing(true)
    }
    
    func onHandleAutocomplete(keywords:Array<String>?, error:NSError?) {
        if (error != nil || keywords == nil) {
            println("Failed to get autocomplete:\(error?.description)")
            return
        }
        autocomKeywords.removeAll(keepCapacity: false)
        for keyword in keywords! {
            autocomKeywords.append(keyword)
        }
        autocomTableView.reloadData()
        if (autocomTableView.hidden) {
            showAutocomplete(clear: true)
        }
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        if (count(searchText) == 0) {
            hideAutocomplete()
            searchResultView.hidden = false
        } else {
            autocomRequester?.send(searchText)
            searchResultView.hidden = true
        }
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchBar.endEditing(true)
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchBar.endEditing(true)
        let keyword = searchBar.text
        if count(keyword) == 0 {
            return
        }
        doSearch(keyword)
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if (tableView == trackTableView) {
            var cell:AddableTrackTableViewCell = tableView.dequeueReusableCellWithIdentifier("AddableTrackTableViewCell", forIndexPath: indexPath) as! AddableTrackTableViewCell
            var track:Track!
            if indexPath.section == 0 {
                track = tracks[indexPath.row]
            } else {
                var firstSectionCount:Int = self.tableView(tableView, numberOfRowsInSection: 0)
                track = tracks[indexPath.row + firstSectionCount]
            }
            cell.delegate = self
            cell.nameView.text = track.title
            if track.thumbnailUrl != nil {
                cell.thumbView.sd_setImageWithURL(NSURL(string: track!.thumbnailUrl!),
                        placeholderImage: UIImage(named: "default_artwork"), completed: {
                        (image: UIImage!, error: NSError!, cacheType:SDImageCacheType, imageURL: NSURL!) -> Void in
                    if error != nil {
                        cell.thumbView.image = UIImage(named: "default_artwork")
                    }
                })
            } else {
                cell.thumbView.image = UIImage(named: "default_artwork")
            }
            var dropBtnImageName:String!
            if dropPlayerContext.sectionName == getSectionName() &&
                dropPlayerContext.currentTrack?.id == track.id {
                    switch(dropPlayerContext.playStatus) {
                    case .Playing:
                        dropBtnImageName = "ic_drop_pause_small"
                        break
                    case .Loading:
                        dropBtnImageName = "ic_drop_loading_small"
                        break
                    case .Ready:
                        dropBtnImageName = "ic_drop_small"
                        break
                    }
            } else {
                dropBtnImageName = "ic_drop_small"
            }
            cell.dropBtn.setImage(UIImage(named: dropBtnImageName), forState: UIControlState.Normal)
            cell.dropBtn.hidden = track!.drop == nil
            return cell
        } else {
            var cell:AutocomTableViewCell = tableView.dequeueReusableCellWithIdentifier("AutocomItem", forIndexPath: indexPath) as! AutocomTableViewCell
            let keyword = autocomKeywords[indexPath.row]
            cell.keywordView?.text = keyword
            return cell
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if (tableView == trackTableView) {
            var index:Int = indexPath.row
            if (indexPath.section != 0) {
                index += self.tableView(tableView, numberOfRowsInSection: 0)
            }
            onTrackPlayBtnClicked(tracks[index])
        } else {
            let keyword = autocomKeywords[indexPath.row]
            searchBar!.text = keyword
            searchBar!.endEditing(true)
            doSearch(keyword)
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if (tableView == trackTableView && showAsRowSection) {
            return 2
        }
        return 1
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if (tableView == trackTableView && showAsRowSection) {
            if (section == 0) {
                return "TOP MATCH"
            } else {
                return "OTHER RESULTS"
            }
        }
        return nil
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (tableView == trackTableView) {
            if (currentSection == nil) {
                return 0
            }
            if (showAsRowSection) {
                var count = 0
                for t in tracks {
                    if (t.topMatch ?? false) {
                        count += 1
                    }
                }
                return section == 0 ? count : tracks.count - count
            }
            return tracks.count
        } else {
            return autocomKeywords.count
        }
    }
    
    func hideAutocomplete() {
        autocomTableView.hidden = true
        autocomRequester?.cancelAll()
    }
    
    func showAutocomplete(clear:Bool = false) {
        if (clear) {
            autocomKeywords.removeAll(keepCapacity: false)
            autocomTableView.reloadData()
        }
        autocomTableView.hidden = false
    }
    
    func doSearch(keyword:String) {
        hideAutocomplete()
        
        // stop prev drop
        onDropFinished()
        
        let progressHud = ViewUtils.showProgress(self, message: NSLocalizedString("Searching..", comment:""))
        searchResultView.hidden = false
        
        // Log to Us
        if (Account.getCachedAccount() != nil) {
            Requests.logSearch(keyword)
        }
        // Log to GA
        let tracker = GAI.sharedInstance().defaultTracker
        let event = GAIDictionaryBuilder.createEventWithCategory(
                "search-sectio",
                action: "search-with-keyword",
                label: keyword,
                value: 0
            ).build()
        tracker.send(event as [NSObject: AnyObject]!)
        
        Requests.search(keyword, respCb: {
                (request:NSURLRequest, response:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            progressHud.hide(true)
            if (error != nil || result == nil) {
                if (error != nil && error!.domain == NSURLErrorDomain &&
                        error!.code == NSURLErrorNotConnectedToInternet) {
                    ViewUtils.showNoticeAlert(self,
                        title: NSLocalizedString("Failed to search", comment:""),
                        message: NSLocalizedString("Internet is not connected", comment:""))
                    return
                }
                var message = NSLocalizedString("Failed to search.", comment:"")
                ViewUtils.showNoticeAlert(self, title: NSLocalizedString("Failed to search", comment:""), message: message)
                self.searchResult = nil
                self.sectionedTracks = [String:[Track]]()
                self.tracks.removeAll(keepCapacity: false)
                self.currentSections = nil
                self.currentSection = nil
                
                self.trackTableView.hidden = true
                self.noSearchResultView.hidden = false
                self.trackTableView.reloadData()
                self.updatePlay(PlayerContext.currentTrack, playlistId: PlayerContext.currentPlaylistId)
                return
            }
            self.searchResult = Search.parseSearch(result!)
            
            
            // clear sectionedTracks
            self.showAsRowSection = self.searchResult!.showType == SearchShowType.ROW
            if (self.showAsRowSection) {
                self.sectionedTracks = [String:[Track]]()
                self.sectionedTracks[SearchSections.RELEVANT] = self.searchResult!.getConcatedSectionTracks()
            } else {
                self.sectionedTracks = self.searchResult!.sectionedTracks
            }
            
            // sectionize
            var foundSections:[String] = self.sectionedTracks.keys.array
            if (self.searchResult!.hasPodcast) {
                foundSections.append(SearchSections.PODCAST)
            }
            if (self.searchResult!.hasLiveset) {
                foundSections.append(SearchSections.LIVESET)
            }
            if (find(foundSections, SearchSections.RELEVANT) ?? -1 == -1) {
                foundSections.append(SearchSections.RELEVANT)
            }
            
            foundSections.sort({ (lhs:String, rhs:String) -> Bool in
                var lhsIdx:Int = find(Search.availableSections, lhs) ?? -1
                var rhsIdx:Int = find(Search.availableSections, rhs) ?? -1
                if lhsIdx > -1 && rhsIdx > -1 {
                    return lhsIdx < rhsIdx
                }
                if lhsIdx > -1 {
                    return true
                }
                if rhsIdx > -1 {
                    return false
                }
                return true
            })
            var foundTitles:[String] = foundSections.map {
                return SearchViewController.sectionTitles[$0]!
            }
            if (foundSections.count > 0) {
                self.currentSection = foundSections[0]
            } else {
                self.currentSection = nil
                
                ViewUtils.showNoticeAlert(self, title: NSLocalizedString("Failed to search", comment:""),
                    message: NSLocalizedString("Failed to search.", comment:""))
                self.searchResult = nil
                self.sectionedTracks = [String:[Track]]()
                self.tracks.removeAll(keepCapacity: false)
                self.currentSections = nil
                self.currentSection = nil
                
                self.trackTableView.hidden = true
                self.noSearchResultView.hidden = false
                self.trackTableView.reloadData()
                self.updatePlay(PlayerContext.currentTrack, playlistId: PlayerContext.currentPlaylistId)
                return
            }
            self.currentSections = foundSections
            
            if (self.searchResult!.showType == SearchShowType.ROW) {
                self.scrollPagerConstraint.constant = 0
                self.scrollPager.hidden = true
            } else {
                self.scrollPagerConstraint.constant = 50
                self.scrollPager.addSegmentsWithTitles(foundTitles)
                self.scrollPager.hidden = false
            }
            
            self.tracks.removeAll(keepCapacity: false)
            var tracks = self.sectionedTracks[self.currentSection!]
            if tracks != nil {
                for track in tracks! {
                    self.tracks.append(track)
                }
            }
            
            self.trackTableView.reloadData()
            self.searchResultView.hidden = false
            
            let showNoResultView = self.tracks.count == 0
            self.trackTableView.hidden = showNoResultView
            self.noSearchResultView.hidden = !showNoResultView
            self.updatePlay(PlayerContext.currentTrack, playlistId: PlayerContext.currentPlaylistId)
        })
    }
    
    func selectTab(section:String) {
        // stop prev drop
        onDropFinished()
        
        self.currentSection = section
        var tracks = self.sectionedTracks[self.currentSection!]
        if (tracks == nil) {
            var progress = ViewUtils.showProgress(self, message: NSLocalizedString("Loading..", comment:""))
            let callback = { (tracks: [Track]?, error:NSError?) -> Void in
                progress.hide(true)
                if (error != nil || tracks == nil) {
                    if (error != nil && error!.domain == NSURLErrorDomain &&
                            error!.code == NSURLErrorNotConnectedToInternet) {
                        ViewUtils.showNoticeAlert(self,
                            title: NSLocalizedString("Failed to fetch data", comment:""),
                            message: NSLocalizedString("Internet is not connected", comment:""))
                        return
                    }
                    var message = NSLocalizedString("Failed to fetch data.", comment:"")
                    ViewUtils.showNoticeAlert(self,
                        title: NSLocalizedString("Failed to fetch data", comment:""), message: message)
                    return
                }
                self.tracks.removeAll(keepCapacity: false)
                self.sectionedTracks[self.currentSection!] = tracks
                if (tracks!.count == 0) {
                    ViewUtils.showToast(self, message: NSLocalizedString("No search results", comment:""))
                } else {
                    for track in tracks! {
                        self.tracks.append(track)
                    }
                }
                self.trackTableView.reloadData()
                self.updatePlay(PlayerContext.currentTrack, playlistId: PlayerContext.currentPlaylistId)
            }
            if (self.currentSection == SearchSections.LIVESET) {
                self.searchResult!.fetchListset(callback)
            } else if (self.currentSection == SearchSections.PODCAST) {
                self.searchResult!.fetchPodcast(callback)
            } else if (self.currentSection == SearchSections.RELEVANT) {
                self.searchResult!.fetchRelevant(callback)
            }
        } else {
            self.tracks.removeAll(keepCapacity: false)
            if (tracks!.count == 0) {
                ViewUtils.showToast(self, message: NSLocalizedString("No search results", comment:""))
            } else {
                for track in tracks! {
                    self.tracks.append(track)
                }
            }
            self.trackTableView.reloadData()
            self.updatePlay(PlayerContext.currentTrack, playlistId: PlayerContext.currentPlaylistId)
        }
        trackTableView.setContentOffset(CGPointZero, animated:false)
    }
    
    func scrollPager(scrollPager: ScrollPager, changedIndex: Int) {
        if (self.currentSections == nil || self.searchResult == nil) {
            return
        }
        selectTab(self.currentSections![changedIndex])
    }
    
}
