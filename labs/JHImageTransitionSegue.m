//
//  JKImageTransitionSegue.m
//  ImageTransition
//
//  Created by Joris Kluivers on 1/12/13.
//  Copyright (c) 2013 Joris Kluivers. All rights reserved.
//

#import "JHImageTransitionSegue.h"

@interface JHImageTransitionSegue ()
@property(readonly) UIImageView *transitionImageView;
@property(readonly) UILabel *label;
@property(strong) UIImage *transitionImage;
@end

@implementation JHImageTransitionSegue {
    UIImageView *_sourceImageView;
    UILabel *_sourceLabel;
    
	UIImageView *_transitionImageView;
    UILabel *_label;
}

- (id) initWithIdentifier:(NSString *)identifier source:(UIViewController *)source destination:(UIViewController *)destination
{
	self = [super initWithIdentifier:identifier source:source destination:destination];
	if (self) {
		_unwinding = NO;
		_destinationRect = CGRectZero;
	}
	return self;
}

- (void)setSourceImageView:(UIImageView *)sourceImageView
{
    _sourceImageView = sourceImageView;
    
    _transitionImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    
    _transitionImageView.contentMode = UIViewContentModeScaleAspectFill;
    _transitionImageView.backgroundColor = [UIColor whiteColor];
    _transitionImageView.layer.cornerRadius = 10;
    _transitionImageView.layer.borderWidth = 2;
    _transitionImageView.layer.borderColor = [UIColor colorWithWhite:0.95 alpha:1.0].CGColor;
    _transitionImageView.clipsToBounds = true;
    
    _transitionImageView.image = sourceImageView.image;
}

- (void)setSourceLable:(UILabel *)label
{
    _sourceLabel = label;
    
    UILabel *newLabel = [[UILabel alloc]initWithFrame:label.frame];
    newLabel.backgroundColor = label.backgroundColor;
    newLabel.textColor = label.textColor;
    newLabel.textAlignment = label.textAlignment;
    newLabel.text = label.text;
    newLabel.font = label.font;
    newLabel.shadowColor = [UIColor colorWithWhite:0.5 alpha:0.5];
    newLabel.shadowOffset = CGSizeMake(1, 1);
    _label = newLabel;
}

- (void) perform {
    _sourceImageView.hidden = YES;
    _sourceLabel.hidden = YES;
    
	UIWindow *mainWindow = [[UIApplication sharedApplication].windows objectAtIndex:0];
	
	CGRect sourceRectInWindow = [mainWindow convertRect:self.sourceRect fromView:((UIViewController *)self.sourceViewController).view];
	
	UIImageView *imageView = self.transitionImageView;
	imageView.frame = sourceRectInWindow;
	[mainWindow addSubview:imageView];
    
    if (self.label) {
        self.label.frame = [mainWindow convertRect:self.labelSourceRect fromView:((UIViewController *)self.sourceViewController).view];
        [mainWindow addSubview:self.label];
    }
    
	CGRect dest = self.destinationRect;
    CGRect labelDest = self.labelDestinationRect;
	if (CGRectEqualToRect(dest, CGRectZero)) {
		
		CGSize transitionSize = self.transitionImage.size;
		CGRect screenBounds = [UIScreen mainScreen].bounds;
		
		CGFloat factor = fminf(
			CGRectGetWidth(screenBounds) / self.transitionImage.size.width,
			CGRectGetHeight(screenBounds) / self.transitionImage.size.height
		);
		
		dest.size = CGSizeMake(transitionSize.width * factor, transitionSize.height * factor);
		dest.origin = CGPointMake(
			roundf((CGRectGetWidth(screenBounds) - CGRectGetWidth(dest)) / 2.0f),
			roundf((CGRectGetHeight(screenBounds) - CGRectGetHeight(dest)) / 2.0f)
		);
	} else {
		UIView *sourceView = ((UIViewController *)self.sourceViewController).view;
		dest = [sourceView convertRect:dest toView:sourceView.window];
        if (self.label)
            labelDest = [sourceView convertRect:labelDest toView:sourceView.window];
	}
	
	[UIView animateWithDuration:0.5f delay:.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
		
		imageView.frame = dest;
        if (self.label){
            self.label.frame = labelDest;
            self.label.textColor = [UIColor whiteColor];
        }
		
		if (self.unwinding) {
			[self.destinationViewController.navigationController popViewControllerAnimated:YES];
		} else {
            [self.sourceViewController.navigationController pushViewController:self.destinationViewController animated:YES];
		}
	} completion:^(BOOL completed) {
		imageView.hidden = YES;
		[imageView removeFromSuperview];
        _sourceImageView.hidden = NO;
        
        if (self.label){
            self.label.hidden = YES;
            [self.label removeFromSuperview];
            _sourceLabel.hidden = NO;
        }

	}];
}

@end
