//
//In our new sliding view GUI, I can not have table view controller as a "top level" controller,
//it should be a child of navigation controller.
//NewsTableNavigationController is a parent for NewsTableViewController.
//

#import <UIKit/UIKit.h>

#import "Experiments.h"

@interface MenuNavigationController : UINavigationController

- (void) addFeed : (NSString *) feed withName : (NSString *) feedName;
- (void) setExperiment : (CernAPP::LHCExperiment) experiment;
- (void) setStaticInfo : (NSArray *) staticInfo withTitle : (NSString *) sectionName;
- (void) setTableStaticInfo : (NSArray *) staticInfo withTitle : (NSString *) sectionName;

@end
