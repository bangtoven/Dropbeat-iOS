//
//  MMSparkDrawerVisualStateManager.swift
//  labs
//
//  Created by vulpes on 2015. 5. 19..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

import Foundation
import QuartzCore
import MMDrawerController

enum MMDrawerAnimationType: NSInteger {
    case None
    case Slide
    case SlideAndScale
    case SwingingDoor
    case Parallax
}

class MMSparkDrawerVisualStateManager {
    class var sharedMaanger:MMSparkDrawerVisualStateManager {
        struct Static {
            static var onceToken : dispatch_once_t = 0
            static var instance: MMSparkDrawerVisualStateManager? = nil
        }
        dispatch_once(&Static.onceToken) {
            Static.instance = MMSparkDrawerVisualStateManager(left: MMDrawerAnimationType.Parallax, right: MMDrawerAnimationType.Parallax)
        }
        return Static.instance!
    }
    
    var leftDrawerAnimationType:MMDrawerAnimationType
    var rightDrawerAnimationType:MMDrawerAnimationType
    
    init (left:MMDrawerAnimationType, right:MMDrawerAnimationType) {
        self.leftDrawerAnimationType = left
        self.rightDrawerAnimationType = right
    }
    
    func drawerVisualStateBlockForDrawerSide(drawerSide:MMDrawerSide) -> MMDrawerControllerDrawerVisualStateBlock {
        var animationType:MMDrawerAnimationType
        if (drawerSide == MMDrawerSide.Left) {
            animationType = self.leftDrawerAnimationType
        } else {
            animationType = self.rightDrawerAnimationType
        }
        
        var visualStateBlock:MMDrawerControllerDrawerVisualStateBlock?
        switch(animationType) {
        case .Slide:
            visualStateBlock = MMDrawerVisualState.slideVisualStateBlock()
            break
            
        case .SlideAndScale:
            visualStateBlock = MMDrawerVisualState.slideAndScaleVisualStateBlock()
            break
            
        case .SwingingDoor:
            visualStateBlock = MMDrawerVisualState.swingingDoorVisualStateBlock()
            break
            
        case .Parallax:
            visualStateBlock = MMDrawerVisualState.parallaxVisualStateBlockWithParallaxFactor(2.0)
            break
        default:
            visualStateBlock = { (drawerController:MMDrawerController!, drawerSide:MMDrawerSide, percentVisible:CGFloat) -> Void in
                var sideDrawerViewController:UIViewController?
                var transform:CATransform3D?
                var maxDrawerWidth:CGFloat?
                
                if (drawerSide == MMDrawerSide.Left) {
                    sideDrawerViewController = drawerController.leftDrawerViewController
                    maxDrawerWidth = drawerController.maximumLeftDrawerWidth
                } else if (drawerSide == MMDrawerSide.Right) {
                    sideDrawerViewController = drawerController.rightDrawerViewController
                    maxDrawerWidth = drawerController.maximumRightDrawerWidth
                }
                
                if (percentVisible > 1.0) {
                    transform = CATransform3DMakeScale(percentVisible, 1.0, 1.0)
                   
                    if (drawerSide == MMDrawerSide.Left) {
                        transform = CATransform3DTranslate(transform!, maxDrawerWidth! * (percentVisible - (1.0)) / 2, 0.0, 0.0)
                    } else if (drawerSide == MMDrawerSide.Right) {
                        transform = CATransform3DTranslate(transform!, -maxDrawerWidth! * (percentVisible - (1.0)) / 2, 0.0, 0.0)
                    }
                } else {
                    transform = CATransform3DIdentity
                }
            }
            break
        }
        return visualStateBlock!
    }
}