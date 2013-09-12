//
//  ARLocationController.h
//  This file is part of the "transform-flow" project, and is released under the MIT license.
//
//  Created by Samuel Williams on 13/04/11.
//  Copyright, 2013, by Samuel G. D. Williams.
//

#import <Foundation/Foundation.h>

#import <CoreLocation/CoreLocation.h>
#import <CoreMotion/CoreMotion.h>
#import <UIKit/UIAccelerometer.h>

extern NSString * const ARLocationChanged;
extern NSString * const ARHeadingChanged;
extern NSString * const ARAccelerationChanged;

@class ARWorldLocation;

/// Provides access to location information via a shared instance.
@interface ARLocationController : NSObject

@property(retain,readonly,nonatomic) CLLocation * currentLocation;
@property(retain,readonly,nonatomic) CLHeading * currentHeading;

/// Set a specific fixed location, which overrides the GPS:
@property(nonatomic,retain) CLLocation * fixedLocation;

/// The device's current gravity downwards vector.
@property(assign,readonly,nonatomic) CMAcceleration currentGravity;

/// The devices current rotation from north, e.g. around the downwards vector.
@property(assign,readonly,nonatomic) CLLocationDirection currentBearing;

// The local device axis that represents north.
@property(assign,readonly,nonatomic) CMAcceleration northAxis;

/// Get the origin of the current device.
@property(retain,readonly,nonatomic) ARWorldLocation * worldLocation;

/// Get the shared location controller.
+ sharedInstance;

@end
