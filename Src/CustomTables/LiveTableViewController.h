//
//  ExperimentLiveControlleriPHONEViewController.h
//  CERN
//
//  Created by Timur Pocheptsov on 11/29/12.
//  Copyright (c) 2012 CERN. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Experiments.h"

@interface LiveTableViewController : UITableViewController

@property (nonatomic, assign) CernAPP::LHCExperiment experiment;

- (IBAction) revealMenu : (id) sender;

@end
