//
//  MTBookFallActionSheet.m
//  DynamicsPlayground
//
//  Created by Dan Willoughby on 5/30/14.
//  Copyright (c) 2014 Willoughby. All rights reserved.
//


#define PAD UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad


typedef NS_ENUM(NSInteger, MYSGravityActionSheetButtonType) {
    MYSGravityActionSheetButtonTypeNormal       = 0,
    MYSGravityActionSheetButtonTypeCancel       = 1,
    MYSGravityActionSheetButtonTypeDestructive  = 2,
};


typedef void (^ActionBlock)();


#import "MYSGravityActionSheet.h"
#import "MYSGravityArrowView.h"


@interface MYSGravityActionSheet () <UIDynamicAnimatorDelegate>
@property (nonatomic, strong) UIDynamicAnimator       *animator;
@property (nonatomic, strong) NSMutableArray          *buttons;
@property (nonatomic, strong) NSArray                 *reorderedButtons;
@property (nonatomic, strong) NSMutableArray          *buttonTitles;
@property (nonatomic, retain) NSMutableDictionary     *buttonBlockDictionary;
@property (nonatomic, assign) int                     padding;
@property (nonatomic, assign) int                     paddingBottom;
@property (nonatomic, assign) int                     paddingCancelButton;
@property (nonatomic, assign) CGFloat                 buttonHeight;
@property (nonatomic, assign) CGFloat                 magnitude;
@property (nonatomic, assign) CGFloat                 elasticity;
@property (nonatomic, assign) CGFloat                 force;
@property (nonatomic, assign) CGFloat                 buttonLineHeight;
@property (nonatomic, assign) CGFloat                 separationDistance;
@property (nonatomic, assign) CGFloat                 roundCornerOffset;
@property (nonatomic, strong) UIPopoverController     *popover;
@property (nonatomic, weak  ) UIView                  *presentInView;
@property (nonatomic, strong) UIView                  *presentFromView;
@property (nonatomic, strong) UIBarButtonItem         *presentFromBarButton;
@property (nonatomic, strong) UIView                  *buttonView;
@property (nonatomic, assign) CGRect                  displayRect;
@property (nonatomic, assign) UIPopoverArrowDirection arrowDirection;
@property (nonatomic, assign) BOOL                    isDismissing;
@end


@implementation MYSGravityActionSheet



- (void)showFromBarButtonItem:(UIBarButtonItem *)item inView:(UIView *)inView animated:(BOOL)animated
{
    self.presentFromBarButton   = item;
    self.presentInView          = inView;
    
    [self showInView:self.presentInView];
    
    UIView *view            = [item valueForKey:@"view"];
    self.presentFromView    = view;
    [self adjustPopoverLayout];
    
    // HACK leech off the popover's rect but don't actually use the popover (present popover so rect is set, then immediately dismiss)
    [self.popover presentPopoverFromBarButtonItem:item permittedArrowDirections:UIPopoverArrowDirectionDown | UIPopoverArrowDirectionUp animated:NO];
    self.arrowDirection = self.popover.popoverArrowDirection;
    CGRect pt1          = [self.popover.contentViewController.view convertRect:self.popover.contentViewController.view.frame toView:self.superview];
    self.displayRect    = pt1;
    
    [self.popover dismissPopoverAnimated:NO];
}

- (void)showFromView:(UIView *)fromView inView:(UIView *)inView animated:(BOOL)animated
{
    self.presentFromView    = fromView;
    self.presentInView      = inView;
    
    [self showInView:inView];
    [self adjustPopoverLayout];
    
    // HACK leech off the popover's rect but don't actually use the popover (present popover so rect is set, then immediately dismiss)
    [self.popover presentPopoverFromRect:fromView.frame inView:inView permittedArrowDirections:UIPopoverArrowDirectionUp | UIPopoverArrowDirectionDown animated:NO];
    self.arrowDirection = self.popover.popoverArrowDirection;
    CGRect pt1          = [self.popover.contentViewController.view convertRect:self.popover.contentViewController.view.frame toView:inView];
    self.displayRect    = pt1;
    
    [self.popover dismissPopoverAnimated:NO];
}

