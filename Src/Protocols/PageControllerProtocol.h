//
//  PageController.h
//  CERN
//
//  Created by Timur Pocheptsov on 12/3/12.
//  Copyright (c) 2012 CERN. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol PageController <NSObject>

@required

- (void) reloadPage;
- (void) reloadPageFromRefreshControl;

@optional

@property (nonatomic) BOOL pageLoaded;
@property (nonatomic, assign) BOOL needsRefreshButton;

@end
