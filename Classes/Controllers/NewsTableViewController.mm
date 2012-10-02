//Author: Timur Pocheptsov.
//Developed for CERN app.

//This is a code for a table view controller, which shows author, title, short content, date for
//a news item.
//It can be used ONLY for iPhone/iPod touch device, for iPad we'll have different approach.

#import <cassert>

//#import "ArticleDetailViewController.h"//FIXFIX
#import "NewsTableViewController.h"
#import "NewsTableViewCell.h"


@implementation NewsTableViewController

@synthesize rangeOfArticlesToShow;

//________________________________________________________________________________________
- (id) initWithCoder : (NSCoder *) aDecoder
{
   if (self = [super initWithCoder : aDecoder]) {
      //
   }

   return self;
}

//________________________________________________________________________________________
- (void) awakeFromNib
{
}

//________________________________________________________________________________________
- (id)initWithStyle : (UITableViewStyle) style
{
   if (self = [super initWithStyle : style]) {
      //
   }

   return self;
}


//________________________________________________________________________________________
- (void)viewDidLoad
{
    [super viewDidLoad];
}

//________________________________________________________________________________________
- (void)viewDidUnload
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
//FIXFIXFIX.
//    ArticleDetailViewController *viewController = (ArticleDetailViewController *)segue.destinationViewController;
//    [viewController setContentForArticle : [self.aggregator.allArticles objectAtIndex : self.gridView.indexOfSelectedItem]];
//    [self.gridView deselectItemAtIndex : self.gridView.indexOfSelectedItem animated : YES];
}

//________________________________________________________________________________________
- (void)didReceiveMemoryWarning
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
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
   // Return the number of rows in the section.
   if (self.rangeOfArticlesToShow.length)
      return self.rangeOfArticlesToShow.length;
   else
      return self.aggregator.allArticles.count;
}

//________________________________________________________________________________________
- (UITableViewCell *) tableView : (UITableView *)tableView cellForRowAtIndexPath : (NSIndexPath *) indexPath
{
   //Find feed item first.
   const NSInteger row = indexPath.row;
   assert(row >= 0 && row < [self.aggregator.allArticles count]);

   MWFeedItem * const article = [self.aggregator.allArticles objectAtIndex : row + self.rangeOfArticlesToShow.location];
   assert(article != nil && "tableView:cellForRowAtIndexPath:, article was not found");

   static NSString *CellIdentifier = @"NewsCell";
   NewsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier : CellIdentifier forIndexPath : indexPath];
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
   UIImage * const image = [self.aggregator firstImageForArticle : article];

   return [NewsTableViewCell calculateCellHeightForData : article image : image imageOnTheRight : (indexPath.row % 4) == 3];
}

#pragma mark - RSSAggregatorDelegate methods

//________________________________________________________________________________________
- (void) allFeedsDidLoadForAggregator : (RSSAggregator *) theAggregator
{
   [super allFeedsDidLoadForAggregator : theAggregator];
   [(UITableView *)self.view reloadData];
}

//________________________________________________________________________________________
- (void) aggregator : (RSSAggregator *) aggregator didDownloadFirstImage : (UIImage *)image forArticle : (MWFeedItem *)article
{
   const NSInteger index = [self.aggregator.allArticles indexOfObject : article] + self.rangeOfArticlesToShow.location;
   NSArray *indexPaths = [NSArray arrayWithObject : [NSIndexPath indexPathWithIndex : index]];
   [(UITableView *)self.view reloadRowsAtIndexPaths : indexPaths withRowAnimation : UITableViewRowAnimationFade];
}

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

@end
