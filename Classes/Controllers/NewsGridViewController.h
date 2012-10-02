//
//  NewsGridViewController.h
//  CERN App
//
//  Created by Eamon Ford on 8/7/12.
//  Copyright (c) 2012 CERN. All rights reserved.
//

#import "AQGridViewController.h"
#import "RSSAggregator.h"
#import "RSSGridViewController.h"

@interface NewsGridViewController : RSSGridViewController
{
    NSRange _rangeOfArticlesToShow;
}

@property NSRange rangeOfArticlesToShow;

@end
