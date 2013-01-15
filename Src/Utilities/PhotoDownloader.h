//
//  PhotoDownloader.h
//  CERN App
//
//  Created by Eamon Ford on 7/4/12.
//  Copyright (c) 2012 CERN. All rights reserved.
//

//The code was modified/fixed to at least some working state by Timur Pocheptsov.

#import <Foundation/Foundation.h>
#import "CernMediaMARCParser.h"

@class PhotoDownloader;

@protocol PhotoDownloaderDelegate <NSObject>
@optional
- (void) photoDownloaderDidFinish : (PhotoDownloader *) photoDownloader;
- (void) photoDownloader : (PhotoDownloader *) photoDownloader didDownloadThumbnailForIndex : (int) index;
- (void) photoDownloader : (PhotoDownloader *) photoDownloader didFailWithError : (NSError *) error;
@end

@interface PhotoDownloader : NSObject<CernMediaMarcParserDelegate, NSURLConnectionDataDelegate>

- (void) parse;

@property (nonatomic, strong) NSMutableArray *urls;
@property (nonatomic, strong) NSMutableDictionary *thumbnails;
@property (nonatomic, strong) NSURL *url;
@property (nonatomic) __weak id<PhotoDownloaderDelegate> delegate;
@property (nonatomic, assign) BOOL isDownloading;

- (bool) hasConnection;
- (void) stop;

@end
