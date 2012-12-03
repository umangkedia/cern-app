#import <UIKit/UIKit.h>

#import "PageController.h"

@class LiveEventsProvider;

//Now we want to be able to have a table with different LIVE events in different cells.
//Each cell will have a name and image (small version of an original image) + (possibly) date.
//Images to be reused by EventDisplayViewController later (if they were loaded already,
//if not - they have to be loaded by EventDisplayViewController.
//Unfortunately, as experiments don't have uniform live event representation,
//this class have to know too much about concrete experiments and the way they
//display live events.

@interface LiveEventTableController : UITableViewController<NSURLConnectionDelegate, UITableViewDataSource, UITableViewDelegate, PageController>

//These are the keys to be used when setting table's data -
//array of dictionaries.
+ (NSString *) nameKey;
+ (NSString *) urlKey;

//'contents' is an array of pairs [url : name].
- (void) setTableContents : (NSArray *) contents experimentName : (NSString *) name;
//This is a _very_ special way to create images: ATLAS have one big png and we cut pieces (front and side view)
//from this big image.
- (void) setTableContentsFromImage : (NSString *) url cellNames : (NSArray *) names imageBounds : (const CGRect *) bounds experimentName : (NSString *) name;

//PageController protocol.
- (void) refresh;
@property (nonatomic) BOOL loaded;

@property (nonatomic) __weak LiveEventsProvider *provider;
@property (nonatomic) __weak UINavigationController *navController;

@end

