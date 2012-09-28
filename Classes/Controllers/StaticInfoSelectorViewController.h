//
//  AboutTableViewController.h
//  CERN App
//
//  Created by Eamon Ford on 7/18/12.
//  Copyright (c) 2012 CERN. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface StaticInfoSelectorViewController : UITableViewController
{
    NSArray *tableDataSource;
    NSString *currentTitle;
    NSInteger currentLevel;
    NSIndexPath *currentlyShowingIndexPath;
}

@property (nonatomic, strong) NSArray *tableDataSource;
@property (nonatomic, strong) NSString *currentTitle;
@property (nonatomic, readwrite) NSInteger currentLevel;
@property (nonatomic, strong) NSIndexPath *currentlyShowingIndexPath;
@end
