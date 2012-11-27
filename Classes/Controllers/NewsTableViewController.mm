//Author: Timur Pocheptsov.
//Developed for CERN app.

//This is a code for a table view controller, which shows author, title, short content, date for
//an every news item.
//It can be used ONLY for iPhone/iPod touch device, for iPad we'll have different approach.

#import <cassert>

#import "ArticleDetailViewController.h"
#import "NewsTableViewController.h"
#import "NewsTableViewCell.h"
#import "Constants.h"


@implementation NewsTableViewController

@synthesize rangeOfArticlesToShow, loaded, navigationControllerForArticle;

//________________________________________________________________________________________
- (id) initWithCoder : (NSCoder *) aDecoder
{
   if (self = [super initWithCoder : aDecoder]) {
      //
   }

   return self;
}

//________________________________________________________________________________________
- (id) initWithStyle : (UITableViewStyle) style
{
   if (self = [super initWithStyle : style]) {
      //
   }

   return self;
}


//________________________________________________________________________________________
- (void) viewDidLoad
{
   [super viewDidLoad];
   [(UITableView *)self.view reloadData];
}

//________________________________________________________________________________________
- (void) viewDidUnload
{
   [super viewDidUnload];
    // Release any retained subviews of the main view.
}

//________________________________________________________________________________________
- (BOOL) shouldAutorotateToInterfaceOrientation : (UIInterfaceOrientation) interfaceOrientation
{
   if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
      return YES;
   else
      return interfaceOrientation == UIInterfaceOrientationPortrait;
}

//________________________________________________________________________________________
- (void) prepareForSegue : (UIStoryboardSegue *) segue sender : (id)sender
{
   UITableView * const tableView = (UITableView *)self.view;
   NSIndexPath * const indexPath = [tableView indexPathForSelectedRow];

   assert(indexPath != nil && "prepareForSegue:sender:, index path for selected table's row is nil");
   ArticleDetailViewController * const viewController = (ArticleDetailViewController *)segue.destinationViewController;
   //
   viewController.loadOriginalLink = YES;
   //
   const NSUInteger index = rangeOfArticlesToShow.length ? indexPath.row + rangeOfArticlesToShow.location : indexPath.row;
   [viewController setContentForArticle : [self.aggregator.allArticles objectAtIndex : index]];
}

//________________________________________________________________________________________
- (void) didReceiveMemoryWarning
{
   [super didReceiveMemoryWarning];
   // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

//________________________________________________________________________________________
- (NSInteger) numberOfSectionsInTableView : (UITableView *) tableView
{
   // Return the number of sections.
   return 1;
}

//________________________________________________________________________________________
- (void) refresh
{
   self.rangeOfArticlesToShow = NSRange();
   [self.aggregator clearAllFeeds];
   [self.tableView reloadData];
   [super refresh];
}

//________________________________________________________________________________________
- (NSInteger) tableView : (UITableView *) tableView numberOfRowsInSection : (NSInteger) section
{
   // Return the number of rows in the section.   
   if (self.rangeOfArticlesToShow.length)
      return self.rangeOfArticlesToShow.length;
   else
      return self.aggregator.allArticles.count;
}

//________________________________________________________________________________________
- (UITableViewCell *) tableView : (UITableView *) tableView cellForRowAtIndexPath : (NSIndexPath *) indexPath
{
   //Find feed item first.
   const NSInteger row = indexPath.row;
   assert(row >= 0 && row < [self.aggregator.allArticles count]);

   MWFeedItem * const article = [self.aggregator.allArticles objectAtIndex : row + self.rangeOfArticlesToShow.location];
   assert(article != nil && "tableView:cellForRowAtIndexPath:, article was not found");

   static NSString *CellIdentifier = @"NewsCell";
   
   //Why do not I have compilation error (warning at least)? And get runtime error on non-existing selector instead?
   //Apple always thinks different.
   //NewsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier : CellIdentifier forIndexPath : indexPath];

   NewsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier : CellIdentifier];
   if (!cell)
      cell = [[NewsTableViewCell alloc] initWithFrame : [NewsTableViewCell defaultCellFrame]];

   UIImage * const image = [self.aggregator firstImageForArticle : article];
   [cell setCellData : article image : image imageOnTheRight : (indexPath.row % 4) == 3];

   return cell;
}

