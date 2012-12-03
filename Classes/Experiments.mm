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

NSString * const liveEventTableViewControllerID = @"LiveEventTableControllerID";

const CGFloat largeImageDimension = 764.f;
const CGFloat smallImageDimension = 379.f;

const CGRect imageBoundsForATLAS[] = {CGRectMake(2.f, 2.f, largeImageDimension, largeImageDimension),
                                      CGRectMake(2.f + 4.f + largeImageDimension, 2.f, smallImageDimension, smallImageDimension)};
   
   
const CGRect imageBoundsForLHCb = CGRectMake(0.f, 66.f, 1685.f, 811.f);

}