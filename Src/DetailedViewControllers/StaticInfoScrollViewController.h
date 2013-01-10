//
//  PageContainingViewController.h
//  CERN App
//
//  Created by Eamon Ford on 7/26/12.
//  Copyright (c) 2012 CERN. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "StaticInfoItemViewController.h"

@interface StaticInfoScrollViewController : UIViewController {
   IBOutlet UIScrollView *scrollView;
   IBOutlet UIPageControl *pageControl;
}

@property (nonatomic) __weak NSArray *dataSource;

- (void)refresh;
- (StaticInfoItemViewController *)viewControllerForPage:(int)page;


- (IBAction)revealMenu : (id) sender;
@end
