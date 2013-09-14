//
//  ARLocationController3.m
//  ARBrowser
//
//  Created by Samuel Williams on 20/10/11.
//  Copyright (c) 2011 Samuel Williams. All rights reserved.
//

#import "ARLocationController3.h"

#import "ARLocationController.h"
#import "ARWorldLocation.h"

#define kFilteringFactor 0.33

@implementation ARLocationController3

- (id)init {
    self = [super init];
    if (self) {
		[[UIAccelerometer sharedAccelerometer] setDelegate:self];
		[[UIAccelerometer sharedAccelerometer] setUpdateInterval:(1.0 / kSensorSampleFrequency)];
    }
    return self;
}

- (void)dealloc {
	[[UIAccelerometer sharedAccelerometer] setDelegate:nil];	
}

- (void)accelerometer:(UIAccelerometer*)accelerometer didAccelerate:(UIAcceleration*)acceleration
{	
    //Use a basic low-pass filter to only keep the gravity in the accelerometer values
    currentGravity.x = acceleration.x * kFilteringFactor + currentGravity.x * (1.0 - kFilteringFactor);
    currentGravity.y = acceleration.y * kFilteringFactor + currentGravity.y * (1.0 - kFilteringFactor);
    currentGravity.z = acceleration.z * kFilteringFactor + currentGravity.z * (1.0 - kFilteringFactor);
}

- (CMAcceleration) currentGravity
{
    return currentGravity;
}

@end
