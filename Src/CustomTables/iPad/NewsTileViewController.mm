#import <algorithm>

#import <QuartzCore/QuartzCore.h>

#import "ECSlidingViewController.h"
#import "NewsTableViewController.h"
#import "NewsTileViewController.h"
#import "ApplicationErrors.h"
#import "TiledPageView.h"
#import "MWFeedItem.h"

@implementation NewsTileViewController {
   NSMutableArray *pages;
   NSUInteger pageBeforeRotation;
   
   NSMutableDictionary *imageDownloaders;
   BOOL viewDidAppear;
   
   NSMutableArray *allArticles;
}

@synthesize aggregator, noConnectionHUD, spinner;

//________________________________________________________________________________________
- (void) doInitController
{
   //Shared method for different "ctors".
   pages = nil;
   pageBeforeRotation = 0;
   imageDownloaders = nil;
   viewDidAppear = NO;
   allArticles = nil;
   
   aggregator = [[RSSAggregator alloc] init];
   aggregator.delegate = self;
}

//________________________________________________________________________________________
- (id) initWithCoder : (NSCoder *) aDecoder
{
   if (self = [super initWithCoder : aDecoder]) {
      [self doInitController];
   }

   return self;
}

//________________________________________________________________________________________
- (void) viewDidLoad
{
   [super viewDidLoad];
   
   CernAPP::AddSpinner(self);
   CernAPP::HideSpinner(self);

   pages = [[NSMutableArray alloc] init];
}

//________________________________________________________________________________________
- (void) viewDidAppear : (BOOL) animated
{
   [super viewDidAppear : animated];

   //viewDidAppear can be called many times: the first time when controller
   //created and view loaded, next time - for example, when article detailed view
   //controller is poped from the navigation stack.

   if (!viewDidAppear) {
      viewDidAppear = YES;
      //TODO: cache!
      [self reloadPage];
   }
}

#pragma mark - Layout.

//________________________________________________________________________________________
- (void) layoutPages : (BOOL) layoutTiles
{
   CGRect currentFrame = self.view.frame;
   currentFrame.origin = CGPoint();

   NSUInteger index = 0;
   for (TiledPageView *page in pages) {
      page.frame = currentFrame;
      currentFrame.origin.x += currentFrame.size.width;
      if (layoutTiles)
         [page layoutTiles];
      ++index;
   }
   
   [scrollView setContentSize : CGSizeMake(currentFrame.size.width * pages.count, currentFrame.size.height)];
}

#pragma mark - Device orientation changes.

//________________________________________________________________________________________
- (void) willRotateToInterfaceOrientation : (UIInterfaceOrientation) toInterfaceOrientation duration : (NSTimeInterval) duration
{
   pageBeforeRotation = NSUInteger(scrollView.contentOffset.x / scrollView.frame.size.width);
}


//________________________________________________________________________________________
- (void) willAnimateRotationToInterfaceOrientation : (UIInterfaceOrientation) toInterfaceOrientation duration : (NSTimeInterval) duration
{
   if (!pages.count)
      return;

   [scrollView setContentOffset : CGPointMake(pageBeforeRotation * self.view.frame.size.width, 0.f) animated : NO];

   if (pageBeforeRotation)
      ((TiledPageView *)pages[pageBeforeRotation - 1]).hidden = YES;
   if (pageBeforeRotation < pages.count - 1)
      ((TiledPageView *)pages[pageBeforeRotation + 1]).hidden = YES;

   [self layoutPages : YES];
      
   TiledPageView * const page = (TiledPageView *)pages[pageBeforeRotation];
   [page explodeTiles : toInterfaceOrientation];
   [page collectTilesAnimatedForOrientation : toInterfaceOrientation from : CACurrentMediaTime() + duration withDuration : 0.5f];
}

//________________________________________________________________________________________
- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
   if (!pages.count)
      return;

   if (pageBeforeRotation)
      ((TiledPageView *)pages[pageBeforeRotation - 1]).hidden = NO;
   if (pageBeforeRotation < pages.count - 1)
      ((TiledPageView *)pages[pageBeforeRotation + 1]).hidden = NO;
}

#pragma mark - Sliding view.
//________________________________________________________________________________________
- (void) revealMenu : (id) sender
{
   [self.slidingViewController anchorTopViewTo : ECRight];
}

#pragma mark - RSSAggregatorDelegate.
//________________________________________________________________________________________
- (void) allFeedsDidLoadForAggregator : (RSSAggregator *) anAggregator
{
#pragma unused(anAggregator)

   allArticles = [aggregator.allArticles mutableCopy];
   
   //TODO: update a cache???
   
   CernAPP::HideSpinner(self);

   //Let's create tiled view now.
   
   //At the moment, I'm using simple layout - 6 items per page.
   if (!pages)
      pages = [[NSMutableArray alloc] init];
   else {
      for (UIView *v in pages)
         [v removeFromSuperview];

      [pages removeAllObjects];
   }
   
   const NSUInteger nPages = allArticles.count / 6 + 1;
   
   for (NSUInteger pageIndex = 0; pageIndex < nPages; ++pageIndex) {
      TiledPageView * const newPage = [[TiledPageView alloc] initWithFrame : CGRect()];
      [newPage setPageItems : allArticles startingFrom : pageIndex * 6];
      [scrollView addSubview : newPage];
      [pages addObject : newPage];
   }
   
   [self layoutPages : YES];
   [scrollView setContentOffset : CGPointMake(0.f, 0.f)];
   
   //The first page is visible now, let's download ... IMAGES NOW!!! :)
   [self loadImagesForVisiblePage];
}

