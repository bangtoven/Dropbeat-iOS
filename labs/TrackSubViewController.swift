//
//  TrackSubViewController
//  labs
//
//  Created by Jungho Bang on 2015. 9. 16..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

class ChannelSubViewController: TrackSubViewController, DYAlertPickViewDataSource, DYAlertPickViewDelegate {
    var channel: Channel? {
        willSet {
            self.baseUser = channel
        }
    }
    var isSectioned: Bool = false
    
    private var currentSectionIndex: Int = 0
    private var nextPageToken:String?
    private var listEnd:Bool = false
    
    @IBOutlet weak var indicatorView: UIView!
    
    override func subViewWillAppear() {
        if self.tracks.count == 0 {
            print("start fetching channel \(self.title!)")
            
            if self.isSectioned != true {
                self.selectSection(0)
            } else {
                self.selectSection(1)
            }
        }
        
        self.trackTableView.reloadData()
        self.updatePlay(PlayerContext.currentTrack, playlistId: PlayerContext.currentPlaylistId)
    }
    
    func selectSection (index: Int) {
        self.currentSectionIndex = index
        let playlist = self.channel!.playlists[index]
        nextPageToken = nil
        listEnd = false
        
        if self.isSectioned {
            self.indicatorView.hidden = false
        }
        
        if (self.trackTableView.tableHeaderView != nil) {
            self.selectSectionButton.setTitle(self.channel!.playlists[index].name, forState: UIControlState.Normal)
        }
        
        self.loadTracks(playlist.uid, pageToken: nextPageToken)
    }
    
    @IBOutlet weak var selectSectionButton: UIButton!
    @IBAction func showSelectSection(sender: AnyObject) {
        let picker: DYAlertPickView = DYAlertPickView(headerTitle: "Choose Section", cancelButtonTitle: nil, confirmButtonTitle: nil, switchButtonTitle: nil)
        picker.dataSource = self
        picker.delegate = self
        picker.tintColor = UIColor.dropbeatColor()
        picker.headerBackgroundColor = UIColor.dropbeatColor()
        picker.headerTitleColor = UIColor.dropbeatColor()
        picker.showAndSelectedIndex(self.currentSectionIndex-1)
    }
    
    func numberOfRowsInDYAlertPickerView(pickerView: DYAlertPickView) -> Int {
        return self.channel!.playlists.count-1
    }
    
    func titleForRowInDYAlertPickView(titleForRow: Int) -> NSAttributedString! {
        let attr = [NSFontAttributeName: UIFont.systemFontOfSize(12)]
        return NSAttributedString(string:self.channel!.playlists[titleForRow+1].name, attributes:attr)
    }
    
    func didConfirmWithItemAtRowInDYAlertPickView(row: Int) {
        self.selectSection(row+1)
    }
    
    func loadTracks(playlistUid:String, pageToken:String?) {
        self.tracks.removeAll(keepCapacity: false)
        self.trackTableView.reloadData()
        
        Requests.getChannelPlaylist(playlistUid, pageToken: pageToken) { (req: NSURLRequest, resp: NSHTTPURLResponse?, result: AnyObject?, error :NSError?) -> Void in
            if self.isSectioned != true {
                self.trackTableView.tableHeaderView = nil
            } else {
                self.indicatorView.hidden = true
            }
            
            if (error != nil || result == nil) {
                if (error != nil && error!.domain == NSURLErrorDomain &&
                    error!.code == NSURLErrorNotConnectedToInternet) {
                        ViewUtils.showNoticeAlert(self,
                            title: NSLocalizedString("Failed to load", comment:""),
                            message: NSLocalizedString("Internet is not connected", comment:""))
                        return
                }
                let message = NSLocalizedString("Failed to load tracks.", comment:"")
                ViewUtils.showNoticeAlert(self, title: NSLocalizedString("Failed to load", comment:""), message: message)
                return
            }
            
            if pageToken == nil {
                self.tracks.removeAll(keepCapacity: false)
            }
            var json = JSON(result!)
            
            if json["nextPageToken"].error == nil {
                self.nextPageToken = json["nextPageToken"].stringValue
            } else {
                self.nextPageToken = nil
            }
            if self.nextPageToken == nil {
                self.listEnd = true
            }
            
            for (_, item): (String, JSON) in json["items"] {
                if item["snippet"].error != nil {
                    continue
                }
                var snippet = item["snippet"]
                if snippet["resourceId"].error != nil {
                    continue
                }
                var resourceId = snippet["resourceId"]
                if resourceId["videoId"].error != nil {
                    continue
                }
                let id = resourceId["videoId"].stringValue
                
                if snippet["title"].error != nil {
                    continue
                }
                let title = snippet["title"].stringValue
                
                if snippet["description"].error != nil {
                    continue
                }
                _ = snippet["description"].stringValue
                
                if snippet["publishedAt"].error != nil {
                    continue
                }
                let publishedAtStr = snippet["publishedAt"].stringValue
                let formatter = NSDateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.000Z"
                let publishedAt = formatter.dateFromString(publishedAtStr)
                self.tracks.append(ChannelTrack(id: id, title:title, publishedAt: publishedAt))
            }
            self.updatePlaylist(false)
            self.trackTableView.reloadData()
            self.updatePlay(PlayerContext.currentTrack, playlistId: PlayerContext.currentPlaylistId)
        }
    }
}

