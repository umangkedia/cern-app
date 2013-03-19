#import "ECSlidingViewController.h"
#import "NewsTileViewController.h"
#import "TiledPageView.h"

@implementation NewsTileViewController {
   NSMutableArray *pages;
   NSUInteger pageBeforeRotation;
}

//________________________________________________________________________________________
- (void) viewDidLoad
{
   [super viewDidLoad];
   
   //
   pages = [[NSMutableArray alloc] init];
}

//________________________________________________________________________________________
- (void) viewDidAppear : (BOOL) animated
{
   [super viewDidAppear : animated];

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
}

//________________________________________________________________________________________
- (void) didRotateFromInterfaceOrientation : (UIInterfaceOrientation) fromInterfaceOrientation
{
   [UIView animateWithDuration : 0.15f animations : ^ {
         [self layoutPages : YES];
      } completion : ^ (BOOL) {
   }];
}

//________________________________________________________________________________________
- (void) animateLayout
{
   [UIView animateWithDuration : 0.25f animations : ^ {
      [self layoutPages : YES];
   } completion : ^ (BOOL) {
   }];
}

#pragma mark - Sliding view.
//________________________________________________________________________________________
- (void) revealMenu : (id) sender
{
   [self.slidingViewController anchorTopViewTo : ECRight];
}

@end
