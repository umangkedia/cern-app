//
//  PhotoBrowserProtocol.h
//  CERN
//
//  Created by Timur Pocheptsov on 2/12/13.
//  Copyright (c) 2013 CERN. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MWPhoto;

@protocol PhotoBrowserProtocol <NSObject>

- (UIImage *) imageForPhoto : (id<MWPhoto>) photo;
- (void) cancelControlHiding;
- (void) hideControlsAfterDelay;
- (void) toggleControls;

@required

@end
