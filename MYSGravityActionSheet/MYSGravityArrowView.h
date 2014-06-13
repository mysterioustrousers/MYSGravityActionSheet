//
//  MYSGravityArrowView.h
//  Pods
//
//  Created by Dan Willoughby on 6/5/14.
//
//

#import <UIKit/UIKit.h>

@interface MYSGravityArrowView : UIView
@property (nonatomic,         readwrite) UIPopoverArrowDirection arrowDirection;
@property (nonatomic, assign           ) CGFloat                 posX;
@property (nonatomic, assign           ) CGFloat                 posY;
@property (nonatomic,         readwrite) CGFloat                 roundCornerOffset;
+ (CGFloat)arrowHeight;
+ (CGFloat)arrowBase;
@end
