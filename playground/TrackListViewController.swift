//
//  TrackListViewController
//  labs
//
//  Created by Jungho Bang on 2015. 9. 16..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

class TrackListViewController: AddableTrackListViewController, UITableViewDataSource, UITableViewDelegate, AddableTrackCellDelegate, AXSubViewController, AXStretchableSubViewControllerViewSource {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    func subViewWillDisappear() {
        println(" subViewDidDisappear")
        
        onDropFinished()
    }
    
    func subViewWillAppear() {
        println(" subViewWillAppear")
        
        self.trackTableView.reloadData()
        self.updatePlay(PlayerContext.currentTrack, playlistId: PlayerContext.currentPlaylistId)
    }
    
    func stretchableSubViewInSubViewController() -> UIScrollView! {
        return self.trackTableView
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tracks.count
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
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath:NSIndexPath) {
        onTrackPlayBtnClicked(tracks[indexPath.row])
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
    
    //    override func updatePlay(track:Track?, playlistId:String?) {
    //        super.updatePlay(track, playlistId: playlistId)
    //        if track == nil {
    //            return
    //        }
    //        var indexPath = trackTableView.indexPathForSelectedRow()
    //        if (indexPath != nil) {
    //            var preSelectedTrack:Track?
    //            preSelectedTrack = tracks[indexPath!.row]
    //            if (preSelectedTrack != nil &&
    //                (preSelectedTrack!.id != track!.id ||
    //                    (playlistId != nil && playlistId!.toInt() >= 0))) {
    //                        trackTableView.deselectRowAtIndexPath(indexPath!, animated: false)
    //            }
    //        }
    //
    //        if playlistId != nil {
    //            return
    //        }
    //
    //        for (idx, t) in enumerate(tracks) {
    //            if (t.id == track!.id) {
    //                trackTableView.selectRowAtIndexPath(NSIndexPath(forRow: idx, inSection: 0),
    //                    animated: false, scrollPosition: UITableViewScrollPosition.None)
    //                break
    //            }
    //        }
    //    }
}
