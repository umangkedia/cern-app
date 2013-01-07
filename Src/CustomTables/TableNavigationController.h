//
//In our new sliding view GUI, I can not have table view controller as a "top level" controller,
//it should be a child of navigation controller.
//NewsTableNavigationController is a parent for NewsTableViewController.
//

#import <UIKit/UIKit.h>

#import "Experiments.h"

@interface TableNavigationController : UINavigationController

- (void) addFeed : (NSString *) feed;
- (void) setExperiment : (CernAPP::LHCExperiment) experiment;

@end