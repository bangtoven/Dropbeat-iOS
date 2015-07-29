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

class SearchViewController: BaseViewController,
    UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate,
    UISearchBarDelegate, UIActionSheetDelegate, AddableTrackCellDelegate, ScrollPagerDelegate{
    
    private static var sectionTitles = [
        SearchResultSections.RELEASED: "OFFICIAL",
        SearchResultSections.PODCAST: "PODCASTS",
        SearchResultSections.LIVESET: "LIVE SETS",
        SearchResultSections.TOP_MATCH: "TOP_MATCH",
        SearchResultSections.RELEVANT: "OTHERS"
    ]
    
    var searchResult:Search?
    var sectionedTracks = [String:[Track]]()
    var currentSections:[String]?
    var currentSection:String?
    var showAsRowSection = false
    var autocomKeywords:[String] = []
    var autocomRequester:AutocompleteRequester?
    var searchBar:UISearchBar?
    var actionSheetTargetTrack:Track?
    
//    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet var tabGestureRecognizer: UITapGestureRecognizer!
    @IBOutlet weak var scrollPagerConstraint: NSLayoutConstraint!
    @IBOutlet weak var searchResultView: UIView!
    @IBOutlet weak var scrollPager: ScrollPager!
    @IBOutlet weak var autocomTableView: UITableView!
    @IBOutlet weak var resultTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Search bar initialize as code 
        // cause in storyboard cannot set searchbar with full width
        searchBar = UISearchBar()
        searchBar!.delegate = self
        navigationItem.titleView = searchBar!
        searchBar!.sizeToFit()
        searchBar!.placeholder = "Artist or Track"
        searchBar!.searchBarStyle = UISearchBarStyle.Minimal
        searchBar!.barStyle = UIBarStyle.Default
        searchBar!.translucent = false
        searchBar!.returnKeyType = UIReturnKeyType.Search
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
        
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "updatePlay:", name: NotifyKey.updatePlay, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "sender", name: NotifyKey.playerPlay, object: nil)
    }
    
    override func viewDidDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotifyKey.updatePlay, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotifyKey.playerPlay, object: nil)
    }
    
    func sender () {}

    @IBAction func onTabed(sender: AnyObject) {
        searchBar!.endEditing(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        if (tableView == resultTableView) {
            var cell:AddableTrackTableViewCell = tableView.dequeueReusableCellWithIdentifier("AddableTrackTableViewCell", forIndexPath: indexPath) as! AddableTrackTableViewCell
            let tracks:[Track] = sectionedTracks[currentSection!]!
            var track:Track?
            if (indexPath.section == 0) {
                track = tracks[indexPath.row]
            } else {
                var firstSectionCount:Int = self.tableView(tableView, numberOfRowsInSection: 0)
                track = tracks[indexPath.row + firstSectionCount]
            }
            cell.delegate = self
            cell.nameView.text = track!.title
            if (track!.thumbnailUrl != nil) {
                cell.thumbView.sd_setImageWithURL(NSURL(string: track!.thumbnailUrl!),
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
        } else {
            var cell:AutocomTableViewCell = tableView.dequeueReusableCellWithIdentifier("AutocomItem", forIndexPath: indexPath) as! AutocomTableViewCell
            let keyword = autocomKeywords[indexPath.row]
            cell.keywordView?.text = keyword
            return cell
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if (tableView == resultTableView) {
            let tracks:[Track] = sectionedTracks[currentSection!]!
            var index:Int = indexPath.row
            if (indexPath.section != 0) {
                index += self.tableView(tableView, numberOfRowsInSection: 0)
            }
            onPlayBtnClicked(tracks[index])
        } else {
            let keyword = autocomKeywords[indexPath.row]
            searchBar!.text = keyword
            searchBar!.endEditing(true)
            doSearch(keyword)
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if (tableView == resultTableView && showAsRowSection) {
            return 2
        }
        return 1
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if (tableView == resultTableView && showAsRowSection) {
            if (section == 0) {
                return "TOP MATCH"
            } else {
                return "OTHER RESULTS"
            }
        }
        return nil
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (tableView == resultTableView) {
            if (currentSection == nil) {
                return 0
            }
            let tracks:[Track]? = sectionedTracks[currentSection!]
            if (tracks == nil) {
                return 0
            }
            if (showAsRowSection) {
                var count = 0
                for t in tracks! {
                    if (t.topMatch ?? false) {
                        count += 1
                    }
                }
                return section == 0 ? count : tracks!.count - count
            }
            return tracks!.count
        } else {
            return autocomKeywords.count
        }
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
        let indexPath:NSIndexPath = resultTableView.indexPathForCell(sender)!
        let tracks:[Track] = sectionedTracks[currentSection!]!
        var index:Int = indexPath.row
        if (indexPath.section != 0) {
            index += self.tableView(resultTableView, numberOfRowsInSection: 0)
        }
        
        var track = tracks[index]
        actionSheetTargetTrack = track
        
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
        var track:Track? = actionSheetTargetTrack
        var foundIdx = -1
        
        let tracks:[Track] = sectionedTracks[currentSection!]!
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
        actionSheetTargetTrack = nil
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
        
        let progressHud = ViewUtils.showProgress(self, message: "Searching..")
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
                value: nil
            ).build()
        tracker.send(event as [NSObject: AnyObject]!)
        
        Requests.search(keyword, respCb: {
                (request:NSURLRequest, response:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            progressHud.hide(true)
            if (error != nil || result == nil) {
                if (error != nil && error!.domain == NSURLErrorDomain &&
                        error!.code == NSURLErrorNotConnectedToInternet) {
                    ViewUtils.showNoticeAlert(self, title: "Failed to search", message: "Internet is not connected")
                    return
                }
                var message = "Failed to search caused by undefined error."
                if (error != nil) {
                    message += " (\(error!.domain):\(error!.code))"
                }
                ViewUtils.showNoticeAlert(self, title: "Failed to search", message: message)
                self.searchResult = nil
                self.sectionedTracks = [String:[Track]]()
                self.currentSections = nil
                self.currentSection = nil
                return
            }
            let parser = Parser()
            self.searchResult = parser.parseSearch(result!)
            
            
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
                return
            }
            self.currentSections = foundSections
            
            if (self.searchResult!.showType == SearchShowType.ROW) {
                self.scrollPagerConstraint.constant = 0
                self.scrollPager.hidden = true
            } else {
                self.scrollPagerConstraint.constant = 40
                self.scrollPager.addSegmentsWithTitles(foundTitles)
                self.scrollPager.hidden = false
            }
            
            self.resultTableView.reloadData()
            self.searchResultView.hidden = false
        })
    }
    
    func selectTab(section:String) {
        self.currentSection = section
        var tracks = self.sectionedTracks[self.currentSection!]
        if (tracks == nil) {
            var progress = ViewUtils.showProgress(self, message: "Loading..")
            let callback = { (tracks: [Track]?, error:NSError?) -> Void in
                progress.hide(false)
                if (error != nil || tracks == nil) {
                    if (error != nil && error!.domain == NSURLErrorDomain &&
                            error!.code == NSURLErrorNotConnectedToInternet) {
                        ViewUtils.showNoticeAlert(self, title: "Failed to fetch data", message: "Internet is not connected")
                        return
                    }
                    var message = "Failed to fetch data caused by undefined error."
                    if (error != nil) {
                        message += " (\(error!.domain):\(error!.code))"
                    }
                    ViewUtils.showNoticeAlert(self, title: "Failed to fetch data", message: message)
                    return
                }
                if (tracks!.count == 0) {
                    ViewUtils.showToast(self, message: "No search results")
                }
                self.sectionedTracks[self.currentSection!] = tracks
                self.resultTableView.reloadData()
            }
            if (self.currentSection == SearchSections.LIVESET) {
                self.searchResult!.fetchListset(callback)
            } else if (self.currentSection == SearchSections.PODCAST) {
                self.searchResult!.fetchPodcast(callback)
            } else if (self.currentSection == SearchSections.RELEVANT) {
                self.searchResult!.fetchRelevant(callback)
            }
        } else {
            if (tracks!.count == 0) {
                ViewUtils.showToast(self, message: "No search results")
            }
            self.resultTableView.reloadData()
        }
        resultTableView.setContentOffset(CGPointZero, animated:false)
    }
    
    func scrollPager(scrollPager: ScrollPager, changedIndex: Int) {
        if (self.currentSections == nil || self.searchResult == nil) {
            return
        }
        selectTab(self.currentSections![changedIndex])
    }
    
    func updatePlay(noti: NSNotification) {
        var params = noti.object as! Dictionary<String, AnyObject>
        var track = params["track"] as! Track
        var playlistId:String? = params["playlistId"] as? String
        
        var indexPath = resultTableView.indexPathForSelectedRow()
        if (indexPath != nil) {
            var preSelectedTrack:Track?
            var tracks = sectionedTracks[currentSection!]!
            preSelectedTrack = tracks[indexPath!.row]
            if (preSelectedTrack != nil &&
                (preSelectedTrack!.id != track.id ||
                (playlistId != nil && playlistId!.toInt() >= 0))) {
                resultTableView.deselectRowAtIndexPath(indexPath!, animated: false)
            }
        }
        
        // NOTE
        // we have to handle re select case when user search agian with same keyword etc.
        // but we will ignore this case because we have only one week for iphone
        
//        if (playlistId == nil || playlistId!.toInt() >= 0) {
//            return
//        }
//        
//        for (idx, t) in enumerate(tracks) {
//            if (t.id == track.id) {
//                feedTableView.selectRowAtIndexPath(NSIndexPath(index: idx),
//                    animated: false, scrollPosition: UITableViewScrollPosition.None)
//                break
//            }
//        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
