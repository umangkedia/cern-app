#import <UIKit/UIKit.h>

#import "PageControllerProtocol.h"
#import "ConnectionController.h"

@class LiveEventsProvider;

//Now we want to be able to have a table with different LIVE events in different cells.
//Each cell will have a name and image (small version of an original image) + (possibly) date.
//Images to be reused by EventDisplayViewController later (if they were loaded already,
//if not - they have to be loaded by EventDisplayViewController.

@interface LiveEventTableController : UITableViewController<NSURLConnectionDelegate, UITableViewDataSource, UITableViewDelegate,
                                                            PageController, ConnectionController>

//These are the keys to be used when setting table's data -
//array of dictionaries.
+ (NSString *) nameKey;
+ (NSString *) urlKey;

//Content provider and LiveEventTableController share the 'contents' array.
- (void) setTableContents : (NSArray *) contents experimentName : (NSString *) name;

- (void) refresh;

//PageController protocol.
- (void) reloadPage;
- (void) reloadPageFromRefreshControl;
@property (nonatomic) BOOL pageLoaded;

@property (nonatomic) __weak LiveEventsProvider *provider;
@property (nonatomic) __weak UINavigationController *navController;

- (IBAction) revealMenu : (id) sender;

@end
