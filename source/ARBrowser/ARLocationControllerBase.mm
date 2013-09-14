//
//  ARLocationControllerBase.m
//  ARBrowser
//
//  Created by Samuel Williams on 20/10/11.
//  Copyright (c) 2011 Samuel Williams. All rights reserved.
//

#import "ARLocationControllerBase.h"
#import "ARWorldLocation.h"
#import "ARRendering.h"

#import <QuartzCore/QuartzCore.h>
#import <math.h>

// X is defined as the vector product <b>Y.Z</b> (It is tangential to the ground at the device's current location and roughly points East).
// Y is tangential to the ground at the device's current location and points towards the magnetic North Pole.
// Z points towards the sky and is perpendicular to the ground.
int calculateRotationMatrixFromMagnetometer(CMAcceleration gravity, CMMagneticField magnetometer, float * R) {
    float Ax = gravity.x, Ay = gravity.y, Az = gravity.z;
    float Ex = magnetometer.x, Ey = magnetometer.y, Ez = magnetometer.z;
    
    float Hx = Ey*Az - Ez*Ay, Hy = Ez*Ax - Ex*Az, Hz = Ex*Ay - Ey*Ax;
    
    float normH = sqrt(Hx*Hx + Hy*Hy + Hz*Hz);
    
    if (normH < 0.1) {
        // device is close to free fall (or in space?), or close to
        // magnetic north pole. Typical values are  > 100.
        return 0;
    }
    
    float invH = 1.0f / normH;
    Hx *= invH;
    Hy *= invH;
    Hz *= invH;
    
    float invA = 1.0f / sqrt(Ax*Ax + Ay*Ay + Az*Az);
    Ax *= invA;
    Ay *= invA;
    Az *= invA;
    
    float Mx = Ay*Hz - Az*Hy, My = Az*Hx - Ax*Hz, Mz = Ax*Hy - Ay*Hx;
    
    R[0]  = Hx;    R[1]  = Hy;    R[2]  = Hz;   R[3]  = 0;
    R[4]  = Mx;    R[5]  = My;    R[6]  = Mz;   R[7]  = 0;
    R[8]  = Ax;    R[9]  = Ay;    R[10] = Az;   R[11] = 0;
    R[12] = 0;     R[13] = 0;     R[14] = 0;    R[15] = 1;
    
    return 1;
}

@interface ARLocationControllerBase ()
@property(retain,readwrite) CLLocationManager * locationManager;
@property(retain,readwrite) CLLocation * currentLocation;
@property(retain,readwrite) CLHeading * currentHeading;
@property(assign,readwrite) CMAcceleration northAxis;

@property(assign,readwrite) CLLocationCoordinate2D smoothedLocation;
@property(retain,readwrite) ARWorldLocation * worldLocation;
@end

@implementation ARLocationControllerBase

@synthesize currentHeading = _currentHeading, currentLocation = _currentLocation, smoothedLocation = _smoothedLocation, northAxis = _northAxis, locationManager = _locationManager;

@synthesize worldLocation = _worldLocation;

- (id)init {
    self = [super init];
    if (self) {
		self.locationManager = [[CLLocationManager alloc] init];
		[self.locationManager setDesiredAccuracy:kCLLocationAccuracyBestForNavigation];
		[self.locationManager setDelegate:self];
        
		//NSLog(@"Heading Orientation: %d", [locationManager headingOrientation]);
		// This is the same as the default, but setting it explicitly.
		[self.locationManager setHeadingOrientation:CLDeviceOrientationPortrait];
		self.northAxis = (CMAcceleration){0, 1, 0};
		
		updateTimer = [NSTimer scheduledTimerWithTimeInterval:(1.0/60.0) target:self selector:@selector(update) userInfo:nil repeats:YES];
		
		[self.locationManager startUpdatingLocation];
		[self.locationManager startUpdatingHeading];
    }
    return self;
}

