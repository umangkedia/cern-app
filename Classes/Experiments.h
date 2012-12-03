#ifndef CERN_Experiments_h
#define CERN_Experiments_h

namespace CernAPP {

enum class LHCExperiment : unsigned {
   ATLAS,
   CMS,
   ALICE,
   LHCb,
   LHC,//That's not an experiment actually, but we treat it as an experiment in CERN LIVE.
   nExperiments
};

const char *ExperimentName(LHCExperiment experiment);

extern NSString * const liveEventTableViewControllerID;


//Unfortunately, I have to hardcode these things here.
extern const CGRect imageBoundsForATLAS[2];
extern const CGRect imageBoundsForLHCb;

}

#endif
