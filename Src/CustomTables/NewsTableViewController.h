//Author: Timur Pocheptsov.
//Developed for CERN app.

//This is a code for a table view controller, which shows an author, a title, and a date for
//an every news item.
//It can be used ONLY for iPhone/iPod touch device, for iPad we'll have a different approach.

#import <Availability.h>

#import <UIKit/UIKit.h>

#import "PageControllerProtocol.h"
#import "ConnectionController.h"
#import "ImageDownloader.h"
#import "RSSAggregator.h"
#import "MBProgressHUD.h"

@interface NewsTableViewController : UITableViewController<UITableViewDataSource, UITableViewDelegate,
                                                           RSSAggregatorDelegate, PageController,
                                                           ImageDownloaderDelegate, ConnectionController>
{
@protected
   UIActivityIndicatorView *spinner;
   MBProgressHUD *noConnectionHUD;
}

+ (NSString *) firstImageURLFromHTMLString : (NSString *) htmlString;

//From PageController protocol:
- (void) reloadPage;
- (void) reloadPageFromRefreshControl;


@property (nonatomic) BOOL pageLoaded;
@property (nonatomic, strong) RSSAggregator *aggregator;

- (IBAction) revealMenu : (id) sender;

@end
