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


class FeedViewController: BaseContentViewController, UITableViewDelegate, UITableViewDataSource {
    var tracks:Array<Track> = []
    
    @IBOutlet weak var feedTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadFeed()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell:AddableTrackTableViewCell = tableView.dequeueReusableCellWithIdentifier("AddableTrackTableViewCell", forIndexPath: indexPath) as! AddableTrackTableViewCell
        let track:Track = tracks[indexPath.row]
        cell.nameView.text = track.title
        if (track.thumbnailUrl != nil) {
            cell.thumbView.image = UIImage(data: NSData(contentsOfURL: NSURL(string: track.thumbnailUrl!)!)!)
        }
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tracks.count
    }
    
    func loadFeed() {
        Requests.fetchFeed({(request:NSURLRequest, response:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            if (error != nil) {
                ViewUtils.showNoticeAlert(self, title: "Failed to fetch feed", message: error!.description)
                return
            }
            let parser = Parser()
            var fetchedTracks = parser.parseFeed(result!)
            self.tracks = fetchedTracks.result
            self.feedTableView.reloadData()
        })
    }
    
}
