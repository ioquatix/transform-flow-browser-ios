//
//  ARLocationController4.m
//  ARBrowser
//
//  Created by Samuel Williams on 20/10/11.
//  Copyright (c) 2011 Samuel Williams. All rights reserved.
//

#import "ARLocationController4.h"

#import "ARLocationController.h"
#import "ARWorldLocation.h"
#include "ARRendering.h"
#include <math.h>

#define HYBRID_SENSORS

@implementation ARLocationController4

@synthesize currentMotion = _currentMotion;

static CLLocationDirection calculateBearingChange(CMDeviceMotion * previousMotion, CMDeviceMotion * currentMotion)
{
    NSTimeInterval dt = [currentMotion timestamp] - [previousMotion timestamp];
    CMRotationRate rotationRate = [currentMotion rotationRate];
    CMAcceleration currentGravity = [currentMotion gravity];
    
    // This method isn't technically correct but it is accurate enough for most use-cases and very fast.
    return ((currentGravity.x * rotationRate.x) + (currentGravity.y * rotationRate.y) + (currentGravity.z * rotationRate.z)) * dt * ARBrowser::R2D;
}

double interpolateAnglesRadians(double a, double b, double blend) {
    double ix = sin(a), iy = cos(a);
    double jx = sin(b), jy = cos(b);
    
    return atan2(ix-(ix-jx)*blend, iy-(iy-jy)*blend);
}

double interpolateAnglesDegrees(double a, double b, double blend) {
    return interpolateAnglesRadians(a * ARBrowser::D2R, b * ARBrowser::D2R, blend) * ARBrowser::R2D;
}

- (id)init {
    self = [super init];
    if (self) {
        motionManager = [[CMMotionManager alloc] init];
        
        // Tell CoreMotion to show the compass calibration HUD when required to provide true north-referenced attitude
        motionManager.showsDeviceMovementDisplay = YES;
        motionManager.deviceMotionUpdateInterval = 1.0 / kSensorSampleFrequency;
        
        // New in iOS 5.0: Attitude that is referenced to true north
        //[motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXTrueNorthZVertical];
        
        _currentBearing = -360.0;
        
		// Run the motion manager on a separate operations queue.
        [motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue new] withHandler:^(CMDeviceMotion *motion, NSError *error) {
			CLHeading * currentHeading = self.currentHeading;
			
			if (!currentHeading)
				return;
            
            // Initialize the bearing
            if (_currentBearing == -360.0 && currentHeading) {
                _currentBearing = [currentHeading trueHeading];
                _smoothedBearing = _currentBearing;
            }
            
			CMDeviceMotion * currentMotion = self.currentMotion;
			
            if (currentHeading && currentMotion) {
                CLLocationDirection bearingChange = calculateBearingChange(currentMotion, motion);
                _currentBearing = interpolateAnglesDegrees(_currentBearing + bearingChange, [currentHeading trueHeading], 0.05);
            }
            
			self.currentMotion = motion;
        }];
    }
    
    return self;
}

- (void)dealloc {
    [motionManager stopDeviceMotionUpdates];
}

- (CLLocationDirection) currentBearing
{
    return _currentBearing;
	//return [currentHeading trueHeading];
}

- (CMAcceleration) currentGravity
{    
    CMAcceleration gravity = {0, 0, -1};
    
    if (!motionManager.deviceMotion) {
        return gravity;
    }
    
    gravity = motionManager.deviceMotion.gravity;
    
    // Normalize
    double factor = 1.0 / sqrt(gravity.x * gravity.x + gravity.y * gravity.y + gravity.z * gravity.z);
    gravity.x *= factor;
    gravity.y *= factor;
    gravity.z *= factor;
    
    return gravity;
}

@end
