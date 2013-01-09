#import <cassert>

#import "TableNavigationController.h"
#import "NewsTableViewController.h"
#import "LiveTableViewController.h"
#import "ECSlidingViewController.h"
#import "MenuViewController.h"

@implementation TableNavigationController

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
- (void) addFeed : (NSString *) feed withName : (NSString *) feedName
{
   assert(feed != nil && "addFeed:, parameter 'feed' is nil");
   assert(feedName != nil && "addFeed:, parameter 'feedName' is nil");
   assert([self.topViewController isKindOfClass : [NewsTableViewController class]] &&
          "addFeed:, topViewController is either nil, or has a wrong type - not a NewsTableViewController");

   NewsTableViewController * const nt = (NewsTableViewController *)self.topViewController;
   nt.navigationItem.title = feedName;
   [nt.aggregator addFeedForURL : [NSURL URLWithString:feed]];
}

//________________________________________________________________________________________
- (void) setExperiment : (CernAPP::LHCExperiment) experiment
{
   assert([self.topViewController isKindOfClass:[LiveTableViewController class]] &&
          "setExperiment:, topViewController is either nil, or has a wrong type - not a LiveTableViewController");

   LiveTableViewController * const lt = (LiveTableViewController *)self.topViewController;
   lt.experiment = experiment;
}

@end
