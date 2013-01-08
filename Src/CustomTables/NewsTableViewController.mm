//Author: Timur Pocheptsov.
//Developed for CERN app.

//This is a code for a table view controller, which shows author, title, short content, date for
//an every news item.
//It can be used ONLY for iPhone/iPod touch device, for iPad we'll have different approach.

//NewsTableViewController supports several protocols:
//1. UITableViewDataSource - provide data/cells to show in a table;
//2. UITableViewDelegate - react on user touches in a table;
//3. RSSAggregatorDelegate - rss aggregator calls feed parser,
//   loads articles, images, etc. informing its delegate
//   about possible errors or success.
//4. PageController - before we have MultiPageViewController, which could
//   contain several tables as pages. Still, methods like reloadPage/reloadPageFromRefreshControl,
//   pageLoaded property - are required.

//
//Life cycle and approx. calls sequence:
//1. created by either MenuViewController or InitialSlisingViewController:
//   [storyboard instantiateViewControllerWithIdentifier : CernAPP::NewTableNavigationControllerID];
//   This leads to initWithCoder, which create an empty (yet) but initialized aggregator.
//   initWithStyle is automatically generated, it also create an empty aggregator.
//2. After controller was created, feed must be specified.
//3. viewDidLoad creates activity indicator (invisible at the beginning) and refreshControl (non animated at
//   the beginning).
//4. viewDidAppear: if feed was not loaded yet (!pageLoaded) - call reloadPage.

#import <cassert>

#import "ArticleDetailViewController.h"
#import "ECSlidingViewController.h"
#import "NewsTableViewController.h"
#import "StoryboardIdentifiers.h"
#import "NewsTableViewCell.h"
#import "ApplicationErrors.h"
#import "GUIHelpers.h"

@implementation NewsTableViewController {
   //I need a stupid hack - table view shows ugly empty rows,
   //when data is not loaded yet. Before I was using empty footers,
   //but they lead to stupid crashes with UIRefreshController
   //(and it looks like a bug in UIKit). So now I simply set the separator's color:
   //when no data present, it's a clear color, when we have at least one row with data -
   //it's a gray color.
   BOOL resetSeparatorColor;
   NSMutableArray *allArticles;
   
   //TODO: replace this with a standard indicator.
   MBProgressHUD *noConnectionHUD;
   
   UIActivityIndicatorView *spinner;
}

@synthesize pageLoaded, aggregator;

#pragma mark - Construction/destruction.

//________________________________________________________________________________________
- (id) initWithCoder : (NSCoder *) aDecoder
{
   if (self = [super initWithCoder : aDecoder]) {
      pageLoaded = NO;
      aggregator = [[RSSAggregator alloc] init];
      aggregator.delegate = self;
   }

   return self;
}

//________________________________________________________________________________________
- (id) initWithStyle : (UITableViewStyle) style
{
   if (self = [super initWithStyle : style]) {
      pageLoaded = NO;
      aggregator = [[RSSAggregator alloc] init];
      aggregator.delegate = self;
   }

   return self;
}

#pragma mark - viewDid/Will/Should/Must/Could/Would stuff.

//________________________________________________________________________________________
- (void) viewDidLoad
{
   using CernAPP::spinnerSize;

   [super viewDidLoad];

   self.tableView.separatorColor = [UIColor clearColor];
   resetSeparatorColor = YES;
   [self.tableView reloadData];
   
   const CGPoint spinnerOrigin = CGPointMake(self.view.frame.size.width / 2 - spinnerSize / 2, self.view.frame.size.height / 2 - spinnerSize / 2);
   
   spinner = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(spinnerOrigin.x, spinnerOrigin.y, spinnerSize, spinnerSize)];
   spinner.color = [UIColor grayColor];
   [self.view addSubview : spinner];
   
   [spinner setHidden : YES];
   
   self.refreshControl = [[UIRefreshControl alloc] init];
   [self.refreshControl addTarget : self action : @selector(reloadPageFromRefreshControl) forControlEvents : UIControlEventValueChanged];
}

//________________________________________________________________________________________
- (void) viewDidAppear : (BOOL)animated
{
   [super viewDidAppear : animated];
   
   if (!pageLoaded)
      [self reloadPage];
}

//________________________________________________________________________________________
- (void) viewWillAppear : (BOOL) animated
{
   [super viewWillAppear : animated];
   
   if(self.navigationController.viewControllers.count == 1)//??? Kind of a hack.
      CernAPP::ResetMenuButton(self);
}

//________________________________________________________________________________________
- (BOOL) shouldAutorotateToInterfaceOrientation : (UIInterfaceOrientation) interfaceOrientation
{
   //This is iPhone ONLY view/controller and it works ONLY with
   //a portrait orientation.
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

   allArticles = [aggregator.allArticles mutableCopy];
}

//________________________________________________________________________________________
- (void) setAggregator : (RSSAggregator *) rssAggregator
{
   assert(aggregator != nil && "setAggregator:, parameter 'rssAggregator' is nil");

   aggregator = rssAggregator;
   aggregator.delegate = self;
   [self copyArticlesFromAggregator];
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
   if (self.aggregator.isLoadingData) {
      //Do not try to reload if we are still loading.
      [self.refreshControl endRefreshing];
      return;
   }

   if (!aggregator.hasConnection) {
      CernAPP::ShowErrorAlert(@"Please, check network", @"Close");
      [self.refreshControl endRefreshing];
      if (spinner.isAnimating)
         [spinner stopAnimating];
      if (!spinner.isHidden)
         [spinner setHidden : YES];
      return;
   }

   [self reloadPageShowHUD : NO];
}

