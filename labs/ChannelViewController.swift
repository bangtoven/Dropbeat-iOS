//
//  ChannelViewController.swift
//  labs
//
//  Created by vulpes on 2015. 7. 25..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

class Genre {
    var name:String
    var key:String
    init(key:String, name:String) {
        self.name = name
        self.key = key
    }
}

class ChannelViewController: BaseViewController,
        UITableViewDelegate, UITableViewDataSource, ScrollPagerDelegate, ChannelTableViewCellDelegate {
    
    var channels : [Channel] = [Channel]()
    var bookmarkedChannels : [Channel] = [Channel]()
    var genres : [Genre] = [
            Genre(key: "ALL", name: "ALL"),
            Genre(key: "BREAKS", name: "BREAKS"),
            Genre(key: "CHILL OUT", name: "CHILL OUT"),
            Genre(key: "DEEP HOUSE", name: "DEEP HOUSE"),
            Genre(key: "DRUM & BASS", name: "DRUM & BASS"),
            Genre(key: "DUBSTEP", name: "DUBSTEP"),
            Genre(key: "ELECTRO HOUSE", name: "ELECTRO HOUSE"),
            Genre(key: "ELECTRONICA", name: "ELECTRONICA"),
            Genre(key: "GLITCH HOP", name: "GLITCH HOP"),
            Genre(key: "HARD DANCE", name: "HARD DANCE"),
            Genre(key: "HARDCORE / HARD TECHNO", name: "HARDCORE / HARD TECHNO"),
            Genre(key: "HOUSE", name: "HOUSE"),
            Genre(key: "INDIE DANCE / NU DISCO", name: "INDIE DANCE / NU DISCO"),
            Genre(key: "MINIMAL", name: "MINIMAL"),
            Genre(key: "PROGRESSIVE HOUSE", name: "PROGRESSIVE HOUSE"),
            Genre(key: "PSY-TRANCE", name: "PSY-TRANCE"),
            Genre(key: "TECH HOUSE", name: "TECH HOUSE"),
            Genre(key: "TECHNO", name: "TECHNO"),
            Genre(key: "TRANCE", name: "TRANCE")
        ]
    
    var selectedTabIdx = 0
    var channelLoaded = false
    var isGenreSelectMode = false
    var selectedGenre:Genre?
    
    @IBOutlet weak var genreSelectBtn: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var genreTableView: UITableView!
    @IBOutlet weak var genreSelectorWrapper: UIView!
    @IBOutlet weak var pager: ScrollPager!
    @IBOutlet weak var genreSelectorConstraint: NSLayoutConstraint!
    @IBOutlet weak var genreSelectorWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var emptyChannelView: UILabel!
    @IBOutlet weak var emptyBookmarkView: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pager.font = UIFont.systemFontOfSize(11)
        pager.selectedFont = UIFont.systemFontOfSize(11)
        
        pager.delegate = self
        pager.addSegmentsWithTitles(["BOOKMARK", "CHANNELS"])
        pager.reloadInputViews()
        
        genreSelectorConstraint.constant = 0
        genreSelectorWrapper.hidden = true
    }
    
    func updateGenreSelectBtnView(genre: String) {
        var image = genreSelectBtn.imageView!.image
        var titleLabel = genreSelectBtn.titleLabel
        var genreStr:NSString = genre as NSString
        genreSelectBtn.setTitle(genre, forState: UIControlState.Normal)
        
        var attr:[String : UIFont] = [String: UIFont]()
        attr[ NSFontAttributeName] = UIFont.systemFontOfSize(12)
        var textSize:CGSize = genreStr.sizeWithAttributes(attr)
        var textWidth = textSize.width;
        
        //or whatever font you're using
        var frame = genreSelectBtn.frame
        var origin = genreSelectBtn.frame.origin
        genreSelectBtn.frame = CGRectMake(origin.x, origin.y, textWidth + 50, frame.height)
        genreSelectorWidthConstraint.constant = textWidth + 50
        genreSelectBtn.layer.cornerRadius = 4
        genreSelectBtn.imageEdgeInsets = UIEdgeInsetsMake(2, textWidth + 50 - (image!.size.width + 15), 0, 0);
        genreSelectBtn.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 0, image!.size.width + 15);
    }
    
    func scrollPager(scrollPager: ScrollPager, changedIndex: Int) {
        selectedTabIdx = changedIndex
        tableView.reloadData()
        if selectedTabIdx == 0 {
            genreSelectorConstraint.constant = 0
            genreSelectorWrapper.hidden = true
            emptyChannelView.hidden = true
            emptyBookmarkView.hidden = bookmarkedChannels.count != 0
        } else {
            genreSelectorConstraint.constant = 40
            genreSelectorWrapper.hidden = false
            emptyBookmarkView.hidden = true
            emptyChannelView.hidden = channels.count != 0
        }
        tableView.hidden = false
        genreTableView.hidden = true
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.screenName = "ChannelViewScreen"
        
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "appWillEnterForeground",
            name: UIApplicationWillEnterForegroundNotification, object: nil)
        
        if tableView.indexPathForSelectedRow() != nil {
            tableView.deselectRowAtIndexPath(tableView.indexPathForSelectedRow()!, animated: false)
        }
        if (channelLoaded) {
            loadBookmarks()
        } else {
            loadChannels(genres[0], loadBookmarks: true)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self,
            name: UIApplicationWillEnterForegroundNotification, object: nil)
    }
    
    func appWillEnterForeground() {
        if (channelLoaded) {
            loadBookmarks()
        }
    }
    
    func sender () {}
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView,
            cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
                
        if tableView == self.tableView {
            let cell:ChannelTableViewCell = tableView.dequeueReusableCellWithIdentifier(
                    "ChannelTableViewCell", forIndexPath: indexPath) as! ChannelTableViewCell
            cell.delegate = self
            
            var channel: Channel = selectedTabIdx == 0 ? bookmarkedChannels[indexPath.row] : channels[indexPath.row]
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
            
        } else {
            let cell:GenreTableViewCell = genreTableView.dequeueReusableCellWithIdentifier(
                "GenreItem", forIndexPath: indexPath) as! GenreTableViewCell
            let genre = genres[indexPath.row]
            cell.genreView.text = genre.name
            return cell
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if tableView == self.genreTableView {
            var genre = self.genres[indexPath.row]
            loadChannels(genre, loadBookmarks: false)
            toNonGenreSelectMode()
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.tableView {
            var count = 0
            if selectedTabIdx == 0 {
                count = bookmarkedChannels.count
            } else {
                count = channels.count
            }
            return count
        } else {
            return genres.count
        }
    }
    
    func loadBookmarks() {
        if (Account.getCachedAccount() == nil) {
            return
        }
        let progressHud = ViewUtils.showProgress(self, message: "loading bookmarks..")
        Requests.getBookmarkList({ (req: NSURLRequest, resp:NSHTTPURLResponse?, result:AnyObject?, error: NSError?) -> Void in
            
            progressHud.hide(true)
            if (error != nil || result == nil) {
                if (error != nil && error!.domain == NSURLErrorDomain &&
                        error!.code == NSURLErrorNotConnectedToInternet) {
                    ViewUtils.showNoticeAlert(self, title: "Failed to fetch bookmark", message: "Internet is not connected")
                    return
                }
                var message = "Failed to fetch bookmarks caused by undefined error."
                ViewUtils.showNoticeAlert(self, title: "Failed to fetch", message: message)
                return
            }
            
            var json = JSON(result!)
            var data = json["bookmark"]
            var bookmarkIds = [String]()
            for (idx:String, s: JSON) in data {
                bookmarkIds.append(s.stringValue)
            }
            
            self.bookmarkedChannels.removeAll(keepCapacity: false)
            for channel in self.channels {
                if (find(bookmarkIds, channel.uid!) != nil) {
                    channel.isBookmarked = true
                    self.bookmarkedChannels.append(channel)
                } else {
                    channel.isBookmarked = false
                }
            }
            self.tableView.reloadData()
            if !self.isGenreSelectMode {
                if self.bookmarkedChannels.count == 0 &&
                        self.selectedTabIdx == 0 && !self.tableView.hidden {
                    self.emptyBookmarkView.hidden = false
                } else {
                    self.emptyBookmarkView.hidden = true
                }
            }
        })
    }
    
    func loadChannels(genre: Genre, loadBookmarks:Bool) {
        let progressHud = ViewUtils.showProgress(self, message: "loading channels..")
        
        
        selectedGenre = genre
        
        emptyChannelView.hidden = true
        updateGenreSelectBtnView(genre.name)
        
        Requests.getChannelList(genre.key.lowercaseString, respCb: {
                (req: NSURLRequest, resp:NSHTTPURLResponse?, result:AnyObject?, error: NSError?) -> Void in
            progressHud.hide(true)
            if (error != nil || result == nil) {
                if (error != nil && error!.domain == NSURLErrorDomain &&
                        error!.code == NSURLErrorNotConnectedToInternet) {
                    ViewUtils.showNoticeAlert(self, title: "Failed to fetch channels", message: "Internet is not connected")
                    return
                }
                var message = "Failed to fetch channels caused by undefined error."
                ViewUtils.showNoticeAlert(self, title: "Failed to fetch", message: message)
                return
            }
            self.channels.removeAll(keepCapacity: false)
            var channels = Channel.fromListJson(result!, key: "data")
            for channel in channels {
                self.channels.append(channel)
            }
            self.channelLoaded = true
            
            if (loadBookmarks && Account.getCachedAccount() != nil) {
                self.loadBookmarks()
            } else {
                self.tableView.reloadData()
            }
            if !self.isGenreSelectMode {
                if self.channels.count == 0 &&
                        self.selectedTabIdx == 1 && !self.tableView.hidden {
                    self.emptyChannelView.hidden = false
                } else {
                    self.emptyChannelView.hidden = true
                }
            }
        })
    }
    
    @IBAction func onGenreSelectBtnClicked(sender: AnyObject) {
        if isGenreSelectMode {
            toNonGenreSelectMode()
        } else {
            toGenreSelectMode()
        }
    }
    
    func toGenreSelectMode() {
        isGenreSelectMode = true
        tableView.hidden = true
        genreTableView.hidden = false
        emptyChannelView.hidden = true
        emptyBookmarkView.hidden = true
        genreSelectBtn.setImage(UIImage(named:"ic_arrow_up.png"), forState: UIControlState.Normal)
    }
    
    func toNonGenreSelectMode() {
        isGenreSelectMode = false
        tableView.hidden = false
        genreTableView.hidden = true
        if selectedTabIdx == 0 && bookmarkedChannels.count == 0 {
            emptyBookmarkView.hidden = false
        } else if selectedTabIdx == 1 && channels.count == 0 {
            emptyChannelView.hidden = false
        }
        genreSelectBtn.setImage(UIImage(named:"ic_arrow_down.png"), forState: UIControlState.Normal)
    }
    
    func onBookmarkBtnClicked(sender: ChannelTableViewCell) {
        let indexPath:NSIndexPath = tableView.indexPathForCell(sender)!
        if (Account.getCachedAccount() == nil) {
            var appDelegate:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            var centerViewController = appDelegate.centerContainer!
            centerViewController.showSigninView()
            return
        }
        var channel = selectedTabIdx == 0 ? bookmarkedChannels[indexPath.row] : channels[indexPath.row]
        var newBookmarkedIds: [String]?
        var newChannels = [Channel]()
        if (channel.isBookmarked) {
            for c in bookmarkedChannels {
                if (c.uid != channel.uid) {
                    newChannels.append(c)
                }
            }
        } else {
            for c in bookmarkedChannels {
                newChannels.append(c)
            }
            newChannels.append(channel)
        }
        newBookmarkedIds = newChannels.map({ (c:Channel) -> String in
            return c.uid!
        })
        let progressHud = ViewUtils.showProgress(self, message: "saving bookmark..")
        Requests.updateBookmarkList(newBookmarkedIds!, respCb:{
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
            self.bookmarkedChannels = newChannels
            for channel in self.channels {
                channel.isBookmarked = false
            }
            for channel in self.bookmarkedChannels {
                channel.isBookmarked = true
            }
            if self.selectedTabIdx == 0 {
                self.emptyBookmarkView.hidden = self.bookmarkedChannels.count != 0
            }
            self.tableView.reloadData()
        })
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ShowChannelSegue" {
            if let destination = segue.destinationViewController as? ChannelDetailViewController {
                if let idx = tableView.indexPathForSelectedRow()?.row {
                    let channel = selectedTabIdx == 0 ? bookmarkedChannels[idx] : channels[idx]
                    destination.channelUid = channel.uid
                    destination.channelName = channel.name
                }
            }
        }
    }
}
