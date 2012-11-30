//
//  LiveEventTableController.m
//  CERN
//
//  Created by Timur Pocheptsov on 11/30/12.
//  Copyright (c) 2012 CERN. All rights reserved.
//

#import <cassert>

#import "LiveEventTableController.h"
#import "NewsTableViewCell.h"

namespace {

enum ControllerMode {
   kLIVEEventOneImage,
   kLIVEEventManyImages
};

}

@interface LiveImageData : NSObject

@property (nonatomic, readonly) NSString *imageName;
@property (nonatomic, readonly) NSString *url;
@property (nonatomic, retain) UIImage *image;
@property (nonatomic, readonly) CGRect bounds;

@end

@implementation LiveImageData

@synthesize imageName, url, image,bounds;

//________________________________________________________________________________________
- (id) initWithName : (NSString *) name url : (NSString *) imageUrl bounds : (CGRect) imageBounds
{
   if (self = [super init]) {
      imageName = name;
      url = imageUrl;
      image = nil;//to be loaded yet!
      bounds = imageBounds;
   }
   
   return self;
}

@end


//
//
//

@implementation LiveEventTableController {
   ControllerMode mode;
   NSMutableArray *tableData;
   unsigned imageToLoad;
   NSURLConnection *connection;
   NSMutableData *imageData;
   NSString *sourceName;
}

@synthesize loaded;

//________________________________________________________________________________________
+ (NSString *) nameKey
{
   return @"ImageName";
}

//________________________________________________________________________________________
+ (NSString *) urlKey
{
   return @"Url";
}

#pragma mark - Initialization.

//________________________________________________________________________________________
- (id) initWithStyle : (UITableViewStyle) style
{
   //
   if (self = [super initWithStyle : style]) {
      mode = kLIVEEventManyImages;//Is there any guarantee this method is called at all? :(
   }

   return self;
}

//________________________________________________________________________________________
- (void) setTableContents : (NSArray *) contents experimentName : (NSString *)name
{
   assert(contents != nil && "setTableContents:, contents parameter is nil");
   assert(name != nil && "setTableContents:, name parameter is nil");

   if (tableData)
      [tableData removeAllObjects];
   else
      tableData = [[NSMutableArray alloc] init];

   mode = kLIVEEventManyImages;
   sourceName = name;
   
   loaded = NO;
   
   for (id imageDesc in contents) {
      assert([imageDesc isKindOfClass : [NSDictionary class]] && "setTableContents:, array of dictionaries expected");
      NSDictionary * const dict = (NSDictionary *)imageDesc;
      
      id base = [dict objectForKey:[LiveEventTableController nameKey]];
      NSLog(@"base is %@", base);
      assert([base isKindOfClass : [NSString class]] && "Image name must be a string object");
      
      NSString * const name = (NSString *)base;

      base = [dict objectForKey : [LiveEventTableController urlKey]];
      assert([base isKindOfClass : [NSString class]] && "Url for an image must be a string");
      NSString * const url = (NSString *)base;
      
      LiveImageData * const newImage = [[LiveImageData alloc] initWithName : name url : url bounds : CGRect()];
      [tableData addObject : newImage];
   }
}

//________________________________________________________________________________________
- (void) setTableContentsFromImage : (NSString *) url cellNames : (NSArray *) names imageBounds : (const CGRect *) bounds experimentName : (NSString *) name
{
   assert(url != nil && "setTableContentsFromImage:cellNames:imageBounds:, url parameter is nil");
   assert(names != nil && "setTableContentsFromImage:cellNames:imageBounds:, names parameter is nil");
   assert(bounds != nil && "setTableContentsFromImage:cellNames:imageBounds:, bounds parameter is nil");
   assert(name != nil && "setTableContentsFromImage:cellNames:imageBounds:, name parameter is nil");
   
   if (tableData)
      [tableData removeAllObjects];
   else
      tableData = [[NSMutableArray alloc] init];
   
   loaded = NO;

   mode = kLIVEEventOneImage;
   sourceName = name;

   unsigned i = 0;//quite ugly :)
   for (id imageDesc in names) {
      assert([imageDesc isKindOfClass : [NSString class]] && "setTableContentsFromImage:cellNames:imageBounds:, array of strings expected");
      NSString * const name = (NSString *)imageDesc;
      LiveImageData * const newImage = [[LiveImageData alloc] initWithName : name url : url bounds : bounds[i]];
      [tableData addObject : newImage];
      ++i;
   }
}

//________________________________________________________________________________________
- (void) viewDidLoad
{
   [super viewDidLoad];
}


#pragma mark - Data management.

//________________________________________________________________________________________
- (void) refresh
{
   //Here we start loading images one by one, asynchronously (next load only started after the
   //previous finished of failed). Nothing is changed except images and probably dates.
   
   loaded = NO;
   
   if ([tableData count]) {
      [self.tableView reloadData];

      if (connection)
         [connection cancel];

      imageToLoad = 0;
      //
      LiveImageData *liveImageData = (LiveImageData *)[tableData objectAtIndex : 0];
      
      NSURL * const url = [[NSURL alloc] initWithString : liveImageData.url];

      imageData = [[NSMutableData alloc] init];
      connection = [[NSURLConnection alloc] initWithRequest : [NSURLRequest requestWithURL : url] delegate : self];
   }
}

