//
//  BulletinGridViewController.m
//  CERN App
//
//  Created by Eamon Ford on 8/9/12.
//  Copyright (c) 2012 CERN. All rights reserved.
//

//Modified by Timur Pocheptsov.

#import "NSDate+LastOccurrenceOfWeekday.h"
#import "BulletinGridViewController.h"
#import "NewsTableViewController.h"
#import "NewsGridViewController.h"
#import "BulletinGridViewCell.h"
#import "GuiAdjustment.h"
#import "DeviceCheck.h"

@implementation BulletinGridViewController

//________________________________________________________________________________________
- (id) initWithCoder : (NSCoder *) aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        self.gridView.resizesCellWidthToFit = NO;
        self.gridView.backgroundColor = [UIColor whiteColor];
        self.gridView.allowsSelection = YES;
    }
    return self;
}

//________________________________________________________________________________________
- (void) viewDidLoad
{
   [super viewDidLoad];
   // Do any additional setup after loading the view.
}

//________________________________________________________________________________________
- (void) viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

//________________________________________________________________________________________
- (BOOL) shouldAutorotateToInterfaceOrientation : (UIInterfaceOrientation) interfaceOrientation
{
     if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        return YES;
     else
         return (interfaceOrientation == UIInterfaceOrientationPortrait);

}

//________________________________________________________________________________________
- (NSArray *) calculateRangesOfArticlesSeparatedByWeek : (NSArray *) articles
{
   assert(articles != nil && "calculateRangesOfArticlesSeparatedByWeek:, articles parameter is nil");
   
   //TP: I had to replace this function completely.

   NSMutableArray *issues = [NSMutableArray array];

   if (![articles count])
      return issues;

   NSRange currentRange = NSMakeRange(0, 0);

   MWFeedItem *firstArticle = [articles objectAtIndex : 0];
   
   NSCalendar * const calendar = [NSCalendar currentCalendar];
   const NSUInteger requiredComponents = NSWeekCalendarUnit | NSYearCalendarUnit;

   NSDateComponents *dateComponents = [calendar components : requiredComponents fromDate : firstArticle.date];
   NSInteger currentWeek = dateComponents.week;
   NSInteger currentYear = dateComponents.year;
   currentRange.length = 1;//we already have at least one.
   
   for (int i = 1; i < articles.count; i++) {
      MWFeedItem * const article = [articles objectAtIndex : i];
      
      dateComponents = [calendar components : requiredComponents fromDate : article.date];

      if (dateComponents.year != currentYear || dateComponents.week != currentWeek) {
         [issues addObject : [NSValue valueWithRange : currentRange]];
         
         currentRange.location = i;
         currentRange.length = 1;
         currentWeek = dateComponents.week;
         currentYear = dateComponents.year;
      } else
         currentRange.length++;
   }

   [issues addObject : [NSValue valueWithRange : currentRange]];

   return issues;
}

