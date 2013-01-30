//
//  WebcastsGridViewController.m
//  CERN App
//
//  Created by Eamon Ford on 8/16/12.
//  Copyright (c) 2012 CERN. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>

#import "WebcastsGridViewController.h"


@implementation WebcastsGridViewController {
    MBProgressHUD *_noConnectionHUD;
}

//________________________________________________________________________________________
- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        //self.gridView.backgroundColor = [UIColor whiteColor];
        _noConnectionHUD.delegate = self;
        _noConnectionHUD.mode = MBProgressHUDModeText;
        _noConnectionHUD.labelText = @"No internet connection";
        _noConnectionHUD.removeFromSuperViewOnHide = YES;
        
        self.parser = [[WebcastsParser alloc] init];
        self.parser.delegate = self;
        [self refresh];
    }
    return self;
}

//________________________________________________________________________________________
- (void)refresh
{
    if (!self.parser.recentWebcasts.count && !self.parser.upcomingWebcasts.count) {
        [_noConnectionHUD hide:YES];

        self.finishedParsingRecent = NO;
        self.finishedParsingUpcoming = NO;
        
        [self.parser parseRecentWebcasts];
        [self.parser parseUpcomingWebcasts];
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    }
}

//________________________________________________________________________________________
- (void)hudWasTapped:(MBProgressHUD *)hud
{
    [self refresh];
}

//________________________________________________________________________________________
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        return YES;
    else
        return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

//________________________________________________________________________________________
- (void)viewDidLoad
{
    [super viewDidLoad];
    // When we call self.view this will reload the view after a didReceiveMemoryWarning.
    self.view.backgroundColor = [UIColor whiteColor];
}

//________________________________________________________________________________________
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//________________________________________________________________________________________
- (IBAction)segmentedControlTapped:(UISegmentedControl *)sender
{
    self.mode = WebcastMode(sender.selectedSegmentIndex);
    if (self.mode == WebcastModeRecent)
        ;//self.gridView.allowsSelection = YES;
    else
        ;//self.gridView.allowsSelection = NO;
    
//    [self.gridView reloadData];
}

#pragma mark WebcastsParserDelegate methods

//________________________________________________________________________________________
- (void)webcastsParserDidFinishParsingRecentWebcasts:(WebcastsParser *)parser
{
    self.finishedParsingRecent = YES;
    if (self.finishedParsingUpcoming)
        [MBProgressHUD hideHUDForView : self.view animated : YES];
    if (self.mode == WebcastModeRecent) {
        //[self.gridView reloadData];
    }
}

//________________________________________________________________________________________
- (void)webcastsParserDidFinishParsingUpcomingWebcasts:(WebcastsParser *)parser
{
    self.finishedParsingUpcoming = YES;
    if (self.finishedParsingRecent)
        [MBProgressHUD hideHUDForView:self.view animated:YES];
    if (self.mode == WebcastModeUpcoming) {
        //[self.gridView reloadData];
    }
}

//________________________________________________________________________________________
- (void)webcastsParser:(WebcastsParser *)parser didDownloadThumbnailForRecentWebcastIndex:(int)index
{
    if (self.mode == WebcastModeRecent)
        ;//[self.gridView reloadItemsAtIndices:[NSIndexSet indexSetWithIndex:index] withAnimation:AQGridViewItemAnimationFade];
}

//________________________________________________________________________________________
- (void)webcastsParser:(WebcastsParser *)parser didDownloadThumbnailForUpcomingWebcastIndex:(int)index
{
    if (self.mode == WebcastModeUpcoming)
        ;//[self.gridView reloadItemsAtIndices:[NSIndexSet indexSetWithIndex:index] withAnimation:AQGridViewItemAnimationFade];
}

//________________________________________________________________________________________
- (void)webcastsParser:(WebcastsParser *)parser didFailWithError:(NSError *)error
{
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
	_noConnectionHUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    _noConnectionHUD.delegate = self;
    _noConnectionHUD.mode = MBProgressHUDModeText;
    _noConnectionHUD.labelText = @"No internet connection";
    _noConnectionHUD.removeFromSuperViewOnHide = YES;
}

@end
