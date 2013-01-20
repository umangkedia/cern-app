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

@end
