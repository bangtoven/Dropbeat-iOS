//
//  ProfileViewController.swift
//  labs
//
//  Created by vulpes on 2015. 7. 29..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

class ProfileViewController: BaseViewController,
        UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var profileView: UIImageView!
    @IBOutlet weak var nameView: UILabel!
    @IBOutlet weak var nicknameView: UILabel!
    @IBOutlet weak var emailView: UILabel!
    @IBOutlet weak var likeDescView: UILabel!
    @IBOutlet weak var likeBoxBtn: UIButton!
    @IBOutlet weak var nicknameChangeBtn: UIButton!
    @IBOutlet weak var favoriteGenresView: UILabel!
    @IBOutlet weak var configFavoriteGenreBtn: UIButton!
    
    var playlists:[Playlist] = [Playlist]()
    var genres:[String:Genre] = [String:Genre]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let account = Account.getCachedAccount()!
        nameView.text = "\(account.user!.firstName) \(account.user!.lastName)"
        emailView.text = account.user!.email
        
        nicknameChangeBtn.layer.borderColor = UIColor(netHex: 0x982EF4).CGColor
        nicknameChangeBtn.layer.cornerRadius = 3.0
        nicknameChangeBtn.layer.borderWidth = 1
        
        likeBoxBtn.layer.borderWidth = 1
        likeBoxBtn.layer.cornerRadius = 3.0
        likeBoxBtn.layer.borderColor = UIColor(netHex: 0x982EF4).CGColor
        
        configFavoriteGenreBtn.layer.borderWidth = 1
        configFavoriteGenreBtn.layer.cornerRadius = 3.0
        configFavoriteGenreBtn.layer.borderColor = UIColor(netHex: 0x982EF4).CGColor
        
        if account.user!.fbId != nil && count(account.user!.fbId!) > 0 {
            let fbId = account.user!.fbId!
            let profileUrl = "https://graph.facebook.com/\(fbId)/picture?type=large"
            profileView.sd_setImageWithURL(NSURL(string:profileUrl),
                placeholderImage: UIImage(named: "default_profile.png"))
        } else {
            profileView.image = UIImage(named: "default_profile.png")
        }
        nicknameView.text = account.user!.nickname
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.screenName = "ProfileViewScreen"
        
        let account = Account.getCachedAccount()!
        nicknameView.text = account.user!.nickname
        
        likeDescView.text = NSString.localizedStringWithFormat(
            NSLocalizedString("%d tracks are liked", comment: ""), account.likes.count) as String
            
        playlists.removeAll(keepCapacity: false)
        for playlist in PlayerContext.playlists {
            playlists.append(playlist)
        }
        tableView.reloadData()
        
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "appWillEnterForeground", name: UIApplicationWillEnterForegroundNotification, object: nil)
        
        if tableView.indexPathForSelectedRow() != nil {
            tableView.deselectRowAtIndexPath(tableView.indexPathForSelectedRow()!, animated: false)
        }
        loadPlaylist()
        loadFavoriteGenres()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationWillEnterForegroundNotification, object: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "PlaylistSegue" {
            let playlist = playlists[tableView.indexPathForSelectedRow()!.row]
            let playlistVC = segue.destinationViewController as! PlaylistViewController
            playlistVC.currentPlaylist = playlist
        }
    }
    
    @IBAction func onCreatePlaylistBtnClicked(sender: AnyObject) {
        ViewUtils.showTextInputAlert(
            self, title: NSLocalizedString("Create new playlist", comment:""),
            message: NSLocalizedString("Type new playlist name", comment:""),
            placeholder: NSLocalizedString("Playlist 01", comment:""),
            positiveBtnText: NSLocalizedString("Create", comment:""),
            positiveBtnCallback: { (result) -> Void in
                if (count(result) == 0) {
                    return
                }
                let progressHud = ViewUtils.showProgress(self,
                    message: NSLocalizedString("Creating playlist..", comment:""))
                Requests.createPlaylist(result, respCb: {
                        (request:NSURLRequest, response:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
                    progressHud.hide(true)
                    if (error != nil) {
                        var message:String?
                        if (error != nil && error!.domain == NSURLErrorDomain &&
                                error!.code == NSURLErrorNotConnectedToInternet) {
                            message = NSLocalizedString("Internet is not connected", comment:"")
                        }
                        if (message == nil) {
                            message = NSLocalizedString("Failed to create playlist", comment:"")
                        }
                        ViewUtils.showNoticeAlert(self,
                            title: NSLocalizedString("Failed to create", comment:""),
                            message: message!)
                        return
                    }
                    self.loadPlaylist()
                })
            })
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let playlist = playlists[indexPath.row]
        var cell:PlaylistSelectTableViewCell = tableView.dequeueReusableCellWithIdentifier(
                "PlaylistSelectTableViewCell", forIndexPath: indexPath) as! PlaylistSelectTableViewCell
        cell.nameView.text = playlist.name
        let trackCount = playlist.tracks.count
        cell.trackCount.text = NSString.localizedStringWithFormat(
            NSLocalizedString("%d tracks", comment: ""), trackCount) as String
        if playlist.id == PlayerContext.currentPlaylistId {
            cell.setSelected(true, animated: false)
        }
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return playlists.count
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if tableView.respondsToSelector("separatorInset") {
            tableView.separatorInset = UIEdgeInsetsMake(0, 8, 0, 8)
        }
        
        if tableView.respondsToSelector("layoutMargins") {
            tableView.layoutMargins = UIEdgeInsetsZero
        }
        
        if cell.respondsToSelector("layoutMargins") {
            cell.layoutMargins = UIEdgeInsetsZero
        }
    }
    
    func appWillEnterForeground () {
        loadPlaylist()
    }
    
    func loadFavoriteGenres() {
        
        let handler = { () -> Void in
            let account = Account.getCachedAccount()!
            if account.favoriteGenreIds.count == 0 {
                self.favoriteGenresView.text =
                    NSLocalizedString("No favorite genre selected", comment: "")
            } else {
                var message:String = ""
                var count = 0
                var selectedGenres = [String]()
                for genreId:String in account.favoriteGenreIds {
                    let genre = self.genres[genreId]
                    selectedGenres.append(genre!.name)
                    count += 1
                    if count >= 3 {
                        break
                    }
                }
                message = ", ".join(selectedGenres)
                
                let total = account.favoriteGenreIds.count
                let selected = selectedGenres.count
                var remain = total - selected
                if remain > 0 {
                    message += NSString.localizedStringWithFormat(
                        NSLocalizedString("and %d genres", comment:""),
                        remain) as String
                }
                
                self.favoriteGenresView.text = message
            }
        }
        
        if self.genres.count > 0 {
            handler()
            return
        }
        
        let progressHud = ViewUtils.showProgress(self, message: "")
        favoriteGenresView.text = ""
        Requests.getFeedGenre { (req:NSURLRequest, resp:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            progressHud.hide(true)
            
            var genreResult:GenreList?
            if result != nil {
                genreResult = Parser().parseGenre(result!)
            }
            if error != nil || result == nil ||
                    (genreResult != nil && !genreResult!.success) {
                ViewUtils.showConfirmAlert(self, title: NSLocalizedString("Failed to load", comment:""),
                    message: NSLocalizedString("Failed to load favorite genres", comment:""),
                    positiveBtnText: NSLocalizedString("Retry", comment:""), positiveBtnCallback: { () -> Void in
                    self.loadFavoriteGenres()
                }, negativeBtnText: NSLocalizedString("Cancel", comment:""))
                return
            }
            
            let genres = genreResult!.results!["default"]!
            self.genres.removeAll(keepCapacity: false)
            for genre:Genre in genres {
                self.genres[genre.key] = genre
            }
            
            handler()
        }
    }
    
    func loadPlaylist() {
        let progressHud = ViewUtils.showProgress(self, message: NSLocalizedString("Loading..", comment:""))
        Requests.fetchAllPlaylists({ (request:NSURLRequest, response:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            progressHud.hide(true)
            if error != nil || result == nil {
                ViewUtils.showConfirmAlert(self, title: NSLocalizedString("Failed to fetch", comment:""),
                    message: NSLocalizedString("Failed to fetch playlists.", comment:""),
                    positiveBtnText: NSLocalizedString("Retry", comment:""), positiveBtnCallback: { () -> Void in
                    self.loadPlaylist()
                }, negativeBtnText: NSLocalizedString("Cancel", comment:""))
                return
            }
            let playlists = Parser().parsePlaylists(result!).reverse()
            if playlists.count == 0 {
                ViewUtils.showNoticeAlert(self, title: NSLocalizedString("Failed to fetch playlists", comment:""), message: error!.description)
                return
            }
            PlayerContext.playlists.removeAll(keepCapacity: false)
            self.playlists.removeAll(keepCapacity: false)
            for playlist in playlists {
                PlayerContext.playlists.append(playlist)
                self.playlists.append(playlist)
            }
            self.tableView.reloadData()
        })
    }
}
