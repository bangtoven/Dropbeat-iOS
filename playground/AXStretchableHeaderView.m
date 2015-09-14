//
//  AXStretchableHeaderView.m
//  Pods
//

#import "AXStretchableHeaderView.h"

@implementation AXStretchableHeaderView

+ (instancetype)instantiate {
    AXStretchableHeaderView *view = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass(self).pathExtension owner:self options:nil].lastObject;
    return view;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self configureAXStretchableHeaderView];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self configureAXStretchableHeaderView];
    }
    return self;
}

- (void)configureAXStretchableHeaderView
{
    self.clipsToBounds = YES;
    _bounces = YES;
    _minimumOfHeight = 0;
    _maximumOfHeight = 200;
}

- (NSArray*)interactiveSubviews
{
    return nil;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *targetView = [super hitTest:point withEvent:event];
    if (!targetView) {
        return nil;
    }
    
    NSArray *interactiveSubviews = self.interactiveSubviews;
    if (interactiveSubviews == nil) {
        return targetView;
    }
    
    if ([interactiveSubviews containsObject:self]) {
        return targetView;
    }
    
    // Recursive search interactive view in children.
    __block BOOL isFound = NO;
    UIView *checkView = targetView;
    while (checkView != self) {
        [interactiveSubviews enumerateObjectsUsingBlock:^(UIView *interactiveSubview, NSUInteger idx, BOOL *stop) {
            if (checkView == interactiveSubview) {
                isFound = YES;
                *stop = YES;
            }
        }];
        if (isFound) {
            return targetView;
        }
        checkView = [checkView superview];
    }
    
    return nil;
}

- (void)didHeightRatioChange:(CGFloat)ratio
{
    
}

@end
