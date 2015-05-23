//
//  PlaylistTableViewCell.swift
//  labs
//
//  Created by vulpes on 2015. 5. 18..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

protocol PlaylistTableViewDelegate {
    func onDeleteBtnClicked(sender:PlaylistTableViewCell)
}

class PlaylistTableViewCell: UITableViewCell {
    
    var delegate:PlaylistTableViewDelegate?

    @IBOutlet weak var deleteBtn: UIButton!
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var trackTitle: UILabel!
    
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
    
    @IBAction func onDeleteBtnClicked(sender: UIButton) {
        delegate?.onDeleteBtnClicked(self)
    }

}
