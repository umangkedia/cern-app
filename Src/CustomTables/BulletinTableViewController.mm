//
//  BulletinTableViewController.m
//  CERN
//
//  Created by Timur Pocheptsov on 1/17/13.
//  Copyright (c) 2013 CERN. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "BulletinIssueTableViewController.h"
#import "BulletinTableViewController.h"
#import "StoryboardIdentifiers.h"
#import "NewsTableViewCell.h"
#import "BulletinViewCell.h"
#import "GUIHelpers.h"

@implementation BulletinTableViewController {
   NSMutableArray *bulletins;
   NSMutableDictionary *thumbnails;

   BulletinIssueTableViewController *activeIssueController;
}

//________________________________________________________________________________________
- (id) initWithCoder : (NSCoder *) aDecoder
{
   return self = [super initWithCoder : aDecoder];
}

//________________________________________________________________________________________
- (void) viewDidLoad
{
   [super viewDidLoad];
	//Do any additional setup after loading the view.
}

//________________________________________________________________________________________
- (void) viewDidAppear : (BOOL) animated
{
   [super viewDidAppear : animated];
   activeIssueController = nil;
}

//________________________________________________________________________________________
- (void) didReceiveMemoryWarning
{
   [super didReceiveMemoryWarning];
   //Dispose of any resources that can be recreated.
}

#pragma mark - Aux. functions.

//________________________________________________________________________________________
- (NSString *) titleForIssue : (NSUInteger) index
{
   assert(index < bulletins.count && "titleForIssue:, parameter 'index' is out of bounds");

   NSArray * const articles = (NSArray *)bulletins[index];
   assert(articles.count != 0 && "titleForIssue:, not articles found");

   //Set the title for a bulletin - "Week " + date of the week beginning day for this article.
   MWFeedItem * const latestArticle = (MWFeedItem *)articles[articles.count - 1];

   //Formatter to create a string representation.
   NSDateFormatter * const dateFormatter = [[NSDateFormatter alloc] init];
   dateFormatter.dateStyle = NSDateFormatterMediumStyle;

   //Weekday of the article's date
   NSDateComponents * const dateComponents = [[NSCalendar currentCalendar] components : NSWeekdayCalendarUnit fromDate : latestArticle.date];

   NSString *issueDateString = nil;
   if (dateComponents.weekday > 1) {
      NSDate * const firstDay = [latestArticle.date dateByAddingTimeInterval : -(dateComponents.weekday - 1) * 24 * 60 * 60];
      issueDateString = [dateFormatter stringFromDate:firstDay];
   } else {
      issueDateString = [dateFormatter stringFromDate : latestArticle.date];
   }
   
   return [NSString stringWithFormat : @"Week %@", issueDateString];
}


#pragma mark - UITableViewDataSource.

//________________________________________________________________________________________
- (NSInteger) numberOfSectionsInTableView : (UITableView *) tableView
{
#pragma unused(tableView)
   //Table has only one section.
   return 1;
}

//________________________________________________________________________________________
- (NSInteger) tableView : (UITableView *) tableView numberOfRowsInSection : (NSInteger) section
{
#pragma unused(tableView)
   // Return the number of rows in the section.
   return bulletins.count;
}

//________________________________________________________________________________________
- (UITableViewCell *) tableView : (UITableView *) tableView cellForRowAtIndexPath : (NSIndexPath *) indexPath
{
   assert(tableView != nil && "tableView:cellForRowAtIndexPath:, parameter 'tableView' is nil");
   assert(indexPath != nil && "tableView:cellForRowAtIndexPath:, parameter 'indexPath' is nil");

   const NSInteger row = indexPath.row;
   assert(row >= 0 && row < bulletins.count && "tableView:cellForRowAtIndexPath:, index is out of bounds");

   UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier : @"BulletinCell"];
   assert(!cell || [cell isKindOfClass : [NewsTableViewCell class]] &&
          "tableView:cellForRowAtIndexPath:, reusable cell has a wrong type");

   if (!cell)
      cell = [[NewsTableViewCell alloc] initWithFrame : [NewsTableViewCell defaultCellFrame]];

   if (![cell.selectedBackgroundView isKindOfClass : [BackgroundView class]]) {   
      BackgroundView * const sbv = [[BackgroundView alloc] initWithFrame:CGRect()];
      cell.backgroundView = sbv;
   }

   NewsTableViewCell * const newsCell = (NewsTableViewCell *)cell;
   UIImage * const image = [thumbnails objectForKey : indexPath];
   [newsCell setTitle : [self titleForIssue : row] image : image];

   if (!image)
      [self startIconDownloadForIndexPath : indexPath];

   return cell;
}