//________________________________________________________________________________________
- (NSString *) issueTitleForRange : (NSRange) issueRange dateFormatterStyle : (NSDateFormatterStyle) style
{
   //TP: return a string == the name of the bulletin issue, corresponding to the articleIndex.
   assert(issueRange.length > 0 && "issueTitleForArticle:, parameter issueRange is an empty range");

   //Set the title for a bulletin - "Week " + date of the week beginning day for this article.
   MWFeedItem * const latestArticle = [self.aggregator.allArticles objectAtIndex : issueRange.location + issueRange.length - 1];

   //Formatter to create a string representation.
   NSDateFormatter * const dateFormatter = [[NSDateFormatter alloc] init];
   dateFormatter.dateStyle = style;

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

//________________________________________________________________________________________
-(void) prepareForSegue : (UIStoryboardSegue *) segue sender : (id) sender
{
   if ([DeviceCheck deviceIsiPad]) {
      NewsGridViewController * const viewController = [segue destinationViewController];
      
      NSUInteger issueIndex = [self.gridView indexOfSelectedItem];
      viewController.aggregator = self.aggregator;
      viewController.aggregator.delegate = viewController;
       
      NSRange issueRange = [[self.rangesOfArticlesSeparatedByWeek objectAtIndex : issueIndex] rangeValue];
      viewController.rangeOfArticlesToShow = issueRange;
      [viewController.gridView reloadData];

      //TP: change issue naming.
      viewController.title = [self issueTitleForRange : issueRange dateFormatterStyle : NSDateFormatterShortStyle];
   } else {
      //Ugly code duplication for the moment - different controllers for iPad/iPhone devices.
      NewsTableViewController * const viewController = [segue destinationViewController];      
//#ifndef __IPHONE_6_0
      viewController.shouldRefresh = NO;
//#endif
      NSUInteger issueIndex = [self.gridView indexOfSelectedItem];
      viewController.aggregator = self.aggregator;
      viewController.aggregator.delegate = viewController;
       
      NSRange issueRange = [[self.rangesOfArticlesSeparatedByWeek objectAtIndex : issueIndex] rangeValue];
      viewController.rangeOfArticlesToShow = issueRange;
      //[(UITableView *)viewController.view reloadData];

      //TP: change issue naming.
      viewController.title = [self issueTitleForRange : issueRange dateFormatterStyle : NSDateFormatterShortStyle];
      
      //
      CernAPP::ResetBackButton(viewController, @"back_button_flat.png");
      //
   }

   [self.gridView deselectItemAtIndex : self.gridView.indexOfSelectedItem animated : YES];
}


#pragma mark - AQGridView methods

//________________________________________________________________________________________
- (NSUInteger) numberOfItemsInGridView: (AQGridView *) gridView
{
    return self.rangesOfArticlesSeparatedByWeek.count;
}

//________________________________________________________________________________________
- (AQGridViewCell *) gridView : (AQGridView *) gridView cellForItemAtIndex : (NSUInteger) index
{
   //TP: I had to replace this function completely.
   
   static NSString *bulletinCellIdentifier = @"bulletinCell";

   BulletinGridViewCell *cell = (BulletinGridViewCell *)[self.gridView dequeueReusableCellWithIdentifier:bulletinCellIdentifier];
   if (!cell) {
      cell = [[BulletinGridViewCell alloc] initWithFrame : CGRectMake(0.0, 0.0, 300.0, 120.0) reuseIdentifier : bulletinCellIdentifier];
      cell.selectionStyle = AQGridViewCellSelectionStyleGlow;
   }
 
   const NSRange issueRange = [[self.rangesOfArticlesSeparatedByWeek objectAtIndex : index] rangeValue];
   assert(issueRange.length > 0 && "gridView:cellForItemAtIndex:, issue range for artice is empty");

   //As a title for a cell set "Week " + first day of this week.
   cell.titleLabel.text = [self issueTitleForRange : issueRange dateFormatterStyle : NSDateFormatterMediumStyle];

   //Show the number of articles in this issue.
   NSMutableString * const articlesString = [NSMutableString stringWithFormat : @"%d ", issueRange.length];
   [articlesString appendString : issueRange.length > 1 ? @"articles" : @"article"];
   cell.descriptionLabel.text = articlesString;

   return cell;
}

//________________________________________________________________________________________
- (CGSize) portraitGridCellSizeForGridView : (AQGridView *) aGridView
{
   return CGSizeMake(320.0, 140.0);
}

//________________________________________________________________________________________
- (void) gridView : (AQGridView *) gridView didSelectItemAtIndex : (NSUInteger) index numFingersTouch : (NSUInteger) numFingers
{
   [self performSegueWithIdentifier : @"ShowBulletinArticles" sender : self];
}

#pragma mark - RSSAggregatorDelegate methods

//________________________________________________________________________________________
- (void) allFeedsDidLoadForAggregator : (RSSAggregator *) sender
{
   [super allFeedsDidLoadForAggregator : sender];
   self.rangesOfArticlesSeparatedByWeek = [self calculateRangesOfArticlesSeparatedByWeek : self.aggregator.allArticles];
   [self.gridView reloadData];
}

@end
