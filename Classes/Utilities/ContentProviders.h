#import <Foundation/Foundation.h>

@class MultiPageController;

//
//
//
@protocol ContentProvider <NSObject>
@optional

- (NSString *) categoryName;
- (UIImage *) categoryImage;

- (void) addPageWithContentTo : (MultiPageController *) controller;
- (void) loadControllerTo : (UINavigationController *) controller;

@end

//
//
//
@interface FeedProvider : NSObject<ContentProvider>

- (id) initWith : (NSDictionary *) feedInfo;

- (NSString *) categoryName;
- (UIImage *) categoryImage;

- (void) addPageWithContentTo : (MultiPageController *) controller;
- (void) loadControllerTo : (UINavigationController *) controller;

@end

//
//
//

/*
@interface LiveEventsProvider : NSObject<ContentProvider>

- (NSString *) categoryName;
- (UIImage *) categoryImage;

- (void) addPageWithContentTo : (MultiPageController *) controller;
- (void) loadControllerTo : (UINavigationController *) controller;

@end
*/