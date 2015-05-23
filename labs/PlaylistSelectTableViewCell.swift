//
//  PlaylistSelectTableViewCell.swift
//  labs
//
//  Created by vulpes on 2015. 5. 21..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

protocol PlaylistSelectTableViewDelegate {
    func onRenameBtnClicked(sender:PlaylistSelectTableViewCell, btn:UIButton)
    func onDeleteBtnClicked(sender:PlaylistSelectTableViewCell, btn:UIButton)
}

class PlaylistSelectTableViewCell: UITableViewCell {
    
    var delegate:PlaylistSelectTableViewDelegate?

    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var renameBtn: UIButton!
    @IBOutlet weak var deleteBtn: UIButton!
    @IBOutlet weak var nameView: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        var selectedBgView = UIView(frame: self.bounds)
        selectedBgView.autoresizingMask = UIViewAutoresizing.FlexibleHeight | UIViewAutoresizing.FlexibleWidth
        selectedBgView.backgroundColor = UIColor(netHex: 0x1A1A1A)
        self.selectedBackgroundView = selectedBgView
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func onRenameBtnClicked(sender: UIButton) {
        delegate?.onRenameBtnClicked(self, btn: sender)
    }
    
    @IBAction func onDeleteBtnClicked(sender: UIButton) {
        delegate?.onDeleteBtnClicked(self, btn: sender)
    }
}
