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
@property (nonatomic) BOOL pageLoaded;

@optional
@property (nonatomic, assign) BOOL needsRefreshButton;

@end
