//
//  FollowingFeedViewController.swift
//  labs
//
//  Created by 방정호 on 2015. 11. 4..
//  Copyright © 2015년 dropbeat. All rights reserved.
//

import UIKit

class FollowingFeedViewController: AddableTrackListViewController {
    func getFollowingFeedTrackCell(indexPath:NSIndexPath) -> AddableTrackTableViewCell {
        let track = tracks[indexPath.row]
        
        if track.repostingUser != nil {
            let identifier = (track.user == nil) ? "DropbeatTrackTableViewCell" : "RepostedTrackTableViewCell"
            let cell = trackTableView.dequeueReusableCellWithIdentifier(identifier, forIndexPath: indexPath) as! DropbeatTrackTableViewCell
            cell.setContentsWithTrack(track, reposting: true)
            cell.delegate = self
            return cell
        } else {
            return getDropbeatTrackCell(indexPath)
        }
    }
    
    func getDropbeatTrackCell(indexPath:NSIndexPath) -> AddableTrackTableViewCell {
        let cell = trackTableView.dequeueReusableCellWithIdentifier("DropbeatTrackTableViewCell", forIndexPath: indexPath) as! DropbeatTrackTableViewCell
        cell.setContentsWithTrack(tracks[indexPath.row])
        cell.delegate = self
        
        return cell
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl = UIRefreshControl()
        refreshControl.tintColor = UIColor(netHex:0xc380fc)
        refreshControl.addTarget(self, action: "refresh", forControlEvents: UIControlEvents.ValueChanged)
        
        let refreshControlTitle = NSAttributedString(
            string: NSLocalizedString("Pull to refresh", comment: ""),
            attributes: [NSForegroundColorAttributeName: UIColor(netHex: 0x909090)])
        refreshControl.attributedTitle = refreshControlTitle
        trackTableView.insertSubview(refreshControl, atIndex: 0)
    }
    
