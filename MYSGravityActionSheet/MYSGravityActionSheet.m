//
//  MTBookFallActionSheet.m
//  DynamicsPlayground
//
//  Created by Dan Willoughby on 5/30/14.
//  Copyright (c) 2014 Willoughby. All rights reserved.
//

#import "MYSGravityActionSheet.h"
#import "UIView+PREBorderView.h"

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
@property (nonatomic, assign) CGFloat             resistance;
@end


@implementation MYSGravityActionSheet


- (void)showInView:(UIView *)view
{
    // pre-animation configuration
    self.padding        = 10;
    self.paddingBottom  = 10;
    self.buttonHeight   = 50;
    self.magnitude      = 3.0;
    self.elasticity     = 0.55;
    self.resistance     = 0.4;  // before items leave the screen upwards, resistance is applied iteratively to each item.
                                // item 0 (top) = 0; item 1 = resistance; item 2 = 2 * resistance;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped:)];
    [self addGestureRecognizer:tap];
    [view addSubview:self];
    
    UIView *selfView = self;
    self.translatesAutoresizingMaskIntoConstraints = NO;
    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[selfView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(selfView)]];
    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[selfView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(selfView)]];
    
    // do the animation
    self.backgroundColor = [UIColor clearColor];
    [UIView animateWithDuration:0.5 animations:^{
        self.backgroundColor =[UIColor colorWithWhite:0.0 alpha:0.4];
    }];
}


- (void)layoutSubviews
{
    CGRect bounds = self.bounds;
   
    // Reverse the buttons so they layout more naturally (the opposite order they are added)
    if (self.reversedButtons == nil)
        self.reversedButtons = [[self.buttons reverseObjectEnumerator] allObjects];

    for (int i = 0; i < self.buttons.count; i++) {
        UIButton *button = [self.reversedButtons objectAtIndex:i];
        button.frame = CGRectMake(bounds.origin.x + self.padding, self.frame.origin.y + self.buttonHeight * (i * -1), bounds.size.width - self.padding * 2, self.buttonHeight);
    }
    
    if (self.buttons.count == 1) {
        [self roundCorner:self.reversedButtons.lastObject corners:UIRectCornerAllCorners];
    }
    else if (self.buttons.count > 1) {
        [self roundCorner:self.reversedButtons[0] corners:UIRectCornerBottomLeft | UIRectCornerBottomRight];
        [self roundCorner:self.reversedButtons.lastObject corners:UIRectCornerTopLeft | UIRectCornerTopRight];
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
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button addOneRetinaPixelBorderWithColor:[UIColor colorWithWhite:0.0 alpha:0.4]];
    [button setTitle:title forState:UIControlStateNormal];
    [button addTarget:self action:@selector(buttonWasTapped:) forControlEvents:UIControlEventTouchDown];
    //button.titleLabel.font = [UIFont systemFontOfSize:13.0];
    button.backgroundColor = [UIColor groupTableViewBackgroundColor];
    
    [self.buttons addObject:button];
    [self addSubview:button];
}

- (void)dismiss
{
    for (UIDynamicBehavior *behavior in self.animator.behaviors) {
        if ([behavior isKindOfClass:[UIGravityBehavior class]])
            [self.animator removeBehavior:behavior];
        else if ([behavior isKindOfClass:[UICollisionBehavior class]])
            [((UICollisionBehavior *)behavior) removeAllBoundaries]; // so items don't get stuck on walls
    }
    
    [self addGravityOnItems:self.reversedButtons magnitude:-1 * self.magnitude animator:self.animator];
    
    for (int i = 0; i < self.reversedButtons.count; i++) {
        UIButton *button = self.buttons[i];
        UIDynamicItemBehavior *behavior = [[UIDynamicItemBehavior alloc] initWithItems:@[button]];
        behavior.resistance = i * self.resistance;
        [self.animator addBehavior:behavior];
    }
    
    [UIView animateWithDuration:self.buttons.count * 0.11
                     animations:^{
                         self.backgroundColor =[UIColor clearColor]; }
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
    [self dismiss]; // always dismiss
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
    [self addGravityOnItems:items magnitude:self.magnitude animator:self.animator];
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

- (void)addGravityOnItems:(NSArray *)items magnitude:(CGFloat)magnitude animator:(UIDynamicAnimator *)animator
{
    UIGravityBehavior *gravity  = [[UIGravityBehavior alloc] initWithItems: items];
    gravity.magnitude           = magnitude;
    
    [animator addBehavior:gravity];
}

- (void)addCollisionOnItems:(NSArray *)items animator:(UIDynamicAnimator *)animator
{
    CGRect bounds   = self.bounds;
    UICollisionBehavior *collision  = [[UICollisionBehavior alloc] initWithItems: items];
    [collision addBoundaryWithIdentifier:@"floor"
                                    fromPoint:CGPointMake(0,bounds.size.height - self.paddingBottom)
                                      toPoint:CGPointMake(bounds.size.width,
                                                          bounds.size.height)];
    double offset = -0.1;
    [collision addBoundaryWithIdentifier:@"leftside"
                                    fromPoint:CGPointMake(self.padding + offset,0)
                                      toPoint:CGPointMake(self.padding + offset,
                                                          bounds.size.height)];
    [collision addBoundaryWithIdentifier:@"rightside"
                                    fromPoint:CGPointMake(bounds.size.width - self.padding + offset, 0)
                                      toPoint:CGPointMake(bounds.size.width - self.padding + offset,
                                                          bounds.size.height)];
    [animator addBehavior:collision];
}

@end
