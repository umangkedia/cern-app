#import <Foundation/Foundation.h>

#import "Experiments.h"

//
//The base class for content providers.
//
@protocol ContentProvider <NSObject>
@optional

- (UIImage *) categoryImage;

- (void) loadControllerTo : (UIViewController *) controller;
- (void) pushViewControllerInto : (UINavigationController *) navController;
@property (nonatomic, retain) NSString *categoryName;

@end

//
//I'm using this class, at the moment, for news feeds and tweets.
//
@interface FeedProvider : NSObject<ContentProvider>

- (id) initWith : (NSDictionary *) feedInfo;

@property (nonatomic, retain) NSString *categoryName;

- (UIImage *) categoryImage;

- (void) loadControllerTo : (UIViewController *) controller;
- (void) pushViewControllerInto : (UINavigationController *) navController;

@end

@interface PhotoSetProvider : NSObject<ContentProvider>

- (id) initWithDictionary : (NSDictionary *) info;

@property (nonatomic, retain) NSString *categoryName;

- (UIImage *) categoryImage;

- (void) loadControllerTo : (UIViewController *) controller;
- (void) pushViewControllerInto : (UINavigationController *) navController;

@end

//
//This is class to keep references and names for Live Events.
//
@interface LiveEventsProvider : NSObject<ContentProvider>

- (id) initWith : (NSArray *) dataEntry forExperiment : (CernAPP::LHCExperiment) experiment;

@property (nonatomic, retain) NSString *categoryName;

- (UIImage *) categoryImage;

- (void) loadControllerTo : (UIViewController *) controller;
- (void) pushViewControllerInto : (UINavigationController *) navController;
- (void) pushEventDisplayInto : (UINavigationController *) controller selectedImage : (NSInteger) selected;

@end

//
//Info about live event image.
//
@interface LiveImageData : NSObject

- (id) initWithName : (NSString *) name url : (NSString *) imageUrl bounds : (CGRect) imageBounds;

@property (nonatomic, readonly) NSString *imageName;
@property (nonatomic, readonly) NSString *url;
@property (nonatomic, retain) UIImage *image;
@property (nonatomic, readonly) CGRect bounds;

@end
