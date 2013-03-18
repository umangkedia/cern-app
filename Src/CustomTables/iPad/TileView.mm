//
//  TileView.m
//  CERN
//
//  Created by Timur Pocheptsov on 3/18/13.
//  Copyright (c) 2013 CERN. All rights reserved.
//

#import <cassert>
#import <cstdlib>

#import <QuartzCore/QuartzCore.h>

#import "TileView.h"

namespace {
//Titles, content, images - just for testing purpose, to be replaced with a real data from feed.
NSString * titles[] = {@"Title for article", @"Quite a long title for article",
                       @"This is a really, really long title, which does not fit any line",
                       @"Short title", @"Another title"};
const NSUInteger nArticles = sizeof titles / sizeof titles[0];

NSString * contents[nArticles] =
                        {@"The LHC at CERN is a prime example of worldwide collaboration to build a large instrument and pursue frontier science. The discovery there of a particle consistent with the long-sought Higgs boson points to future directions both for the LHC and more broadly for particle physics. Now, the international community is considering machines to complement the LHC and further advance particle physics, including the favoured option: an electron–positron linear collider (LC). Two major global efforts are underway: the International Linear Collider (ILC), which is distributed among many laboratories; and the Compact Linear Collider (CLIC), centred at CERN. Both would collide electrons and positrons at tera-electron-volt energies but have different technologies, energy ranges and timescales. Now, the two efforts are coming closer together and forming a worldwide linear-collider community in the areas of accelerators, detectors and resources.",
                         @"The historic academic building of Utrecht University provided the setting for the 5th International Workshop on Heavy Quark Production in Heavy-Ion Collisions, offering a unique atmosphere for a lively discussion and interpretation of the current measurements on open and hidden heavy flavour in high-energy heavy-ion collisions.",
                         @"A noble gas, a missing scientist and an underground laboratory. It could be the starting point for a classic detective story. But a love story?",
                         @"SPIN 2012, the 20th International Symposium on Spin Physics, took place at the Joint Institute for Nuclear Research (JINR) in Dubna on 17–22 September.",
                         @"The LHC has been delivering data to the physics experiments since the first collisions in 2009. Now, with the first long shutdown, LS1, which started on 13 February, work begins to refurbish and consolidate aspects of the collider, together with the experiments and other accelerators in the injections chain."
                        };

NSString * imageNames[nArticles] =
                        {@"testimage1.png",
                         @"testimage2.png",
                         @"testimage3.png",
                         @"testimage4.png",
                         @"testimage5.png",
                        };

}

@implementation TileView {
   UIImageView *thumbnailView;
   UITextView *textView;
}

//________________________________________________________________________________________
- (id) initWithFrame : (CGRect) frame
{
   if (self = [super initWithFrame : frame]) {
     // thumbnailView = [[UIImageView alloc] initWithFrame : CGRect()];
     // textView = [[UITextView alloc] initWithFrame : CGRect()];
//      self.backgroundColor = []
      self.backgroundColor = [UIColor colorWithPatternImage : [UIImage imageNamed : @"paper.jpg"]];
      
      //These lines MUST be deleted, they are here just to show the bounds.
      self.layer.borderColor = [UIColor blackColor].CGColor;
      self.layer.borderWidth = 1.f;
   }

   return self;
}

//________________________________________________________________________________________
- (void) setTileData : (MWFeedItem *) feedItem
{
//Temporary pragma
#pragma unused(feedItem)
//
   assert(feedItem != nil && "setTileData:, parameter 'feedItem' is nil");

   ///////////////////////////////////////////////////
   //Test only.
   const NSUInteger choise = std::rand() % nArticles;
   (void) choise;
   //Test only.
   ///////////////////////////////////////////////////
   
   NSMutableAttributedString * const articleText = [[NSMutableAttributedString alloc] init];
   (void) articleText;

}

@end
