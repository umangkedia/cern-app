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
   NSMutableArray *allArticles;
   
   //TODO: replace this with a standard indicator.
   MBProgressHUD *noConnectionHUD;
   
   UIActivityIndicatorView *spinner;
}

@synthesize rangeOfArticlesToShow, pageLoaded, navigationControllerForArticle, aggregator;

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

      aggregator = [[RSSAggregator alloc] init];
      aggregator.delegate = self;
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

      aggregator = [[RSSAggregator alloc] init];
      aggregator.delegate = self;
   }

   return self;
}

//________________________________________________________________________________________
- (void) dealloc
{
   [aggregator stopLoading];
}

//________________________________________________________________________________________
- (void) viewDidLoad
{
   [super viewDidLoad];

#ifdef __IPHONE_6_0
   if (enableRefresh) {
      self.refreshControl = [[UIRefreshControl alloc] init];
      [self.refreshControl addTarget : self action : @selector(reloadPageFromRefreshControl) forControlEvents : UIControlEventValueChanged];
   }
#endif

   self.tableView.separatorColor = [UIColor clearColor];
   resetColor = YES;
   [self.tableView reloadData];
   
   const CGFloat spinnerSize = 150.f;
   const CGPoint spinnerOrigin = CGPointMake(self.view.frame.size.width / 2 - spinnerSize / 2, self.view.frame.size.height / 2 - spinnerSize / 2);
   
   spinner = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(spinnerOrigin.x, spinnerOrigin.y, spinnerSize, spinnerSize)];
   spinner.color = [UIColor grayColor];
   [self.view addSubview : spinner];
   
   [spinner setHidden : YES];
}

//________________________________________________________________________________________
- (void) viewDidUnload
{
   [super viewDidUnload];
   //Never gets called on iOS 6 (deprecated).
}

//________________________________________________________________________________________
- (BOOL) shouldAutorotateToInterfaceOrientation : (UIInterfaceOrientation) interfaceOrientation
{
   return NO;
}

//________________________________________________________________________________________
- (void) didReceiveMemoryWarning
{
   [super didReceiveMemoryWarning];
   // Dispose of any resources that can be recreated.
}

#pragma mark - Aux. methods to work with aggregators/articles.

//________________________________________________________________________________________
- (void) copyArticlesFromAggregator
{
   assert(aggregator != nil && "copyArticlesFromAggregator, aggregator is nil");

   if (allArticles)
      [allArticles removeAllObjects];
   else
      allArticles = [[NSMutableArray alloc] init];
   
   for (MWFeedInfo *feed in aggregator.allArticles)
      [allArticles addObject : feed];
}

//________________________________________________________________________________________
- (void) setAggregator : (RSSAggregator *) rssAggregator
{
   assert(aggregator != nil && "setAggregator:, parameter 'rssAggregator' is nil");

   aggregator = rssAggregator;
   aggregator.delegate = self;
   [self copyArticlesFromAggregator];
}

#pragma mark - Storyboard.

//________________________________________________________________________________________
- (void) prepareForSegue : (UIStoryboardSegue *) segue sender : (id)sender
{
   NSIndexPath * const indexPath = [self.tableView indexPathForSelectedRow];

   assert(indexPath != nil && "prepareForSegue:sender:, index path for selected table's row is nil");
   
   ArticleDetailViewController * const viewController = (ArticleDetailViewController *)segue.destinationViewController;
   viewController.loadOriginalLink = YES;
   const NSUInteger index = rangeOfArticlesToShow.length ? indexPath.row + rangeOfArticlesToShow.location : indexPath.row;
   [viewController setContentForArticle : [allArticles objectAtIndex : index]];
}

#pragma mark - Table view data source

//________________________________________________________________________________________
- (NSInteger) numberOfSectionsInTableView : (UITableView *) tableView
{
   //Table has only one section.
   return 1;
}

//________________________________________________________________________________________
- (void) reloadPageFromRefreshControl
{
   [self reloadPageShowHUD : NO];
}

//________________________________________________________________________________________
- (void) reloadPage
{
   [self reloadPageShowHUD : YES];
}

//________________________________________________________________________________________
- (void) reloadPageShowHUD : (BOOL) show
{
   if (self.aggregator.isLoadingData) {
      [self.refreshControl endRefreshing];
      return;
   }

   [noConnectionHUD hide : YES];
   
   if (show) {
      [spinner setHidden : NO];
      [spinner startAnimating];
   }

   self.rangeOfArticlesToShow = NSRange();
   [self.aggregator clearAllFeeds];
   
   [allArticles removeAllObjects];
   self.tableView.separatorColor = [UIColor clearColor];
   resetColor = YES;
   [self.tableView reloadData];
   //It will re-parse feed and show load indicator.
   [self.aggregator refreshAllFeeds];
}

#ifndef __IPHONE_6_0

//This method is called by PullRefreshTableViewController.