//________________________________________________________________________________________
- (void) aggregator : (RSSAggregator *) aggregator didFailWithError : (NSString *) errorDescription
{
}

//________________________________________________________________________________________
- (void) lostConnection : (RSSAggregator *) aggregator
{
}

#pragma mark - PageController.
//________________________________________________________________________________________
- (void) reloadPage
{
   if (aggregator.isLoadingData)
      return;
   //Stop any image download if we have any.
   [self cancelAllImageDownloaders];

   if (!aggregator.hasConnection) {
      //Network problems, we can not reload
      //and do not have any previous data to show.
      if (!allArticles.count) {//TODO: cache also!!!
         CernAPP::ShowErrorHUD(self, @"No network");
         return;
      }
   }

   [noConnectionHUD hide : YES];

   //TODO: Cache will also affect the logic here!
   
   CernAPP::ShowSpinner(self);

   [self.aggregator clearAllFeeds];
   //It will re-parse feed and (probably) re-fill the tiled view.
   [self.aggregator refreshAllFeeds];
}

//________________________________________________________________________________________
- (void) reloadPageFromRefreshControl
{
   if (aggregator.isLoadingData)//assert? can this ever happen?
      return;

   if (!aggregator.hasConnection) {
      CernAPP::ShowErrorAlert(@"Please, check network", @"Close");
      CernAPP::HideSpinner(self);
      return;
   }

   [self reloadPage];
}


#pragma mark - ImageDownloaderDelegate.
//________________________________________________________________________________________
- (void) imageDidLoad : (NSIndexPath *) indexPath
{
   assert(indexPath != nil && "imageDidLoad, parameter 'indexPath' is nil");
   const NSInteger page = indexPath.row;
   assert(page >= 0 && page < allArticles.count / 6 + 1 && "imageDidLoad:, index is out of bounds");
   
   MWFeedItem * const article = (MWFeedItem *)allArticles[indexPath.section];

   //We should not load any image more when once.
   assert(article.image == nil && "imageDidLoad:, image was loaded already");
   
   ImageDownloader * const downloader = (ImageDownloader *)imageDownloaders[indexPath];
   assert(downloader != nil && "imageDidLoad:, no downloader found for the given index path");

   if (downloader.image) {
      article.image = downloader.image;
      //
      TiledPageView * const pageToUpdate = (TiledPageView *)pages[page];
      [pageToUpdate setThumbnail : article.image forTile : indexPath.section % 6];
      //
   }
   
   [imageDownloaders removeObjectForKey : indexPath];
   if (!imageDownloaders.count)
      imageDownloaders = nil;
}

//________________________________________________________________________________________
- (void) imageDownloadFailed : (NSIndexPath *) indexPath
{
   assert(indexPath != nil && "imageDownloadFailed:, parameter 'indexPath' is nil");

   const NSInteger page = indexPath.row;
   //Even if download failed, index still must be valid.
   assert(page >= 0 && page < allArticles.count / 6 &&
          "imageDownloadFailed:, index is out of bounds");
   assert(imageDownloaders[indexPath] != nil &&
          "imageDownloadFailed:, no downloader for the given path");

   [imageDownloaders removeObjectForKey : indexPath];
   //But no need to update the tableView.
   if (!imageDownloaders.count)
      imageDownloaders = nil;
}

#pragma mark - Connection controller.
//________________________________________________________________________________________
- (void) cancelAnyConnections
{
}


#pragma mark - UIScrollView delegate.

// Load images for all onscreen rows (if not done yet) when scrolling is finished
//________________________________________________________________________________________
- (void) scrollViewDidEndDragging : (UIScrollView *) scrollView willDecelerate : (BOOL) decelerate
{
#pragma unused(scrollView)
   //Cached feeds do not have any images.
   if (!decelerate)
      [self loadImagesForVisiblePage];

}

//________________________________________________________________________________________
- (void) scrollViewDidEndDecelerating : (UIScrollView *) scrollView
{
#pragma unused(scrollView)
   [self loadImagesForVisiblePage];
}

#pragma mark - Aux.
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
}

//________________________________________________________________________________________
- (void) loadImagesForVisiblePage
{
   const NSUInteger visiblePage = NSUInteger(scrollView.contentOffset.x / scrollView.frame.size.width);
   
   //At the moment I have a very simple layout - up to 6 tiles on a page.
   const NSUInteger endOfRange = std::min(visiblePage * 6 + 6, allArticles.count);
   for (NSUInteger i = visiblePage * 6; i < endOfRange; ++i) {
      MWFeedItem * const article = (MWFeedItem *)allArticles[i];
      if (!article.image) {
         if (!imageDownloaders)
            imageDownloaders = [[NSMutableDictionary alloc] init];
      

         //May be, we already have a downloader for this item?
         NSIndexPath * const indexPath = [NSIndexPath indexPathForRow : visiblePage inSection : i];//Using absolute index i, not relative (on a page).
         ImageDownloader *downloader = (ImageDownloader *)imageDownloaders[indexPath];
         
         if (!downloader) {
            NSString * body = article.content;
            if (!body)
               body = article.summary;

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
}

@end
