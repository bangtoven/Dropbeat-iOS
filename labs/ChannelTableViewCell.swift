//
//  ChannelTableViewCell.swift
//  labs
//
//  Created by vulpes on 2015. 7. 26..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

protocol ChannelTableViewCellDelegate {
    func onBookmarkBtnClicked(sender:ChannelTableViewCell)
}

class ChannelTableViewCell: UITableViewCell {
    
    var delegate:ChannelTableViewCellDelegate?

    @IBOutlet weak var nameView: UILabel!
    @IBOutlet weak var thumbView: UIImageView!
    @IBOutlet weak var bookmarkBtn: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        let selectedBgView = UIView(frame: self.bounds)
        selectedBgView.autoresizingMask = [UIViewAutoresizing.FlexibleHeight, UIViewAutoresizing.FlexibleWidth]
        selectedBgView.backgroundColor = UIColor(netHex: 0xdddddd)
        self.selectedBackgroundView = selectedBgView
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func onBookmarkBtnClicked(sender: UIButton) {
        delegate?.onBookmarkBtnClicked(self)
    }
    
}