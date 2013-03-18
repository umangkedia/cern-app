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
   [self layoutPages];
}

#pragma mark - Layout.

//________________________________________________________________________________________
- (void) layoutPages
{
   CGRect currentFrame = self.view.frame;
   currentFrame.origin = CGPoint();

   for (TiledPageView *page in pages) {
      page.frame = currentFrame;
      currentFrame.origin.x += currentFrame.size.width;
   }
   
   [scrollView setContentSize : CGSizeMake(currentFrame.size.width * pages.count, currentFrame.size.height)];
   [scrollView setContentOffset : CGPointMake(pageBeforeRotation * currentFrame.size.width, 0.f)];
}


#pragma mark - Device orientation changes.

//________________________________________________________________________________________
- (void) willAnimateRotationToInterfaceOrientation : (UIInterfaceOrientation) toInterfaceOrientation duration : (NSTimeInterval) duration
{
   pageBeforeRotation = NSUInteger(scrollView.contentOffset.x / scrollView.frame.size.width);
}


//________________________________________________________________________________________
- (void) didRotateFromInterfaceOrientation : (UIInterfaceOrientation) fromInterfaceOrientation
{
   [self layoutPages];
}

#pragma mark - Sliding view.
//________________________________________________________________________________________
- (void) revealMenu : (id) sender
{
   [self.slidingViewController anchorTopViewTo : ECRight];
}

@end
