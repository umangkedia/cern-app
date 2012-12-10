//Author: Timur Pocheptsov.
//Developed for CERN app.

//This is a code for a table view controller, which shows an author, a title, and a date for
//an every news item.
//It can be used ONLY for iPhone/iPod touch device, for iPad we'll have different approach.

#import <Availability.h>

#import <UIKit/UIKit.h>

#import "PullRefreshTableViewController.h"
#import "PageControllerProtocol.h"
#import "RSSAggregator.h"
#import "MBProgressHUD.h"

//TODO: replace MBProgressHUD with a standard indicator.

#ifdef __IPHONE_6_0

@interface NewsTableViewController : UITableViewController<UITableViewDataSource, UITableViewDelegate, RSSAggregatorDelegate, MBProgressHUDDelegate, PageController>

#else

@interface NewsTableViewController : PullRefreshTableViewController<UITableViewDataSource, UITableViewDelegate, RSSAggregatorDelegate, MBProgressHUDDelegate, PageController>

#endif

//From PageController protocol:
- (void) reloadPage;
@property (nonatomic) BOOL pageLoaded;



#ifdef __IPHONE_6_0
//In some cases, we want to disable refresh control.
//TODO: this should be re-factored: even
//for bulletin we need a refresh.
@property (nonatomic) BOOL enableRefresh;
#endif

@property NSRange rangeOfArticlesToShow;

@property __weak UINavigationController *navigationControllerForArticle;
@property (nonatomic, strong) RSSAggregator *aggregator;

@end
