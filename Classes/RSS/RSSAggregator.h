//
//  RSSAggregator.h
//  CERN App
//
//  Created by Eamon Ford on 5/31/12.
//  Copyright (c) 2012 CERN. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RSSFeed.h"

@class RSSAggregator;
@protocol RSSAggregatorDelegate <NSObject>

@optional
- (void)allFeedsDidLoadForAggregator:(RSSAggregator *)aggregator;
- (void)aggregator:(RSSAggregator *)aggregator didFailWithError:(NSError *)error;
- (void)aggregator:(RSSAggregator *)aggregator didDownloadFirstImage:(UIImage *)image forArticle:(MWFeedItem *)article;

@end

@interface RSSAggregator : NSObject<RSSFeedDelegate>
{
    @private
    int _feedLoadCount;
    int _feedFailCount;
}

@property (nonatomic, strong) NSMutableArray *feeds;
@property (nonatomic, strong) id<RSSAggregatorDelegate> delegate;
@property (nonatomic, strong) NSArray *allArticles;
@property (nonatomic, strong) NSMutableDictionary *firstImages;

/*
   NSArray *sortedArray = [
                           data sortedArrayUsingComparator : ^NSComparisonResult(id a, id b) {
                           return [((CellData *)a).date compare : ((CellData*)b).date];}
                          ];
*/

- (void) addFeed : (RSSFeed *) feed;
- (void) addFeedForURL : (NSURL *) url;
- (void) refreshAllFeeds;
- (UIImage *) firstImageForArticle : (MWFeedItem *) article;
- (RSSFeed *) feedForArticle : (MWFeedItem *) article;

@end