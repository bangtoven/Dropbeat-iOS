//
//  PlaylistViewController.swift
//  labs
//
//  Created by vulpes on 2015. 5. 18..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

class PlaylistViewController: UIViewController, UITableViewDelegate, UITableViewDataSource{

    @IBOutlet weak var playlistView: UITableView!
    
    var currentPlaylist:Playlist!
    
    static var pipeKey = "playPipe"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadInitialPlaylist()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "sender", name: PlaylistViewController.pipeKey, object: nil)
    }
    
    func sender() {}
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loadInitialPlaylist() {
        // Some how load playlist
        var tracks = Array<Track>()
        
        var track = Track(
            id: "rLMas3USFbA",
            title: "Bassjackers - Mush Mush (Original Mix)",
            type: "youtube"
        )
        tracks.append(track)
        
        track = Track(
            id: "O0vf2EfesOA",
            title: "Coldplay - Paradise (Fedde le Grand Remix)",
            type: "youtube"
        )
        tracks.append(track)
        
        track = Track(
            id: "PsO6ZnUZI0g",
            title: "Kanye West - Stronger",
            type: "youtube"
        )
        tracks.append(track)
        
        currentPlaylist = Playlist(id: "-1", name: "test playlist", tracks: tracks)
        PlayerContext.playlists = [currentPlaylist]
        playlistView.reloadData()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentPlaylist!.tracks.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var track = currentPlaylist?.tracks[indexPath.row]
        
        var cell:PlaylistTableViewCell = tableView.dequeueReusableCellWithIdentifier("PlaylistTableViewCell", forIndexPath: indexPath) as!PlaylistTableViewCell
        cell.trackTitle.text = track?.title
        return UITableViewCell()
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var selectedTrack: Track = currentPlaylist!.tracks[indexPath.row] as Track
        // DO SOMETHING with selected track
        var params: Dictionary<String, AnyObject> = [
            "track": selectedTrack,
            "playlistId": currentPlaylist!.id
        ]
        NSNotificationCenter.defaultCenter().postNotificationName(
            PlaylistViewController.pipeKey, object: params)
    }
    
    func dismiss() {
        presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    

    @IBAction func onCloseBtnClicked(sender: UIButton) {
        dismiss()
    }
    
    @IBAction func onPlaylistChangeBtnClicked(sender: UIButton) {
        
    }
    
    @IBAction func onShuffleBtnClicked(sender: UIButton) {
    }
    
    @IBAction func onPrevBtnClicked(sender: UIButton) {
    }
    
    @IBAction func onPlayBtnClicked(sender: UIButton) {
    }
    
    @IBAction func onPauseBtnClicked(sender: UIButton) {
    }
    
    @IBAction func onNextBtnClicked(sender: UIButton) {
    }
    
    @IBAction func onRepeatBtnClicked(sender: UIButton) {
    }
}