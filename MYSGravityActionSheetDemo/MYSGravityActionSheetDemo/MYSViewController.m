//
//  MYSViewController.m
//  MYSGravityActionSheetDemo
//
//  Created by Dan Willoughby on 6/2/14.
//  Copyright (c) 2014 Mysterious Trousers. All rights reserved.
//

#import "MYSViewController.h"
#import "MYSGravityActionSheet.h"

@interface MYSViewController ()
@property (weak, nonatomic) IBOutlet UIButton *changeBackgroundButton;
@property (nonatomic, strong)  MYSGravityActionSheet *actionSheet;


@end

@implementation MYSViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.actionSheet = [[MYSGravityActionSheet alloc] init];
    __weak UIViewController *bself = self;
    [self.actionSheet setDestructiveButtonWithTitle: @"Red"    block: ^{ bself.view.backgroundColor = [UIColor redColor]; }];
    [self.actionSheet addButtonWithTitle: @"Orange" block: ^{ bself.view.backgroundColor = [UIColor orangeColor]; }];
    [self.actionSheet addButtonWithTitle: @"Yellow" block: ^{ bself.view.backgroundColor = [UIColor yellowColor]; }];
    [self.actionSheet addButtonWithTitle: @"Green"  block: ^{ bself.view.backgroundColor = [UIColor greenColor]; }];
    [self.actionSheet addButtonWithTitle: @"Blue"   block: ^{ bself.view.backgroundColor = [UIColor blueColor]; }];
    [self.actionSheet addButtonWithTitle: @"Purple" block: ^{ bself.view.backgroundColor = [UIColor purpleColor]; }];
    [self.actionSheet setCancelButtonWithTitle:@"Cancel" block:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)changeBackgroundWasTapped:(UIButton *)sender
{
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ) {
        [self.actionSheet showFromView:sender inView:self.view animated:YES];
    }
    else {
        [self.actionSheet showInView:self.view];
    }
}

- (IBAction)barButtonWasTapped:(UIBarButtonItem *)sender
{
    [self.actionSheet showFromBarButtonItem:sender inView:self.view animated:YES];
    
    
}
@end
