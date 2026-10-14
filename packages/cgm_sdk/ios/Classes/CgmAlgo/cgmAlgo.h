#import <Foundation/Foundation.h>
#include "gluValueRet.h"

// CGMAlgorithm interface
@interface cgmAlgo : NSObject

// Returns the algorithm library version number
+ (NSString *)algoVersion;

// step 1:  Load algorithm library
+ (BOOL)algoInit:(int)startTs
    paramBGMbase:(double)paramBGMbase
       tempcoef1:(double)tempcoef1
       tempcoef2:(double)tempcoef2;

// step 2: Call this interface cyclically to calculate each blood glucose measurement value
// enter：
//    dpoint CGMGenerated current data
//    dTemp   temperature value
//    uiTs  The timestamp corresponding to the current data, in seconds
//
// output: GluValueRet：  result     See details GluValueRetStructure Definition
+ (GluValueRet)algoDataProc:(double)dpoint dTemp:(double)dTemp
                       uiTs:(uint32_t)uiTs;

// step 3: Uninstall algorithm library
+ (void)algoUninit;

// Optional:  Assume that the positive sensitivity parameter of the algorithm is set. Phase 1
+ (BOOL)algoSetPositiveSlope1:(double)dVal;

// Optional:  Assume that the negative sensitivity parameter of the algorithm is set in stage one.
+ (BOOL)algoSetNegativesSlope1:(double)dVal;

// Optional:  Assume that the positive sensitivity parameter of the algorithm is set. Phase 2
+ (BOOL)algoSetPositiveSlope2:(double)dVal
                         bgSw:(BOOL)bgSw;

// Optional:  Suppose the negative sensitivity parameter of the algorithm is set. Phase 2
+ (BOOL)algoSetNegativesSlope2:(double)dVal;

// Optional:  Set daytime Kalman filter parameters
+ (BOOL)algoSetDayKalman:(double)dQ
                      dR:(double)dR;
// Optional:  Set daytime Kalman filter parameters
+ (BOOL)algoSetNightKalman:(double)dQ
                        dR:(double)dR;

@end
