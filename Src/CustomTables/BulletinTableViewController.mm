//
//  BulletinTableViewController.m
//  CERN
//
//  Created by Timur Pocheptsov on 1/17/13.
//  Copyright (c) 2013 CERN. All rights reserved.
//

#import "BulletinTableViewController.h"

@interface BulletinTableViewController ()

@end

@implementation BulletinTableViewController

//________________________________________________________________________________________
- (id) initWithNibName : (NSString *) nibNameOrNil bundle : (NSBundle *) nibBundleOrNil
{
   if (self = [super initWithNibName : nibNameOrNil bundle : nibBundleOrNil]) {
   }

   return self;
}

//________________________________________________________________________________________
- (void) viewDidLoad
{
   [super viewDidLoad];
	//Do any additional setup after loading the view.
}

//________________________________________________________________________________________
- (void) didReceiveMemoryWarning
{
   [super didReceiveMemoryWarning];
   //Dispose of any resources that can be recreated.
}

//________________________________________________________________________________________
- (void) reloadPage
{
   NSLog(@"reload page!");
}

@end
