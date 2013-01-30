//
//  WebcastsGridViewController.h
//  CERN App
//
//  Created by Eamon Ford on 8/16/12.
//  Copyright (c) 2012 CERN. All rights reserved.
//


#import "WebcastsParser.h"
#import "MBProgressHUD.h"

enum WebcastMode {
    WebcastModeRecent,
    WebcastModeUpcoming
};

@interface WebcastsGridViewController : UICollectionViewController<WebcastsParserDelegate, MBProgressHUDDelegate>

@property (nonatomic, strong) WebcastsParser *parser;
@property BOOL finishedParsingRecent;
@property BOOL finishedParsingUpcoming;
@property WebcastMode mode;

- (void) refresh;
- (IBAction) segmentedControlTapped : (UISegmentedControl *) sender;

@end
