#import <Foundation/Foundation.h>

#import "Experiments.h"

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
//This is class to keep references and names for Live Events.
//Unfortunately, this class has to know, what's experiment,
//since for some experiments we do not have normal images
//and have to do stupid tricks to make it work at least somehow.
//
@interface LiveEventsProvider : NSObject<ContentProvider>

- (id) initWith : (NSArray *) images forExperiment : (CernAPP::LHCExperiment) experiment;

- (NSString *) categoryName;
- (UIImage *) categoryImage;

- (void) addPageWithContentTo : (MultiPageController *) controller;
- (void) loadControllerTo : (UINavigationController *) controller;
- (void) loadControllerTo : (UINavigationController *) controller selectedImage : (unsigned) selected;

@end
