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
}

@synthesize pageLoaded, aggregator, imageDownloaders, nLoadedImages;

#pragma mark - Construction/destruction.

//________________________________________________________________________________________
- (id) initWithNibName : (NSString *) nibNameOrNil bundle : (NSBundle *) nibBundleOrNil
{
   if (self = [super initWithNibName : nibNameOrNil bundle : nibBundleOrNil]) {
      pageLoaded = NO;
      aggregator = [[RSSAggregator alloc] init];
      aggregator.delegate = self;
   }

   return self;
}


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
   
   [self cancelAllImageDownloaders];

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
- (NSInteger) numberOfSectionsInTableView : (UITableView *) tableView
{
#pragma unused(tableView)
   //Table has only one section.
   return 1;
}

//________________________________________________________________________________________
- (NSInteger) tableView : (UITableView *) tableView numberOfRowsInSection : (NSInteger) section
{
#pragma unused(tableView, section)
   // Return the number of rows in the section.
   return allArticles.count;
}

//________________________________________________________________________________________
- (UITableViewCell *) tableView : (UITableView *) tableView cellForRowAtIndexPath : (NSIndexPath *) indexPath
{
#pragma unused(tableView)

   assert(indexPath != nil && "tableView:cellForRowAtIndexPath:, parameter 'indexPath' is nil");

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
   
   if (!article.image)
      [self startIconDownloadForIndexPath : indexPath];

   return cell;
}

