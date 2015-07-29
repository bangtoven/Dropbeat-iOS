//
//  AddableTrackTableViewCell.swift
//  labs
//
//  Created by vulpes on 2015. 5. 20..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit
    
protocol AddableTrackCellDelegate {
    func onMenuBtnClicked(sender:AddableTrackTableViewCell)
}

class AddableTrackTableViewCell: UITableViewCell {
    
    var delegate:AddableTrackCellDelegate?

    @IBOutlet weak var nameView: UILabel!
    @IBOutlet weak var thumbView: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        var selectedBgView = UIView(frame: self.bounds)
        selectedBgView.autoresizingMask = UIViewAutoresizing.FlexibleHeight | UIViewAutoresizing.FlexibleWidth
        selectedBgView.backgroundColor = UIColor(netHex: 0xdddddd)
        self.selectedBackgroundView = selectedBgView
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func onMenuBtnClicked(sender: UIButton) {
        delegate?.onMenuBtnClicked(self)
    }
    
}
