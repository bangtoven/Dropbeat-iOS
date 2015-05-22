//
//  SearchViewController.swift
//  labs
//
//  Created by vulpes on 2015. 5. 15..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

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
        SearchResultSections.FEATURED_LIVESET: "FEATURED LIVESETS",
        SearchResultSections.TRENDING: "TRENDING LIVESETS",
        SearchResultSections.RELEVANT: "OTHER"
    ]
    
    var sectionedTracks = [String:[Track]]()
    var currentSections:[String]?
    var currentSection:String?
    var useTopMatch = false
    var autocomKeywords:[String] = []
    var autocomRequester:AutocompleteRequester?
    
    @IBOutlet weak var scrollPager: ScrollPager!
    @IBOutlet weak var autocomTableView: UITableView!
    @IBOutlet weak var resultTableView: UITableView!
    @IBOutlet weak var keywordView: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        autocomRequester = AutocompleteRequester(handler: onHandleAutocomplete)
        keywordView.becomeFirstResponder()
        autocomTableView.hidden = true
        resultTableView.hidden = true
        keywordView.text = ""
        
        scrollPager.delegate = self
        for section in SearchResultSections.allValues {
            sectionedTracks[section] = [Track]()
        }
        
        // Do any additional setup after loading the view.
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "sender", name: NotifyKey.playerPlay, object: nil)
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
        } else {
            autocomRequester?.send(sender.text)
        }
        resultTableView.hidden = true
    }
    
    @IBAction func onKeywordBeginEditing(sender: UITextField) {
        hideAutocomplete()
        resultTableView.hidden = true
    }
    
    @IBAction func onKeywordEndEditing(sender: UITextField) {
        hideAutocomplete()
        resultTableView.hidden = false
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
            var image:UIImage?
            if (track.thumbnailUrl != nil) {
                var data:NSData? = NSData(contentsOfURL: NSURL(string:track.thumbnailUrl!)!)
                if (data != nil) {
                    image = UIImage(data: data!)
                }
            }
            if (image == nil) {
                image = UIImage(named: "btn_play_disabled")
            }
            cell.thumbView.image = image!
            return cell
        } else {
            var cell:UITableViewCell = tableView.dequeueReusableCellWithIdentifier("AutocomItem", forIndexPath: indexPath) as! UITableViewCell
            let keyword = autocomKeywords[indexPath.row]
            cell.textLabel?.text = keyword
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
        
        PlaylistViewController.addTrack(track, afterAdd: { (needRefresh, error) -> Void in
            if (error != nil) {
                if (error!.domain == "addTrack") {
                    if (error!.code == 100) {
                        ViewUtils.showNoticeAlert(self, title: "Failed to add", message: "Failed to find playlist to add")
                        return
                    }
                    ViewUtils.showToast(self, message: "Already in playlist")
                    return
                }
                ViewUtils.showNoticeAlert(self, title: "Failed to add", message: error!.description)
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
        resultTableView.hidden = false
        
        Requests.search(keyword, respCb: {
                (request:NSURLRequest, response:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            progressHud.hide(true)
            if (error != nil || result == nil) {
                let errorText = error?.description ?? "undefined error"
                ViewUtils.showNoticeAlert(self, title: "Failed to search", message: errorText)
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
            } else {
                self.scrollPager.addSegmentsWithTitles(foundTitles)
                self.scrollPager.hidden = false
            }
            
            self.resultTableView.reloadData()
            self.resultTableView.hidden = false
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
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
