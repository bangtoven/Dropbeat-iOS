//
//  GradientView.h
//  labs
//
//  Created by Jungho Bang on 2015. 9. 15..
//  Copyright (c) 2015년 dropbeat. All rights reserved.
//

#import <UIKit/UIKit.h>

IB_DESIGNABLE
@interface GradientView : UIView

@property (nonatomic) IBInspectable UIColor *fillColor;
@property (nonatomic) IBInspectable CGFloat fillRatio;
@property (nonatomic) IBInspectable BOOL reverse;

@end