- (void)adjustPopoverLayout
{
    // TODO determine width dynamically or something..
    [self.popover setPopoverContentSize:CGSizeMake(250, self.buttons.count * (self.buttonHeight - self.buttonLineHeight) + self.buttonLineHeight) animated:NO];
}

- (void)showInView:(UIView *)view
{
    self.visible = YES;

    // pre-animation configuration
    self.padding                = 8;
    self.paddingBottom          = 8;
    self.paddingCancelButton    = 5;
    self.buttonHeight           = 48;
    self.magnitude              = 3.0;
    self.elasticity             = 0.55;
    self.force                  = PAD ? -200 : -100; // applies force to items above selected item
    self.isDismissing           = NO;
    self.buttonLineHeight       = 2;
    self.separationDistance     = 10;       // The distance each button is apart before they start to fall
    self.roundCornerOffset      = 5;        // How much the button corners are rounded
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped:)];
    [self addGestureRecognizer:tap];
    if(![self isDescendantOfView: view]) {
        [view addSubview:self];
        [self setNeedsLayout];
    }

    UIView *selfView = self;
    self.translatesAutoresizingMaskIntoConstraints = NO;
    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[selfView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(selfView)]];
    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[selfView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(selfView)]];
    
    self.backgroundColor = [UIColor clearColor];
    [UIView animateWithDuration:0.5 animations:^{
        self.backgroundColor =[UIColor colorWithWhite:0.0 alpha:0.3];
    }];
    
    [self startOrientationObserving];
}


- (void)layoutSubviews
{
    [super layoutSubviews];
    CGRect bounds;
    
    if (self.popover)
        bounds = self.displayRect;
    else
        bounds = self.bounds;
    
    if (self.reorderedButtons == nil)
        self.reorderedButtons = [self reorderButtons];
    
    // The button order is determined by its y origin value.
    for (int i = 0; i < self.buttons.count; i++) {
        UIView *buttonContainer = [self.reorderedButtons objectAtIndex:i];
        if (self.popover) {
            buttonContainer.frame = CGRectMake(bounds.origin.x , self.bounds.origin.y + (self.buttonHeight + self.separationDistance)* ((i + 1) * -1), bounds.size.width, self.buttonHeight);
        }
        else {
            buttonContainer.frame = CGRectMake(bounds.origin.x + self.padding , self.bounds.origin.y + (self.buttonHeight + self.separationDistance) * ((i + 1) * -1), bounds.size.width - self.padding * 2, self.buttonHeight);
        }
        
        // Makes a line visable between each button
        UIButton *button    = [self buttonFromContainer:buttonContainer];
        button.frame        = CGRectInset(buttonContainer.bounds, 0, self.buttonLineHeight);
    }
    
    [self roundButtonCornersAndCancelButtonPadding];
    
    if (self.popover) {
        [self addArrowToButtonContainer];
        [self adjustDisplayRectForArrow];
    }
    
    if (self.animator == nil) {
        [self addAnimations];
    }
}


- (void)addButtonWithTitle:(NSString *)title block:(void (^)(void))block
{
    if (block != nil) {
        self.buttonBlockDictionary[title] = block;
    }

    UIView *buttonContainer = [UIView new];
    buttonContainer.tag     = MYSGravityActionSheetButtonTypeNormal;
    [self addSubview:buttonContainer];
    [buttonContainer addSubview:[self buttonWithTitle:title textColor:nil]];
    
    [self.buttons addObject:buttonContainer];
}

