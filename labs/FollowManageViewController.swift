//
//  FollowManageViewController.swift
//  labs
//
//  Created by vulpes on 2015. 8. 3..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

protocol FollowManageViewControllerDelegate {
    func onFollowManageCloseWithResult(isChanged:Bool)
}

class FollowManageViewController: BaseViewController,
        UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate,
        FollowingTableViewCellDelegate, FollowSearchViewControllerDelegate {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    var artists:[Following] = []
    var isLoading:Bool = false
    var delegate:FollowManageViewControllerDelegate?
    var isChanged = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.screenName = "FollowManageScreen"
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "appWillEnterForeground",
            name: UIApplicationWillEnterForegroundNotification, object: nil)
        
        searchBar.text = ""
        loadFollowingList()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(
            self, name: UIApplicationWillEnterForegroundNotification, object: nil)
        
        delegate?.onFollowManageCloseWithResult(isChanged)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func appWillEnterForeground() {
        loadFollowingList()
    }
    
    func onFollowSearchCloseWithResult(isChanged:Bool) {
        self.isChanged = isChanged
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        if count(searchBar.text) == 0 {
            searchBar.endEditing(true)
            return
        }
        performSegueWithIdentifier("SearchSegue", sender: searchBar.text)
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell:FollowingTableViewCell = tableView.dequeueReusableCellWithIdentifier("FollowingTableViewCell",
            forIndexPath: indexPath) as! FollowingTableViewCell
        cell.artistName.text = artists[indexPath.row].name
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
        unfollow(artist.id)
    }
    
    func unfollow(id:Int) {
        let progressHud = ViewUtils.showProgress(self, message: NSLocalizedString("Saving..", comment:""))
        Requests.unfollow([id], respCb: { (req:NSURLRequest, resp:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            progressHud.hide(false)
            if (error != nil || result == nil) {
                if (error != nil && error!.domain == NSURLErrorDomain &&
                        error!.code == NSURLErrorNotConnectedToInternet) {
                    ViewUtils.showConfirmAlert(
                        self, title: NSLocalizedString("Failed to save", comment:""), message: NSLocalizedString("Internet is not connected", comment:""),
                        positiveBtnText: NSLocalizedString("Retry", comment:""),
                        positiveBtnCallback: { () -> Void in
                            self.unfollow(id)
                        },
                        negativeBtnText: NSLocalizedString("Cancel", comment:""), negativeBtnCallback: nil)
                    return
                }
                var message = NSLocalizedString("Failed to save follow info.", comment:"")
                ViewUtils.showNoticeAlert(self, title: NSLocalizedString("Failed to save", comment:""), message: message)
                return
            }
            self.isChanged = true
            self.loadFollowingList()
        })
    }
    
    func loadFollowingList() {
        if isLoading {
            return
        }
        
        let progressHud = ViewUtils.showProgress(self, message: NSLocalizedString("Loading..", comment:""))
        Requests.following { (req:NSURLRequest, resp:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            self.isLoading = false
            progressHud.hide(false)
            if (error != nil || result == nil) {
                if (error != nil && error!.domain == NSURLErrorDomain &&
                        error!.code == NSURLErrorNotConnectedToInternet) {
                    ViewUtils.showConfirmAlert(
                        self, title: NSLocalizedString("Failed to load", comment:""), message: NSLocalizedString("Internet is not connected", comment:""),
                        positiveBtnText: NSLocalizedString("Retry", comment:""),
                        positiveBtnCallback: { () -> Void in
                            self.loadFollowingList()
                        },
                        negativeBtnText: NSLocalizedString("Cancel", comment:""), negativeBtnCallback: nil)
                    return
                }
                var message = NSLocalizedString("Failed to load following info.", comment:"")
                ViewUtils.showNoticeAlert(self, title: NSLocalizedString("Failed to load", comment:""), message: message)
                return
            }
            
            let parser = Parser()
            let info = parser.parseFollowing(result!)
            if !info.success {
                var message = NSLocalizedString("Failed to load following info.", comment:"")
                ViewUtils.showNoticeAlert(self, title: NSLocalizedString("Failed to load", comment:""), message: message)
                return
            }
            
            self.artists.removeAll(keepCapacity: false)
            
            for artist in info.results! {
                self.artists.append(artist)
            }
            self.tableView.reloadData()
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "SearchSegue" {
            let searchVC = segue.destinationViewController as! FollowSearchViewController
            searchVC.initialKeyword = sender as! String
            searchVC.delegate = self
        }
    }
}
