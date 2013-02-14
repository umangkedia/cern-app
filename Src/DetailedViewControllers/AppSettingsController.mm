//
//  AppSettingsController.m
//  CERN
//
//  Created by Timur Pocheptsov on 2/14/13.
//  Copyright (c) 2013 CERN. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "ECSlidingViewController.h"
#import "AppSettingsController.h"

@implementation AppSettingsController

//________________________________________________________________________________________
- (id) initWithNibName : (NSString *) nibNameOrNil bundle : (NSBundle *) nibBundleOrNil
{
   if (self = [super initWithNibName : nibNameOrNil bundle : nibBundleOrNil]) {
      //Add observer.
   }

   return self;
}

//________________________________________________________________________________________
- (void) dealloc
{
   //Remove observer.
}

//________________________________________________________________________________________
- (void) viewDidLoad
{
   [super viewDidLoad];
	// Do any additional setup after loading the view.
   //set group views.
   guiSettingsView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent : 0.5f];
   guiSettingsView.layer.cornerRadius = 10.f;
   
   rdbSettingsView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent : 0.5f];
   rdbSettingsView.layer.cornerRadius = 10.f;
}

//________________________________________________________________________________________
- (void) didReceiveMemoryWarning
{
   [super didReceiveMemoryWarning];
   // Dispose of any resources that can be recreated.
}

//________________________________________________________________________________________
- (IBAction) revealMenu : (id) sender
{
#pragma unused(sender)
   [self.slidingViewController anchorTopViewTo : ECRight];
}

@end
