//
//  ExploreViewController.swift
//  labs
//
//  Created by Jungho Bang on 2015. 9. 24..
//  Copyright © 2015년 dropbeat. All rights reserved.
//

import UIKit

class ExploreTableViewCell: AddableTrackTableViewCell {
    @IBOutlet weak var channelImageView: UIImageView!
    @IBOutlet weak var channelName: UILabel!
    @IBOutlet weak var publishedAt: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.channelImageView.layer.cornerRadius = 4
        self.channelImageView.layer.borderWidth = 1
        self.channelImageView.layer.borderColor = UIColor(white: 0.95, alpha: 1.0).CGColor
    }
}

class ExploreViewController: AddableTrackListViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var loadMoreSpinner: UIActivityIndicatorView!
    @IBOutlet weak var loadMoreSpinnerWrapper: UIView!
    
    private var nextPage:Int = 0
    private var isLoading:Bool = false
    private var refreshControl:UIRefreshControl!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:" ", style:.Plain, target:nil, action:nil)
        
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
        nextPage = 0
        loadExploreFeed(nextPage, forceRefresh: true)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.screenName = "ExploreViewScreen"
        
        if trackTableView.indexPathForSelectedRow != nil {
            trackTableView.deselectRowAtIndexPath(trackTableView.indexPathForSelectedRow!, animated: false)
        }
        
        self.refresh()
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tracks.count
    }
    
    func tableView(tableView: UITableView,
        cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
            let cell = trackTableView.dequeueReusableCellWithIdentifier(
                "ExploreTableViewCell", forIndexPath: indexPath) as! ExploreTableViewCell
            let track = tracks[indexPath.row]
            cell.delegate = self
            
            cell.channelName.text = track.user?.name
            if let imageUrl = track.user?.image {
                cell.channelImageView.sd_setImageWithURL(NSURL(string: imageUrl), placeholderImage: UIImage(named: "default_profile"))
            } else {
                cell.channelImageView.image = UIImage(named: "default_profile")
            }
            
            cell.nameView.text = track.title
            
            cell.thumbView.setImageForTrack(track, size: .SMALL)
            
            if let publishedAt = track.releaseDate {
                cell.publishedAt.text = publishedAt.timeAgoSinceNow()
            } else {
                cell.publishedAt.hidden = true
            }

            return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let track:Track = tracks[indexPath.row]
        onTrackPlayBtnClicked(track)
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row == tracks.count - 1 {
            if nextPage <= 0{
                return
            }
            loadMoreSpinnerWrapper.hidden = false
            loadMoreSpinner.startAnimating()
            loadExploreFeed(nextPage)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch segue.identifier! {
        case "PlaylistSelectSegue":
            let playlistSelectVC = segue.destinationViewController as! PlaylistSelectViewController
            playlistSelectVC.targetTrack = sender as? Track
            playlistSelectVC.fromSection = "explore"
            playlistSelectVC.caller = self
        case "showChannelInfo":
            let indexPath = self.trackTableView.indexPathOfCellContains(sender as! UIButton)
            let track = self.tracks[indexPath!.row]

            let mySegue = segue as! JHImageTransitionSegue
            let sourceImageView = (self.trackTableView.cellForRowAtIndexPath(indexPath!) as! ExploreTableViewCell).channelImageView
            
            mySegue.setSourceImageView(sourceImageView)
            mySegue.sourceRect = sourceImageView.convertRect(sourceImageView.bounds, toView: self.view)
            mySegue.destinationRect = self.view.convertRect(UserHeaderView.profileImageRect(self), fromView: nil)
            
            let uvc = segue.destinationViewController as! UserViewController
            uvc.resource = track.user?.resourceName
            uvc.passedImage = sourceImageView.image
        default:
            break
        }
    }
    
    func loadExploreFeed(pageIdx: Int, forceRefresh:Bool = false) {
        if isLoading {
            return
        }
        isLoading = true
        
        let tracker = GAI.sharedInstance().defaultTracker
        let event = GAIDictionaryBuilder.createEventWithCategory(
            "load_feed",
            action: "channel_feed",
            label: "feed",
            value: 1
            ).build()
        tracker.send(event as [NSObject: AnyObject]!)
        
        var progressHud:MBProgressHUD?
        if !refreshControl.refreshing && pageIdx == 0 {
            progressHud = ViewUtils.showProgress(self, message: NSLocalizedString("Loading..", comment:""))
            trackTableView.scrollsToTop = true
        }
        Requests.fetchExploreChannelFeed(pageIdx) {(result, error) -> Void in
            
            progressHud?.hide(true)
            self.refreshControl.endRefreshing()
            
            self.isLoading = false
            if (error != nil || result == nil) {
                if (error!.domain == NSURLErrorDomain &&
                    error!.code == NSURLErrorNotConnectedToInternet) {
                        ViewUtils.showNoticeAlert(self,
                            title: NSLocalizedString("Failed to load", comment:""),
                            message: NSLocalizedString("Internet is not connected", comment:""))
                        return
                } else if error!.domain == DropbeatRequestErrorDomain {
                    let message = NSLocalizedString("Failed to load channel feed.", comment:"")
                    ViewUtils.showNoticeAlert(self, title: NSLocalizedString("Failed to load", comment:""), message: message)
                    return
                }
                let message = "Failed to load channel feed."
                ViewUtils.showNoticeAlert(self, title: NSLocalizedString("Failed to load", comment:""), message: message)
                return
            }
            
            let tracks = Track.parseTracks(result!["data"])
            
            if tracks.count == 0 {
                self.nextPage = -1
                self.loadMoreSpinnerWrapper.hidden = true
                self.loadMoreSpinner.stopAnimating()
                return
            } else {
                self.nextPage = pageIdx + 1
            }
            
            if forceRefresh {
                self.tracks.removeAll(keepCapacity: false)
            }
            
            self.tracks.appendContentsOf(tracks)
            
            self.updatePlaylist(false)
            
            self.trackTableView.reloadData()
            self.trackChanged()
        }
        
    }
    
    override func getPlaylistId() -> String? {
        return "Explore"
    }
    
    override func getPlaylistName() -> String? {
        return "Explore"
    }
    
    override func getSectionName() -> String {
        return "explore"
    }
}
