//
//  MTBookFallActionSheet.h
//  DynamicsPlayground
//
//  Created by Dan Willoughby on 5/30/14.
//  Copyright (c) 2014 Willoughby. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MYSGravityActionSheet : UIView

@property (nonatomic, assign, getter = isVisible) BOOL visible;

- (void)dismiss;
- (void)showInView:(UIView *)view;
// iPad
- (void)showFromView:(UIView *)fromView inView:(UIView *)inView animated:(BOOL)animated;
- (void)showFromBarButtonItem:(UIBarButtonItem *)item animated:(BOOL)animated;


- (void)addButtonWithTitle:(NSString *)title block:(void (^)(void))block;

// Adds a cancel button. Use only once.
- (void)setCancelButtonWithTitle:(NSString *)title block:(void (^)(void))block;

/// Adds a destructive button. Use only once.
- (void)setDestructiveButtonWithTitle:(NSString *)title block:(void (^)(void))block;


/*
/// Add regular button.

/// @name Properties and show/destroy

/// Count the buttons.
- (NSUInteger)buttonCount;

/// Is clever about the sender, uses fallbackView if sender is not usable (nil, or not `UIBarButtonItem`/`UIView`)
- (void)showWithSender:(id)sender fallbackView:(UIView *)view animated:(BOOL)animated;

/// A `UIActionSheet` can always be cancelled, even if no cancel button is present.
/// Use `allowsTapToDismiss` to block cancellation on tap. The control might still be cancelled from OS events.
- (void)addCancelBlock:(void (^)(NSInteger buttonIndex))cancelBlock;

/// Add block that is called after the sheet will be dismissed (before animation).
/// @note In difference to the action sheet, this is called BEFORE any of the block-based button actions are called.
- (void)addWillDismissBlock:(void (^)(NSInteger buttonIndex))willDismissBlock;

/// Add block that is called after the sheet has been dismissed (after animation).
- (void)addDidDismissBlock:(void (^)(NSInteger buttonIndex))didDismissBlock;

/// Allows to be dismissed by tapping outside? Defaults to YES (UIActionSheet default)
@property (nonatomic, assign) BOOL allowsTapToDismiss;
 
 */
@end