//________________________________________________________________________________________
- (void) refresh
{
   if (self.aggregator.isLoadingData) {
      [self.refreshControl endRefreshing];
      return;
   }

   [noConnectionHUD hide : YES];

   self.rangeOfArticlesToShow = NSRange();
   [self.aggregator clearAllFeeds];
   
   [allArticles removeAllObjects];
   self.tableView.separatorColor = [UIColor clearColor];
   resetColor = YES;
   [self.tableView reloadData];
   //It will re-parse feed and show load indicator.
   [self.aggregator refreshAllFeeds];
}

#endif

#pragma mark - MBProgressHUDDelegate methods

//________________________________________________________________________________________
- (void) hudWasTapped : (MBProgressHUD *) hud
{
   [self reloadPage];
}

#pragma mark - UITableViewDataSource.

//________________________________________________________________________________________
- (NSInteger) tableView : (UITableView *) tableView numberOfRowsInSection : (NSInteger) section
{
   // Return the number of rows in the section.   
   if (self.rangeOfArticlesToShow.length)
      return self.rangeOfArticlesToShow.length;
   else
      return allArticles.count;
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
   assert(row >= 0 && row < [allArticles count]);

   MWFeedItem * const article = [allArticles objectAtIndex : row + self.rangeOfArticlesToShow.location];
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
   assert(row >= 0 && row < [allArticles count] && "tableView:heightForRowAtIndexPath:, indexPath.row is out of bounds");

   MWFeedItem * const article = [allArticles objectAtIndex : row + self.rangeOfArticlesToShow.location];
   //From time to time this crap dies at start.
   UIImage * const image = [self.aggregator firstImageForArticle : article];
   return [NewsTableViewCell calculateCellHeightForData : article image : image imageOnTheRight : (indexPath.row % 4) == 3];
}

#pragma mark - RSSAggregatorDelegate methods

//________________________________________________________________________________________
- (void) allFeedsDidLoadForAggregator : (RSSAggregator *) theAggregator
{
   assert(theAggregator != nil && "allFeedsDidLoadForAggregator:, parameter 'theAggregator' is nil");

   [self copyArticlesFromAggregator];

   [spinner stopAnimating];
   [spinner setHidden : YES];
#ifdef __IPHONE_6_0
   [self.refreshControl endRefreshing];
#else
   [self stopLoading];
#endif

   [self.tableView reloadData];

   pageLoaded = YES;
}

//________________________________________________________________________________________
- (void) aggregator : (RSSAggregator *) aggregator didFailWithError : (NSError *)error
{
   [MBProgressHUD hideAllHUDsForView : self.view animated : NO];
   noConnectionHUD = [MBProgressHUD showHUDAddedTo : self.view animated : NO];
    
   noConnectionHUD.delegate = self;
   noConnectionHUD.mode = MBProgressHUDModeText;
   noConnectionHUD.labelText = @"Load error";
   noConnectionHUD.removeFromSuperViewOnHide = YES;
   
   if (!spinner.isHidden) {
      if (spinner.isAnimating)
         [spinner stopAnimating];
      [spinner setHidden : YES];
   }
   
#ifdef __IPHONE_6_0
   [self.refreshControl  endRefreshing];
#endif
}

//________________________________________________________________________________________
- (void) aggregator : (RSSAggregator *) aggregator didDownloadFirstImage : (UIImage *) image forArticle : (MWFeedItem *)article
{
   (void) image;

   const NSUInteger index = [allArticles indexOfObject : article];
   NSUInteger path[2] = {};
   
   if (self.rangeOfArticlesToShow.length) {
      if (index >= self.rangeOfArticlesToShow.location && index < self.rangeOfArticlesToShow.location + self.rangeOfArticlesToShow.length)
         path[1] = index - self.rangeOfArticlesToShow.location;
   } else if (index < [allArticles count]) {
      path[1] = index;
   }

   NSIndexPath *indexPath = [NSIndexPath indexPathWithIndexes : path length : 2];
   NSArray *indexPaths = [NSArray arrayWithObject : indexPath];

   [self.tableView reloadRowsAtIndexPaths : indexPaths withRowAnimation : UITableViewRowAnimationNone];
}

#pragma mark - Table view delegate

//________________________________________________________________________________________
- (void) tableView : (UITableView *) tableView didSelectRowAtIndexPath : (NSIndexPath *) indexPath
{
   assert(indexPath != nil && "tableView:didSelectRowAtIndexPath, index path for selected table's row is nil");

   if (navigationControllerForArticle && !self.aggregator.isLoadingData) {
      UIStoryboard * const mainStoryboard = [UIStoryboard storyboardWithName : @"MainStoryboard_iPhone" bundle : nil];
      assert(mainStoryboard != nil && "tableView:didSelectRowAtIndexPath, storyboard is nil");

      ArticleDetailViewController *viewController = [mainStoryboard instantiateViewControllerWithIdentifier : CernAPP::ArticleDetailViewControllerID];
      viewController.loadOriginalLink = YES;
      const NSUInteger index = rangeOfArticlesToShow.length ? indexPath.row + rangeOfArticlesToShow.location : indexPath.row;
      [viewController setContentForArticle : [allArticles objectAtIndex : index]];
      
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
