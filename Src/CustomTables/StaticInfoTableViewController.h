//
//  StaticInfoTableViewController.h
//  CERN
//
//  Created by Timur Pocheptsov on 1/10/13.
//  Copyright (c) 2013 CERN. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface StaticInfoTableViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) __weak NSArray *staticInfo;

- (IBAction) revealMenu : (id) sender;

@end
