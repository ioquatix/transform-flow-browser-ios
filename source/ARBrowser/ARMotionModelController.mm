//
//  ARMotionModelController.mm
//  ARBrowser
//
//  Created by Samuel Williams on 14/09/13.
//
//

#import "ARMotionModelController.h"

@implementation ARMotionModelController

- (void)videoFrameController:(ARVideoFrameController *)controller didCaptureFrame:(CGImageRef)buffer atTime:(CMTime)time {
	TransformFlow::ImageUpdate image_update;

	ARVideoFrame * frame = [controller videoFrame];

	image_update.image_buffer = new Dream::Imaging::Image({frame->size.width, frame->size.height}, Dream::Imaging::PixelFormat::BGRA, Dream::Imaging::DataType::BYTE);

	Dream::Core::StaticBuffer pixel_buffer(frame->data, (frame->bytesPerRow * frame->size.height));
	image_update.image_buffer->buffer().assign(pixel_buffer);

	image_update.time_offset = frame->timestamp;

	_motionModel->update(image_update);
}

- (void) calculateTimestampOffset
{
	NSTimeInterval uptime = [NSProcessInfo processInfo].systemUptime;
	NSTimeInterval nowTimeIntervalSince1970 = [[NSDate date] timeIntervalSince1970];
	self.timestampOffset = nowTimeIntervalSince1970 - uptime;
}

- (void)startTracking
{
	if (self.motionQueue == nil) {
		_motionQueue = [NSOperationQueue mainQueue];
		//_motionQueue = [[NSOperationQueue alloc] init];
	}
	
	if (self.motionManager == nil) {
		_motionManager = [[CMMotionManager alloc] init];

		// Device sensor frame rate:
		NSTimeInterval rate = 1.0 / 60.0;

		[_motionManager setDeviceMotionUpdateInterval:rate];
	}
	
	[_motionManager startDeviceMotionUpdatesToQueue:_motionQueue withHandler:^(CMDeviceMotion *motion, NSError *error) {		
		CMAcceleration acceleration = motion.userAcceleration;
		CMAcceleration gravity = motion.gravity;
		CMRotationRate rotation_rate = motion.rotationRate;

		TransformFlow::MotionUpdate motion_update;

		motion_update.gravity[0] = gravity.x;
		motion_update.gravity[1] = gravity.y;
		motion_update.gravity[2] = gravity.z;

		motion_update.rotation_rate[0] = rotation_rate.x;
		motion_update.rotation_rate[1] = rotation_rate.y;
		motion_update.rotation_rate[2] = rotation_rate.z;

		motion_update.acceleration[0] = acceleration.x;
		motion_update.acceleration[1] = acceleration.y;
		motion_update.acceleration[2] = acceleration.z;

		motion_update.time_offset = motion.timestamp;

		_motionModel->update(motion_update);
	}];

	if (self.locationManager == nil) {
		self.locationManager = [CLLocationManager new];

		[self.locationManager setDesiredAccuracy:kCLLocationAccuracyBestForNavigation];
		[self.locationManager setDelegate:self];
	
		[self.locationManager setHeadingOrientation:CLDeviceOrientationPortrait];
	}

	[self calculateTimestampOffset];
	
	[self.locationManager startUpdatingLocation];
	[self.locationManager startUpdatingHeading];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
	CLLocationCoordinate2D coordinate = newLocation.coordinate;

	NSTimeInterval timestamp = newLocation.timestamp.timeIntervalSince1970 - _timestampOffset;

	TransformFlow::LocationUpdate location_update;

	location_update.time_offset = timestamp;

	location_update.latitude = coordinate.latitude;
	location_update.longitude = coordinate.longitude;

	location_update.horizontal_accuracy = newLocation.horizontalAccuracy;
	location_update.vertical_accuracy = newLocation.verticalAccuracy;

	_motionModel->update(location_update);
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
	NSTimeInterval timestamp = newHeading.timestamp.timeIntervalSince1970 - _timestampOffset;

	TransformFlow::HeadingUpdate heading_update;

	heading_update.time_offset = timestamp;
	
	heading_update.true_bearing = newHeading.trueHeading;
	heading_update.magnetic_bearing = newHeading.magneticHeading;

	_motionModel->update(heading_update);
}

- (ARWorldLocation *) worldLocation
{
	ARWorldLocation * worldLocation = [ARWorldLocation new];

	auto position = _motionModel->position();

	CLLocationCoordinate2D coordinate;
	coordinate.latitude = position[0];
	coordinate.longitude = position[1];
	ARLocationAltitude altitude = position[2];

	[worldLocation setCoordinate:coordinate altitude:altitude];
	[worldLocation setBearing:_motionModel->bearing() * TransformFlow::R2D];

	return worldLocation;
}

- (CMAcceleration) currentGravity
{
	CMAcceleration gravityAcceleration;

	auto internalGravity = _motionModel->gravity();
	gravityAcceleration.x = internalGravity[0];
	gravityAcceleration.y = internalGravity[1];
	gravityAcceleration.z = internalGravity[2];

	return gravityAcceleration;
}

- (void)stopTracking
{
	[self.locationManager stopUpdatingHeading];
	[self.locationManager stopUpdatingLocation];
	[self.motionManager stopDeviceMotionUpdates];
}

@end
