#import <cassert>

#import "Experiments.h"

namespace CernAPP {

//I'm using string literals not to care about
//ARC and NSStrings.
const char * experimentNames[(int)LHCExperiment::nExperiments] = {
   "ATLAS",
   "CMS",
   "ALICE",
   "LHCb",
   "LHC"
};

//________________________________________________________________________________________
const char *ExperimentName(LHCExperiment experiment)
{
   const unsigned n = unsigned(experiment);
   assert(n < unsigned(LHCExperiment::nExperiments) && "ExperimentName, bad experiment id");
   
   return experimentNames[n];
}

//String identifiers for the storybord/GUI.
NSString * const LIVEEventTableViewControllerID = @"LiveEventTableControllerID";
NSString * const ALICEPhotoGridViewControllerID = @"ALICEPhotoGridViewControllerIdentifier";
NSString * const EventDisplayViewControllerID = @"EventDisplayViewControllerIdentifier";

}