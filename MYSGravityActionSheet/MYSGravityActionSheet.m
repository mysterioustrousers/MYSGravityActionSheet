//
//  MTBookFallActionSheet.m
//  DynamicsPlayground
//
//  Created by Dan Willoughby on 5/30/14.
//  Copyright (c) 2014 Willoughby. All rights reserved.
//

#import "MYSGravityActionSheet.h"
#import "UIView+AUISelectiveBorder.h"

typedef void (^ActionBlock)();

@interface MYSGravityActionSheet ()
@property (nonatomic, strong) UIDynamicAnimator   *animator;
@property (nonatomic, strong) NSMutableArray      *buttons;
@property (nonatomic, strong) NSArray             *reversedButtons;
@property (nonatomic, strong) NSMutableArray      *buttonTitles;
@property (nonatomic, retain) NSMutableDictionary *buttonBlockDictionary;
@property (nonatomic, assign) int                 padding;
@property (nonatomic, assign) int                 paddingBottom;
@property (nonatomic, assign) int                 buttonHeight;
@property (nonatomic, assign) CGFloat             magnitude;
@property (nonatomic, assign) CGFloat             elasticity;
@property (nonatomic, assign) CGFloat             force;
@property (nonatomic, strong) UIPopoverController *popover;
@end


@implementation MYSGravityActionSheet


- (void)showFromRect:(CGRect)rect inView:(UIView *)view animated:(BOOL)animated
{
    if (self.popover == nil) {
        //The color picker popover is not showing. Show it.
        UIViewController *viewController = [UIViewController new];
        self.popover = [[UIPopoverController alloc] initWithContentViewController:viewController];
        [self.popover presentPopoverFromRect:rect inView:view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        
       [self showInView:viewController.view];
        CGRect frame = self.popover.contentViewController.view.frame;
        frame.size.height = self.buttons.count * self.buttonHeight + self.padding;
        
        [self.popover setPopoverContentSize:frame.size animated:NO];
        [self setFrame:frame];
        //self.popover.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.4];
    }
}

- (void)showInView:(UIView *)view
{
    // pre-animation configuration
    self.padding       = 10;
    self.paddingBottom = 10;
    self.buttonHeight  = 50;
    self.magnitude     = 3.0;
    self.elasticity    = 0.55;
    self.force         = -100;      // before items leave the screen upwards, resistance is applied iteratively to each item.
                                // item 0 (top) = 0; item 1 = resistance; item 2 = 2 * resistance;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped:)];
    [self addGestureRecognizer:tap];
    [view addSubview:self];
    
    UIView *selfView = self;
    self.translatesAutoresizingMaskIntoConstraints = NO;
    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[selfView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(selfView)]];
    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[selfView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(selfView)]];
    
    // do the animation
    if (self.popover == nil) {
        self.backgroundColor = [UIColor clearColor];
        [UIView animateWithDuration:0.5 animations:^{
            self.backgroundColor =[UIColor colorWithWhite:0.0 alpha:0.4];
        }];
    }
}


- (void)layoutSubviews
{
    CGRect bounds = self.bounds;
   
    // Reverse the buttons so they layout more naturally (the opposite order they are added)
    if (self.reversedButtons == nil)
        self.reversedButtons = [[self.buttons reverseObjectEnumerator] allObjects];

    for (int i = 0; i < self.buttons.count; i++) {
        UIButton *button = [self.reversedButtons objectAtIndex:i];
        button.frame = CGRectMake(bounds.origin.x + self.padding , bounds.origin.y + self.buttonHeight * ((i + 1) * -1), bounds.size.width - self.padding * 2, self.buttonHeight);
    }
    
    if (self.buttons.count == 1) {
        [self roundCorner:self.reversedButtons.lastObject corners:UIRectCornerAllCorners];
    }
    else if (self.buttons.count > 1) {
        [self roundCorner:self.reversedButtons[0] corners:UIRectCornerBottomLeft | UIRectCornerBottomRight];
        UIButton *topButton = self.reversedButtons.lastObject;
        topButton.selectiveBordersWidth = 0;
        [self roundCorner:topButton corners:UIRectCornerTopLeft | UIRectCornerTopRight];
    }
    [self addAnimations];
}

- (void)addButtonWithTitle:(NSString *)title block:(void (^)(void))block
{
    if (self.buttonBlockDictionary == nil) {
        self.buttonBlockDictionary = [[NSMutableDictionary alloc] init];
    }
    if (self.buttons == nil) {
        self.buttons = [[NSMutableArray alloc] init];
    }
    if (block != nil) 
        self.buttonBlockDictionary[title] = block;
    
    UIButton *button                = [UIButton buttonWithType:UIButtonTypeSystem];
    button.selectiveBordersColor    = [UIColor colorWithWhite:0.0 alpha:0.4];
    button.selectiveBordersWidth    = 1;
    button.selectiveBorderFlag      = AUISelectiveBordersFlagTop;
    
    [button setTitle:title forState:UIControlStateNormal];
    [button addTarget:self action:@selector(buttonWasTapped:) forControlEvents:UIControlEventTouchDown];
    //button.titleLabel.font = [UIFont systemFontOfSize:13.0];
    button.backgroundColor = [UIColor groupTableViewBackgroundColor];
    
    [self.buttons addObject:button];
    [self addSubview:button];
}

- (void)dismiss
{
    [self dismissWithButton:nil];
}

