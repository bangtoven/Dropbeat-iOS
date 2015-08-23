//
//  GenreSampleTableViewCell.swift
//  labs
//
//  Created by vulpes on 2015. 8. 23..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

protocol GenreSampleTableViewCellDelegate {
    func onPlayBtnClicked(sender:GenreSampleTableViewCell)
    func onPauseBtnClicked(sender:GenreSampleTableViewCell)
    func onLikeBtnClicked(sender:GenreSampleTableViewCell)
}

class GenreSampleTableViewCell: UITableViewCell {
    
    @IBOutlet weak var loaderView: UIActivityIndicatorView!
    @IBOutlet weak var thumbnailView: UIImageView!
    @IBOutlet weak var likeBtn: UIButton!
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var pauseBtn: UIButton!
    var delegate:GenreSampleTableViewCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        self.likeBtn.layer.cornerRadius = 3.0
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    @IBAction func onPauseBtnClicked(sender: AnyObject) {
        delegate?.onPauseBtnClicked(self)
    }
    @IBAction func onPlayBtnClicked(sender: AnyObject) {
        delegate?.onPlayBtnClicked(self)
    }
    @IBAction func onLikeBtnClicked(sender: AnyObject) {
        delegate?.onLikeBtnClicked(self)
    }
}
