//
//  CreditsViewController.m
//  CERN
//
//  Created by Timur Pocheptsov on 2/15/13.
//  Copyright (c) 2013 CERN. All rights reserved.
//

#import "CreditsViewController.h"

@interface CreditsViewController ()

@end

@implementation CreditsViewController

//________________________________________________________________________________________
- (id) initWithNibName : (NSString *) nibNameOrNil bundle : (NSBundle *) nibBundleOrNil
{
   if (self = [super initWithNibName : nibNameOrNil bundle : nibBundleOrNil]) {
      // Custom initialization
   }

   return self;
}

//________________________________________________________________________________________
- (void)viewDidLoad
{
   [super viewDidLoad];
   //
}

//________________________________________________________________________________________
- (void)didReceiveMemoryWarning
{
   [super didReceiveMemoryWarning];
   //Dispose of any resources that can be recreated.
}

//________________________________________________________________________________________
- (IBAction) donePressed : (id) sender
{
   [self dismissViewControllerAnimated : YES completion : nil];
}

@end
