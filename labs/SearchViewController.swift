//
//  SearchViewController.swift
//  labs
//
//  Created by vulpes on 2015. 5. 15..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

class SearchResultUserCell: FollowInfoTableViewCell {
    @IBOutlet weak var isFollowedImageView: UIImageView!
}

class SearchViewController: AddableTrackListViewController,
    UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate,
    UISearchBarDelegate {
    
    @IBOutlet weak var noSearchResultView: UILabel!
    @IBOutlet weak var searchResultView: UIView!
    @IBOutlet weak var autocomTableView: UITableView!
    
    private var searchBar:UISearchBar!
    private var autocomKeywords:[String] = []
    private var autocomRequester:AutocompleteRequester?
    
    private var users = [BaseUser]()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:" ", style:.Plain, target:nil, action:nil)
        
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
        
        autocomTableView.hidden = true
        searchResultView.hidden = true
        
        searchBar.becomeFirstResponder()

        self.screenName = "SearchViewScreen"
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if self.isMovingToParentViewController() == false{
            // back from navigation stack. previous page was popped!!
            for u in self.users {
                u.updateFollowInfo()
            }
            self.trackTableView.reloadData()
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch segue.identifier! {
        case "PlaylistSelectSegue":
            let playlistSelectVC = segue.destinationViewController as! PlaylistSelectViewController
            playlistSelectVC.targetTrack = sender as? Track
            playlistSelectVC.fromSection = "search"
            playlistSelectVC.caller = self
        case "showChannelInfo":
            let cell = sender as! FollowInfoTableViewCell
            let indexPath = self.trackTableView.indexPathForSelectedRow
            let u = self.users[indexPath!.row]
            
            let mySegue = segue as! JHImageTransitionSegue
            let sourceImageView = cell.profileImageView
            mySegue.setSourceImageView(sourceImageView)
            mySegue.sourceRect = sourceImageView.convertRect(sourceImageView.bounds, toView: self.view)
            mySegue.destinationRect = self.view.convertRect(CGRectMake(10, 157, 80, 80), fromView: nil)
            
            let uvc = segue.destinationViewController as! UserViewController
            uvc.resource = u.resourceName
            uvc.passedImage = sourceImageView.image
            
        default:
            break
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if tableView == trackTableView {
            if indexPath.section == 0 {
                return
            } else {
                onTrackPlayBtnClicked(tracks[indexPath.row])
            }
        } else {
            let keyword = autocomKeywords[indexPath.row]
            searchBar!.text = keyword
            searchBar!.endEditing(true)
            doSearch(keyword)
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if tableView == trackTableView {
            return 2
        } else {
            return 1
        }
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if tableView == trackTableView {
            if (section == 0) {
                return self.users.count > 0 ? "ARTISTS" : nil
            } else {
                return self.tracks.count > 0 ? "TRACKS" : nil
            }
        } else {
            return nil
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (tableView == trackTableView) {
            if (section == 0) {
                return self.users.count
            } else {
                return self.tracks.count
            }
        } else {
            return autocomKeywords.count
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if (tableView == trackTableView) {
            if indexPath.section == 0 {
                let cell = tableView.dequeueReusableCellWithIdentifier("SearchResultUserCell", forIndexPath: indexPath) as! SearchResultUserCell
                let u = self.users[indexPath.row]
                cell.nameLabel.text = u.name
                if let image = u.image {
                    cell.profileImageView.sd_setImageWithURL(NSURL(string: image), placeholderImage: UIImage(named: "default_profile"))
                } else {
                    cell.profileImageView.image = UIImage(named: "default_profile")
                }
                
                cell.profileImageView.layer.cornerRadius = 10
                cell.profileImageView.layer.borderWidth = 2
                cell.profileImageView.layer.borderColor = UIColor(white: 0.95, alpha: 1.0).CGColor
                
                cell.isFollowedImageView.hidden = (u.isFollowed() == false)
                
                return cell

            } else {
                let cell:AddableTrackTableViewCell = tableView.dequeueReusableCellWithIdentifier("AddableTrackTableViewCell", forIndexPath: indexPath) as! AddableTrackTableViewCell
                cell.delegate = self
                
                let track = tracks[indexPath.row]
                cell.nameView.text = track.title
                if let thumbnailUrl = track.thumbnailUrl {
                    cell.thumbView.sd_setImageWithURL(NSURL(string: thumbnailUrl),
                        placeholderImage: UIImage(named: "default_artwork"))
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
                cell.dropBtn.hidden = track.drop == nil
                return cell
            }
        } else {
            let cell:AutocomTableViewCell = tableView.dequeueReusableCellWithIdentifier("AutocomItem", forIndexPath: indexPath) as! AutocomTableViewCell
            let keyword = autocomKeywords[indexPath.row]
            cell.keywordView?.text = keyword
            return cell
        }
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
                let message = NSLocalizedString("Failed to search.", comment:"")
                ViewUtils.showNoticeAlert(self, title: NSLocalizedString("Failed to search", comment:""), message: message)
                self.tracks.removeAll(keepCapacity: false)
                
                self.trackTableView.hidden = true
                self.noSearchResultView.hidden = false
                self.trackTableView.reloadData()
                self.updatePlay(PlayerContext.currentTrack, playlistId: PlayerContext.currentPlaylistId)
                return
            }
            
            self.users = [BaseUser]()
            
            let json = JSON(result!)["data"]
            for (_, a):(String,JSON) in json["artists"] {
                var user: BaseUser
                do {
                    try user = BaseUser(json: a)
                } catch _ {
                    continue
                }
                self.users.append(user)
            }
            self.tracks = Track.parseTracks(json["tracks"])
            
            self.searchResultView.hidden = false
            self.trackTableView.reloadData()
            
            let showNoResultView = (self.tracks.count == 0 && self.users.count == 0)
            self.trackTableView.hidden = showNoResultView
            self.noSearchResultView.hidden = !showNoResultView
            
            self.updatePlay(PlayerContext.currentTrack, playlistId: PlayerContext.currentPlaylistId)
        })
    }
    
    // MARK: auto complete
    
    
    @IBAction func onTabed(sender: AnyObject) {
        searchBar!.endEditing(true)
    }
    
    func onHandleAutocomplete(keywords:Array<String>?, error:NSError?) {
        if (error != nil || keywords == nil) {
            print("Failed to get autocomplete")
            return
        }
        autocomKeywords.removeAll(keepCapacity: false)
        for keyword in keywords! {
            autocomKeywords.append(keyword)
        }
        autocomTableView.reloadData()
        if (autocomTableView.hidden) {
            showAutocomplete(true)
        }
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        if (searchText.characters.count == 0) {
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
        if keyword!.characters.count == 0 {
            return
        }
        doSearch(keyword!)
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
    
    // MARK: etc
    
    override func getPlaylistId() -> String? {
        return "Explore"
    }
    
    override func getSectionName() -> String {
        return "search"
    }
    
    override func updatePlay(track:Track?, playlistId:String?) {
        if track == nil {
            return
        }
        let indexPath = trackTableView.indexPathForSelectedRow
        if (indexPath != nil) {
            var preSelectedTrack:Track?
            preSelectedTrack = tracks[indexPath!.row]
            if (preSelectedTrack != nil &&
                (preSelectedTrack!.id != track!.id ||
                    (playlistId != nil && Int(playlistId!) >= 0))) {
                        trackTableView.deselectRowAtIndexPath(indexPath!, animated: false)
            }
        }
        
        if playlistId != nil {
            return
        }
        
        for (idx, t) in tracks.enumerate() {
            if (t.id == track!.id) {
                trackTableView.selectRowAtIndexPath(NSIndexPath(forRow: idx, inSection: 0),
                    animated: false, scrollPosition: UITableViewScrollPosition.None)
                break
            }
        }
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
                name: "Search",
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
}
