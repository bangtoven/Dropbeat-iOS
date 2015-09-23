//
//  AXStretchableHeaderView.h
//  Pods
//

#import <UIKit/UIKit.h>

@class AXStretchableHeaderView;

@interface AXStretchableHeaderView : UIView

@property (nonatomic) CGFloat minimumOfHeight;
@property (nonatomic) CGFloat maximumOfHeight;
@property (nonatomic) BOOL bounces;

- (NSArray*)interactiveSubviews;
- (void)didHeightRatioChange:(CGFloat)ratio;

@end
