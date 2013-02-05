//
//  BtnView.h
//  FBT
//
//  Created by Timur Pocheptsov on 2/5/13.
//  Copyright (c) 2013 Timur Pocheptsov. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PictureButtonView : UIView

- (id) initWithFrame : (CGRect) frame image : (UIImage *) image;
- (void) addTarget : (NSObject *) target selector : (SEL) selector;

@end