//________________________________________________________________________________________
- (void) didReceiveMemoryWarning
{
   [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

//________________________________________________________________________________________
- (NSInteger) numberOfSectionsInTableView : (UITableView *) tableView
{
   // Return the number of sections.
   return 1;
}

//________________________________________________________________________________________
- (NSInteger) tableView : (UITableView *) tableView numberOfRowsInSection : (NSInteger) section
{
   return [tableData count];//even if tableData is nil, this will be 0.
}

//________________________________________________________________________________________
- (UITableViewCell *) tableView : (UITableView *) tableView cellForRowAtIndexPath : (NSIndexPath *) indexPath
{
   //Find feed item first.
   const NSInteger row = indexPath.row;
   assert(row >= 0 && row < [tableData count] && "tableView:cellForRowAtIndexPath:, row must be in the range [0, [tableData count])");
   LiveImageData * const liveData = (LiveImageData *)[tableData objectAtIndex : row];

   static NSString *CellIdentifier = @"NewsCell";
   
   //Why do not I have compilation error (warning at least)? And get runtime error on non-existing selector instead?
   //Apple always thinks different.
   //NewsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier : CellIdentifier forIndexPath : indexPath];

   NewsTableViewCell *cell = (NewsTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier : CellIdentifier];
   if (!cell)
      cell = [[NewsTableViewCell alloc] initWithFrame : [NewsTableViewCell defaultCellFrame]];

   [cell setCellData : liveData.imageName source : sourceName image : liveData.image imageOnTheRight : (indexPath.row % 4) == 3];

   return cell;
}

//________________________________________________________________________________________
- (CGFloat) tableView : (UITableView *) tableView heightForRowAtIndexPath : (NSIndexPath *) indexPath
{
   const NSInteger row = indexPath.row;
   assert(row >= 0 && row < [tableData count] && "tableView:heightForRowAtIndexPath:, indexPath.row is out of bounds");

   LiveImageData * const liveData = (LiveImageData *)[tableData objectAtIndex : row];
   return [NewsTableViewCell calculateCellHeightForText : liveData.imageName source : sourceName image : liveData.image imageOnTheRight : (indexPath.row % 4) == 3];
}

#pragma mark - Table view delegate

//________________________________________________________________________________________
- (void) tableView : (UITableView *) tableView didSelectRowAtIndexPath : (NSIndexPath *) indexPath
{
   //
}

#pragma mark - NSURLConnection delegate

//________________________________________________________________________________________
- (void) connection : (NSURLConnection *) connection didReceiveData : (NSData *)data
{
   [imageData appendData : data];
}

//________________________________________________________________________________________
- (void) connectionDidFinishLoading : (NSURLConnection *) urlConnection
{
   assert(imageData != nil && "connectionDidFinishLoading:, imageData is nil");
   assert(tableData != nil && [tableData count] && "connectionDidFinishLoading:, tableData is either nil or empty");
   assert(imageToLoad < [tableData count] && "connectionDidFinishLoading:, imageToLoad index is out of bounds");
   
   (void) urlConnection;

   //Woo-hoo! We've got an image!(??)
   UIImage *newImage = nil;
   if ([imageData length])
      newImage = [UIImage imageWithData : imageData];
   
   if (mode == kLIVEEventManyImages) {
      LiveImageData *liveImageData = (LiveImageData *)[tableData objectAtIndex : imageToLoad];
      if (newImage) {
         liveImageData.image = newImage;
         //Now:
         //a) reload table's row.
         NSUInteger path[2] = {0, imageToLoad};//Row to update in a table view.
         NSIndexPath * const indexPath = [NSIndexPath indexPathWithIndexes : path length : 2];
         NSArray *indexPaths = [NSArray arrayWithObject : indexPath];
         [self.tableView reloadRowsAtIndexPaths : indexPaths withRowAnimation : UITableViewRowAnimationNone];
      }
      
      //Now, should we download another image?
      if (imageToLoad + 1 < [tableData count]) {
         ++imageToLoad;
         liveImageData = (LiveImageData *)[tableData objectAtIndex : imageToLoad];
         NSURL * const url = [[NSURL alloc] initWithString : liveImageData.url];
         imageData = [[NSMutableData alloc] init];
         connection = [[NSURLConnection alloc] initWithRequest : [NSURLRequest requestWithURL : url] delegate : self];
      } else
         loaded = YES;
   } else {
      //Now we have to cut sub-images.
      for (LiveImageData *liveData in tableData) {
         //Strange, that UIImage does not have a ctor from another UIImage and rect.
         //So we need all this gymnastics.
         CGImageRef imageRef(CGImageCreateWithImageInRect(newImage.CGImage, liveData.bounds));
         if (imageRef)
            liveData.image = [UIImage imageWithCGImage : imageRef];
      }
      
      imageData = nil;
      connection = nil;
      
      loaded = YES;
      
      //Ok, we can update ALL the rows now!
      [self.tableView reloadData];
   }
}

//________________________________________________________________________________________
- (void) connection : (NSURLConnection *) urlConnection didFailWithError : (NSError *) error
{
   assert(tableData != nil && [tableData count] && "connection:didFailWithError:, tableData is either nil or empty");
   assert(imageToLoad < [tableData count] && "connection:didFailWithError:, imageToLoad index is out of bounds");

   (void) urlConnection;
   (void) error;
   
   if (mode == kLIVEEventManyImages) {
      //Ok, let's try to load the next image.
      
      //Now, should we download another image?
      if (imageToLoad + 1 < [tableData count]) {
         ++imageToLoad;
         LiveImageData *liveImageData = (LiveImageData *)[tableData objectAtIndex : imageToLoad];
         NSURL * const url = [[NSURL alloc] initWithString : liveImageData.url];

         imageData = [[NSMutableData alloc] init];
         connection = [[NSURLConnection alloc] initWithRequest : [NSURLRequest requestWithURL : url] delegate : self];
      } else
         loaded = YES;
   } else {
      //Image load failed, nothing to update, no cell has any image.
      loaded = YES;
   }
   
}


@end