//________________________________________________________________________________________
- (void) reloadPage
{
   if (self.aggregator.isLoadingData)
      return;

   [self reloadPageShowHUD : YES];
}

//________________________________________________________________________________________
- (void) reloadPageShowHUD : (BOOL) show
{
   if (self.aggregator.isLoadingData)
      return;

   if (!aggregator.hasConnection) {
      [MBProgressHUD hideAllHUDsForView : self.view animated : NO];
      noConnectionHUD = [MBProgressHUD showHUDAddedTo : self.view animated : NO];
      noConnectionHUD.mode = MBProgressHUDModeText;
      noConnectionHUD.labelText = @"No network";
      noConnectionHUD.removeFromSuperViewOnHide = YES;

      return;
   }

   [noConnectionHUD hide : YES];
   
   if (show) {
      [spinner setHidden : NO];
      [spinner startAnimating];
   }

   [self.aggregator clearAllFeeds];
   
   [allArticles removeAllObjects];
   self.tableView.separatorColor = [UIColor clearColor];
   resetSeparatorColor = YES;
   [self.tableView reloadData];
   //It will re-parse feed and show load indicator.
   [self.aggregator refreshAllFeeds];
}

#pragma mark - UITableViewDataSource.

//________________________________________________________________________________________
- (NSInteger) tableView : (UITableView *) tableView numberOfRowsInSection : (NSInteger) section
{
   // Return the number of rows in the section.
   return allArticles.count;
}

//________________________________________________________________________________________
- (UITableViewCell *) tableView : (UITableView *) tableView cellForRowAtIndexPath : (NSIndexPath *) indexPath
{
   //Find feed item first.
   if (resetSeparatorColor) {
      resetSeparatorColor = NO;
      self.tableView.separatorColor = [UIColor colorWithRed : 0.88 green : 0.88 blue : 0.88 alpha : 1.];
   }
   
   const NSInteger row = indexPath.row;
   assert(row >= 0 && row < [allArticles count]);

   MWFeedItem * const article = [allArticles objectAtIndex : row];
   assert(article != nil && "tableView:cellForRowAtIndexPath:, article was not found");

   NewsTableViewCell *cell = (NewsTableViewCell *)[tableView dequeueReusableCellWithIdentifier : @"NewsCell"];
   if (!cell)
      cell = [[NewsTableViewCell alloc] initWithFrame : [NewsTableViewCell defaultCellFrame]];

   [cell setCellData : article imageOnTheRight : (indexPath.row % 4) == 3];

   return cell;
}

//________________________________________________________________________________________
- (CGFloat) tableView : (UITableView *) tableView heightForRowAtIndexPath : (NSIndexPath *) indexPath
{
   const NSInteger row = indexPath.row;
   assert(row >= 0 && row < [allArticles count] && "tableView:heightForRowAtIndexPath:, indexPath.row is out of bounds");

   MWFeedItem * const article = [allArticles objectAtIndex : row];
   return [NewsTableViewCell calculateCellHeightForData : article imageOnTheRight : (indexPath.row % 4) == 3];
}

#pragma mark - RSSAggregatorDelegate methods

//________________________________________________________________________________________
- (void) allFeedsDidLoadForAggregator : (RSSAggregator *) theAggregator
{
   assert(theAggregator != nil && "allFeedsDidLoadForAggregator:, parameter 'theAggregator' is nil");

   [self copyArticlesFromAggregator];

   [spinner stopAnimating];
   [spinner setHidden : YES];
   [self.refreshControl endRefreshing];
   [self.tableView reloadData];
   pageLoaded = YES;
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
   pageLoaded = NO;
}

//________________________________________________________________________________________
- (void) aggregator : (RSSAggregator *) rssAggregator didDownloadFirstImage : (UIImage *) image forArticle : (MWFeedItem *) article
{
#pragma unused(rssAggregator, image)

   const NSUInteger index = [allArticles indexOfObject : article];

   assert(index != NSNotFound &&
          "aggregator:didDownloadFirstImage:forArticle:, article is not found in a list of articles");

   const NSUInteger path[2] = {0, index};
   NSIndexPath * const indexPath = [NSIndexPath indexPathWithIndexes : path length : 2];
   [self.tableView reloadRowsAtIndexPaths : @[indexPath] withRowAnimation : UITableViewRowAnimationNone];
}

//________________________________________________________________________________________
- (void) lostConnection : (RSSAggregator *) rssAggregator
{
#pragma unused(rssAggregator)
   
   pageLoaded = NO;
   CernAPP::ShowErrorAlert(@"Please, check network!", @"Close");
}

#pragma mark - Table view delegate

//________________________________________________________________________________________
- (void) tableView : (UITableView *) tableView didSelectRowAtIndexPath : (NSIndexPath *) indexPath
{
   assert(indexPath != nil && "tableView:didSelectRowAtIndexPath, index path for selected table's row is nil");

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
   }
   
   [tableView deselectRowAtIndexPath : indexPath animated : NO];
}

#pragma mark - Sliding view controller's "menu"

//________________________________________________________________________________________
- (IBAction) revealMenu : (id) sender
{
#pragma unused(sender)
   [self.slidingViewController anchorTopViewTo : ECRight];
}

@end