- (void)dealloc {
	[updateTimer invalidate];
	
    [self.locationManager stopUpdatingLocation];
    [self.locationManager stopUpdatingHeading];
    [self.locationManager setDelegate:nil];
}

- (void)update {
	// This should really use spherical interpolation, but for small distances it doesn't really make any difference..
	const double kFilteringFactor = 0.80;
	
	if (self.currentLocation) {
		CLLocationCoordinate2D currentLocationCoordinate = self.currentLocation.coordinate;
		
		// Calculate location change:
		double latitudeChange = self.smoothedLocation.latitude - currentLocationCoordinate.latitude;
		double longitudeChange = self.smoothedLocation.longitude - currentLocationCoordinate.longitude;
		double change = (latitudeChange * latitudeChange) + (longitudeChange * longitudeChange);
		
		if (change == 0.0) {
			return;
		}
		
		if (change > 0.00000001) {
			//Use a basic low-pass filter to smooth out changes in GPS data.
			CLLocationCoordinate2D nextSmoothedLocation = {
				self.smoothedLocation.latitude * kFilteringFactor + self.currentLocation.coordinate.latitude * (1.0 - kFilteringFactor),
				self.smoothedLocation.longitude * kFilteringFactor + self.currentLocation.coordinate.longitude * (1.0 - kFilteringFactor)
			};
			
			self.smoothedLocation = nextSmoothedLocation;
		} else {
			// Snap to the final position if the change is very small:
			self.smoothedLocation = currentLocationCoordinate;
		}
		
		[self updateWorldLocation];
	}
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {

	if (self.currentLocation == nil) {
		// First update:
		self.smoothedLocation = [newLocation coordinate];
	}
		
	self.currentLocation = newLocation;
	
	[self updateWorldLocation];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
    [self setCurrentHeading:newHeading];
	
	//if (self.worldLocation) {
		// Avoid recalculating location based information.
	//	[self.worldLocation setBearing:newHeading.trueHeading];
	//} else {
		[self updateWorldLocation];
	//}
}

- (void) setFixedLocation:(CLLocation *)fixedLocation
{
	_fixedLocation = fixedLocation;

	if (_fixedLocation)
		[self updateWorldLocation];
}

- (void) updateWorldLocation {
	if (self.currentLocation && self.currentHeading) {
		ARWorldLocation * updatedWorldLocation = [ARWorldLocation new];

		// If the user has specified to use a fixedLocation, we use this for the current world location, otherwise set it from the smoothed GPS data.
		if (self.fixedLocation) {
			[updatedWorldLocation setLocation:self.fixedLocation];
		} else {
			// We truncate the altitude to ensure that all coordinates are on the surface of the same sphere. This isn't entirely correct but generally produces good behaviour.
			[updatedWorldLocation setCoordinate:self.smoothedLocation altitude:0.0 /* self.currentLocation.altitude */];
		}

		[updatedWorldLocation setBearing:self.currentBearing];

		self.worldLocation = updatedWorldLocation;
	} else {
		self.worldLocation = nil;
	}
}

//#warning "AR_DEBUG_LOCATION defined!"
//#define AR_DEBUG_LOCATION

- (CMAcceleration) currentGravity
{
    CMAcceleration gravity = {0, 0, -1};
    
    return gravity;
}

- (CLLocationDirection) currentBearing
{
    return [self.currentHeading trueHeading];
}

- (BOOL) calculateGlobalOrientation: (float[16])matrix
{
    CMMagneticField magneticField = {
        self.currentHeading.x * ARBrowser::D2R,
        self.currentHeading.y * ARBrowser::D2R,
        self.currentHeading.z * ARBrowser::D2R
    };
    
    //NSLog(@"Magnetic Field Vector: %0.3f, %0.3f, %0.3f", self.currentHeading.x, self.currentHeading.y, self.currentHeading.z);
    
    return calculateRotationMatrixFromMagnetometer([self currentGravity], magneticField, matrix);
}

@end