//________________________________________________________________________________________
- (CGFloat) tableView : (UITableView *) tableView heightForRowAtIndexPath : (NSIndexPath *) indexPath
{
   const NSInteger row = indexPath.row;
   assert(row >= 0 && row < [self.aggregator.allArticles count] && "tableView:heightForRowAtIndexPath:, indexPath.row is out of bounds");

   MWFeedItem * const article = [self.aggregator.allArticles objectAtIndex : row + self.rangeOfArticlesToShow.location];
   //From time to time this crap dies at start.
   UIImage * const image = [self.aggregator firstImageForArticle : article];

   return [NewsTableViewCell calculateCellHeightForData : article image : image imageOnTheRight : (indexPath.row % 4) == 3];
}

#pragma mark - RSSAggregatorDelegate methods

//________________________________________________________________________________________
- (void) allFeedsDidLoadForAggregator : (RSSAggregator *) theAggregator
{
   [super allFeedsDidLoadForAggregator : theAggregator];
   [(UITableView *)self.view reloadData];
   loaded = YES;
}

//________________________________________________________________________________________
- (void) aggregator : (RSSAggregator *) aggregator didDownloadFirstImage : (UIImage *) image forArticle : (MWFeedItem *)article
{
   (void) image;

   const NSUInteger index = [self.aggregator.allArticles indexOfObject : article];
   NSUInteger path[2] = {};
   
   if (self.rangeOfArticlesToShow.length) {
      if (index >= self.rangeOfArticlesToShow.location && index < self.rangeOfArticlesToShow.location + self.rangeOfArticlesToShow.length)
         path[1] = index - self.rangeOfArticlesToShow.location;
   } else if (index < [self.aggregator.allArticles count]) {
      path[1] = index;
   }

   NSIndexPath *indexPath = [NSIndexPath indexPathWithIndexes : path length : 2];
   NSArray *indexPaths = [NSArray arrayWithObject : indexPath];
//   [(UITableView *)self.view reloadRowsAtIndexPaths : indexPaths withRowAnimation : UIT UITableViewRowAnimationFade];
   //This crap dies at start.
   [(UITableView *)self.view reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - Table view delegate

//________________________________________________________________________________________
- (void) tableView : (UITableView *) tableView didSelectRowAtIndexPath : (NSIndexPath *) indexPath
{
   // Navigation logic may go here. Create and push another view controller.
   assert(indexPath != nil && "tableView:didSelectRowAtIndexPath, index path for selected table's row is nil");

   if (navigationControllerForArticle) {
      UIStoryboard * const mainStoryboard = [UIStoryboard storyboardWithName : @"MainStoryboard_iPhone" bundle : nil];
      assert(mainStoryboard != nil && "tableView:didSelectRowAtIndexPath, storyboard is nil");
      
      ArticleDetailViewController *viewController = [mainStoryboard instantiateViewControllerWithIdentifier : kArticleDetailViewIdentifier];
      //Actually, no need in assert - storyboard will generate an exception.
      assert(viewController != nil && "tableView:didSelectRowAtIndexPath, no ArticleDetailViewController was found in a storyboard");
      viewController.loadOriginalLink = YES;
      const NSUInteger index = rangeOfArticlesToShow.length ? indexPath.row + rangeOfArticlesToShow.location : indexPath.row;
      [viewController setContentForArticle : [self.aggregator.allArticles objectAtIndex : index]];
      
      [navigationControllerForArticle pushViewController : viewController animated : YES];
   }
   
   [tableView deselectRowAtIndexPath : indexPath animated : NO];
}

//________________________________________________________________________________________
- (UIView *) tableView : (UITableView *)tableView viewForFooterInSection : (NSInteger) section
{
   //Many thanks to J. Costa for this trick. (http://stackoverflow.com/questions/1369831/eliminate-extra-separators-below-uitableview-in-iphone-sdk)
   //Many thanks to Apple's "brilliant" engineers for the fact I need this - continue to think different, guys!
   if (!section)
      return [[UIView alloc] init];

   return nil;
}

@end
