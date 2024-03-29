#import <UIKit/UIKit.h>

#import "PageControllerProtocol.h"
#import "ConnectionController.h"
#import "HUDRefreshProtocol.h"
#import "SlideScrollView.h"
#import "ImageDownloader.h"
#import "RSSAggregator.h"



namespace CernAPP {

enum class ControllerMode : unsigned char {
   feedView,
   bulletinView,
   bulletinIssueView
};

}

@interface FeedTileViewController : UIViewController<HUDRefreshProtocol, RSSAggregatorDelegate, PageController,
                                                     ImageDownloaderDelegate, ConnectionController,
                                                     UIScrollViewDelegate>
{
   IBOutlet SlideScrollView *scrollView;
}

@property (nonatomic) CernAPP::ControllerMode mode;
@property (nonatomic, strong) RSSAggregator *aggregator;
@property (nonatomic, copy) NSString *feedStoreID;//Cache ID.

//ECSlidingViewController:
- (IBAction) revealMenu : (id) sender;

//RSSAggregatorDelegate:
- (void) allFeedsDidLoadForAggregator : (RSSAggregator *) aggregator;
- (void) aggregator : (RSSAggregator *) aggregator didFailWithError : (NSString *) errorDescription;
- (void) lostConnection : (RSSAggregator *) aggregator;

//PageController:
- (void) reloadPage;
- (IBAction) reloadPageFromRefreshControl;

//ImageDownloaderDelegate:
- (void) imageDidLoad : (NSIndexPath *) indexPath;
- (void) imageDownloadFailed : (NSIndexPath *) indexPath;

//Connection controller:
- (void) cancelAnyConnections;

//HUD/GUI
@property (nonatomic, strong) MBProgressHUD *noConnectionHUD;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;

@end