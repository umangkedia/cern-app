#import "ECSlidingViewController.h"
#import "NewsTileViewController.h"
#import "TiledPageView.h"

@implementation NewsTileViewController {
   NSMutableArray *pages;
   NSUInteger pageBeforeRotation;
   
   NSMutableArray *imageDownloaders;
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
   
   //
   pages = [[NSMutableArray alloc] init];

   CernAPP::AddSpinner(self);
   CernAPP::HideSpinner(self);
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
      //read a cache?
      //May be, we have a cache already.
      [self reloadPage];
   }

   //Let's create the pages.
   ////////////////////////////////
   //Test only.
   const CGRect currentFrame = self.view.frame;
   for (NSUInteger i = 0; i < 3; ++i) {
      TiledPageView * const newPage = [[TiledPageView alloc] initWithFrame : currentFrame ];
      [newPage setPageItems : nil startingFrom : 0];//nil and 0 are illegal, just for test here!
      [pages addObject : newPage];
      [scrollView addSubview : newPage];
   }
   //Test only.
   ////////////////////////////////
   [self layoutPages : YES];
   [scrollView setContentOffset : CGPoint()];
}

#pragma mark - Layout.

//________________________________________________________________________________________
- (void) layoutPages : (BOOL) layoutTiles
{
   CGRect currentFrame = self.view.frame;
   currentFrame.origin = CGPoint();

   for (TiledPageView *page in pages) {
      page.frame = currentFrame;
      currentFrame.origin.x += currentFrame.size.width;
      if (layoutTiles)
         [page layoutTiles];
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
   [scrollView setContentOffset : CGPointMake(pageBeforeRotation * self.view.frame.size.width, 0.f)];
   [self layoutPages : NO];

   TiledPageView * const page = (TiledPageView *)pages[pageBeforeRotation];
   [page startTileAnimationTo : toInterfaceOrientation];
   
   if (pageBeforeRotation)
      ((TiledPageView *)pages[pageBeforeRotation - 1]).hidden = YES;
   if (pageBeforeRotation < pages.count - 1)
      ((TiledPageView *)pages[pageBeforeRotation + 1]).hidden = YES;
}

//________________________________________________________________________________________
- (void) didRotateFromInterfaceOrientation : (UIInterfaceOrientation) fromInterfaceOrientation
{
   [UIView animateWithDuration : 0.15f animations : ^ {
         [self layoutPages : YES];
      } completion : ^ (BOOL) {
         if (pageBeforeRotation)
            ((TiledPageView *)pages[pageBeforeRotation - 1]).hidden = NO;
         if (pageBeforeRotation < pages.count - 1)
            ((TiledPageView *)pages[pageBeforeRotation + 1]).hidden = NO;

      }
   ];
}

#pragma mark - Sliding view.
//________________________________________________________________________________________
- (void) revealMenu : (id) sender
{
   [self.slidingViewController anchorTopViewTo : ECRight];
}

#pragma mark - RSSAggregatorDelegate.
//________________________________________________________________________________________
- (void) allFeedsDidLoadForAggregator : (RSSAggregator *) aggregator
{
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
}

//________________________________________________________________________________________
- (void) reloadPageFromRefreshControl
{
}


#pragma mark - ImageDownloaderDelegate.
//________________________________________________________________________________________
- (void) imageDidLoad : (NSIndexPath *) indexPath
{
}

//________________________________________________________________________________________
- (void) imageDownloadFailed : (NSIndexPath *) indexPath
{
}

#pragma mark - Connection controller.
//________________________________________________________________________________________
- (void) cancelAnyConnections
{
}

@end
