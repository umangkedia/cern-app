//
//  StaticInfoTableViewController.m
//  CERN
//
//  Created by Timur Pocheptsov on 1/10/13.
//  Copyright (c) 2013 CERN. All rights reserved.
//

#import "StaticInfoTableViewController.h"
#import "ECSlidingViewController.h"
#import "MenuViewCell.h"
#import "GUIHelpers.h"

@implementation StaticInfoTableViewController

@synthesize staticInfo;

//________________________________________________________________________________________
- (id) initWithStyle : (UITableViewStyle) style
{
   return self = [super initWithStyle : style];
}

//________________________________________________________________________________________
- (void) viewDidLoad
{
   [super viewDidLoad];

   using CernAPP::menuBackgroundColor;
   using CernAPP::menuTableRgbShift;

   self.tableView.backgroundColor = [UIColor colorWithRed : menuBackgroundColor[0] + menuTableRgbShift green : menuBackgroundColor[1] + menuTableRgbShift
                                             blue : menuBackgroundColor[2] + menuTableRgbShift alpha : 1.f];
   self.tableView.separatorColor = [UIColor clearColor];

}

//________________________________________________________________________________________
- (void)didReceiveMemoryWarning
{
   [super didReceiveMemoryWarning];
   // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

//________________________________________________________________________________________
- (NSInteger) numberOfSectionsInTableView : (UITableView *) tableView
{
#pragma unused(tableView)
   return 1;
}

//________________________________________________________________________________________
- (NSInteger) tableView : (UITableView *) tableView numberOfRowsInSection : (NSInteger) section
{
#pragma unused(tableView, section)

   return staticInfo.count;
}

//________________________________________________________________________________________
- (UITableViewCell *) tableView : (UITableView *) tableView cellForRowAtIndexPath : (NSIndexPath *) indexPath
{
#pragma unused(tableView)

   assert(indexPath != nil && "tableView:cellForRowAtIndexPath:, parameter 'indexPath' is nil");
   assert(indexPath.row >= 0 && indexPath.row < staticInfo.count &&
          "tableView:cellForRowAtIndexPath:, index is out of bounds");

   NSString * const cellIdentifier = @"MenuCell";
   UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier : cellIdentifier forIndexPath : indexPath];
   assert(!cell || [cell isKindOfClass : [MenuViewCell class]] &&
          "tableView:cellForRowAtIndexPath:, reusable cell has a wrong type - MenuViewCell expected");
   
   cell.textLabel.backgroundColor = [UIColor clearColor];
   //
   cell.textLabel.text = @"LALA";
   
   return cell;
}

#pragma mark - Table view delegate

//________________________________________________________________________________________
- (void) tableView : (UITableView *) tableView didSelectRowAtIndexPath : (NSIndexPath *) indexPath
{
   //We have to load a scroll view now.
}

//________________________________________________________________________________________
- (void) tableView : (UITableView *) aTableView willDisplayCell : (UITableViewCell *) cell
         forRowAtIndexPath : (NSIndexPath *) indexPath
{
#pragma unused(aTableView, indexPath)

   using CernAPP::childMenuFontName;
   using CernAPP::childTextColor;

   cell.textLabel.textColor = [UIColor colorWithRed : childTextColor[0] green : childTextColor[1] blue : childTextColor[2] alpha : 1.f];
   cell.textLabel.font = [UIFont fontWithName : childMenuFontName size : 14.f];
}

#pragma mark - Sliding menu.

//________________________________________________________________________________________
- (IBAction) revealMenu : (id) sender
{
#pragma unused(sender)
   [self.slidingViewController anchorTopViewTo : ECRight];
}

@end
