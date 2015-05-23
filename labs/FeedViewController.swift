//
//  ViewController.swift
//  labs
//
//  Created by Park Il Su on 2015. 5. 14..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit
import Alamofire
import MMDrawerController
import MBProgressHUD


class FeedViewController: BaseContentViewController, UITableViewDelegate, UITableViewDataSource, AddableTrackCellDelegate{
    var tracks:Array<Track> = []
    
    @IBOutlet weak var feedTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadFeed()
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "updatePlay:", name: NotifyKey.updatePlay, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "sender", name: NotifyKey.playerPlay, object: nil)
        
    }
    
    func sender () {}
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell:AddableTrackTableViewCell = tableView.dequeueReusableCellWithIdentifier("AddableTrackTableViewCell", forIndexPath: indexPath) as! AddableTrackTableViewCell
        let track:Track = tracks[indexPath.row]
        cell.delegate = self
        cell.nameView.text = track.title
        if (track.thumbnailUrl != nil) {
            cell.thumbView.image = UIImage(data: NSData(contentsOfURL: NSURL(string: track.thumbnailUrl!)!)!)
        }
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var params: Dictionary<String, AnyObject> = [
            "track": tracks[indexPath.row],
            "playlistId": "-1"
        ]
        NSNotificationCenter.defaultCenter().postNotificationName(
            NotifyKey.playerPlay, object: params)
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tracks.count
    }
    
    func loadFeed() {
        let progressHud = ViewUtils.showProgress(self, message: "loading feed..")
        Requests.fetchFeed({(request:NSURLRequest, response:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            progressHud.hide(true)
            if (error != nil) {
                ViewUtils.showNoticeAlert(self, title: "Failed to fetch feed", message: error!.description)
                return
            }
            let parser = Parser()
            var fetchedTracks = parser.parseFeed(result!)
            self.tracks = fetchedTracks.result
            self.feedTableView.reloadData()
            self.updatePlay(PlayerContext.currentTrack, playlistId: PlayerContext.currentPlaylistId)
        })
    }
    
    func onAddBtnClicked(sender: AddableTrackTableViewCell) {
        let indexPath:NSIndexPath = feedTableView.indexPathForCell(sender)!
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
    
    func updatePlay(noti: NSNotification) {
        var params = noti.object as! Dictionary<String, AnyObject>
        var track = params["track"] as! Track
        var playlistId:String? = params["playlistId"] as? String
        
        updatePlay(track, playlistId: playlistId)
    }
    
    func updatePlay(track:Track?, playlistId: String?) {
        if (track == nil) {
            return
        }
        var indexPath = feedTableView.indexPathForSelectedRow()
        if (indexPath != nil) {
            var preSelectedTrack = tracks[indexPath!.row]
            if (preSelectedTrack.id != track!.id ||
                (playlistId != nil && playlistId!.toInt() >= 0)) {
                feedTableView.deselectRowAtIndexPath(indexPath!, animated: false)
            }
        }
        
        
        if (playlistId == nil || playlistId!.toInt() >= 0) {
            return
        }
        
        for (idx, t) in enumerate(tracks) {
            if (t.id == track!.id) {
                feedTableView.selectRowAtIndexPath(NSIndexPath(forRow: idx, inSection: 0),
                    animated: false, scrollPosition: UITableViewScrollPosition.None)
                break
            }
        }
    }
    
}