class TrackSubViewController: AddableTrackListViewController, UITableViewDataSource, UITableViewDelegate, AXSubViewController, AXStretchableSubViewControllerViewSource {
    
    var baseUser: BaseUser?
    var fetchFunc: ((([Track]?, NSError?) -> Void) -> Void)?
    
    func subViewWillAppear() {
        if self.tracks.count == 0 && fetchFunc != nil {
            print("start fetching \(self.title!)")
            fetchFunc!({ (tracks, error) -> Void in
                if let t = tracks {
                    self.tracks = t
                    self.trackTableView.reloadData()
                } else {
                    print(error)
                }
                self.trackTableView.tableHeaderView = nil
            })
        } else {
            self.trackTableView.tableHeaderView = nil
        }
        
        self.trackTableView.reloadData()
        self.updatePlay(PlayerContext.currentTrack, playlistId: PlayerContext.currentPlaylistId)
    }
    
    func subViewWillDisappear() {
        onDropFinished()
    }
    
    func stretchableSubViewInSubViewController() -> UIScrollView! {
        return self.trackTableView
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tracks.count + 1
    }
    
    let CELL_HIGHT:CGFloat = 76
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        var cellHeight: CGFloat = 0
        if (indexPath.row < tracks.count) {
            cellHeight = 76
        } else if let parentVc = self.parentViewController as? UserViewController {
            if let navigationBar = parentVc.navigationController?.navigationBar {
                let minHeight = parentVc.view.frame.size.height - (CGRectGetMaxY(navigationBar.frame)+CGRectGetHeight(parentVc.tabBar.bounds))
                let diff = minHeight - (CELL_HIGHT * CGFloat(tracks.count))
                if diff > 0 {
                    cellHeight = diff
                }
            }
        }
        return cellHeight
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if (indexPath.row >= tracks.count) {
            let identifier = "EmptyCell"
            var cell = tableView.dequeueReusableCellWithIdentifier(identifier)
            if (cell == nil) {
                cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: identifier)
            }
            cell?.backgroundColor = UIColor.whiteColor()
            cell?.userInteractionEnabled = false
            return cell!
        }
        
        let cell:AddableTrackTableViewCell = tableView.dequeueReusableCellWithIdentifier("AddableTrackTableViewCell", forIndexPath: indexPath) as! AddableTrackTableViewCell
        let track = tracks[indexPath.row]

        cell.delegate = self
        cell.nameView.text = track.title
        if let thumbnailUrl = track.thumbnailUrl {
            cell.thumbView.sd_setImageWithURL(NSURL(string: thumbnailUrl),
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
        cell.dropBtn.hidden = track.drop == nil
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath:NSIndexPath) {
        onTrackPlayBtnClicked(tracks[indexPath.row])
    }
    
    override func getPlaylistId() -> String? {
        return "user_\(self.baseUser?.id)_\(self.title)"
    }
    
    override func getPlaylistName() -> String? {
        return self.baseUser?.name
    }
    
    override func getSectionName() -> String {
        return "user_\(self.baseUser?.name)_\(self.title)"
    }
    
    override func updatePlay(track:Track?, playlistId:String?) {
        super.updatePlay(track, playlistId: playlistId)
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
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "PlaylistSelectSegue" {
            let playlistSelectVC:PlaylistSelectViewController = segue.destinationViewController as! PlaylistSelectViewController
            playlistSelectVC.targetTrack = sender as? Track
            playlistSelectVC.fromSection = "user view"
            playlistSelectVC.caller = self
        }
    }
}
