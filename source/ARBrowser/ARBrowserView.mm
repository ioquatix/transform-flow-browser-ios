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

#import "ARRendering.h"
#import "ARWorldPoint.h"
#import "ARModel.h"

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
		self.motionModelController.motionModel = new TransformFlow::BasicSensorMotionModel;
		
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

- (void)touchesBegan: (NSSet *)touches withEvent: (UIEvent *)event
{
	for (UITouch * touch in touches) {
		// viewport: (X, Y, Width, Height)
		CGRect bounds = [self bounds];
		float viewport[4] = {bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height};

		ARBrowser::Ray ray = ARBrowser::calculateRayFromScreenCoordinates(_projectionMatrix, _viewMatrix, viewport, positionInView(self, touch));
		
		ARWorldLocation * origin = [self.motionModelController worldLocation];
		NSArray * worldPoints = [[self delegate] worldPoints];

		ARWorldPoint * closestWorldPoint = nil;
		float closestIntersection = INFINITY, t1, t2;

		for (ARWorldPoint * worldPoint in worldPoints) {
			// We need to calculate collision detection in the same coordinate system as drawn on screen.
			Vec3 offset = [origin calculateRelativePositionOf:worldPoint];
			
			// Calculate actual (non-scaled) distance.
			float distance = offset.length();
			
			// Cull the object if it is outside the view bounds.
			if (distance < _minimumDistance || distance > _maximumDistance) {
				continue;
			}

			ARBrowser::BoundingBox box = [worldPoint.model boundingBox];			
			box = box.transform([worldPoint transform]);

			box.min += offset;
			box.max += offset;

			//ARBrowser::BoundingSphere sphere(box.center(), box.radius());

			// Box ray-slab intersection requires a line segment, not just a line.
			if (box.intersectsWith(ray.origin, ray.direction * _maximumDistance, t1, t2)) {
				if (t1 < closestIntersection) {
					closestIntersection = t1;
					closestWorldPoint = worldPoint;
				}
			}
		}

		if (closestWorldPoint) {
			[self.delegate browserView:self didSelect:closestWorldPoint];
		}
	}
}

- (void) drawRadar {
	ARWorldLocation * origin = [self.motionModelController worldLocation];
	CMAcceleration gravity = [self.motionModelController currentGravity];
	//NSLog(@"Bearing: %0.3f", origin.rotation);
	
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
			delta.z = 0;
			
			if (delta.length() == 0) {
				radarPoints.push_back(delta);
			} else {
				// Normalize the distance of the point
				//const float LF = 10.0;
				//float length = log10f((delta.length() / LF) + 1) * LF;
				float length = sqrt(delta.length() / _maximumDistance);
				
				// Normalize the vector so we can scale its length appropriately.
				delta.normalize();
				
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
	
	MATRIX orthoProjection;
	MatrixOrthoRH(orthoProjection, viewSize.width, viewSize.height, -1, 1, false);
	glMultMatrixf(orthoProjection.f);
	
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
		Vec3 up(0, 0, +1);
		Vec3 g(-gravity.x, -gravity.y, -gravity.z);
		g.normalize();
		
		float sz = acos(up.dot(g));
		
		// We only do this if there is sufficient rotation of the device around the vertical axis.
		if (sz > 0.1) {
			// Simplified version of the line/plane intersection test, since the plane and line are from the origin.
			Vec3 at = g + (up * -(up.dot(g)));
			at.normalize();
			
			Vec3 north(0, 1, 0);
			
			rotationAxis = at.cross(north);
			forwardAngle = acos(at.dot(north));
		} else {
			flat = YES;
		}
	}
	
	if (!flat) {
		glRotatef(-forwardAngle * ARBrowser::R2D, rotationAxis.x, rotationAxis.y, rotationAxis.z);		
	} else {
		// We do this to avoid strange behaviour around the vertical axis:
		glRotatef([origin rotation], 0, 0, 1);
	}
	
	ARBrowser::renderRadar(radarPoints, radarEdgePoints, scale / 2.0);
	
	if (!flat) {		
		Mat44 inverseViewMatrix;
		MatrixInverse(inverseViewMatrix, _viewMatrix);
		
		// This matrix now contains the transform where +Y maps to North
		// The North axis of the phone is mapped to global North axis.
		Vec3 north(0, 1, 0); //, deviceNorth;
		//NSLog(@"  Device north: %0.3f, %0.3f, %0.3f", deviceNorth.x, deviceNorth.y, deviceNorth.z);
		
		Vec3 forward(0, 0, -1), deviceForward;
		// We calculate the forward vector in global space where (0, 1, 0) is north, (0, 0, -1) is down, (1, 0, 0) is approximately east.
		MatrixVec3Multiply(deviceForward, forward, inverseViewMatrix);
		//NSLog(@"Device forward: %0.3f, %0.3f, %0.3f", deviceForward.x, deviceForward.y, deviceForward.z);
		
		deviceForward.z = 0;
		deviceForward.normalize();
		
		float bearing = acos(deviceForward.dot(north));
		Vec3 r = deviceForward.cross(north).normalize();
		
		//NSLog(@"Bearing: %0.3f", bearing);
		glRotatef(-bearing * ARBrowser::R2D, r.x, r.y, r.z);
		ARBrowser::renderRadarFieldOfView();
	}
	
	glPopMatrix();
	
	glMatrixMode(GL_PROJECTION);
	glPopMatrix();
}

