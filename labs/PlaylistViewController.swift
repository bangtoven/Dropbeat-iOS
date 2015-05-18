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
    
    var currentPlaylist:Playlist?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadInitialPlaylist()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loadInitialPlaylist() {
        // Some how load playlist
        var tracks = Array<Track>()
        let sampleTrackId = "L1yRgeh9Ojc"
        for idx in 0...10 {
            let trackName:String = "test track \(idx)"
            var track = Track(
                id: sampleTrackId,
                title: trackName,
                type:"youtube"
            )
            tracks.append(track)
        }
        currentPlaylist = Playlist(id: "-1", name: "test playlist", tracks: tracks)
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
        var selectedTrack =  currentPlaylist?.tracks[indexPath.row]
        // DO SOMETHING with selected track
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
