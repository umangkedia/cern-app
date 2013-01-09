//
//  LiveTableViewCell.h
//  CERN
//
//  Created by Timur Pocheptsov on 1/7/13.
//  Copyright (c) 2013 CERN. All rights reserved.
//

#import <UIKit/UIKit.h>

namespace CernAPP {

//We use the same rgb, as menu, but make a table slightly brighter.
extern const CGFloat liveTableRgbShift;

}

@interface LiveTableViewCell : UITableViewCell

- (void) drawRect : (CGRect) rect;

@end
