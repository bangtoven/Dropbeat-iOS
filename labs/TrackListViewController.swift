//
//  TrackListViewController
//  labs
//
//  Created by Jungho Bang on 2015. 9. 16..
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

class TrackListViewController: AddableTrackListViewController, UITableViewDataSource, UITableViewDelegate, AddableTrackCellDelegate {
    
    private static var sectionTitles = [
        SearchResultSections.RELEASED: NSLocalizedString("OFFICIAL", comment:""),
        SearchResultSections.PODCAST: NSLocalizedString("PODCASTS", comment:""),
        SearchResultSections.LIVESET: NSLocalizedString("LIVE SETS", comment:""),
        SearchResultSections.TOP_MATCH: NSLocalizedString("TOP MATCH", comment:""),
        SearchResultSections.RELEVANT: NSLocalizedString("OTHERS", comment:"")
    ]
    
    private var sectionedTracks = [String:[Track]]()
    private var currentSections:[String]?
    private var currentSection:String?
    private var showAsRowSection = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        for section in SearchResultSections.allValues {
            sectionedTracks[section] = [Track]()
        }
        
        // Do any additional setup after loading the view.
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
// TODO: 이거 빼야돼
//        if segue.identifier == "PlaylistSelectSegue" {
//            let playlistSelectVC:PlaylistSelectViewController = segue.destinationViewController as! PlaylistSelectViewController
//            playlistSelectVC.targetTrack = sender as? Track
//            playlistSelectVC.fromSection = "search"
//            playlistSelectVC.caller = self
//        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
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
                    placeholderImage: UIImage(named: "default_artwork.png"), completed: {
                        (image: UIImage!, error: NSError!, cacheType:SDImageCacheType, imageURL: NSURL!) -> Void in
                        if error != nil {
                            cell.thumbView.image = UIImage(named: "default_artwork.png")
                        }
                })
            } else {
                cell.thumbView.image = UIImage(named: "default_artwork.png")
            }
            var dropBtnImageName:String!
            if dropPlayerContext.sectionName == getSectionName() &&
                dropPlayerContext.currentTrack?.id == track.id {
                    switch(dropPlayerContext.playStatus) {
                    case .Playing:
                        dropBtnImageName = "ic_drop_pause_small.png"
                        break
                    case .Loading:
                        dropBtnImageName = "ic_drop_loading_small.png"
                        break
                    case .Ready:
                        dropBtnImageName = "ic_drop_small.png"
                        break
                    }
            } else {
                dropBtnImageName = "ic_drop_small.png"
            }
            cell.dropBtn.setImage(UIImage(named: dropBtnImageName), forState: UIControlState.Normal)
            cell.dropBtn.hidden = track!.drop == nil
            return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
            var index:Int = indexPath.row
            if (indexPath.section != 0) {
                index += self.tableView(tableView, numberOfRowsInSection: 0)
            }
            onTrackPlayBtnClicked(tracks[index])
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
    
}
