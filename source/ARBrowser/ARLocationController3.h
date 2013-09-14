//
//  ARLocationController3.h
//  ARBrowser
//
//  Created by Samuel Williams on 20/10/11.
//  Copyright (c) 2011 Samuel Williams. All rights reserved.
//

#import "ARLocationControllerBase.h"
#import <UIKit/UIAccelerometer.h>

@interface ARLocationController3 : ARLocationControllerBase <UIAccelerometerDelegate> {
	CMAcceleration currentGravity;
}

@end