- (void)setCancelButtonWithTitle:(NSString *)title block:(void (^)(void))block
{
    if (block != nil)
        self.buttonBlockDictionary[title] = block;

    UIView *buttonContainer = [UIView new];
    buttonContainer.tag     = MYSGravityActionSheetButtonTypeCancel;
    [self addSubview:buttonContainer];
    UIButton *button        = [self buttonWithTitle:title textColor:nil];
    button.titleLabel.font  = [UIFont boldSystemFontOfSize:button.titleLabel.font.pointSize];
    [buttonContainer addSubview:button];
    
    [self.buttons addObject:buttonContainer];
}

- (void)setDestructiveButtonWithTitle:(NSString *)title block:(void (^)(void))block
{
    if (block != nil)
        self.buttonBlockDictionary[title] = block;

    UIView *buttonContainer = [UIView new];
    buttonContainer.tag     = MYSGravityActionSheetButtonTypeDestructive;
    [self addSubview:buttonContainer];
    [buttonContainer addSubview:[self buttonWithTitle:title textColor:[UIColor redColor]]];
    
    [self.buttons addObject:buttonContainer];
}

- (void)dismiss
{
    [self dismissWithButton:nil];
}

- (void)dismissWithButton:(UIButton *)button
{
    if (self.isDismissing) return;
    
    self.isDismissing   = YES;
    
    for (UIDynamicBehavior *behavior in self.animator.behaviors) {
        if ([behavior isKindOfClass:[UIGravityBehavior class]])
            [self.animator removeBehavior:behavior];
        else if ([behavior isKindOfClass:[UICollisionBehavior class]])
            [((UICollisionBehavior *)behavior) removeAllBoundaries]; // so items don't get stuck on walls
    }

    NSInteger buttonIndex   = [self.reorderedButtons indexOfObject:[button superview]];
    BOOL isDropViewSelected = NO;
    if (buttonIndex == NSNotFound) {
        buttonIndex         = 0;
        isDropViewSelected  = YES;
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIGravityBehavior *gravityBehavior  = [[UIGravityBehavior alloc] init];
        gravityBehavior.magnitude           = self.magnitude * (PAD ? 10 : 1);
            
        // Delay the chosen one
        [self.reorderedButtons enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (idx > buttonIndex || isDropViewSelected) {
                    UIPushBehavior *pushBehavior    = [[UIPushBehavior alloc] initWithItems:@[obj] mode:UIPushBehaviorModeContinuous];
                    pushBehavior.pushDirection      = CGVectorMake(0, self.force);
                    [self.animator addBehavior:pushBehavior];
                }
                else if (idx < buttonIndex) {
                    [gravityBehavior addItem:obj];
                    [self.animator addBehavior:gravityBehavior];
                }
                else if (idx == buttonIndex){
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [gravityBehavior addItem:obj];
                        [self.animator addBehavior:gravityBehavior];
                    });
                }
            });
            [NSThread sleepForTimeInterval:0.02];
        }];
    });
    
    // A rect on the bottom of the superview to detect when the last visable view is leaving. Then fade the backdrop.

    if (self.reorderedButtons.count > 0) {
        UIView *lastVisableView             = self.reorderedButtons[buttonIndex];
        __block BOOL isAnimatingBackDrop    = NO;
        UIDynamicItemBehavior *dynamic      = [[UIDynamicItemBehavior alloc] initWithItems:@[lastVisableView]];
        dynamic.action = ^{
            for (UIDynamicBehavior *behavior in self.animator.behaviors) {
                for (UIView *view in [(UIPushBehavior *)behavior items]) {
                    CGRect frameInWindow = [view.superview convertRect:view.frame toView:nil];
                    if (CGRectIntersectsRect(frameInWindow, view.window.frame)) {
                        return;
                    }
                }
            }
            [self.animator removeAllBehaviors];

            if (isAnimatingBackDrop) return;
            isAnimatingBackDrop = YES;

            [UIView animateWithDuration:0.3 animations:^{
                self.backgroundColor = [UIColor clearColor];
            } completion:^(BOOL finished) {
                [self removeAnimationAndView];
                self.visible = NO;
                NSString *key       = button.titleLabel.text;
                ActionBlock block   = self.buttonBlockDictionary[key];
                if (block) block();
            }];
        };
        
        [self.animator addBehavior:dynamic];
    }
    else {
        // When there are no buttons.
        [UIView animateWithDuration:0.3 animations:^{
            self.backgroundColor = [UIColor clearColor];
        }];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self removeAnimationAndView];
            self.visible = NO;
        });
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}




