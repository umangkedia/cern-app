//
//  PhotosViewController.h
//  CERN App
//
//  Created by Eamon Ford on 6/27/12.
//  Copyright (c) 2012 CERN. All rights reserved.
//

#import "AQGridViewController.h"
#import "PhotoDownloader.h"
#import "MWPhotoBrowser.h"
#import "MBProgressHUD.h"

@interface PhotosGridViewController : AQGridViewController<AQGridViewDataSource, AQGridViewDelegate, MWPhotoBrowserDelegate,
                                                           PhotoDownloaderDelegate, MBProgressHUDDelegate>

@property (nonatomic, strong) PhotoDownloader *photoDownloader;

- (void) refresh;

- (IBAction) revealMenu : (id) sender;

@end
