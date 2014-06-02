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

@end

@implementation MYSViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)changeBackgroundWasTapped:(id)sender
{
    MYSGravityActionSheet *actionSheet = [[MYSGravityActionSheet alloc] init];
    __weak UIViewController *bself = self;
    [actionSheet addButtonWithTitle: @"Red"    block: ^{ bself.view.backgroundColor = [UIColor redColor]; }];
    [actionSheet addButtonWithTitle: @"Orange" block: ^{ bself.view.backgroundColor = [UIColor orangeColor]; }];
    [actionSheet addButtonWithTitle: @"Yellow" block: ^{ bself.view.backgroundColor = [UIColor yellowColor]; }];
    [actionSheet addButtonWithTitle: @"Green"  block: ^{ bself.view.backgroundColor = [UIColor greenColor]; }];
    [actionSheet addButtonWithTitle: @"Blue"   block: ^{ bself.view.backgroundColor = [UIColor blueColor]; }];
    [actionSheet addButtonWithTitle: @"Purple" block: ^{ bself.view.backgroundColor = [UIColor purpleColor]; }];
    [actionSheet addButtonWithTitle: @"Cancel" block: nil];
    
    [actionSheet showInView:self.view];
    
}
@end