//________________________________________________________________________________________
- (CGFloat) tableView : (UITableView *) tableView heightForRowAtIndexPath : (NSIndexPath *) indexPath
{
#pragma unused(tableView)

   assert(indexPath != nil && "tableView:heightForRowAtIndexPath:, parameter 'indexPath' is nil");

   const NSInteger row = indexPath.row;
   assert(row >= 0 && row < bulletins.count && "tableView:heightForRowAtIndexPath:, index is out of bounds");

   UIImage * const image = [thumbnails objectForKey : [NSNumber numberWithInteger : row]];
   return [NewsTableViewCell calculateCellHeightWithText : [self titleForIssue : row] image : image];
}

#pragma mark - RSSAggregatorDelegate methods

//________________________________________________________________________________________
- (void) allFeedsDidLoadForAggregator : (RSSAggregator *) theAggregator
{
   assert(theAggregator != nil && "allFeedsDidLoadForAggregator:, parameter 'theAggregator' is nil");

   [spinner stopAnimating];
   [spinner setHidden : YES];
   [self.refreshControl endRefreshing];

   //
   //Split articles into groups using week number.
   //
   if (theAggregator.allArticles.count) {
      bulletins = [[NSMutableArray alloc] init];
      thumbnails = [[NSMutableDictionary alloc] init];
   
      NSArray * const articles = theAggregator.allArticles;//They are sorted by date (by an aggregator).
   
      NSMutableArray *weekData = [[NSMutableArray alloc] init];
      MWFeedItem * const firstArticle = [articles objectAtIndex : 0];
      firstArticle.subsetIndex = 0;
      [weekData addObject : firstArticle];
   
      NSCalendar * const calendar = [NSCalendar currentCalendar];
      const NSUInteger requiredComponents = NSWeekCalendarUnit | NSYearCalendarUnit;

      NSDateComponents *dateComponents = [calendar components : requiredComponents fromDate : firstArticle.date];
      NSInteger currentWeek = dateComponents.week;
      NSInteger currentYear = dateComponents.year;
   
      for (NSUInteger i = 1, e = articles.count; i < e; ++i) {
         MWFeedItem * const article = (MWFeedItem *)articles[i];
         dateComponents = [calendar components : requiredComponents fromDate : article.date];

         if (dateComponents.year != currentYear || dateComponents.week != currentWeek) {
            [bulletins addObject : weekData];
            currentWeek = dateComponents.week;
            currentYear = dateComponents.year;
            weekData = [[NSMutableArray alloc] init];
         }
         
         article.subsetIndex = bulletins.count;
         [weekData addObject : article];
      }
      
      [bulletins addObject : weekData];
      
      [self.tableView reloadData];
   }

   self.pageLoaded = YES;
}

//________________________________________________________________________________________
- (void) aggregator : (RSSAggregator *) aggregator didFailWithError : (NSString *) error
{
   [MBProgressHUD hideAllHUDsForView : self.view animated : NO];
   noConnectionHUD = [MBProgressHUD showHUDAddedTo : self.view animated : NO];

   noConnectionHUD.mode = MBProgressHUDModeText;
   if (error)
      noConnectionHUD.labelText = error;
   else
      noConnectionHUD.labelText = @"Load error";
   noConnectionHUD.removeFromSuperViewOnHide = YES;
   
   [spinner stopAnimating];
   [spinner setHidden : YES];
   [self.refreshControl  endRefreshing];
   self.pageLoaded = NO;
}

#pragma mark - Table view delegate

