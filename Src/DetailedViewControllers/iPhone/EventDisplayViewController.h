//
//  EventDisplayViewController.h
//  CERN App
//
//  Created by Eamon Ford on 7/15/12.
//  Copyright (c) 2012 CERN. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PageControllerProtocol.h"
#import "PhotoBrowserProtocol.h"
#import "MBProgressHUD.h"

@interface EventDisplayViewController : UIViewController<NSURLConnectionDelegate, PageController,
                                                         MBProgressHUDDelegate, UIScrollViewDelegate,
                                                         PhotoBrowserProtocol>
{
   IBOutlet UIScrollView *scrollView;
   IBOutlet UIPageControl *pageControl;
   UILabel *titleLabel;
   UILabel *dateLabel;

   NSMutableArray *sources;
   int numPages;
}

- (void) refresh;

//PageController protocol:
- (void) reloadPage;
- (void) reloadPageFromRefreshControl;
@property (nonatomic) BOOL pageLoaded;
@property (nonatomic, assign) BOOL needsRefreshButton;

@property (nonatomic, strong) NSMutableArray *sources;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIPageControl *pageControl;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *dateLabel;

// This method should be called immediately after init, and before viewDidLoad gets called.
- (void) addSourceWithDescription : (NSString *) description URL : (NSURL *) url boundaryRects : (NSArray *) boundaryRects;
- (IBAction)refresh : (id)sender;

- (void) scrollToPage : (NSInteger) page;
//For sliding menu.
- (IBAction) revealMenu : (id) sender;

@end
