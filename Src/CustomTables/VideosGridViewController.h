//
//  VideosGridViewController.h
//  CERN App
//
//  Created by Eamon Ford on 8/9/12.
//  Copyright (c) 2012 CERN. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ConnectionController.h"
#import "CernMediaMARCParser.h"
#import "ImageDownloader.h"
#import "MBProgressHUD.h"

@interface VideosGridViewController : UICollectionViewController<CernMediaMarcParserDelegate, MBProgressHUDDelegate, ImageDownloaderDelegate, ConnectionController,
                                                                 UICollectionViewDataSource, UICollectionViewDelegate>

- (IBAction)refresh : (id) sender;
- (IBAction) revealMenu : (id) sender;

@end
