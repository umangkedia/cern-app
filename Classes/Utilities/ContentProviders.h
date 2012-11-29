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
//I'm using this class, at the moment, for news feeds and tweets.
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