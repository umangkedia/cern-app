//Author: Timur Pocheptsov.
//Developed for CERN app.

//This is a code for a table view controller, which shows author, title, short content, date for
//an every news item.
//It can be used ONLY for iPhone/iPod touch device, for iPad we'll have different approach.

#import <cassert>

#import "ArticleDetailViewController.h"
#import "NewsTableViewController.h"
#import "StoryboardIdentifiers.h"
#import "NewsTableViewCell.h"
#import "Constants.h"

@implementation NewsTableViewController {
   //I need a stupid hack - table view shows ugly empty rows,
   //when data is not loaded yet. Before I was using empty footers,
   //but they lead to stupid crashes with UIRefreshController
   //(and it looks like a bug in UIKit). So now I simply set the separator's color:
   //when no data present, it's a clear color, when we have at least one row with data -
   //it's a gray color.
   BOOL resetColor;
}

@synthesize rangeOfArticlesToShow, pageLoaded, navigationControllerForArticle;

#ifdef __IPHONE_6_0
@synthesize enableRefresh;
#endif

//________________________________________________________________________________________
- (id) initWithCoder : (NSCoder *) aDecoder
{
   if (self = [super initWithCoder : aDecoder]) {
      //
#ifdef __IPHONE_6_0
      enableRefresh = YES;
#endif
   }

   return self;
}

//________________________________________________________________________________________
- (id) initWithStyle : (UITableViewStyle) style
{
   if (self = [super initWithStyle : style]) {
      //
#ifdef __IPHONE_6_0
      enableRefresh = YES;
#endif
   }

   return self;
}


//________________________________________________________________________________________
- (void) viewDidLoad
{
   [super viewDidLoad];
#ifdef __IPHONE_6_0
   if (!enableRefresh)
      self.refreshControl = nil;//.enabled = NO;
#endif

   self.tableView.separatorColor = [UIColor clearColor];
   resetColor = YES;
   [self.tableView reloadData];
}

//________________________________________________________________________________________
- (void) viewDidUnload
{
   [super viewDidUnload];
}

//________________________________________________________________________________________
- (BOOL) shouldAutorotateToInterfaceOrientation : (UIInterfaceOrientation) interfaceOrientation
{
   return NO;
}

//________________________________________________________________________________________
- (void) prepareForSegue : (UIStoryboardSegue *) segue sender : (id)sender
{
   NSIndexPath * const indexPath = [self.tableView indexPathForSelectedRow];

   assert(indexPath != nil && "prepareForSegue:sender:, index path for selected table's row is nil");
   
   ArticleDetailViewController * const viewController = (ArticleDetailViewController *)segue.destinationViewController;
   viewController.loadOriginalLink = YES;
   const NSUInteger index = rangeOfArticlesToShow.length ? indexPath.row + rangeOfArticlesToShow.location : indexPath.row;
   [viewController setContentForArticle : [self.aggregator.allArticles objectAtIndex : index]];
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
   //Table has only one section.
   return 1;
}

//________________________________________________________________________________________
- (void) reloadPage
{
   [self refresh];
}

//________________________________________________________________________________________
- (void) refresh
{
   self.rangeOfArticlesToShow = NSRange();
   [self.aggregator clearAllFeeds];
   [super refresh];
   self.tableView.separatorColor = [UIColor clearColor];
   resetColor = YES;
   [self.tableView reloadData];
}

//________________________________________________________________________________________
- (NSInteger) tableView : (UITableView *) tableView numberOfRowsInSection : (NSInteger) section
{
   // Return the number of rows in the section.
   if (self.rangeOfArticlesToShow.length)
      return self.rangeOfArticlesToShow.length;
   else
      return self.aggregator.allArticles.count;
}

