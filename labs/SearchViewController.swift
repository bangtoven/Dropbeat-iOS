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

class SearchViewController: BaseContentViewController,
    UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate,
    AddableTrackCellDelegate, ScrollPagerDelegate{
    
    private static var sectionTitles = [
        SearchResultSections.RELEASED: "RELEASED",
        SearchResultSections.PODCAST: "PODCAST",
        SearchResultSections.LIVESET: "LIVESETS",
        SearchResultSections.TOP_MATCH: "TOP_MATCH",
        SearchResultSections.RELEVANT: "OTHER"
    ]
    
    var searchResult:Search?
    var sectionedTracks = [String:[Track]]()
    var currentSections:[String]?
    var currentSection:String?
    var showAsRowSection = false
    var autocomKeywords:[String] = []
    var autocomRequester:AutocompleteRequester?
    
    @IBOutlet weak var searchResultView: UIView!
    @IBOutlet weak var scrollPager: ScrollPager!
    @IBOutlet weak var autocomTableView: UITableView!
    @IBOutlet weak var resultTableView: UITableView!
    @IBOutlet weak var keywordView: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        autocomRequester = AutocompleteRequester(handler: onHandleAutocomplete)
        
//        var keywordBgImage = UIImage(named: "search_bar.png")
//        keywordBgImage = keywordBgImage?.resizableImageWithCapInsets(UIEdgeInsetsMake(0, 10, 0, 10))
//        keywordView.background = keywordBgImage
//        keywordView.leftViewMode = UITextFieldViewMode.Always
//        var searchIcon = UIImageView(image:UIImage(named:"search-100.png"))
//        searchIcon.frame = CGRectMake(0, 0, 30, 30)
//        searchIcon.contentMode = UIViewContentMode.ScaleAspectFit
//        keywordView.leftView = searchIcon
        
        scrollPager.font = UIFont.systemFontOfSize(11)
        scrollPager.selectedFont = UIFont.systemFontOfSize(11)
        
        
        autocomTableView.hidden = true
        searchResultView.hidden = true
        keywordView.text = ""
        
        scrollPager.delegate = self
        for section in SearchResultSections.allValues {
            sectionedTracks[section] = [Track]()
        }
        
        // Do any additional setup after loading the view.
        
        keywordView.becomeFirstResponder()
        
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "updatePlay:", name: NotifyKey.updatePlay, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "sender", name: NotifyKey.playerPlay, object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.screenName = "SearchViewScreen"
    }
    
    
    override func viewWillDisappear(animated: Bool) {
        keywordView.resignFirstResponder()
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotifyKey.updatePlay, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotifyKey.playerPlay, object: nil)
    }
    
    func sender () {}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func onHandleAutocomplete(keywords:Array<String>?, error:NSError?) {
        if (error != nil) {
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
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        let keyword = textField.text
        if (count(keyword) > 0) {
            doSearch(keyword)
        }
        return true
    }
    
    @IBAction func onKeywordChanged(sender: UITextField) {
        if (count(sender.text) == 0) {
            hideAutocomplete()
            searchResultView.hidden = false
        } else {
            autocomRequester?.send(sender.text)
            searchResultView.hidden = true
        }
    }
    
    @IBAction func onKeywordBeginEditing(sender: UITextField) {
        showAutocomplete(clear: true)
        searchResultView.hidden = true
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if (tableView == resultTableView) {
            var cell:AddableTrackTableViewCell = tableView.dequeueReusableCellWithIdentifier("AddableTrackTableViewCell", forIndexPath: indexPath) as! AddableTrackTableViewCell
            let tracks:[Track] = sectionedTracks[currentSection!]!
            let track = tracks[indexPath.row]
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
            var params: Dictionary<String, AnyObject> = [
                "track": tracks[indexPath.row],
                "playlistId": "-1"
            ]
            NSNotificationCenter.defaultCenter().postNotificationName(
                NotifyKey.playerPlay, object: params)
        } else {
            let keyword = autocomKeywords[indexPath.row]
            keywordView.text = keyword
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
    
//    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//        let title:String? = self.tableView(tableView, titleForHeaderInSection:section)
//        if (title == nil || count(title!) == 0) {
//            let headerView = UIView()
//            headerView.frame = CGRectMake(0, 0, 0, 0)
//            return headerView
//        }
//        let label:UILabel = UILabel(frame: CGRectMake(16, 0, UIScreen.mainScreen().bounds.size.width, 24))
//        label.font = UIFont.boldSystemFontOfSize(18)
//        label.text = title
//        label.textColor = UIColor(netHex:0xffffff)
//        let headerView = UIView()
//        headerView.addSubview(label)
//        headerView.backgroundColor = UIColor(netHex:0x111111)
//        
//        return headerView
//    }
    
    func onAddBtnClicked(sender: AddableTrackTableViewCell) {
        let indexPath:NSIndexPath = resultTableView.indexPathForCell(sender)!
        let tracks:[Track] = sectionedTracks[currentSection!]!
        let track = tracks[indexPath.row]
        if (Account.getCachedAccount() == nil) {
            var appDelegate:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            var centerViewController = appDelegate.centerContainer!.centerViewController as! CenterViewController
            centerViewController.showSigninView()
            return
        }
        
        PlaylistViewController.addTrack(track, section:"search", afterAdd: { (needRefresh, error) -> Void in
            if (error != nil) {
                if (error!.domain == "addTrack") {
                    if (error!.code == 100) {
                        ViewUtils.showNoticeAlert(self, title: "Failed to add", message: "Failed to find playlist to add")
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
        keywordView.endEditing(true)
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
                
                self.scrollPager.hidden = true
                let constraint = NSLayoutConstraint(
                        item: self.scrollPager,
                        attribute: NSLayoutAttribute.Height,
                        relatedBy: NSLayoutRelation.Equal,
                        toItem: self.scrollPager,
                        attribute: NSLayoutAttribute.Height,
                        multiplier: 1,
                        constant: 0)
                self.scrollPager.addConstraint(constraint)
                self.view.layoutIfNeeded()
            } else {
                self.scrollPager.addSegmentsWithTitles(foundTitles)
                self.scrollPager.hidden = false
                let constraint = NSLayoutConstraint(
                        item: self.scrollPager,
                        attribute: NSLayoutAttribute.Height,
                        relatedBy: NSLayoutRelation.Equal,
                        toItem: self.scrollPager,
                        attribute: NSLayoutAttribute.Height,
                        multiplier: 1,
                        constant: 40)
                self.scrollPager.addConstraint(constraint)
                self.view.layoutIfNeeded()
            }
            
            self.resultTableView.reloadData()
            self.searchResultView.hidden = false
        })
    }
    
    func scrollPager(scrollPager: ScrollPager, changedIndex: Int) {
        if (self.currentSections == nil || self.searchResult == nil) {
            return
        }
        self.currentSection = self.currentSections![changedIndex]
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
                    ViewUtils.showToast(self, message: "empty result")
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
                ViewUtils.showToast(self, message: "empty result")
            }
            self.resultTableView.reloadData()
        }
    }
    
    override func menuBtnClicked(sender: AnyObject) {
        keywordView.endEditing(true)
        super.menuBtnClicked(sender)
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