- (void)dismissWithButton:(UIButton *)button
{
    for (UIDynamicBehavior *behavior in self.animator.behaviors) {
        if ([behavior isKindOfClass:[UIGravityBehavior class]])
            [self.animator removeBehavior:behavior];
        else if ([behavior isKindOfClass:[UICollisionBehavior class]])
            [((UICollisionBehavior *)behavior) removeAllBoundaries]; // so items don't get stuck on walls
    }

    NSInteger buttonIndex = [self.buttons indexOfObject:button];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.buttons enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (idx < buttonIndex) {
                    UIPushBehavior *pushBehavior = [[UIPushBehavior alloc] initWithItems:@[obj] mode:UIPushBehaviorModeContinuous];
                    pushBehavior.pushDirection = CGVectorMake(0, self.force);
                    [self.animator addBehavior:pushBehavior];
                }
                else if (idx > buttonIndex) {
                    UIGravityBehavior *gravityBehavior = [[UIGravityBehavior alloc] initWithItems:@[obj]];
                    gravityBehavior.magnitude = self.magnitude;
                    [self.animator addBehavior:gravityBehavior];
                }
                else if (idx == buttonIndex){
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        UIGravityBehavior *gravityBehavior = [[UIGravityBehavior alloc] initWithItems:@[obj]];
                        gravityBehavior.magnitude = self.magnitude;
                        [self.animator addBehavior:gravityBehavior];
                    });
                }
            });
            [NSThread sleepForTimeInterval:0.02];
        }];
    });

//    [self addGravityOnItems:self.reversedButtons magnitude:-2 * self.magnitude];

//    for (int i = 0; i < self.reversedButtons.count; i++) {
//        UIButton *button = self.buttons[i];
//        UIDynamicItemBehavior *behavior = [[UIDynamicItemBehavior alloc] initWithItems:@[button]];
//        behavior.resistance = i * self.resistance;
//        [self.animator addBehavior:behavior];
//    }

    if (self.popover != nil) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.buttons.count * 0.04 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.popover dismissPopoverAnimated:YES];
            self.popover = nil;
        });
    }
    [UIView animateWithDuration:self.buttons.count * 0.15
                     animations:^{
                         self.backgroundColor   = [UIColor clearColor]; }
                     completion:^(BOOL finished){
                         [self removeFromSuperview];

                     }];
}





# pragma mark - private

- (void)buttonWasTapped:(UIButton *)button
{
    NSString *key       = button.titleLabel.text;
    ActionBlock block   = self.buttonBlockDictionary[key];
    if (block) block();
    [self dismissWithButton:button]; // always dismiss
}

- (void)roundCorner:(UIView *)view corners:(UIRectCorner)corners
{
    UIBezierPath *maskPath;
    maskPath = [UIBezierPath bezierPathWithRoundedRect:view.bounds
                                     byRoundingCorners: corners
                                           cornerRadii:CGSizeMake(5.0, 5.0)];
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame         = view.bounds;
    maskLayer.path          = maskPath.CGPath;
    view.layer.mask         = maskLayer;
}

- (void)pushView:(UIView *)view vector:(CGVector)vector
{
    UIPushBehavior *push    = [[UIPushBehavior alloc] initWithItems:@[view] mode:UIPushBehaviorModeInstantaneous];
    push.pushDirection      = vector;
    [self.animator addBehavior:push];
}

- (void)viewTapped:(id)sender
{
    [self dismiss];
}


- (void)addAnimations
{
    NSArray *items = self.reversedButtons;
    
    self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self];
    [self addGravityOnItems:items magnitude:self.magnitude];
    [self addCollisionOnItems:items animator:self.animator];
    
    for (int i = 0; i < self.buttons.count; i++) { // separate the buttons a bit by pushing them each a little differently
        UIButton *button = [items objectAtIndex:i];
        [self pushView:button vector:CGVectorMake(0, self.buttons.count - i)];
    }

    // Make 'em bounce
    UIDynamicItemBehavior* itemBehaviour    = [[UIDynamicItemBehavior alloc] initWithItems:items];
    itemBehaviour.elasticity                = self.elasticity;
    itemBehaviour.allowsRotation            = NO;
    [self.animator addBehavior:itemBehaviour];
}

- (void)addGravityOnItems:(NSArray *)items magnitude:(CGFloat)magnitude
{
    UIGravityBehavior *gravity  = [[UIGravityBehavior alloc] initWithItems: items];
    gravity.magnitude           = magnitude;
    [self.animator addBehavior:gravity];
}

- (void)addCollisionOnItems:(NSArray *)items animator:(UIDynamicAnimator *)animator
{
    CGRect bounds   = self.bounds;
    UICollisionBehavior *collision  = [[UICollisionBehavior alloc] initWithItems: items];
    [collision addBoundaryWithIdentifier:@"floor"
                                    fromPoint:CGPointMake(0,bounds.size.height - self.paddingBottom)
                                      toPoint:CGPointMake(bounds.size.width,
                                                          bounds.size.height)];
    double offset = 0.5;
    
    [collision addBoundaryWithIdentifier:@"leftside"
                                    fromPoint:CGPointMake(self.padding + offset,0)
                                      toPoint:CGPointMake(self.padding + offset,
                                                          bounds.size.height)];
    [collision addBoundaryWithIdentifier:@"rightside"
                                    fromPoint:CGPointMake(bounds.size.width - self.padding - offset, 0)
                                      toPoint:CGPointMake(bounds.size.width - self.padding - offset,
                                                          bounds.size.height)];
    [animator addBehavior:collision];
}

@end
