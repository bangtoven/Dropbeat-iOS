//
//  FriendFeedHeaderView.swift
//  labs
//
//  Created by vulpes on 2015. 8. 21..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import UIKit

class FriendFeedHeaderView: UIView {
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
        return "FriendFeedHeader"
    }
    
    func xibSetup() {
        view = loadViewFromNib()
        view.frame = bounds
        
        view.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
        
        addSubview(view)
    }
    
    func loadViewFromNib() -> UIView {
        
        let bundle = NSBundle(forClass: self.dynamicType)
        let nib = UINib(nibName: getNibName(), bundle: bundle)
        let view = nib.instantiateWithOwner(self, options: nil)[0] as! UIView
        
        return view
    }
}
