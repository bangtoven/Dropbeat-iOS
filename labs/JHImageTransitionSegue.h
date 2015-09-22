//
//  JKImageTransitionSegue.h
//  ImageTransition
//
//  Created by Joris Kluivers on 1/12/13.
//  Copyright (c) 2013 Joris Kluivers. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JHImageTransitionSegue : UIStoryboardSegue

@property(assign) BOOL unwinding;

- (void)setSourceImageView:(UIImageView *)sourceImageView;
- (void)setSourceLable:(UILabel *)sourceLable;

@property(assign) CGRect sourceRect;
@property(assign) CGRect destinationRect;

@property(assign) CGRect labelSourceRect;
@property(assign) CGRect labelDestinationRect;

@end