//________________________________________________________________________________________
- (UITableViewCell *) tableView : (UITableView *) tableView cellForRowAtIndexPath : (NSIndexPath *) indexPath
{
   //Find feed item first.
   if (resetColor) {
      resetColor = NO;
      self.tableView.separatorColor = [UIColor colorWithRed : 0.88 green : 0.88 blue : 0.88 alpha : 1.];
   }
   
   const NSInteger row = indexPath.row;
   assert(row >= 0 && row < [self.aggregator.allArticles count]);

   MWFeedItem * const article = [self.aggregator.allArticles objectAtIndex : row + self.rangeOfArticlesToShow.location];
   assert(article != nil && "tableView:cellForRowAtIndexPath:, article was not found");

   static NSString *CellIdentifier = @"NewsCell";
   
   //Why do not I have compilation error (warning at least)? And get runtime error on non-existing selector instead?
   //Apple always thinks different.
   //NewsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier : CellIdentifier forIndexPath : indexPath];

   NewsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier : CellIdentifier];
   if (!cell)
      cell = [[NewsTableViewCell alloc] initWithFrame : [NewsTableViewCell defaultCellFrame]];

   UIImage * const image = [self.aggregator firstImageForArticle : article];
   [cell setCellData : article image : image imageOnTheRight : (indexPath.row % 4) == 3];

   return cell;
}

//________________________________________________________________________________________
- (CGFloat) tableView : (UITableView *) tableView heightForRowAtIndexPath : (NSIndexPath *) indexPath
{
   const NSInteger row = indexPath.row;
   assert(row >= 0 && row < [self.aggregator.allArticles count] && "tableView:heightForRowAtIndexPath:, indexPath.row is out of bounds");

   MWFeedItem * const article = [self.aggregator.allArticles objectAtIndex : row + self.rangeOfArticlesToShow.location];
   //From time to time this crap dies at start.
   UIImage * const image = [self.aggregator firstImageForArticle : article];

   return [NewsTableViewCell calculateCellHeightForData : article image : image imageOnTheRight : (indexPath.row % 4) == 3];
}

#pragma mark - RSSAggregatorDelegate methods

//________________________________________________________________________________________
- (void) allFeedsDidLoadForAggregator : (RSSAggregator *) theAggregator
{
   [super allFeedsDidLoadForAggregator : theAggregator];
   [self.tableView reloadData];
   pageLoaded = YES;
}

//________________________________________________________________________________________
- (void) aggregator : (RSSAggregator *) aggregator didDownloadFirstImage : (UIImage *) image forArticle : (MWFeedItem *)article
{
   (void) image;

   const NSUInteger index = [self.aggregator.allArticles indexOfObject : article];
   NSUInteger path[2] = {};
   
   if (self.rangeOfArticlesToShow.length) {
      if (index >= self.rangeOfArticlesToShow.location && index < self.rangeOfArticlesToShow.location + self.rangeOfArticlesToShow.length)
         path[1] = index - self.rangeOfArticlesToShow.location;
   } else if (index < [self.aggregator.allArticles count]) {
      path[1] = index;
   }

   NSIndexPath *indexPath = [NSIndexPath indexPathWithIndexes : path length : 2];
   NSArray *indexPaths = [NSArray arrayWithObject : indexPath];

   //This crap dies at start.
   [self.tableView reloadRowsAtIndexPaths : indexPaths withRowAnimation : UITableViewRowAnimationNone];
}

#pragma mark - Table view delegate

//________________________________________________________________________________________
- (void) tableView : (UITableView *) tableView didSelectRowAtIndexPath : (NSIndexPath *) indexPath
{
   assert(indexPath != nil && "tableView:didSelectRowAtIndexPath, index path for selected table's row is nil");

   if (navigationControllerForArticle) {
      UIStoryboard * const mainStoryboard = [UIStoryboard storyboardWithName : @"MainStoryboard_iPhone" bundle : nil];
      assert(mainStoryboard != nil && "tableView:didSelectRowAtIndexPath, storyboard is nil");

      ArticleDetailViewController *viewController = [mainStoryboard instantiateViewControllerWithIdentifier : CernAPP::ArticleDetailViewControllerID];
      viewController.loadOriginalLink = YES;
      const NSUInteger index = rangeOfArticlesToShow.length ? indexPath.row + rangeOfArticlesToShow.location : indexPath.row;
      [viewController setContentForArticle : [self.aggregator.allArticles objectAtIndex : index]];
      
      [navigationControllerForArticle pushViewController : viewController animated : YES];
   }
   
   [tableView deselectRowAtIndexPath : indexPath animated : NO];
}

#pragma mark - Navigation (since we replace left navbarbutton).

//________________________________________________________________________________________
- (void) backButtonPressed
{
   [self.navigationController popViewControllerAnimated : YES];
}

@end
