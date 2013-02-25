//
//  WebcastsGridViewController.h
//  CERN App
//
//  Created by Eamon Ford on 8/16/12.
//  Copyright (c) 2012 CERN. All rights reserved.
//


#import "ConnectionController.h"
#import "ImageDownloader.h"
#import "WebcastsParser.h"


@interface WebcastsGridViewController : UICollectionViewController<WebcastsParserDelegate, ConnectionController,
                                                                   ImageDownloaderDelegate>

- (IBAction) refresh : (id) sender;
- (IBAction) revealMenu : (id) sender;

@end
