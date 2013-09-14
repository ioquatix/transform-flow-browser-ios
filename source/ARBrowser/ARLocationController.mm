//
//  ARLocationController.m
//  This file is part of the "transform-flow" project, and is released under the MIT license.
//
//  Created by Samuel Williams on 13/04/11.
//  Copyright, 2013, by Samuel G. D. Williams.
//

#import "ARLocationController.h"
#import "ARLocationController3.h"
#import "ARLocationController4.h"

NSString * const ARLocationChanged = @"ARLocationChanged";
NSString * const ARHeadingChanged = @"ARHeadingChanged";

// Ignore the warning about incomplete implementation, this class is a facade.
@implementation ARLocationController

@dynamic currentHeading, currentLocation, currentBearing, currentGravity, northAxis, worldLocation, fixedLocation;

// Cannot initialise this class.
- (id)init
{
    return nil;
}

+ sharedInstance
{
	static ARLocationControllerBase * _sharedInstance = nil;
	
	if (_sharedInstance == nil) {
        NSUInteger version = 3;
        
        CMMotionManager * motionManager = [[CMMotionManager alloc] init];
        
        if (motionManager && motionManager.gyroAvailable) {
            version = 4;
        }
        
		// Force version 3
		//version = 3;
		
        NSLog(@"Using location controller version %u", version);
        
        if (version == 3) {
            _sharedInstance = [[ARLocationController3 alloc] init];
        } else {
            _sharedInstance = [[ARLocationController4 alloc] init];
        }
	}
	
	return _sharedInstance;
}

@end
