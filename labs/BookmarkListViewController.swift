//
//  BookmarkListViewController.swift
//  labs
//
//  Created by vulpes on 2015. 8. 1..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

class BookmarkListViewController: BaseViewController,
        UITableViewDelegate, UITableViewDataSource, ChannelTableViewCellDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var noBookmarkView: UILabel!
    
    var channels : [String:Channel]!
    var bookmarkedChannels : [Channel] = [Channel]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.screenName = "bookmarkListScreen"
        
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "appWillEnterForeground",
            name: UIApplicationWillEnterForegroundNotification, object: nil)
        
        loadBookmarks()
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self,
            name: UIApplicationWillEnterForegroundNotification, object: nil)
    }
    
    func appWillEnterForeground() {
        loadBookmarks()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ShowChannelSegue" {
            if let destination = segue.destinationViewController as? ChannelDetailViewController {
                if let idx = tableView.indexPathForSelectedRow()?.row {
                    let channel = bookmarkedChannels[idx]
                    destination.channelUid = channel.uid
                    destination.channelName = channel.name
                }
            }
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell:ChannelTableViewCell = tableView.dequeueReusableCellWithIdentifier(
                "ChannelTableViewCell", forIndexPath: indexPath) as! ChannelTableViewCell
        cell.delegate = self
        
        var channel: Channel = bookmarkedChannels[indexPath.row]
        if (channel.thumbnail != nil) {
            cell.thumbView.sd_setImageWithURL(
                NSURL(string: channel.thumbnail!),
                placeholderImage: UIImage(named :"default_artwork.png"), completed: {
                    (image: UIImage!, error: NSError!, cacheType:SDImageCacheType, imageURL: NSURL!) -> Void in
                    
                if (error != nil) {
                    cell.thumbView.image = UIImage(named: "default_artwork.png")
                }
                    
            })
        } else {
            cell.thumbView.image = UIImage(named: "default_artwork.png")
        }
        
        cell.nameView.text = channel.name
        if channel.isBookmarked {
            cell.bookmarkBtn.setImage(
                UIImage(named: "ic_star_filled.png"), forState: UIControlState.Normal)
        } else {
            cell.bookmarkBtn.setImage(
                UIImage(named: "ic_star.png"), forState: UIControlState.Normal)
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bookmarkedChannels.count
    }
    
    func loadBookmarks(refreshFeed:Bool=false) {
        if (Account.getCachedAccount() == nil) {
            return
        }
        
        let progressHud = ViewUtils.showProgress(self, message: "Loading..")
        Requests.getBookmarkList({ (req: NSURLRequest, resp:NSHTTPURLResponse?, result:AnyObject?, error: NSError?) -> Void in
            
            progressHud.hide(true)
            if (error != nil || result == nil) {
                if (error != nil && error!.domain == NSURLErrorDomain &&
                        error!.code == NSURLErrorNotConnectedToInternet) {
                    ViewUtils.showNoticeAlert(self, title: "Failed to fetch bookmark", message: "Internet is not connected")
                    return
                }
                var message = "Failed to fetch bookmarks."
                ViewUtils.showNoticeAlert(self, title: "Failed to fetch", message: message)
                return
            }
            
            var json = JSON(result!)
            var data = json["bookmark"]
            var bookmarkIds = Set<String>()
            for (idx:String, s: JSON) in data {
                bookmarkIds.insert(s.stringValue)
            }
            
            self.bookmarkedChannels.removeAll(keepCapacity: false)
            for (uid:String, channel:Channel) in self.channels! {
                channel.isBookmarked = bookmarkIds.contains(channel.uid!)
                if channel.isBookmarked {
                    self.bookmarkedChannels.append(channel)
                }
            }
            self.bookmarkedChannels.sort({ (lhs:Channel, rhs:Channel) -> Bool in
                return lhs.idx! < rhs.idx!
            })
            self.noBookmarkView.hidden = self.bookmarkedChannels.count != 0
            self.tableView.reloadData()
        })
    }
    
    func onBookmarkBtnClicked(sender: ChannelTableViewCell) {
        let indexPath:NSIndexPath = tableView.indexPathForCell(sender)!
        if (Account.getCachedAccount() == nil) {
            var appDelegate:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            var centerViewController = appDelegate.centerContainer!
            centerViewController.showSigninView()
            return
        }
        var channel = bookmarkedChannels[indexPath.row]
        var newBookmarkedIds = Set<String>()
        var newChannels = [Channel]()
        if (channel.isBookmarked) {
            for c in bookmarkedChannels {
                if (c.uid != channel.uid) {
                    newBookmarkedIds.insert(c.uid!)
                }
            }
        } else {
            for c in bookmarkedChannels {
                newBookmarkedIds.insert(c.uid!)
            }
            newBookmarkedIds.insert(channel.uid!)
        }
        let progressHud = ViewUtils.showProgress(self, message: "Saving..")
        Requests.updateBookmarkList(Array(newBookmarkedIds), respCb:{
                (req:NSURLRequest, resp:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            progressHud.hide(false)
            if (error != nil || result == nil) {
                if (error != nil && error!.domain == NSURLErrorDomain &&
                        error!.code == NSURLErrorNotConnectedToInternet) {
                    ViewUtils.showNoticeAlert(self, title: "Failed to update bookmarks", message: "Internet is not connected")
                    return
                }
                var message = "Failed to update bookmarks."
                ViewUtils.showNoticeAlert(self, title: "Failed to update", message: message)
                return
            }
            self.bookmarkedChannels.removeAll(keepCapacity: false)
            for (uid:String, channel:Channel) in self.channels! {
                channel.isBookmarked = newBookmarkedIds.contains(uid)
                if channel.isBookmarked {
                    self.bookmarkedChannels.append(channel)
                }
            }
            self.bookmarkedChannels.sort({ (lhs:Channel, rhs:Channel) -> Bool in
                return lhs.idx! < rhs.idx!
            })
            self.tableView.reloadData()
        })
    }
}
