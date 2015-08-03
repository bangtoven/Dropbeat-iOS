//
//  FollowSearchViewController.swift
//  labs
//
//  Created by vulpes on 2015. 8. 3..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

protocol FollowSearchViewControllerDelegate {
    func onFollowSearchCloseWithResult(isChanged:Bool)
}

class FollowSearchViewController: BaseViewController,
        UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate,
        FollowingTableViewCellDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var followingIds:[Int] = []
    var artists:[Following] = []
    var isChanged:Bool = false
    var initialKeyword:String!
    var delegate:FollowSearchViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.text = initialKeyword
        search(initialKeyword)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.screenName = "FollowManageSearchScreen"
        
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "appWillEnterForeground",
            name: UIApplicationWillEnterForegroundNotification, object: nil)
        
        self.loadFollowings()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(
            self, name: UIApplicationWillEnterForegroundNotification, object: nil)
        delegate?.onFollowSearchCloseWithResult(isChanged)
    }
    
    func appWillEnterForeground() {
        loadFollowings()
    }

    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        if count(searchBar.text) == 0 {
            searchBar.endEditing(true)
            return
        }
        search(searchBar.text)
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell:FollowingTableViewCell = tableView.dequeueReusableCellWithIdentifier("FollowingTableViewCell",
            forIndexPath: indexPath) as! FollowingTableViewCell
        let artist = artists[indexPath.row]
        cell.artistName.text = artist.name
        if artist.isFollowing {
            cell.actionBtn.contentEdgeInsets = UIEdgeInsetsMake(15, 15, 15, 15)
            cell.actionBtn.setImage(UIImage(named:"ic_close.png"), forState: UIControlState.Normal)
        } else {
            cell.actionBtn.contentEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10)
            cell.actionBtn.setImage(UIImage(named:"ic_add_btn.png"), forState: UIControlState.Normal)
        }
        cell.delegate = self
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return artists.count
    }
    
    @IBAction func onTapTouched(sender: AnyObject) {
        searchBar.endEditing(true)
    }
    
    func onActionBtnClicked(sender: FollowingTableViewCell) {
        var indexPath = tableView.indexPathForCell(sender)
        let artist = artists[indexPath!.row]
        if artist.isFollowing {
            unfollow(artist.id)
        } else {
            follow(artist.id)
        }
    }
    
    func search(keyword:String) {
        let progressHud = ViewUtils.showProgress(self, message: "Searching..")
        Requests.searchArtist(keyword, respCb:{
                (req:NSURLRequest, resp:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            progressHud.hide(true)
            if (error != nil || result == nil) {
                if (error != nil && error!.domain == NSURLErrorDomain &&
                        error!.code == NSURLErrorNotConnectedToInternet) {
                    ViewUtils.showConfirmAlert(
                        self, title: "Failed to load", message: "Internet is not connected",
                        positiveBtnText: "Retry",
                        positiveBtnCallback: { () -> Void in
                            self.loadFollowings()
                        },
                        negativeBtnText: "Cancel", negativeBtnCallback: nil)
                    return
                }
                var message = "Failed to load following info."
                ViewUtils.showNoticeAlert(self, title: "Failed to load", message: message)
                return
            }
            
            let parser = Parser()
            let info = parser.parseSearchArtist(result!)
            if !info.success {
                var message = "Failed to load following info."
                ViewUtils.showNoticeAlert(self, title: "Failed to load", message: message)
                return
            }
            
            self.artists.removeAll(keepCapacity: false)
            for artist in info.results! {
                artist.isFollowing = self.followingIds.contains(artist.id)
                self.artists.append(artist)
            }
            self.tableView.reloadData()
        })
    }
    
    func loadFollowings() {
        
        let progressHud = ViewUtils.showProgress(self, message: "Loading..")
        Requests.following { (req:NSURLRequest, resp:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            progressHud.hide(false)
            if (error != nil || result == nil) {
                if (error != nil && error!.domain == NSURLErrorDomain &&
                        error!.code == NSURLErrorNotConnectedToInternet) {
                    ViewUtils.showConfirmAlert(
                        self, title: "Failed to load", message: "Internet is not connected",
                        positiveBtnText: "Retry",
                        positiveBtnCallback: { () -> Void in
                            self.loadFollowings()
                        },
                        negativeBtnText: "Cancel", negativeBtnCallback: nil)
                    return
                }
                var message = "Failed to load following info."
                ViewUtils.showNoticeAlert(self, title: "Failed to load", message: message)
                return
            }
            
            let parser = Parser()
            let info = parser.parseFollowing(result!)
            if !info.success {
                var message = "Failed to load following info."
                ViewUtils.showNoticeAlert(self, title: "Failed to load", message: message)
                return
            }
            
            self.followingIds.removeAll(keepCapacity: false)
            
            for artist in info.results! {
                if !self.followingIds.contains(artist.id) {
                    self.followingIds.append(artist.id)
                }
            }
            for artist in self.artists {
                artist.isFollowing = self.followingIds.contains(artist.id)
            }
            self.tableView.reloadData()
        }
    }
    
    func follow(id:Int) {
        let progressHud = ViewUtils.showProgress(self, message: "Saving..")
        Requests.follow([id], respCb: { (req:NSURLRequest, resp:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            progressHud.hide(false)
            if (error != nil || result == nil) {
                if (error != nil && error!.domain == NSURLErrorDomain &&
                        error!.code == NSURLErrorNotConnectedToInternet) {
                    ViewUtils.showConfirmAlert(
                        self, title: "Failed to follow", message: "Internet is not connected",
                        positiveBtnText: "Retry",
                        positiveBtnCallback: { () -> Void in
                            self.follow(id)
                        },
                        negativeBtnText: "Cancel", negativeBtnCallback: nil)
                    return
                }
                var message = "Failed to save follow info."
                ViewUtils.showNoticeAlert(self, title: "Failed to follow", message: message)
                return
            }
            
            if !(JSON(result!)["success"].bool ?? false) {
                var message = "Failed to save follow info."
                ViewUtils.showNoticeAlert(self, title: "Failed to follow", message: message)
                return
            }
            self.isChanged = true
            self.loadFollowings()
        })
    }
    
    func unfollow(id:Int) {
        let progressHud = ViewUtils.showProgress(self, message: "Saving..")
        Requests.unfollow([id], respCb: { (req:NSURLRequest, resp:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            progressHud.hide(false)
            if (error != nil || result == nil) {
                if (error != nil && error!.domain == NSURLErrorDomain &&
                        error!.code == NSURLErrorNotConnectedToInternet) {
                    ViewUtils.showConfirmAlert(
                        self, title: "Failed to unfollow", message: "Internet is not connected",
                        positiveBtnText: "Retry",
                        positiveBtnCallback: { () -> Void in
                            self.unfollow(id)
                        },
                        negativeBtnText: "Cancel", negativeBtnCallback: nil)
                    return
                }
                var message = "Failed to save unfollow info."
                ViewUtils.showNoticeAlert(self, title: "Failed to unfollow", message: message)
                return
            }
            
            if !(JSON(result!)["success"].bool ?? false) {
                var message = "Failed to save unfollow info."
                ViewUtils.showNoticeAlert(self, title: "Failed to unfollow", message: message)
                return
            }
            
            self.isChanged = true
            self.loadFollowings()
        })
    }
}
