//
//  RSSGridViewController.h
//  CERN App
//
//  Created by Eamon Ford on 8/9/12.
//  Copyright (c) 2012 CERN. All rights reserved.
//

#import <Availability.h>

#import "PullRefreshTableViewController.h"
#import "AQGridViewController.h"
#import "RSSAggregator.h"
#import "MBProgressHUD.h"

@interface RSSGridViewController : AQGridViewController<AQGridViewDataSource, AQGridViewDelegate, RSSAggregatorDelegate, MBProgressHUDDelegate>
{
    MBProgressHUD *_noConnectionHUD;
}
@property (nonatomic, strong) RSSAggregator *aggregator;
- (void)refresh;

@end

#ifdef __IPHONE_6_0
@interface RSSTableViewController : UITableViewController<UITableViewDataSource, UITableViewDelegate, RSSAggregatorDelegate, MBProgressHUDDelegate>
#else
@interface RSSTableViewController : PullRefreshTableViewController<UITableViewDataSource, UITableViewDelegate, RSSAggregatorDelegate, MBProgressHUDDelegate>
#endif

@property (nonatomic, strong) RSSAggregator *aggregator;
- (void) refresh;

@end
