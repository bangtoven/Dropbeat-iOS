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
    
    var playlists = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return playlists.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let identifier:String = "playlist_cell"
        var track = playlists[indexPath.row]
        
        var cell:PlaylistTableViewCell = tableView.dequeueReusableCellWithIdentifier(identifier, forIndexPath: indexPath) as!PlaylistTableViewCell
        cell.trackTitle.text = "sample track title"
        return UITableViewCell()
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var selectedTrack =  playlists[indexPath.row]
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