# pragma mark - Getters

- (NSMutableDictionary *)buttonBlockDictionary
{
    if (_buttonBlockDictionary == nil) {
        _buttonBlockDictionary = [[NSMutableDictionary alloc] init];
    }
    return _buttonBlockDictionary;
}

- (NSMutableArray *)buttons
{
    if (_buttons == nil) {
        _buttons = [[NSMutableArray alloc] init];
    }
    return _buttons;
}

- (UIPopoverController *)popover
{
    if (_popover == nil && PAD) {
        UIViewController *viewController = [UIViewController new];
        _popover = [[UIPopoverController alloc] initWithContentViewController:viewController];
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    }
    return _popover;
}




# pragma mark - private
- (void)addArrowToButtonContainer

{
    UIView *bottomButtonContainer           = [self.reorderedButtons firstObject];
    UIView *topButtonContainer              = [self.reorderedButtons lastObject];
    MYSGravityArrowView *bottomArrowView    = nil;
    MYSGravityArrowView *topArrowView       = nil;
    UIButton *topButton                     = nil;
    
    for(UIView *view in topButtonContainer.subviews){
        if([view isKindOfClass:[UIButton class]]){
            topButton = (UIButton *)view;
        }
        else if([view isKindOfClass:[MYSGravityArrowView class]]){
            topArrowView = (MYSGravityArrowView *)view;
        }
    }
    for(UIView *view in bottomButtonContainer.subviews){
        if([view isKindOfClass:[MYSGravityArrowView class]]){
            bottomArrowView = (MYSGravityArrowView *)view;
        }
    }
    
    // Button Containers
    CGRect bottomContainerFrame         = bottomButtonContainer.frame;
    bottomContainerFrame.size.height   += [MYSGravityArrowView arrowHeight];
    bottomButtonContainer.frame         = bottomContainerFrame;
    
    CGRect topContainerFrame        = topButtonContainer.frame;
    topContainerFrame.size.height  += [MYSGravityArrowView arrowHeight];
    topButtonContainer.frame        = topContainerFrame;
    
    
    // Top Button
    CGRect topButtonRect = topButton.frame;
    if (self.reorderedButtons.count == 1)
        topButtonRect.origin.y = topButtonContainer.bounds.origin.y + topButtonContainer.bounds.size.height - self.buttonLineHeight - topButtonRect.size.height - [MYSGravityArrowView arrowHeight];
    else
        topButtonRect.origin.y = topButtonContainer.bounds.origin.y + topButtonContainer.bounds.size.height - self.buttonLineHeight - topButtonRect.size.height;
    topButton.frame = topButtonRect;
    
    // Bottom Arrow
    CGRect arrowRect        = bottomButtonContainer.bounds;
    arrowRect.origin.y      = bottomButtonContainer.bounds.origin.y + bottomButtonContainer.bounds.size.height - [MYSGravityArrowView arrowHeight] - self.buttonLineHeight - 0.5;     // 0.5 for just a little overlap
    arrowRect.size.height   = [MYSGravityArrowView arrowHeight];
    
    if (bottomArrowView == nil) {
        bottomArrowView                     = [MYSGravityArrowView new];
        bottomArrowView.roundCornerOffset   = self.roundCornerOffset;
        bottomArrowView.arrowDirection      = UIPopoverArrowDirectionDown;
        bottomArrowView.backgroundColor     = [UIColor clearColor];
        [bottomButtonContainer addSubview:bottomArrowView];
    }
    bottomArrowView.frame           = arrowRect;
    
    // Top arrow
    CGRect topArrowRect        = topButtonContainer.bounds;
    topArrowRect.origin.y      = topButtonContainer.bounds.origin.y  + self.buttonLineHeight;
    topArrowRect.size.height   = [MYSGravityArrowView arrowHeight];
    if (topArrowView == nil) {
        topArrowView                    = [MYSGravityArrowView new];
        topArrowView.roundCornerOffset  = self.roundCornerOffset;
        topArrowView.arrowDirection     = UIPopoverArrowDirectionUp;
        topArrowView.backgroundColor    = [UIColor clearColor];
        [topButtonContainer addSubview:topArrowView];
    }
    topArrowView.frame              = topArrowRect;
}

