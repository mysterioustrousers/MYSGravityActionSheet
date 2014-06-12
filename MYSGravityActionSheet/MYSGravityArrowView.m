//
//  MYSGravityArrowView.m
//  Pods
//
//  Created by Dan Willoughby on 6/5/14.
//
//

#define ARROW_BASE 20.0f
#define ARROW_HEIGHT 12.0f

#import "MYSGravityArrowView.h"


@implementation MYSGravityArrowView


- (void)setArrowDirection:(UIPopoverArrowDirection)arrowDirection
{
    _arrowDirection = arrowDirection;
    [self setNeedsDisplay];
}

- (void)setPosX:(CGFloat)posX
{
    CGRect bounds = self.bounds;
    if (posX > bounds.size.width) {
        posX = bounds.size.width - ARROW_BASE - self.roundCornerOffset;
    }
    else if (posX < 0)
        posX = 0 + self.roundCornerOffset;
    _posX = posX;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [[UIColor colorWithWhite:1.0 alpha:0.9] setFill];
    switch (self.arrowDirection)
	{
		case UIPopoverArrowDirectionUp:
            CGContextMoveToPoint(ctx, self.posX + ARROW_BASE/2.0f, self.posY);
            CGContextAddLineToPoint(ctx, self.posX + ARROW_BASE, self.posY + ARROW_HEIGHT);
            CGContextAddLineToPoint(ctx, self.posX, self.posY + ARROW_HEIGHT);
            CGContextAddLineToPoint(ctx, self.posX + ARROW_BASE/2.0f, self.posY);
            break;
		case UIPopoverArrowDirectionDown:
            CGContextMoveToPoint(ctx,self.posX, self.posY);
            CGContextAddLineToPoint(ctx, self.posX + ARROW_BASE, self.posY + 0);
            CGContextAddLineToPoint(ctx, self.posX + ARROW_BASE/2.0f, self.posY + ARROW_HEIGHT);
            CGContextAddLineToPoint(ctx, self.posX, self.posY);
            break;
		case UIPopoverArrowDirectionRight:
            CGContextMoveToPoint(ctx, self.posX + 0, self.posY);
            CGContextAddLineToPoint(ctx, self.posX + ARROW_HEIGHT, self.posY + ARROW_BASE/2.0f);
            CGContextAddLineToPoint(ctx, self.posX, self.posY +  ARROW_BASE);
            CGContextAddLineToPoint(ctx, self.posX, self.posY);
            break;
		case UIPopoverArrowDirectionLeft:
            CGContextMoveToPoint(ctx, self.posX + ARROW_HEIGHT, self.posY);
            CGContextAddLineToPoint(ctx, self.posX + ARROW_HEIGHT, self.posY + ARROW_BASE);
            CGContextAddLineToPoint(ctx, self.posX , self.posY + ARROW_BASE/2.0f);
            CGContextAddLineToPoint(ctx, self.posX + ARROW_HEIGHT, self.posY);
            break;
		default:
			break;
    }
    CGContextClosePath(ctx);
    CGContextFillPath(ctx);
}




#pragma mark - Getters

- (CGFloat)arrowBase
{
    return ARROW_BASE;
}

- (CGFloat)arrowHeight
{
    return ARROW_HEIGHT;
}

@end