//________________________________________________________________________________________
- (void) tableView : (UITableView *) tableView didSelectRowAtIndexPath : (NSIndexPath *) indexPath
{
   assert(tableView != nil && "tableView:didSelectRowAtIndexPath:, parameter 'tableView' is nil");
   assert(indexPath != nil && "tableView:didSelectRowAtIndexPath, parameter 'indexPath' is nil");
   assert(indexPath.row >= 0 && indexPath.row < bulletins.count &&
          "tableView:didSelectRowAtIndexPath, row index is out of bounds");

   if (self.navigationController) {
      UIStoryboard * const mainStoryboard = [UIStoryboard storyboardWithName : @"iPhone" bundle : nil];
      BulletinIssueTableViewController * const vc = [mainStoryboard instantiateViewControllerWithIdentifier : CernAPP::BulletinIssueTableControllerID];
      vc.tableData = bulletins[indexPath.row];
      vc.prevController = self;
      [self.navigationController pushViewController : vc animated : YES];
      activeIssueController = vc;
   }

   [tableView deselectRowAtIndexPath : indexPath animated : NO];
}

#pragma mark - Thumbnails.


//________________________________________________________________________________________
- (void) startIconDownloadForIndexPath : (NSIndexPath *) indexPath
{
   assert(indexPath != nil && "startIconDownloadForIndexPath:, parameter 'indexPath' is nil");
   const NSInteger row = indexPath.row;
   assert(row >= 0 && row < bulletins.count &&
          "startIconDownloadForIndexPath:, index is out of bounds");

   if (!self.imageDownloaders)
      self.imageDownloaders = [[NSMutableDictionary alloc] init];

   ImageDownloader * downloader = (ImageDownloader *)self.imageDownloaders[indexPath];
   if (!downloader) {//We did not start download for this image yet.
      NSArray * const articles = (NSArray *)bulletins[indexPath.row];
      assert(articles.count > 0 && "startIconDownloadForIndexPath, no articles for issue found");
      MWFeedItem * const article = (MWFeedItem *)articles[0];//select the first one.
      assert(article.image == nil && "startIconDownloadForIndexPath:, image was loaded already");
      
      NSString * body = article.content;
      if (!body)
         body = article.summary;
      
      if (body) {
         if (NSString * const urlString = [NewsTableViewController firstImageURLFromHTMLString : body]) {
            downloader = [[ImageDownloader alloc] initWithURLString : urlString];
            downloader.indexPathInTableView = indexPath;
            downloader.delegate = self;
            [self.imageDownloaders setObject : downloader forKey : indexPath];
            [downloader startDownload];//Power on.
         }
      }
   }
}

// This method is used in case the user scrolled into a set of cells that don't have their thumbnails yet.

//________________________________________________________________________________________
- (void) loadImagesForOnscreenRows
{
   if (bulletins.count && self.nLoadedImages != bulletins.count) {
      NSArray * const visiblePaths = [self.tableView indexPathsForVisibleRows];
      for (NSIndexPath *indexPath in visiblePaths) {
         if (!thumbnails[indexPath])
            [self startIconDownloadForIndexPath : indexPath];
      }
   }
}

//________________________________________________________________________________________
- (void) imageDidLoad : (NSIndexPath *) indexPath
{
   //
   assert(indexPath != nil && "imageDidLoad, parameter 'indexPath' is nil");
   const NSInteger row = indexPath.row;
   assert(row >= 0 && row < bulletins.count && "imageDidLoad:, index is out of bounds");
   
   //We should not load any image more when once.
   assert(thumbnails[indexPath] == nil && "imageDidLoad:, image was loaded already");
   
   ImageDownloader * const downloader = (ImageDownloader *)self.imageDownloaders[indexPath];
   assert(downloader != nil && "imageDidLoad:, no downloader found for the given index path");
   
   if (downloader.image) {
      [thumbnails setObject : downloader.image forKey : indexPath];
      [self.tableView reloadRowsAtIndexPaths : @[indexPath] withRowAnimation : UITableViewRowAnimationNone];
   }
   
   ++self.nLoadedImages;
   [self.imageDownloaders removeObjectForKey : indexPath];
}


@end