    func refresh() {
        loadMoreSpinnerWrapper.hidden = true
        loadMoreSpinner.stopAnimating()
        
        self.loadFollowingTracks(true)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.screenName = "FollowingFeedViewScreen"
        self.loadFollowingTracks(true)
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let track = tracks[indexPath.row]
        var height = self.view.bounds.width * 0.5 + 68
        if track.repostingUser != nil && track.user != nil {
            height += 62
        }
        return height
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return tracks.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        self.needsBigSizeDropButton = true
        let cell = getFollowingFeedTrackCell(indexPath)
        
        let track = tracks[indexPath.row]
        if (getPlaylistId() == DropbeatPlayer.defaultPlayer.currentPlaylist?.id &&
            DropbeatPlayer.defaultPlayer.currentTrack != nil &&
            DropbeatPlayer.defaultPlayer.currentTrack!.id == track.id) {
                cell.setSelected(true, animated: false)
        }
        
        self.setDropButtonForCellWithTrack(cell, track: track)
        
        return cell
    }

    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch segue.identifier! {
        case "showUserInfo":
            handleShowUserInfoSegue(segue, sender: sender, showReposter: false)
        case "ShowReposterInfo":
            handleShowUserInfoSegue(segue, sender: sender, showReposter: true)
        default:
            break
        }
    }
    
    func handleShowUserInfoSegue(segue: UIStoryboardSegue, sender: AnyObject?, showReposter: Bool) {
        let indexPath = self.trackTableView.indexPathOfCellContains(sender as! UIButton)
        
        let mySegue = segue as! JHImageTransitionSegue
        var sourceImageView: UIImageView {
            let cell = self.trackTableView.cellForRowAtIndexPath(indexPath!)
            if showReposter {
                return (cell as! RepostedTrackTableViewCell).reposterProfileImageView
            } else {
                return (cell as! DropbeatTrackTableViewCell).userProfileImageView
            }
        }
        
        mySegue.setSourceImageView(sourceImageView)
        mySegue.sourceRect = sourceImageView.convertRect(sourceImageView.bounds, toView: self.view)
        mySegue.destinationRect = self.view.convertRect(UserHeaderView.profileImageRect(self), fromView: nil)
        
        let track = self.tracks[indexPath!.row]
        var user: BaseUser!
        if showReposter || track.user == nil {
            user = track.repostingUser
        } else {
            user = track.user
        }
        
        let uvc = segue.destinationViewController as! UserViewController
        uvc.resource = user?.resourceName
        uvc.passedImage = sourceImageView.image
    }
    
    
    private var nextPage:Int = 0
    private var isLoading:Bool = false
    private var refreshControl: UIRefreshControl!
    
    @IBOutlet weak var loadMoreSpinner: UIActivityIndicatorView!
    @IBOutlet weak var loadMoreSpinnerWrapper: UIView!
    
    @IBOutlet var followGuideHeaderView: UIView!
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if tableView != self.trackTableView || tracks.count == 0 || self.tabBarController?.selectedTab != .Feed {
            return
        }
        let trackCell = cell as! DropbeatTrackTableViewCell
        self.updateTrackCellImageOffset(trackCell)
        
        if indexPath.row == tracks.count - 1 {
            if nextPage <= 0 || isLoading {
                return
            }
            loadMoreSpinnerWrapper.hidden = false
            loadMoreSpinner.startAnimating()
            loadFollowingTracks()
        }
    }
    
    func updateTrackCellImageOffset(cell: DropbeatTrackTableViewCell) {
        let imageOverflowHeight = cell.thumbView.frame.size.height / 3
        let cellOffset = CGRectGetMaxY(cell.frame) - self.trackTableView.contentOffset.y
        let maxOffset = self.trackTableView.frame.height + cell.frame.height
        let verticalOffset = imageOverflowHeight * (0.5 - cellOffset/maxOffset)
        
        cell.thumnailCenterConstraint.constant = verticalOffset
    }
    

    func loadFollowingTracks(forceRefresh:Bool=false) {
        if isLoading {
            return
        }
        
        if forceRefresh {
            nextPage = 0
        }
        
        var progressHud:MBProgressHUD?
        if !refreshControl.refreshing && nextPage <= 0 {
            progressHud = ViewUtils.showProgress(self, message: NSLocalizedString("Loading..", comment:""))
        }
        Track.fetchFollowingTracks(nextPage) { (tracks, error) -> Void in
            self.isLoading = false
            progressHud?.hide(true)
            if self.refreshControl.refreshing {
                self.refreshControl.endRefreshing()
            }
            if (error != nil || tracks == nil) {
                if (error != nil && error!.domain == NSURLErrorDomain &&
                    error!.code == NSURLErrorNotConnectedToInternet) {
                        ViewUtils.showNoticeAlert(self,
                            title: NSLocalizedString("Failed to load", comment:""),
                            message: NSLocalizedString("Internet is not connected", comment:""))
                        return
                }
                let message = NSLocalizedString("Failed to load following tracks feed.", comment:"")
                ViewUtils.showNoticeAlert(self, title: NSLocalizedString("Failed to load", comment:""), message: message)
                return
            }
            
            if tracks!.count == 0 {
                self.nextPage = -1
                self.loadMoreSpinner.stopAnimating()
                self.loadMoreSpinnerWrapper.hidden = true
                
                self.trackTableView.tableHeaderView = self.followGuideHeaderView
            } else {
                // when the user only follows Dropbeat official
                CheckOnlyFollowDropbeat: if (self.nextPage == 0) {
                    guard let user = Account.getCachedAccount()?.user
                        where user.num_following == 1 else {
                            break CheckOnlyFollowDropbeat
                    }
                    
                    guard let dropbeat = tracks![0].user as? User
                        where dropbeat.resourceName == "dropbeat" else {
                            break CheckOnlyFollowDropbeat
                    }
                    
                    self.trackTableView.tableHeaderView = self.followGuideHeaderView
                }
                
                self.nextPage += 1
            }
            
            if forceRefresh {
                self.tracks.removeAll(keepCapacity: true)
            }
            for track in tracks! {
                self.tracks.append(track)
            }
            self.updatePlaylist(false)
            self.trackTableView.reloadData()
            
            self.trackChanged()
        }
    }

}
