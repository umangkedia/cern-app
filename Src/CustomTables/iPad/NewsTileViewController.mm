#import "ECSlidingViewController.h"
#import "NewsTileViewController.h"

@implementation NewsTileViewController

//________________________________________________________________________________________
- (void) revealMenu : (id) sender
{
   [self.slidingViewController anchorTopViewTo : ECRight];
}

@end