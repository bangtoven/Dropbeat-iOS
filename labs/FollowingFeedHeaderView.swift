//
//  FollowingFeedHeaderView.swift
//  labs
//
//  Created by vulpes on 2015. 8. 3..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

protocol FollowingFeedHeaderViewDelegate {
    func onManageFollowBtnClicked(sender:FollowingFeedHeaderView)
}


class FollowingFeedHeaderView:UIView {
    
    @IBOutlet weak var manageFollowBtn: UIButton!

    var delegate:FollowingFeedHeaderViewDelegate?
    var view: UIView!
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        xibSetup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        xibSetup()
    }
    
    func getNibName() -> String {
        return "FollowingFeedHeader"
    }
    
    func xibSetup() {
        view = loadViewFromNib()
        view.frame = bounds
        
        view.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
        
        manageFollowBtn.layer.borderColor = UIColor(netHex: 0x982EF4).CGColor
        manageFollowBtn.layer.borderWidth = 1
        manageFollowBtn.layer.cornerRadius = 3.0
        
        
        addSubview(view)
    }
    
    func loadViewFromNib() -> UIView {
        
        let bundle = NSBundle(forClass: self.dynamicType)
        let nib = UINib(nibName: getNibName(), bundle: bundle)
        let view = nib.instantiateWithOwner(self, options: nil)[0] as! UIView
        
        return view
    }
    
    @IBAction func onManageFollowBtnClicked(sender: AnyObject) {
        delegate?.onManageFollowBtnClicked(self)
    }
}

class FollowingFeedHeaderWithFollowingView:FollowingFeedHeaderView {
    
    @IBOutlet weak var followingInfoView: UILabel!
    
    override func getNibName() -> String {
        return "FollowingFeedHeaderWithFollowing"
    }
}
