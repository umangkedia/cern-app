//Author: Timur Pocheptsov.
//Developed for CERN app.

//This is a code for a table view controller, which shows an author, a title, and a date for
//an every news item.
//It can be used ONLY for iPhone/iPod touch device, for iPad we'll have different approach.

#import <Availability.h>

#import <UIKit/UIKit.h>

#import "PageControllerProtocol.h"
#import "RSSGridViewController.h"


@interface NewsTableViewController : RSSTableViewController<PageController>

- (void) refresh;

//From PageController protocol:
- (void) reloadPage;

#ifdef __IPHONE_6_0
@property (nonatomic) BOOL enableRefresh;
#endif

@property NSRange rangeOfArticlesToShow;

//From PageController protocol:
@property (nonatomic) BOOL pageLoaded;

@property __weak UINavigationController *navigationControllerForArticle;

@end
