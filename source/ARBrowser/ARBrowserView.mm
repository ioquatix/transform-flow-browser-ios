//
//  ARBrowserView.m
//  This file is part of the "transform-flow" project, and is released under the MIT license.
//
//  Created by Samuel Williams on 9/04/11.
//  Copyright, 2013, by Samuel G. D. Williams.
//

#import "ARBrowserView.h"

#import "ARMotionModelController.h"

#include <TransformFlow/BasicSensorMotionModel.h>
#include <TransformFlow/HybridMotionModel.h>
#include <Euclid/Numerics/Matrix.Inverse.h>

#include <Euclid/Geometry/Eye.h>
#include <Euclid/Geometry/Line.h>

#import "ARRendering.h"
#import "ARWorldPoint.h"
#import "ARModel.h"

using Euclid::Numerics::Vec2;

struct ARBrowserVisibleWorldPoint {
	float distance;
	Vec3 delta;
	ARWorldPoint * point;
	
	bool operator< (const ARBrowserVisibleWorldPoint & other) const {
		return this->distance > other.distance;
	}
};

static Vec2 positionInView (UIView * view, UITouch * touch)
{
	CGPoint locationInView = [touch locationInView:view];
	CGRect bounds = [view bounds];
	
	return Vec2(locationInView.x, bounds.size.height - locationInView.y);
}

@interface ARBrowserView () {
	ARVideoFrameController * videoFrameController;
	ARVideoBackground * videoBackground;
	
	/// @internal
	struct ARBrowserViewState * state;

	Mat44 _projectionMatrix, _viewMatrix;
	
	ARBrowser::VerticesT _grid;
}

/// The location controller to use for position information.
@property(nonatomic,retain) ARMotionModelController * motionModelController;

@end

@implementation ARBrowserView

- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame pixelFormat:GL_RGB565_OES depthFormat:GL_DEPTH_COMPONENT16_OES preserveBackbuffer:YES];
	
	if (self) {
		videoFrameController = [[ARVideoFrameController alloc] init];
		videoBackground = [[ARVideoBackground alloc] init];
		[videoFrameController start];
		
		// Initialise the location controller
		self.motionModelController = [ARMotionModelController new];
		self.motionModelController.motionModel = new TransformFlow::HybridMotionModel;
		//self.motionModelController.motionModel = new TransformFlow::BasicSensorMotionModel;

		ARBrowser::generateGrid(_grid);
		
		_minimumDistance = 2.0;
		_nearDistance = _minimumDistance * 2.0;
		
		_maximumDistance = 500.0;
		_farDistance = _maximumDistance / 2.0;

		_displayRadar = YES;
		
		_radarCenter.x = -1;
		_radarCenter.y = -1;
	}
	
	return self;
}

