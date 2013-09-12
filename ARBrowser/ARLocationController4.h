//
//  ARLocationController4.h
//  ARBrowser
//
//  Created by Samuel Williams on 20/10/11.
//  Copyright (c) 2011 Samuel Williams. All rights reserved.
//

#import "ARLocationControllerBase.h"

/// Provides access to location information via a shared instance.
@interface ARLocationController4 : ARLocationControllerBase {
    CMMotionManager * motionManager;
    
    CLLocationDirection _currentBearing;
    CLLocationDirection _smoothedBearing;
    
    CMDeviceMotion * _currentMotion;
}

@property(retain) CMDeviceMotion * currentMotion;

@end