- (UIButton *)buttonFromContainer:(UIView *)buttonContainer
{
    for(UIButton *button in buttonContainer.subviews){
        if([button isKindOfClass:[UIButton class]]){
            return button;
        }
    }
    return nil;
}

- (void)roundButtonCornersAndCancelButtonPadding
{
    if (self.buttons.count == 1) {
        UIButton *button =  [self buttonFromContainer:[self.reorderedButtons lastObject]];
        [self roundCorner:button corners:UIRectCornerAllCorners];
    }
    else if (self.buttons.count > 1) {
        UIButton *topButton =  [self buttonFromContainer:[self.reorderedButtons lastObject]];
        [self roundCorner:topButton corners:UIRectCornerTopLeft | UIRectCornerTopRight];
        
        UIView *bottomButtonContainer   = [self.reorderedButtons firstObject];
        UIButton *bottomButton          = [self buttonFromContainer:bottomButtonContainer];
        
        // Make cancel button separation
        if (bottomButtonContainer.tag == MYSGravityActionSheetButtonTypeCancel) {
            CGRect bFrame               = bottomButtonContainer.frame;
            bFrame.size.height         += self.paddingCancelButton;
            bottomButtonContainer.frame = bFrame;
            bFrame                      = bottomButton.frame;
            bFrame.origin.y            += self.paddingCancelButton;
            bottomButton.frame          = bFrame;
            [self roundCorner:bottomButton corners:UIRectCornerAllCorners];
            
            if (self.reorderedButtons.count > 1) {
                UIView *secondToBottomButtonContainer   = self.reorderedButtons[1];
                UIButton *secondToBottomButton          = [self buttonFromContainer:secondToBottomButtonContainer];
                
                if (self.reorderedButtons.count == 2) // only two
                    [self roundCorner:secondToBottomButton corners:UIRectCornerAllCorners];
                else
                    [self roundCorner:secondToBottomButton corners:UIRectCornerBottomLeft | UIRectCornerBottomRight];
            }
        }
        else {
            [self roundCorner:bottomButton corners:UIRectCornerBottomLeft | UIRectCornerBottomRight];
        }
    }
}

- (NSArray *)reorderButtons
{
    NSMutableArray *arr;
    
    // Reverse the buttons so they layout more naturally (the opposite order they are added)
    arr = [NSMutableArray arrayWithArray:[[self.buttons reverseObjectEnumerator] allObjects]];
    
    // Find cancel button
    UIView *cancelView = nil;
    for (int i = 0; i < arr.count; i++) {
        UIView *buttonContainer = [arr objectAtIndex:i];
        if (buttonContainer.tag == MYSGravityActionSheetButtonTypeCancel) {
            cancelView = buttonContainer;
            [arr removeObject:buttonContainer];
            break;
        }
    }
    
    // Place the cancel button so it appears on bottom
    if (cancelView != nil) {
        [arr insertObject:cancelView atIndex:0];
    }
    
    return [NSArray arrayWithArray:arr];
}

