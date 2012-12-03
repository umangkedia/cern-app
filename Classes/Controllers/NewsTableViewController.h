//Author: Timur Pocheptsov.
//Developed for CERN app.

//This is a code for a table view controller, which shows an author, a title, and a date for
//an every news item.
//It can be used ONLY for iPhone/iPod touch device, for iPad we'll have different approach.

#import <UIKit/UIKit.h>

#import "RSSGridViewController.h"
#import "PageController.h"

@interface NewsTableViewController : RSSTableViewController<PageController>

//From PageController protocol:
- (void) refresh;

@property NSRange rangeOfArticlesToShow;

//From PageController protocol:
@property (nonatomic) BOOL loaded;

@property __weak UINavigationController *navigationControllerForArticle;

@end
