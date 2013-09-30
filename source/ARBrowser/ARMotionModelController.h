//
//  ARMotionModelController.h
//  ARBrowser
//
//  Created by Samuel Williams on 14/09/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreMotion/CoreMotion.h>

#include <TransformFlow/MotionModel.h>

#import "ARVideoFrameController.h"
#import "ARWorldLocation.h"

@interface ARMotionModelController : NSObject <ARVideoFrameControllerDelegate, CLLocationManagerDelegate>

@property(nonatomic,assign) Dream::Ref<TransformFlow::MotionModel> motionModel;

@property(nonatomic,retain) CLLocationManager * locationManager;

@property(nonatomic,retain)	NSOperationQueue * motionQueue;
@property(nonatomic,retain) CMMotionManager * motionManager;

@property(nonatomic,assign) NSTimeInterval timestampOffset;

@property(nonatomic,assign) double cameraFieldOfView;

- (ARWorldLocation *) worldLocation;
- (Vec3) currentGravity;

- (void) startTracking;
- (void) stopTracking;

- (BOOL) localizationValid;

@end