- (void)removeAnimationAndView
{
    [self.animator removeAllBehaviors];
    self.animator = nil;
    self.presentFromView = nil;
    self.presentFromBarButton = nil;
    self.presentInView = nil;
    [self removeFromSuperview];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (UIButton *)buttonWithTitle:(NSString *)title textColor:(UIColor *)color
{
    UIButton *button            = [UIButton buttonWithType:UIButtonTypeSystem];
    button.backgroundColor      = [UIColor colorWithWhite:1.0 alpha:0.95];
    button.titleLabel.font      = [UIFont systemFontOfSize:22];
    [button setTitle:title forState:UIControlStateNormal];
    [button addTarget:self action:@selector(buttonWasTapped:) forControlEvents:UIControlEventTouchDown];
    if (color)
        [button setTitleColor:color forState:UIControlStateNormal];
    return button;
}

- (void)adjustDisplayRectForArrow
{
    CGFloat arrowViewHeight = [MYSGravityArrowView arrowHeight];
    
    UIView *topButtonContainer      = [self.reorderedButtons lastObject];
    UIView *bottomButtonContainer      = [self.reorderedButtons firstObject];
    
    // Locate arrow views in containers
    MYSGravityArrowView *topArrowView  = nil;
    for(MYSGravityArrowView *view in topButtonContainer.subviews)
        if([view isKindOfClass:[MYSGravityArrowView class]] && view.arrowDirection == UIPopoverArrowDirectionUp)
            topArrowView = (MYSGravityArrowView *)view;
    
    MYSGravityArrowView *bottomArrowView  = nil;
    for(MYSGravityArrowView *view in bottomButtonContainer.subviews)
        if([view isKindOfClass:[MYSGravityArrowView class]] && view.arrowDirection == UIPopoverArrowDirectionDown)
            bottomArrowView = (MYSGravityArrowView *)view;
    
    CGRect adjustment   = self.displayRect;
    switch (self.arrowDirection) {
        case UIPopoverArrowDirectionUp:
            if (bottomButtonContainer.tag == MYSGravityActionSheetButtonTypeCancel)
                adjustment.origin.y    += arrowViewHeight + self.paddingCancelButton/1.5; // hack to deal with UIPopupController rect and the custom arrow
            else
                adjustment.origin.y    += arrowViewHeight;
            self.displayRect        = adjustment;
            bottomArrowView.hidden  = YES;
            topArrowView.hidden     = NO;
            break;
        case UIPopoverArrowDirectionDown:
            adjustment              = self.displayRect;
            adjustment.origin.y    += arrowViewHeight + 2; // +2 is a hack to deal UIPopupController rect and the custom arrow (among other things)
            self.displayRect        = adjustment;
            bottomArrowView.hidden  = NO;
            topArrowView.hidden     = YES;
            break;
        default:
            break;
    }
    
    // Place the arrow
    CGRect arrowRect        = [self.superview convertRect:topButtonContainer.bounds fromView:topButtonContainer]; // the top Container is the same size as the arrow view. All we care about is the x position
    CGRect presentViewRect;
    if (self.presentFromBarButton)
        presentViewRect = self.presentFromView.frame;
    else
        presentViewRect = [self.superview convertRect:self.presentFromView.bounds fromView:self.presentFromView];
    
    double offsetX                      = presentViewRect.origin.x - arrowRect.origin.x + presentViewRect.size.width/2 - [MYSGravityArrowView arrowBase]/2 ;
    topArrowView.posX                   = offsetX;
    bottomArrowView.posX                = offsetX;
}

- (void)orientationChanged:(id)sender
{
    if (self.popover && self.presentFromBarButton == nil) {
        [self.popover presentPopoverFromRect:self.presentFromView.frame inView:self.presentInView permittedArrowDirections:UIPopoverArrowDirectionUp | UIPopoverArrowDirectionDown animated:NO];
        CGRect pt1                      = [self.popover.contentViewController.view convertRect:self.popover.contentViewController.view.bounds toView:self.presentInView];
        self.arrowDirection   = self.popover.popoverArrowDirection;
        [self.popover dismissPopoverAnimated:NO];

        self.displayRect = pt1;
    }
    else if (self.popover && self.presentFromBarButton) {
        [self.popover presentPopoverFromBarButtonItem:self.presentFromBarButton permittedArrowDirections:UIPopoverArrowDirectionDown | UIPopoverArrowDirectionUp animated:NO];
        self.arrowDirection   = self.popover.popoverArrowDirection;
        CGRect pt1                      = [self.popover.contentViewController.view convertRect:self.popover.contentViewController.view.frame toView:self.superview];
        self.displayRect                = pt1;
        
    }
    
    [self.popover dismissPopoverAnimated:NO];
    self.animator = nil;
    [self setNeedsLayout];
}

- (void)startOrientationObserving
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationChanged:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
}

