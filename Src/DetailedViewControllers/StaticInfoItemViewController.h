//
//  StaticInfoItemViewController.h
//  CERN App
//
//  Created by Eamon Ford on 7/17/12.
//  Copyright (c) 2012 CERN. All rights reserved.
//

#import <UIKit/UIKit.h>

//#import "MWPhotoBrowser.h"

@interface StaticInfoItemViewController : UIViewController {//<MWPhotoBrowserDelegate> {
   IBOutlet UIScrollView *scrollView;
   IBOutlet UIImageView *imageView;
   IBOutlet UILabel *descriptionLabel;
   IBOutlet UILabel *titleLabel;
}

@property (nonatomic) __weak NSDictionary *staticInfo;

- (void) setAndPositionInformation;

@end
