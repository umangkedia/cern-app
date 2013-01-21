//
//  BulletinIssueTableViewController.m
//  CERN
//
//  Created by Timur Pocheptsov on 1/21/13.
//  Copyright (c) 2013 CERN. All rights reserved.
//

#import "BulletinIssueTableViewController.h"
#import "NewsTableViewCell.h"
#import "MWFeedItem.h"

@implementation BulletinIssueTableViewController {
   BOOL loaded;
}

@synthesize tableData;

//________________________________________________________________________________________
- (void) setTableData : (NSArray *) aData
{
   tableData = aData;
   loaded = NO;
}

//________________________________________________________________________________________
- (id) initWithStyle : (UITableViewStyle) style
{
   return self = [super initWithStyle : style];
}

//________________________________________________________________________________________
- (void) viewDidLoad
{
   [super viewDidLoad];
}

//________________________________________________________________________________________
- (void) viewDidAppear : (BOOL) animated
{
   assert(tableData != nil && "viewDidAppear, tableData is nil");

   [super viewDidAppear : animated];

   if (!loaded) {
      [self.tableView reloadData];
      loaded = YES;
   }
}

//________________________________________________________________________________________
- (void) didReceiveMemoryWarning
{
   [super didReceiveMemoryWarning];
   // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

//________________________________________________________________________________________
- (NSInteger) numberOfSectionsInTableView : (UITableView *) tableView
{
   return 1;
}

//________________________________________________________________________________________
- (NSInteger) tableView : (UITableView *) tableView numberOfRowsInSection : (NSInteger) section
{
#pragma unused(tableView, section)
   if (tableData)
      return tableData.count;

   return 0;
}

//________________________________________________________________________________________
- (UITableViewCell *) tableView : (UITableView *) tableView cellForRowAtIndexPath : (NSIndexPath *) indexPath
{
   assert(indexPath != nil && "tableView:cellForRowAtIndexPath:, parameter 'indexPath' is nil");

   //Find feed item first.
   const NSInteger row = indexPath.row;
   assert(row >= 0 && row < tableData.count &&
          "tableView:cellForRowAtIndexPath:, index is out of bounds");

   MWFeedItem * const article = (MWFeedItem *)tableData[row];
   assert(article != nil && "tableView:cellForRowAtIndexPath:, article was not found");

   NewsTableViewCell *cell = (NewsTableViewCell *)[tableView dequeueReusableCellWithIdentifier : @"BulletinIssueCell"];
   if (!cell)
      cell = [[NewsTableViewCell alloc] initWithFrame : [NewsTableViewCell defaultCellFrame]];

   [cell setCellData : article imageOnTheRight : (indexPath.row % 4) == 3];

   return cell;
}

//________________________________________________________________________________________
- (CGFloat) tableView : (UITableView *) tableView heightForRowAtIndexPath : (NSIndexPath *) indexPath
{
#pragma unused(tableView)
   assert(indexPath != nil && "tableView:heightForRowAtIndexPath:, parameter 'indexPath' is nil");

   const NSInteger row = indexPath.row;
   assert(row >= 0 && row < tableData.count && "tableView:heightForRowAtIndexPath:, indexPath.row is out of bounds");

   MWFeedItem * const article = (MWFeedItem *)tableData[row];
   return [NewsTableViewCell calculateCellHeightForData : article imageOnTheRight : (indexPath.row % 4) == 3];
}

#pragma mark - Table view delegate

//________________________________________________________________________________________
- (void) tableView : (UITableView *) tableView didSelectRowAtIndexPath : (NSIndexPath *) indexPath
{
//
}

#pragma mark - Aux.

//________________________________________________________________________________________
- (void) reloadRowFor : (MWFeedItem *) article
{
   assert(article != nil && "reloadRowFor:, parameter 'article' is nil");
   assert(tableData.count && "reloadRowFor:, tableData is nil or is empty");

   const NSUInteger index = [tableData indexOfObject : article];
   assert(index != NSNotFound &&
          "reloadRowFor:, article is not found in a list of articles");

   const NSUInteger path[2] = {0, index};
   NSIndexPath * const indexPath = [NSIndexPath indexPathWithIndexes : path length : 2];
   [self.tableView reloadRowsAtIndexPaths : @[indexPath] withRowAnimation : UITableViewRowAnimationNone];
}

@end
