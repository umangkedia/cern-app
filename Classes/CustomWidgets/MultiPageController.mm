//
//  Created by Timur Pocheptsov on 11/7/12.
//  Copyright (c) 2012 Timur Pocheptsov. All rights reserved.
//

#import <cstdlib>

#import "MultiPageController.h"
#import "ScrollSelector.h"

@implementation MultiPageController {
   UIScrollView *navigationView;
   ScrollSelector *selector;
   
   NSMutableArray *tableControllers;
}

- (BOOL) shouldAutorotate
{
   return NO;
}

- (void)viewDidLoad
{
   [super viewDidLoad];
   
   const CGRect frame = self.view.frame;
   selector = [[ScrollSelector alloc] initWithFrame:CGRectMake(0.f, 0.f, frame.size.width, [ScrollSelector defaultHeight])];
   [self.view addSubview : selector];
   
   //Items must be added into the selector.
   
   selector.delegate = self;
	// Do any additional setup after loading the view, typically from a nib.

   CGRect tableFrame = CGRectMake(0., [ScrollSelector defaultHeight], 320.f, frame.size.height - [ScrollSelector defaultHeight]);

   navigationView = [[UIScrollView alloc] initWithFrame : tableFrame];
   navigationView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin |
                                     UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
   navigationView.backgroundColor = [UIColor darkTextColor];
   navigationView.delegate = self;

   [self.view addSubview : navigationView];

   //News tables must be added into the navigationView.
   /*
   tableFrame.origin = CGPointZero;
   
   tableControllers = [[NSMutableArray alloc] init];

   for (unsigned i = 0; i < 5; ++i) {
      tableFrame.origin.x = i * tableFrame.size.width;

      TableController *c = [[TableController alloc] initWithStyle : UITableViewStylePlain];
      c.tableView.frame = tableFrame;
      c.tableView.backgroundColor = [UIColor colorWithRed : (rand() % 256 / 256.) green : (rand() % 256 / 256.) blue : (rand() % 256 / 256.) alpha : 1];
      c.tableView.delegate = c;
      c.tableView.dataSource = c;
      [navigationView addSubview : c.tableView];
      [tableControllers addObject : c];
   }
   */
   
   navigationView.canCancelContentTouches = NO;
   navigationView.delaysContentTouches = YES;
   navigationView.contentOffset = CGPointZero;
   navigationView.contentSize = CGSizeMake(tableFrame.size.width * 5, tableFrame.size.height);
   navigationView.showsHorizontalScrollIndicator = NO;
   navigationView.showsVerticalScrollIndicator = NO;
   navigationView.pagingEnabled = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - ScrollSelectorDelegate

- (void) item : (unsigned int) item selectedIn : (ScrollSelector *) selector
{
   //Item was selected by scrolling the "selector wheel".
   const CGPoint newOffset = CGPointMake(item * navigationView.frame.size.width, 0.f);
   [navigationView setContentOffset:newOffset animated : YES];
}

#pragma mark - UIScrollViewDelegate

- (void) scrollViewDidEndDecelerating : (UIScrollView *) sender
{
   //Page scrolled, adjust selector now.
   const unsigned nPage = navigationView.contentOffset.x / navigationView.frame.size.width;
   [selector setSelectedItem : nPage];
}

@end