- (void) drawRadar {
	using namespace Euclid::Numerics;

	ARWorldLocation * origin = [self.motionModelController worldLocation];
	Vec3 gravity = [self.motionModelController currentGravity];

	NSArray * worldPoints = nil;
	if ([self.delegate respondsToSelector:@selector(worldPointsFromLocation:withinDistance:)]) {
		worldPoints = [self.delegate worldPointsFromLocation:origin withinDistance:self.maximumDistance * 2.0];
	} else {
		worldPoints = self.delegate.worldPoints;
	}
	
	ARBrowser::VerticesT radarPoints, radarEdgePoints;
	
	if (worldPoints) {
		for (ARWorldPoint * point in worldPoints) {
			// Try to speed up:
			//Vec3 delta = point.position - origin.position;
			
			// This method is pretty slow:
			Vec3 delta = [origin calculateRelativePositionOf:point];
			// Ignore altitude in distance calculations:
			delta[Z] = 0;
			
			if (delta.length() == 0) {
				radarPoints.push_back(delta);
			} else {
				// Normalize the distance of the point
				//const float LF = 10.0;
				//float length = log10f((delta.length() / LF) + 1) * LF;
				float length = sqrt(delta.length() / _maximumDistance);
				
				// Normalize the vector so we can scale its length appropriately.
				delta = delta.normalize();
				
				if (length <= 1.0) {
					delta *= (length * (ARBrowser::RadarDiameter / 2.0));
					radarPoints.push_back(delta);
				} else {
					delta *= (ARBrowser::RadarDiameter / 2.0);
					radarEdgePoints.push_back(delta);
				}
			}
		}
	}
	
	glMatrixMode(GL_PROJECTION);
	glPushMatrix();
	glLoadIdentity();
	
	CGSize radarSize = CGSizeMake(40, 40);
	CGSize viewSize = [self bounds].size;

	auto projectionBox = Euclid::Geometry::AlignedBox3::from_center_and_size(ZERO, Vec3(viewSize.width, viewSize.height, 2));
	Mat44 orthoProjection = Euclid::Geometry::orthographic_projection_matrix(projectionBox);
	glMultMatrixf(orthoProjection.data());
	
	//float minDimension = std::min(viewSize.width, viewSize.height);
	//float scale = minDimension / ARBrowser::RadarDiameter;
	float minDimension = viewSize.width / 3.0;
	float scale = minDimension / ARBrowser::RadarDiameter;
	
	glMatrixMode(GL_MODELVIEW);
	glPushMatrix();
	glLoadIdentity();
	
	// This isn't quite right due to scaling, but it is sufficient at this time.
	//glTranslatef(minDimension * radarCenter.x, (viewSize.height / 2.0) - ((radarSize.height / 2.0 * scale) * radarCenter.y), 0);
	glTranslatef(minDimension, (viewSize.height / 2.0) - (radarSize.height / 2.0 * scale), 0);	
	
	// Make it slightly smaller so the edges aren't touching the bounding box.
	scale *= 0.9;
	glScalef(scale, scale, 1);
	
	// Calculate the forward angle:
	float forwardAngle = 0.0;
	BOOL flat = NO;
	
	Vec3 rotationAxis;
	{
		Vec3 up(0, 0, 1);
		Vec3 g = gravity.normalize();
		
		float sz = acos(up.dot(g));
		
		// We only do this if there is sufficient rotation of the device around the vertical axis.
		if (sz > 0.1) {
			// Simplified version of the line/plane intersection test, since the plane and line are from the origin.
			Vec3 at = g + (up * -(up.dot(g)));
			at = at.normalize();
			
			Vec3 north(0, 1, 0);
			
			rotationAxis = cross_product(at, north);
			forwardAngle = acos(at.dot(north));
		} else {
			flat = YES;
		}
	}
	
	if (!flat) {
		glRotatef(-forwardAngle * ARBrowser::R2D, rotationAxis[X], rotationAxis[Y], rotationAxis[Z]);
	} else {
		// We do this to avoid strange behaviour around the vertical axis:
		glRotatef([origin rotation], 0, 0, 1);
	}
	
	ARBrowser::renderRadar(radarPoints, radarEdgePoints, scale / 2.0);
	
	if (!flat) {		
		Mat44 inverseViewMatrix = inverse(_viewMatrix);
		
		// This matrix now contains the transform where +Y maps to North
		// The North axis of the phone is mapped to global North axis.
		Vec3 north(0, 1, 0); //, deviceNorth;
		//NSLog(@"  Device north: %0.3f, %0.3f, %0.3f", deviceNorth.x, deviceNorth.y, deviceNorth.z);
		
		Vec3 forward(0, 0, -1), deviceForward;
		// We calculate the forward vector in global space where (0, 1, 0) is north, (0, 0, -1) is down, (1, 0, 0) is approximately east.
		deviceForward = inverseViewMatrix * forward;

		//NSLog(@"Device forward: %0.3f, %0.3f, %0.3f", deviceForward.x, deviceForward.y, deviceForward.z);
		
		deviceForward[Z] = 0;
		deviceForward = deviceForward.normalize();
		
		float bearing = acos(deviceForward.dot(north));
		Vec3 r = cross_product(deviceForward, north).normalize();
		
		//NSLog(@"Bearing: %0.3f", bearing);
		glRotatef(-bearing * ARBrowser::R2D, r[X], r[Y], r[Z]);
		ARBrowser::renderRadarFieldOfView();
	}
	
	glPopMatrix();
	
	glMatrixMode(GL_PROJECTION);
	glPopMatrix();
}

