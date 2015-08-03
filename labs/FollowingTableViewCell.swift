//
//  FollowingTableViewCell.swift
//  labs
//
//  Created by vulpes on 2015. 8. 3..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

protocol FollowingTableViewCellDelegate {
    func onActionBtnClicked(sender:FollowingTableViewCell)
}

class FollowingTableViewCell: UITableViewCell {

    @IBOutlet weak var actionBtn: UIButton!
    @IBOutlet weak var artistName: UILabel!
    
    var delegate:FollowingTableViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func onActionBtnClicked(sender: AnyObject) {
        delegate?.onActionBtnClicked(self)
    }
}
