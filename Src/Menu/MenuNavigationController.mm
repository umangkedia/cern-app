#import <cassert>

#import "StaticInfoScrollViewController.h"
#import "MenuNavigationController.h"
#import "NewsTableViewController.h"
#import "ECSlidingViewController.h"
#import "MenuViewController.h"

@implementation MenuNavigationController

//________________________________________________________________________________________
- (id) initWithNibName : (NSString *) nibNameOrNil bundle : (NSBundle *) nibBundleOrNil
{
   return self = [super initWithNibName : nibNameOrNil bundle : nibBundleOrNil];
}

//________________________________________________________________________________________
- (void) viewDidLoad
{
   [super viewDidLoad];
	// Do any additional setup after loading the view.
}

//________________________________________________________________________________________
- (void) didReceiveMemoryWarning
{
   [super didReceiveMemoryWarning];
   // Dispose of any resources that can be recreated.
}

//________________________________________________________________________________________
- (void) viewWillAppear : (BOOL) animated
{
   [super viewWillAppear : animated];
  
   //We need a nice smooth shadow under our table.
   self.view.layer.shadowOpacity = 0.75f;
   self.view.layer.shadowRadius = 10.f;
   self.view.layer.shadowColor = [UIColor blackColor].CGColor;
  
   if (![self.slidingViewController.underLeftViewController isKindOfClass : [MenuViewController class]])
      self.slidingViewController.underLeftViewController  = [self.storyboard instantiateViewControllerWithIdentifier:@"Menu"];

   [self.view addGestureRecognizer : self.slidingViewController.panGesture];
}

//________________________________________________________________________________________
- (void) cancelAnyConnections
{
   //Cancel all connections in the reversed range [top, self).
   NSEnumerator * const enumerator = [self.viewControllers reverseObjectEnumerator];
   for (id controller in enumerator) {
      if ([controller respondsToSelector : @selector(cancelAnyConnections)])
         [controller performSelector : @selector(cancelAnyConnections)];
   }
}

//________________________________________________________________________________________
- (BOOL) shouldAutorotate
{
   return [self.topViewController shouldAutorotate];
}

//________________________________________________________________________________________
- (NSUInteger) supportedInterfaceOrientations
{
   return [self.topViewController supportedInterfaceOrientations];
}

@end
