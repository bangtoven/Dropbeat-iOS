//
//  SearchViewController.swift
//  labs
//
//  Created by vulpes on 2015. 5. 15..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit
import SDWebImage

class SearchResultSections {
    static var RELEASED = "released"
    static var FEATURED_LIVESET = "featured_liveset"
    static var TRENDING = "trending"
    static var RELEVANT = "relevant"
    static var allValues = [RELEASED, FEATURED_LIVESET, TRENDING, RELEVANT]
}

class SearchViewController: BaseContentViewController, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate, AddableTrackCellDelegate, ScrollPagerDelegate{
    
    private static var sectionTitles = [
        SearchResultSections.RELEASED: "RELEASED",
        SearchResultSections.FEATURED_LIVESET: "LIVESETS",
        SearchResultSections.TRENDING: "TRENDING",
        SearchResultSections.RELEVANT: "OTHER"
    ]
    
    var sectionedTracks = [String:[Track]]()
    var currentSections:[String]?
    var currentSection:String?
    var useTopMatch = false
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
    
    func hasTopMatch() -> Bool{
        if (self.currentSection == nil ||
                self.currentSection != SearchResultSections.RELEVANT) {
            return false
        }
        if (self.sectionedTracks[self.currentSection!]!.count == 0) {
            return false
        }
        let tracks:[Track] = self.sectionedTracks[self.currentSection!]!
        let firstResult:Track = tracks[0]
        if (firstResult.topMatch ?? false) {
            return true
        }
        return false
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
        if (tableView == resultTableView && useTopMatch) {
            return 2
        }
        return 1
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if (tableView == resultTableView && useTopMatch) {
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
            if (useTopMatch) {
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
                return
            }
            let parser = Parser()
            let search = parser.parseSearch(result!)
            
            
            // clear sectionedTracks
            for section in SearchResultSections.allValues {
                self.sectionedTracks[section]!.removeAll(keepCapacity: false)
            }
            
            // sectionize
            var foundSections:[String] = [String]()
            
            for track in search.result {
                if (track.tag == nil) {
                    return
                }
                var tracks:[Track]? = self.sectionedTracks[track.tag!]
                if (tracks != nil) {
                    self.sectionedTracks[track.tag!]!.append(track)
                    if (find(foundSections, track.tag!) == nil) {
                        foundSections.append(track.tag!)
                    }
                }
            }
            self.currentSections = foundSections
            var foundTitles:[String] = foundSections.map {
                return SearchViewController.sectionTitles[$0]!
            }
            if (foundSections.count > 0) {
                self.currentSection = foundSections[0]
            } else {
                self.currentSection = nil
            }
            self.useTopMatch = self.hasTopMatch()
            
            if (self.currentSection == nil ||
                self.currentSection == SearchResultSections.RELEVANT) {
                
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
        if (self.currentSections == nil) {
            return
        }
        self.currentSection = self.currentSections![changedIndex]
        self.useTopMatch = hasTopMatch()
        self.resultTableView.reloadData()
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
