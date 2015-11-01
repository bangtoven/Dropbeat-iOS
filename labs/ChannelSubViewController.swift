//
//  ChannelSubViewController.swift
//  labs
//
//  Created by 방정호 on 2015. 11. 2..
//  Copyright © 2015년 dropbeat. All rights reserved.
//

import UIKit

class ChannelSubViewController: TrackSubViewController, DYAlertPickViewDataSource, DYAlertPickViewDelegate {
    var isSectioned: Bool = false
    
    private var currentSectionIndex: Int = 0
    private var nextPageToken:String?
    private var listEnd:Bool = false
    
    @IBOutlet weak var indicatorView: UIView!
    @IBOutlet weak var loadMoreSpinner: UIActivityIndicatorView!
    @IBOutlet weak var loadMoreSpinnerWrapper: UIView!
    
    override func subViewWillAppear() {
        if self.tracks.count == 0 {
            if self.isSectioned != true {
                self.selectSection(0)
            } else {
                self.selectSection(1)
            }
        }
        
        self.trackTableView.reloadData()
        self.trackChanged()
        
        loadMoreSpinnerWrapper.hidden = true
        loadMoreSpinner.stopAnimating()
    }
    
    @IBOutlet weak var sectionLabel: MarqueeLabel!
    func selectSection (index: Int) {
        self.currentSectionIndex = index
        let channel = self.user as! Channel
        let playlist = channel.playlists[index]
        nextPageToken = nil
        listEnd = false
        
        if self.isSectioned {
            self.indicatorView.hidden = false
        }
        
        if (self.trackTableView.tableHeaderView != nil) {
            self.sectionLabel.text = channel.playlists[index].name
        }
        
        self.loadTracks(playlist.uid, pageToken: nextPageToken)
    }
    
    @IBAction func showSelectSection(sender: AnyObject) {
        let picker: DYAlertPickView = DYAlertPickView(headerTitle: "Choose Section", cancelButtonTitle: nil, confirmButtonTitle: nil, switchButtonTitle: nil)
        picker.dataSource = self
        picker.delegate = self
        picker.tintColor = UIColor.dropbeatColor()
        picker.headerBackgroundColor = UIColor.dropbeatColor()
        picker.headerTitleColor = UIColor.dropbeatColor()
        picker.showAndSelectedIndex(self.currentSectionIndex-1)
    }
    
    func numberOfRowsInDYAlertPickerView(pickerView: DYAlertPickView) -> Int {
        let channel = self.user as! Channel
        return channel.playlists.count-1
    }
    
    func titleForRowInDYAlertPickView(titleForRow: Int) -> NSAttributedString! {
        let attr = [NSFontAttributeName: UIFont.systemFontOfSize(16)]
        let channel = self.user as! Channel
        return NSAttributedString(string:channel.playlists[titleForRow+1].name, attributes:attr)
    }
    
    func didConfirmWithItemAtRowInDYAlertPickView(row: Int) {
        self.selectSection(row+1)
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if tableView != self.trackTableView || tracks.count == 0 {
            return
        }
        if indexPath.row == tracks.count - 1 {
            if listEnd || nextPageToken == nil {
                return
            }
            loadMoreSpinnerWrapper.hidden = false
            loadMoreSpinner.startAnimating()
            
            let channel = self.user as! Channel
            let playlist = channel.playlists[self.currentSectionIndex]
            loadTracks(playlist.uid, pageToken: nextPageToken)
        }
    }
    
    func loadTracks(playlistUid:String, pageToken:String?) {
        Requests.getChannelPlaylist(playlistUid, pageToken: pageToken) { (result, error) -> Void in
            if self.isSectioned != true {
                self.trackTableView.tableHeaderView = nil
            } else {
                self.indicatorView.hidden = true
            }
            
            if (error != nil || result == nil) {
                if (error!.domain == NSURLErrorDomain &&
                    error!.code == NSURLErrorNotConnectedToInternet) {
                        ViewUtils.showNoticeAlert(self,
                            title: NSLocalizedString("Failed to load", comment:""),
                            message: NSLocalizedString("Internet is not connected", comment:""))
                        return
                } else {
                    let message = NSLocalizedString("Failed to load tracks.", comment:"")
                    ViewUtils.showNoticeAlert(self, title: NSLocalizedString("Failed to load", comment:""), message: message)
                    return
                }
            }
            
            if pageToken == nil {
                self.tracks.removeAll(keepCapacity: false)
            }
            
            if result!["nextPageToken"].error == nil {
                self.nextPageToken = result!["nextPageToken"].stringValue
            } else {
                self.nextPageToken = nil
            }
            if self.nextPageToken == nil {
                self.listEnd = true
                self.loadMoreSpinnerWrapper.hidden = true
                self.loadMoreSpinner.stopAnimating()
            }
            
            let tracks = Track.parseTracks(result!["items"])
            self.tracks.appendContentsOf(tracks)
            
            self.updatePlaylist(false)
            self.trackTableView.reloadData()
            self.trackChanged()
        }
    }
}
