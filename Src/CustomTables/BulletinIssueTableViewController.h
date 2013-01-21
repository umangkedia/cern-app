//
//  BulletinIssueTableViewController.h
//  CERN
//
//  Created by Timur Pocheptsov on 1/21/13.
//  Copyright (c) 2013 CERN. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MWFeedItem;

@interface BulletinIssueTableViewController : UITableViewController<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) __weak NSArray *tableData;

- (void) reloadRowFor : (MWFeedItem *) article;

@end
