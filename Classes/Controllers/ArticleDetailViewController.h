//
//  ArticleDetailViewController.h
//  CERN App
//
//  Created by Eamon Ford on 6/18/12.
//  Copyright (c) 2012 CERN. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MWFeedItem.h"

@interface ArticleDetailViewController : UIViewController <UIWebViewDelegate> {
   IBOutlet UIWebView *contentWebView;
}

@property (nonatomic, strong) UIWebView *contentWebView;
@property (nonatomic, strong) NSString *contentString;
@property (nonatomic, assign) BOOL loadOriginalLink;

- (void) setContentForArticle : (MWFeedItem *) article;
- (void) setContentForVideoMetadata : (NSDictionary *) videoMetadata;
- (void) setContentForTweet : (NSDictionary *) tweet;

@end
