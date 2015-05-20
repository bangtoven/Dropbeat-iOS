//
//  SearchViewController.swift
//  labs
//
//  Created by vulpes on 2015. 5. 15..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

class SearchViewController: BaseContentViewController, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate{
    
    var tracks:[Track] = []
    var autocomKeywords:[String] = []
    var autocomRequester:AutocompleteRequester?
    
    @IBOutlet weak var autocomTableView: UITableView!
    @IBOutlet weak var resultTableView: UITableView!
    @IBOutlet weak var keywordView: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        autocomRequester = AutocompleteRequester(handler: onHandleAutocomplete)
        keywordView.becomeFirstResponder()
        autocomTableView.hidden = true
        resultTableView.hidden = true
        keywordView.text = ""
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func onHandleAutocomplete(keywords:Array<String>?, error:NSError?) {
        if (error != nil) {
            println("Failed to get autocomplete:\(error?.description)")
            return
        }
        autocomKeywords.removeAll(keepCapacity: false)
        for keyword in keywords! {
            autocomKeywords.append(keyword)
        }
        autocomTableView.reloadData()
        if (autocomTableView.hidden) {
            showAutocomplete(clear: true)
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        let keyword = textField.text
        if (count(keyword) > 0) {
            doSearch(keyword)
        }
        return true
    }
    
    @IBAction func onKeywordChanged(sender: UITextField) {
        if (count(sender.text) == 0) {
            hideAutocomplete()
        } else {
            autocomRequester?.send(sender.text)
        }
        resultTableView.hidden = true
    }
    
    @IBAction func onKeywordBeginEditing(sender: UITextField) {
        hideAutocomplete()
        resultTableView.hidden = true
    }
    
    @IBAction func onKeywordEndEditing(sender: UITextField) {
        hideAutocomplete()
        resultTableView.hidden = false
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if (tableView == resultTableView) {
            var cell:AddableTrackTableViewCell = tableView.dequeueReusableCellWithIdentifier("AddableTrackTableViewCell", forIndexPath: indexPath) as! AddableTrackTableViewCell
            let track = tracks[indexPath.row]
            cell.nameView.text = track.title
            var image:UIImage?
            if (track.thumbnailUrl != nil) {
                var data:NSData? = NSData(contentsOfURL: NSURL(string:track.thumbnailUrl!)!)
                if (data != nil) {
                    image = UIImage(data: data!)
                }
            }
            if (image == nil) {
                image = UIImage(named: "btn_play_disabled")
            }
            cell.thumbView.image = image!
            return cell
        } else {
            var cell:UITableViewCell = tableView.dequeueReusableCellWithIdentifier("AutocomItem", forIndexPath: indexPath) as! UITableViewCell
            let keyword = autocomKeywords[indexPath.row]
            cell.textLabel?.text = keyword
            return cell
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if (tableView == resultTableView) {
            
        } else {
            let keyword = autocomKeywords[indexPath.row]
            keywordView.text = keyword
            doSearch(keyword)
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (tableView == resultTableView) {
            return tracks.count
        } else {
            return autocomKeywords.count
        }
    }
    
    func hideAutocomplete() {
        autocomTableView.hidden = true
        autocomRequester?.cancelAll()
    }
    
    func showAutocomplete(clear:Bool = false) {
        if (clear) {
            autocomKeywords.removeAll(keepCapacity: false)
            autocomTableView.reloadData()
        }
        autocomTableView.hidden = false
    }
    
    func doSearch(keyword:String) {
        hideAutocomplete()
        // TODO
        // show progress
        keywordView.endEditing(true)
        resultTableView.hidden = false
        
        Requests.search(keyword, respCb: {
                (request:NSURLRequest, response:NSHTTPURLResponse?, result:AnyObject?, error:NSError?) -> Void in
            // TODO 
            // hide progress
            if (error != nil || result == nil) {
                let errorText = error?.description ?? "undefined error"
                ViewUtils.showNoticeAlert(self, title: "Failed to search", message: errorText)
                return
            }
            let parser = Parser()
            let search = parser.parseSearch(result!)
            self.tracks.removeAll(keepCapacity: false)
            for track in search.result {
                self.tracks.append(track)
            }
            self.resultTableView.reloadData()
            self.resultTableView.hidden = false
        })
    }
    
    override func menuBtnClicked(sender: AnyObject) {
        keywordView.endEditing(true)
        super.menuBtnClicked(sender)
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
