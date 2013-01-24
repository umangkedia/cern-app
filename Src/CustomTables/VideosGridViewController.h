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
#import "MBProgressHUD.h"

@interface VideosGridViewController : UICollectionViewController<CernMediaMarcParserDelegate, MBProgressHUDDelegate>

@property (nonatomic, strong) CernMediaMARCParser *parser;
@property (nonatomic, strong) NSMutableArray *videoMetadata;
@property (nonatomic, strong) NSMutableDictionary *videoThumbnails;

- (void)refresh;
@end