//________________________________________________________________________________________
- (CGFloat) tableView : (UITableView *) tableView heightForRowAtIndexPath : (NSIndexPath *) indexPath
{
#pragma unused(tableView)

   assert(indexPath != nil && "tableView:heightForRowAtIndexPath:, parameter 'indexPath' is nil");

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
- (void) aggregator : (RSSAggregator *) anAggregator didFailWithError : (NSString *) error
{
#pragma unused(anAggregator)

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
#pragma unused(tableView)

   assert(indexPath != nil && "tableView:didSelectRowAtIndexPath, index path for selected table's row is nil");

   if (self.navigationController && !self.aggregator.isLoadingData) {
      if (aggregator.hasConnection) {
         UIStoryboard * const mainStoryboard = [UIStoryboard storyboardWithName : @"iPhone" bundle : nil];

         ArticleDetailViewController *viewController = [mainStoryboard instantiateViewControllerWithIdentifier : CernAPP::ArticleDetailViewControllerID];
         const NSUInteger index = indexPath.row;
         [viewController setContentForArticle : [allArticles objectAtIndex : index]];
         viewController.navigationItem.title = @"";
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

#pragma mark - Connection controller.

//________________________________________________________________________________________
- (void) cancelAnyConnections
{
   [aggregator stopAggregator];
   [self cancelAllImageDownloaders];
}

//________________________________________________________________________________________
- (void) cancelAllImageDownloaders
{
   if (imageDownloaders && imageDownloaders.count) {
      NSEnumerator * const keyEnumerator = [imageDownloaders keyEnumerator];
      for (id key in keyEnumerator) {
         ImageDownloader * const downloader = (ImageDownloader *)imageDownloaders[key];
         [downloader cancelDownload];
      }
      
      imageDownloaders = nil;
   }
   
   nLoadedImages = 0;
}

#pragma mark - UIScrollView delegate.

// Load images for all onscreen rows when scrolling is finished
//________________________________________________________________________________________
- (void) scrollViewDidEndDragging : (UIScrollView *) scrollView willDecelerate : (BOOL) decelerate
{
#pragma unused(scrollView)
   if (!decelerate) {
      if (nLoadedImages != allArticles.count)
         [self loadImagesForOnscreenRows];
   }
}

//________________________________________________________________________________________
- (void) scrollViewDidEndDecelerating : (UIScrollView *) scrollView
{
   if (nLoadedImages != allArticles.count)
      [self loadImagesForOnscreenRows];
}

#pragma mark - Download images for news' items in a table.

//________________________________________________________________________________________
- (void) startIconDownloadForIndexPath : (NSIndexPath *) indexPath
{
   assert(indexPath != nil && "startIconDownloadForIndexPath:, parameter 'indexPath' is nil");
   const NSInteger row = indexPath.row;
   assert(row >= 0 && row < allArticles.count &&
          "startIconDownloadForIndexPath:, index is out of bounds");

   if (!imageDownloaders)
      imageDownloaders = [[NSMutableDictionary alloc] init];

   ImageDownloader * downloader = (ImageDownloader *)imageDownloaders[indexPath];
   if (!downloader) {//We did not start download for this image yet.
      MWFeedItem * const article = (MWFeedItem *)allArticles[indexPath.row];
      assert(article.image == nil && "startIconDownloadForIndexPath:, image was loaded already");
      
      NSString * body = article.content;
      if (!body)
         body = article.summary;
      
      if (body) {
         if (NSString * const urlString = [NewsTableViewController firstImageURLFromHTMLString : body]) {
            downloader = [[ImageDownloader alloc] initWithURLString : urlString];
            downloader.indexPathInTableView = indexPath;
            downloader.delegate = self;
            [imageDownloaders setObject : downloader forKey : indexPath];
            [downloader startDownload];//Power on.
         }
      }
   }
}

// This method is used in case the user scrolled into a set of cells that don't have their thumbnails yet.

//________________________________________________________________________________________
- (void) loadImagesForOnscreenRows
{
   if (allArticles.count) {
      NSArray * const visiblePaths = [self.tableView indexPathsForVisibleRows];
      for (NSIndexPath *indexPath in visiblePaths) {
         MWFeedItem * const article = allArticles[indexPath.row];
         if (!article.image)
            [self startIconDownloadForIndexPath : indexPath];
      }
   }
}

#pragma mark - ImageDownloaderDelegate.


//________________________________________________________________________________________
+ (NSString *) firstImageURLFromHTMLString : (NSString *) htmlString
{
   if (!htmlString)
      return nil;

   NSScanner * const theScanner = [NSScanner scannerWithString : htmlString];
   //Find the start of IMG tag
   [theScanner scanUpToString : @"<img" intoString : nil];
   
   if (![theScanner isAtEnd]) {
      [theScanner scanUpToString : @"src" intoString : nil];
      NSCharacterSet * const charset = [NSCharacterSet characterSetWithCharactersInString : @"\"'"];
      [theScanner scanUpToCharactersFromSet : charset intoString : nil];
      [theScanner scanCharactersFromSet : charset intoString : nil];
      NSString *urlString = nil;
      [theScanner scanUpToCharactersFromSet : charset intoString : &urlString];
      // "url" now contains the URL of the img
      return urlString;
   }

   // if no img url was found, return nil
   return nil;
}

//________________________________________________________________________________________
- (void) imageDidLoad : (NSIndexPath *) indexPath
{
   //
   assert(indexPath != nil && "imageDidLoad, parameter 'indexPath' is nil");
   const NSInteger row = indexPath.row;
   assert(row >= 0 && row < allArticles.count && "imageDidLoad:, index is out of bounds");
   
   MWFeedItem * const article = (MWFeedItem *)allArticles[row];
   
   //We should not load any image more when once.
   assert(article.image == nil && "imageDidLoad:, image was loaded already");
   
   ImageDownloader * const downloader = (ImageDownloader *)imageDownloaders[indexPath];
   assert(downloader != nil && "imageDidLoad:, no downloader found for the given index path");
   
   if (downloader.image) {
      article.image = downloader.image;
      [self.tableView reloadRowsAtIndexPaths : @[indexPath] withRowAnimation : UITableViewRowAnimationNone];
   }
   
   ++nLoadedImages;
   [imageDownloaders removeObjectForKey : indexPath];
}

//________________________________________________________________________________________
- (void) imageDownloadFailed : (NSIndexPath *) indexPath
{
   assert(indexPath != nil && "imageDownloadFailed:, parameter 'indexPath' is nil");

   const NSInteger row = indexPath.row;

   //Even if download failed, index still must be valid.
   assert(row >= 0 && row < allArticles.count &&
          "imageDownloadFailed:, index is out of bounds");
   assert(imageDownloaders[indexPath] != nil &&
          "imageDownloadFailed:, no downloader for the given path");
   
   ++nLoadedImages;//Still, we count this image.
   [imageDownloaders removeObjectForKey : indexPath];

   //But no need to update the tableView.
}

@end