- (void)buttonWasTapped:(UIButton *)button
{
    [self dismissWithButton:button]; // always dismiss
}

- (void)roundCorner:(UIView *)view corners:(UIRectCorner)corners
{
    UIBezierPath *maskPath;
    maskPath = [UIBezierPath bezierPathWithRoundedRect:view.bounds
                                     byRoundingCorners: corners
                                           cornerRadii:CGSizeMake(self.roundCornerOffset, self.roundCornerOffset)];
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
    NSArray *items = self.reorderedButtons;
    
    self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self];
    self.animator.delegate = self;
    [self addCollisionOnItems:items animator:self.animator];
    [self addGravityOnItems:items magnitude:self.magnitude];
    
    for (int i = 0; i < self.buttons.count; i++) { // separate the buttons a bit by pushing them each a little differently
        UIButton *button = [items objectAtIndex:i];
        [self pushView:button vector:CGVectorMake(0, self.buttons.count - i)];
    }

    // Make 'em bounce
    UIDynamicItemBehavior *itemBehaviour    = [[UIDynamicItemBehavior alloc] initWithItems:items];
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
    CGRect bounds;
    if (self.popover)
         bounds = self.displayRect;
    else {
        bounds          = self.bounds;
        bounds.origin.y-= self.paddingBottom;
    }
    
    CGPoint topLeftCorner       = CGPointMake(CGRectGetMinX(bounds), CGRectGetMinY(bounds));
    CGPoint topRightCorner      = CGPointMake(CGRectGetMaxX(bounds), CGRectGetMinY(bounds));
    CGPoint bottomRightCorner   = CGPointMake(CGRectGetMaxX(bounds), CGRectGetMaxY(bounds));
    CGPoint bottomLeftCorner    = CGPointMake(CGRectGetMinX(bounds), CGRectGetMaxY(bounds));
    
    UICollisionBehavior *collision  = [[UICollisionBehavior alloc] initWithItems: items];
    [collision addBoundaryWithIdentifier:@"floor"
                               fromPoint: bottomLeftCorner 
                                 toPoint: bottomRightCorner];
    
    [collision addBoundaryWithIdentifier:@"leftside"
                               fromPoint: topLeftCorner
                                 toPoint: bottomLeftCorner];
    
    [collision addBoundaryWithIdentifier:@"rightside"
                               fromPoint: topRightCorner
                                 toPoint: bottomRightCorner];
    [animator addBehavior:collision];
}




#pragma mark - UIDynamicAnimatorDelegate

- (void)dynamicAnimatorWillResume:(UIDynamicAnimator*)animator
{
    
}

- (void)dynamicAnimatorDidPause:(UIDynamicAnimator*)animator
{
    if (self.isDismissing) return;
    CGRect prevRect;
    BOOL isCancelButton = NO;
    for (int i = 0; i < self.reorderedButtons.count; i++) {
        UIView *buttonContainer = self.reorderedButtons[i];
        if (buttonContainer.tag == MYSGravityActionSheetButtonTypeCancel)
            isCancelButton = YES;
        
        if (((isCancelButton && i > 1) || (!isCancelButton && i > 0))) {
            [buttonContainer setFrame: CGRectMake(prevRect.origin.x, prevRect.origin.y - buttonContainer.frame.size.height + self.buttonLineHeight, prevRect.size.width, buttonContainer.frame.size.height)];
        }
        prevRect = buttonContainer.frame;
    }
}

@end