- (void) update {
	using namespace Euclid::Numerics;

	if (videoFrameController) {
		ARVideoFrame * videoFrame = [videoFrameController videoFrame];
		
		if (videoFrame && videoFrame->data) {
			[videoBackground update:videoFrame];
			[videoBackground drawWithViewportSize:self.bounds.size];
		}
	} else {
		glClear(GL_COLOR_BUFFER_BIT);
	}
	
	glEnable(GL_DEPTH_TEST);
	glClear(GL_DEPTH_BUFFER_BIT);

	if (![self.motionModelController localizationValid])
		return;

	Vec3 gravity = [self.motionModelController currentGravity];
	ARWorldLocation * origin = [self.motionModelController worldLocation];

	Mat44 transform = TransformFlow::local_camera_transform(gravity, degrees(origin.rotation));

	// Load the camera projection matrix
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();

	CGSize viewSize = [self bounds].size;

	Mat44 perspectiveProjection;
	perspectiveProjection = perspective_projection_matrix<RealT>(self.motionModelController.cameraFieldOfView * ARBrowser::D2R, viewSize.width / viewSize.height, 0.1, 1000.0);
	glMultMatrixf(perspectiveProjection.data());
	
	glMatrixMode(GL_MODELVIEW);
	glLoadMatrixf(transform.data());

	glTranslatef(0.0, 0.0, -0.2);
	
	glGetFloatv(GL_PROJECTION_MATRIX, _projectionMatrix.data());
	glGetFloatv(GL_MODELVIEW_MATRIX, _viewMatrix.data());
	
	glColor4f(0.7, 0.7, 0.7, 0.2);
	glLineWidth(2.0);
	
	if (_displayGrid) {
		ARBrowser::renderVertices(_grid);
		ARBrowser::renderAxis();
	}
	
	if (true) {
		glColor4f(1.0, 0.0, 0.0, 1.0);
		ARBrowser::renderRing(_maximumDistance);
		ARBrowser::renderRing(_minimumDistance);
		
		glColor4f(0.0, 0.0, 1.0, 1.0);
		ARBrowser::renderRing(_nearDistance);
		
		glColor4f(0.0, 1.0, 0.0, 1.0);
		ARBrowser::renderRing(_farDistance);
		
		glColor4f(1.0, 1.0, 1.0, 1.0);
	}
	
	if ([self.delegate respondsToSelector:@selector(renderInLocalCoordinatesForBrowserView:)]) {
		[self.delegate renderInLocalCoordinatesForBrowserView:self];
	}
	
	NSArray * worldPoints = nil;
	if ([self.delegate respondsToSelector:@selector(worldPointsFromLocation:withinDistance:)]) {
		worldPoints = [self.delegate worldPointsFromLocation:origin withinDistance:self.farDistance];
	} else {
		worldPoints = [self.delegate worldPoints];
	}
	
	if (worldPoints == nil) {
		return;
	}
	
	std::vector<ARBrowserVisibleWorldPoint> visibleWorldPoints;

	for (ARWorldPoint * point in worldPoints) {
		Vec3 delta = [origin calculateRelativePositionOf:point];
		
		//NSLog(@"Delta: %0.3f, %0.3f, %0.3f", delta.x, delta.y, delta.z);
		
		// Distance as a bird flies (e.g. ignoring altitude)
		Vec3 birdFlys = delta;
		birdFlys[Z] = 0;
		
		// Calculate actual (non-scaled) distance.
		float distance = birdFlys.length();
		
		if (distance < _minimumDistance || distance > _maximumDistance) {
			continue;
		}
		
		visibleWorldPoints.push_back((ARBrowserVisibleWorldPoint){distance, delta, point});
	}
	
	// Depth sort the visible objects.
	std::sort(visibleWorldPoints.begin(), visibleWorldPoints.end());

	Euclid::Geometry::Line3 forward;

	{
		using namespace Euclid::Geometry;

		auto eye_transform = eye_transformation(_projectionMatrix, _viewMatrix);
		auto eye = eye_transform.convert_from_normalized_space_to_object_space(Vec3(0, 0, -1));

		forward = eye.forward;
	}

	for (std::size_t i = 0; i < visibleWorldPoints.size(); i += 1) {
		ARBrowserVisibleWorldPoint & p = visibleWorldPoints[i];

		auto t = forward.time_for_closest_point(p.delta);
		auto closest = forward.point_at_time(t);
		auto distance = (closest - p.delta).length();

		if (distance < 0.05 && t > 0) {
			// Randomly move the point somewhere else:
			CLLocationCoordinate2D c = origin.coordinate;

			AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);

			NSLog(@"Coordinate: %0.8f, %0.8f", c.latitude, c.longitude);

			c.latitude += (((double(rand()) / RAND_MAX) * 2.0) - 1.0) * 0.0001;
			c.longitude += (((double(rand()) / RAND_MAX) * 2.0) - 1.0) * 0.0001;

			NSLog(@"Updated: %0.8f, %0.8f", c.latitude, c.longitude);

			[p.point setCoordinate:c altitude:p.point.altitude];
		} else if (distance < 2.0) {

		}

		glPushMatrix();
		
		glTranslatef(p.delta[X], p.delta[Y], p.delta[Z]);
		
		glRotatef(p.point.rotation, 0.0, 0.0, 1.0);
		glMultMatrixf(p.point.transform.data());
		[p.point.model draw];
		
		glPopMatrix();
	}
	
	if (_displayRadar)
		[self drawRadar];
	
	[super update];
}

- (void) stopRendering
{
	[self.motionModelController stopTracking];
	
	[videoFrameController stop];
	
	[super stopRendering];
}

- (void) startRendering
{
	[self.motionModelController startTracking];

	[videoFrameController start];
	
	[videoFrameController setDelegate:self.motionModelController];
	
	[super startRendering];
}

- (void)dealloc
{
	[self.motionModelController stopTracking];

	[videoFrameController stop];	
}

@end
