//
//  BulletinTableViewController.m
//  CERN
//
//  Created by Timur Pocheptsov on 1/17/13.
//  Copyright (c) 2013 CERN. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "BulletinTableViewController.h"
#import "BulletinViewCell.h"
#import "GUIHelpers.h"

const CGFloat rowHeight = 100.f;

@implementation BulletinTableViewController {
   NSMutableArray *bulletins;
}

//________________________________________________________________________________________
- (id) initWithCoder : (NSCoder *) aDecoder
{
   if (self = [super initWithCoder : aDecoder]) {
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
- (void) tableView : (UITableView *) tableView willDisplayCell : (UITableViewCell *)cell forRowAtIndexPath : (NSIndexPath *) indexPath
{
//   cell.backgroundColor = [UIColor whiteColor];

   cell.layer.cornerRadius = 10.f;
   cell.layer.borderWidth = 1.f;
   cell.layer.borderColor = [UIColor colorWithRed : 209.f / 255 green : 215.f / 255 blue : 227.f / 255 alpha : 1.f].CGColor;

   cell.layer.shadowColor = [UIColor blackColor].CGColor;
   cell.layer.shadowOffset = CGSizeMake(1.f, 1.f);
   cell.layer.shadowOpacity = 0.5f;
   
   CGRect frame(cell.frame);
   frame.origin = CGPoint();
   cell.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect : frame cornerRadius : 10.f].CGPath;
   
   assert([cell isKindOfClass : [BulletinViewCell class]] &&
          "tableView:willDisplayCell:forRowAtIndexPath:, cell has a wrong type");
   
   BulletinViewCell * const bc = (BulletinViewCell *)cell;
   
   CGRect labelFrame(bc.cellLabel.frame);
   labelFrame.origin.y = frame.size.height / 2 - labelFrame.size.height / 2;
   
   bc.cellLabel.frame = labelFrame;
}

//- (void) ta

//________________________________________________________________________________________
- (UITableViewCell *) tableView : (UITableView *) tableView cellForRowAtIndexPath : (NSIndexPath *) indexPath
{
   assert(tableView != nil && "tableView:cellForRowAtIndexPath:, parameter 'tableView' is nil");
   assert(indexPath != nil && "tableView:cellForRowAtIndexPath:, parameter 'indexPath' is nil");

   const NSInteger row = indexPath.row;
   assert(row >= 0 && row < bulletins.count && "tableView:cellForRowAtIndexPath:, index is out of bounds");

   UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier : @"BulletinCell"];
   assert(!cell || [cell isKindOfClass : [BulletinViewCell class]] &&
          "tableView:cellForRowAtIndexPath:, reusable cell has a wrong type");

   if (!cell)
      cell = [[BulletinViewCell alloc] initWithFrame : CGRectMake(0, 0, self.tableView.frame.size.width, rowHeight)];

   if (![cell.selectedBackgroundView isKindOfClass : [BackgroundView class]]) {
      BackgroundView * const sbv = [[BackgroundView alloc] initWithFrame:CGRect()];
      sbv.selectedView = YES;
      cell.selectedBackgroundView = sbv;
      cell.selectedBackgroundView.backgroundColor = [UIColor clearColor];
      
      BackgroundView * const bv = [[BackgroundView alloc] initWithFrame : CGRect()];
      bv.selectedView = NO;
      cell.backgroundView = bv;
      bv.backgroundColor = [UIColor clearColor];
   }

   BulletinViewCell * const newsCell = (BulletinViewCell *)cell;
   newsCell.cellLabel.text = [self titleForIssue : row];
   
   UIFont * const font = [UIFont fontWithName : CernAPP::groupMenuFontName size : 18.f];
   assert(font != nil && "tableView:cellForRowAtIndexPath:, failed to create a font");
   
   cell.backgroundColor = [UIColor clearColor];
   
   newsCell.cellLabel.font = font;

   return cell;
}

//________________________________________________________________________________________
- (CGFloat) tableView : (UITableView *) tableView heightForRowAtIndexPath : (NSIndexPath *) indexPath
{
#pragma unused(tableView)

   assert(indexPath != nil && "tableView:heightForRowAtIndexPath:, parameter 'indexPath' is nil");

   const NSInteger row = indexPath.row;
   assert(row >= 0 && row < bulletins.count && "tableView:heightForRowAtIndexPath:, index is out of bounds");

   return rowHeight;
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

//________________________________________________________________________________________
- (void) aggregator : (RSSAggregator *) rssAggregator didDownloadFirstImage : (UIImage *) image forArticle : (MWFeedItem *) article
{
#pragma unused(rssAggregator, image)

//   const NSUInteger index = [allArticles indexOfObject : article];

//   assert(index != NSNotFound &&
//          "aggregator:didDownloadFirstImage:forArticle:, article is not found in a list of articles");

  // const NSUInteger path[2] = {0, index};
  // NSIndexPath * const indexPath = [NSIndexPath indexPathWithIndexes : path length : 2];
  // [self.tableView reloadRowsAtIndexPaths : @[indexPath] withRowAnimation : UITableViewRowAnimationNone];
  //We have to check, if any week is loaded now and inform the corresponding child controller.
}


#pragma mark - Table view delegate

//________________________________________________________________________________________
- (void) tableView : (UITableView *) tableView didSelectRowAtIndexPath : (NSIndexPath *) indexPath
{
   assert(indexPath != nil && "tableView:didSelectRowAtIndexPath, index path for selected table's row is nil");

   /*
   if (self.navigationController && !self.aggregator.isLoadingData) {
      if (aggregator.hasConnection) {
         UIStoryboard * const mainStoryboard = [UIStoryboard storyboardWithName : @"iPhone" bundle : nil];

         ArticleDetailViewController *viewController = [mainStoryboard instantiateViewControllerWithIdentifier : CernAPP::ArticleDetailViewControllerID];
         viewController.loadOriginalLink = YES;
         const NSUInteger index = indexPath.row;
         [viewController setContentForArticle : [allArticles objectAtIndex : index]];
         
         [self.navigationController pushViewController : viewController animated : YES];
      } else {
         CernAPP::ShowErrorAlert(@"Please, check network!", @"Close");
      }
   }*/
   
   [tableView deselectRowAtIndexPath : indexPath animated : NO];
}

@end
