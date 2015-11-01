//
//  TrackSubViewController
//  labs
//
//  Created by Jungho Bang on 2015. 9. 16..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

class TrackSubTableViewwCell: AddableTrackTableViewCell {
    @IBOutlet weak var dropButtonWidthConstraint: NSLayoutConstraint!
}

class TrackSubViewController: AddableTrackListViewController, UITableViewDataSource, UITableViewDelegate, AXSubViewController, AXStretchableSubViewControllerViewSource {
    
    @IBOutlet var loadingHeaderView: UIView!
    
    var user: BaseUser?
    var fetchFunc: ((([Track]?, NSError?) -> Void) -> Void)?
    
    override func viewDidLayoutSubviews() {
    }
    
    func subViewWillAppear() {
        if fetchFunc != nil {
            self.trackTableView.tableHeaderView = self.loadingHeaderView
            
            fetchFunc!({ (tracks, error) -> Void in
                if let t = tracks {
                    self.tracks = t
                    self.trackTableView.reloadData()
                } else {
                    print(error)
                }
                self.trackTableView.tableHeaderView = nil
            })
        }
        
        self.trackTableView.reloadData()
        self.trackChanged()
    }
    
    func subViewWillDisappear() {
        updateDropPlayState(.Ready)
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
    
    let CELL_HEIGHT:CGFloat = 76
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        var cellHeight: CGFloat = 0
        if (indexPath.row < tracks.count) {
            cellHeight = CELL_HEIGHT
        } else if let parentVc = self.parentViewController as? UserViewController,
            navigationBar = parentVc.navigationController?.navigationBar {
                let minHeight = parentVc.view.frame.size.height - (CGRectGetMaxY(navigationBar.frame)+CGRectGetHeight(parentVc.tabBar.bounds))
                let diff = minHeight - (CELL_HEIGHT * CGFloat(tracks.count))
                if diff > 0 {
                    cellHeight = diff
                }
                
                if cellHeight < 44 {
                    cellHeight = 44
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
        
        let cell = tableView.dequeueReusableCellWithIdentifier("TrackSubTableViewwCell", forIndexPath: indexPath) as! TrackSubTableViewwCell
        cell.delegate = self

        let track = tracks[indexPath.row]
        cell.nameView.text = track.title

        cell.thumbView.setImageForTrack(track, size: .SMALL)

        self.setDropButtonForCellWithTrack(cell, track: track)
        cell.dropButtonWidthConstraint.constant = cell.dropBtn.hidden ? 0 : 44
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath:NSIndexPath) {
        onTrackPlayBtnClicked(tracks[indexPath.row])
    }
    
    override func getPlaylistId() -> String? {
        return "user_\(self.user?.id)_\(self.title)"
    }
    
    override func getPlaylistName() -> String? {
        let title = self.title ?? "tracks"
        if let user = self.user as? User,
            mySelf = Account.getCachedAccount()?.user
            where user.id == mySelf.id {
                return "My \(title)"
        } else if let name = self.user?.name {
            return "\(name)'s \(title)"
        } else {
            return title
        }
    }
    
    override func getSectionName() -> String {
        return "user_\(self.user?.name)_\(self.title)"
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