- (void) update {
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
	
	CMAcceleration gravity = [self.motionModelController currentGravity];
	
	// Calculate the camera paremeters
	{
		glMatrixMode(GL_PROJECTION);
		glLoadIdentity();
		
		glMatrixMode(GL_MODELVIEW);
		glLoadIdentity();
		
		// This moves the camera back slightly and improves the perspective for debugging purposes.
		//glTranslatef(0.0, 0.0, -2.0);
		
		// F defines the negative normal for the plain
		// x -> latitude (horizontal, red marker points east)
		// y -> longitude (vertical, green marker points north)
		// z -> altitude (altitude, blue marker points up)
		Vec3 _f(gravity.x, gravity.y, gravity.z);
		_f.normalize();
		
		Vec3 f(_f.x, _f.y, _f.z);
		Vec3 down(0, 0, -1);
		
		//NSLog(@"f: %0.4f, %0.4f, %0.4f, Length: %0.4f", _f.x, _f.y, _f.z, _f.length());
		
		float sz = acos(down.dot(f));
		
		//NSLog(@"Angle: %0.5f", sz);
		
		if (sz > 0.01) {
			Vec3 s = down.cross(f);
			
			//NSLog(@"d x f: %0.4f, %0.4f, %0.4f, Lenght: %0.4f", s.x, s.y, s.z, s.length());
			
			glRotatef(sz * ARBrowser::R2D, s.x, s.y, s.z);
		}
		
		// Move the origin down 1 meter.
		glTranslatef(0.0, 0.0, -1.0);
	}
	
	// Load the camera projection matrix
	glMatrixMode(GL_PROJECTION);
	
	CGSize viewSize = [self bounds].size;
	
	MATRIX perspectiveProjection;
	MatrixPerspectiveFovRH(perspectiveProjection, 40.0 * ARBrowser::D2R, viewSize.width / viewSize.height, 0.1f, 1000.0f, 0);
	glMultMatrixf(perspectiveProjection.f);
	
	glMatrixMode(GL_MODELVIEW);
	ARWorldLocation * origin = [self.motionModelController worldLocation];
	
	glRotatef([origin rotation], 0, 0, 1);
	
	glGetFloatv(GL_PROJECTION_MATRIX, _projectionMatrix.f);
	glGetFloatv(GL_MODELVIEW_MATRIX, _viewMatrix.f);
	
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
		
		delta.z = -2;
		
		//NSLog(@"Delta: %0.3f, %0.3f, %0.3f", delta.x, delta.y, delta.z);
		
		// Distance as a bird flies (e.g. ignoring altitude)
		Vec3 birdFlys = delta;
		birdFlys.z = 0;
		
		// Calculate actual (non-scaled) distance.
		float distance = birdFlys.length();
		
		if (distance < _minimumDistance || distance > _maximumDistance) {
			continue;
		}
		
		visibleWorldPoints.push_back((ARBrowserVisibleWorldPoint){distance, delta, point});
	}
	
	// Depth sort the visible objects.
	std::sort(visibleWorldPoints.begin(), visibleWorldPoints.end());
	
	for (std::size_t i = 0; i < visibleWorldPoints.size(); i += 1) {
		const ARBrowserVisibleWorldPoint & p = visibleWorldPoints[i];
		glPushMatrix();
		
		glTranslatef(p.delta.x, p.delta.y, p.delta.z);
		
		glRotatef(p.point.rotation, 0.0, 0.0, 1.0);
		glMultMatrixf(p.point.transform.f);
		[p.point.model draw];
		
		// Render the bounding sphere for debugging.
		//ARBrowser::VerticesT points;
		//ARBoundingSphere sphere = [[point model] boundingSphere];
		//ARBrowser::generateGlobe(points, sphere.radius);
		
		//glTranslatef(sphere.center.x, sphere.center.y, sphere.center.z);
		//ARBrowser::renderVertices(points);
		
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
