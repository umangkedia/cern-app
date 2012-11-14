//
//  RSSGridViewController.h
//  CERN App
//
//  Created by Eamon Ford on 8/9/12.
//  Copyright (c) 2012 CERN. All rights reserved.
//

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

@interface RSSTableViewController : PullRefreshTableViewController<UITableViewDataSource, UITableViewDelegate, RSSAggregatorDelegate, MBProgressHUDDelegate>
//UITableViewController<UITableViewDataSource, UITableViewDelegate, RSSAggregatorDelegate, MBProgressHUDDelegate>

@property (nonatomic, strong) RSSAggregator *aggregator;
- (void) refresh;

@end
