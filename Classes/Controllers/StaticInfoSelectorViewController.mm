//
//  AboutTableViewController.m
//  CERN App
//
//  Created by Eamon Ford on 7/18/12.
//  Copyright (c) 2012 CERN. All rights reserved.
//

#import "StaticInfoSelectorViewController.h"
#import "StaticInfoScrollViewController.h"
#import "StaticInfoItemViewController.h"
#import "GuiAdjustment.h"
#import "AppDelegate.h"
#import "Constants.h"


@interface StaticInfoSelectorViewController ()

@end

@implementation StaticInfoSelectorViewController
@synthesize tableDataSource, currentTitle, currentLevel, currentlyShowingIndexPath;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if (self.currentLevel == 0) {
        self.navigationItem.title = @"About CERN";
    } else {
        self.navigationItem.title = self.currentTitle;
    }
    CGSize contentSize = CGSizeMake(320.0, [self.tableView numberOfRowsInSection:0]*[self.tableView rowHeight]);
    self.contentSizeForViewInPopover = contentSize;
}

- (void)viewWillAppear:(BOOL)animated
{
   CGSize contentSize = CGSizeMake(320.0, [self.tableView numberOfRowsInSection:0]*[self.tableView rowHeight]);
   self.contentSizeForViewInPopover = contentSize;

   if (self.navigationController.viewControllers.count > 1)
      CernAPP::ResetBackButton(self, @"back_button_flat.png");
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        return YES;
    else
        return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tableDataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
   
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
    
    NSDictionary *item = [self.tableDataSource objectAtIndex:indexPath.row];
    cell.textLabel.text = [item objectForKey:@"Title"];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        if (self.currentlyShowingIndexPath.row == indexPath.row &&
            self.currentLevel == self.currentlyShowingIndexPath.section) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    NSDictionary *item = [self.tableDataSource objectAtIndex:indexPath.row];
    NSArray *children = [item objectForKey:@"Items"];
    
    // If its children have children...
    if (children && [[children objectAtIndex:0] objectForKey:@"Items"]) {
        StaticInfoSelectorViewController *viewController = [[StaticInfoSelectorViewController alloc] initWithStyle:UITableViewStyleGrouped];
        viewController.tableDataSource = children;
        viewController.currentTitle = [item objectForKey:@"Title"];
        viewController.currentLevel = self.currentLevel + 1;
       
        [self.navigationController pushViewController:viewController animated:YES];
    } else {
        // Show the static info scroll view, and set its data source to the proper info set
        int selectedRow = [self.tableView indexPathForSelectedRow].row;
        
        NSArray *staticInfoRecords = [[self.tableDataSource objectAtIndex:selectedRow] objectForKey:@"Items"];
        
        StaticInfoScrollViewController *scrollViewController;
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
            scrollViewController = [mainStoryboard instantiateViewControllerWithIdentifier:kStaticInfoScrollViewController];
            [self.navigationController presentViewController:scrollViewController animated:YES completion:nil];
        } else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            
            self.currentlyShowingIndexPath = [NSIndexPath indexPathForRow:selectedRow inSection:self.currentLevel];
            [self.tableView reloadData];
            
            AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
            scrollViewController = [appDelegate.tabBarController.viewControllers objectAtIndex:CernAPP::TabIndexAbout];
        }
        
        scrollViewController.dataSource = staticInfoRecords;
        [scrollViewController refresh];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

//________________________________________________________________________________________
- (void) backButtonPressed
{
   [self.navigationController popViewControllerAnimated : YES];
}

@end
