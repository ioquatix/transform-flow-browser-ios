//
//  ARViewModel.m
//  This file is part of the "transform-flow" project, and is released under the MIT license.
//
//  Created by Samuel Williams on 3/08/11.
//  Copyright, 2013, by Samuel G. D. Williams.
//

#import "ARViewModel.h"

#import <QuartzCore/CALayer.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

@implementation ARViewModel

@synthesize overlay = _overlay, scale = _scale;

- (id)init
{
    self = [super init];
    if (self) {
		glGenTextures(1, &billboardTexture);
		_dirty = YES;
		
		_scale = 1.0;
    }
    
    return self;
}

- (void)dealloc {
    glDeleteTextures(1, &billboardTexture);	
}

// http://stackoverflow.com/questions/4118778/render-contents-of-uiview-as-an-opengl-texture
- (void) updateTextureWithView:(UIView *)view 
{
    NSLog(@"Updating view texture...");
	//GLuint saveName = 0;
	//glGetIntegerv(GL_TEXTURE_BINDING_2D, &saveName);
	
	glBindTexture(GL_TEXTURE_2D, billboardTexture);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	
	// make space for an RGBA image of the view
	GLubyte *pixelBuffer = (GLubyte *)malloc(4 * view.bounds.size.width * view.bounds.size.height);

	// create a suitable CoreGraphics context
	CGColorSpaceRef colourSpace = CGColorSpaceCreateDeviceRGB();
	CGContextRef context = CGBitmapContextCreate(pixelBuffer, 
		view.bounds.size.width, view.bounds.size.height, 
		8, 4*view.bounds.size.width, 
		colourSpace, 
		kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
	
	CGColorSpaceRelease(colourSpace);
	
	// draw the view to the buffer
	[view.layer renderInContext:context];
	
	// upload to OpenGL
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, view.bounds.size.width, view.bounds.size.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, pixelBuffer);

	// clean up
	CGContextRelease(context);
	free(pixelBuffer);
	
	//glBindTexture(GL_TEXTURE_2D, saveName);
}

- (void) setNeedsUpdate
{
	_dirty = YES;
}

- (void) updateNow
{
	[self updateTextureWithView:_overlay];
	_dirty = NO;
}

- (void) draw
{
	using namespace Euclid::Numerics;

	// We can only update if there was a view given.
	if (_dirty && _overlay) {
		[self updateNow];
	}
	
	// ARBrowser::renderMarker(1.0);
	
	// Draw view rectangle
	float s = _scale;
	float verts[] = {
		 s, -s,  0,
		-s, -s,  0,
		-s,  s,  0,
		 s,  s,  0,
	};
	
	float texCoords[] = {
		1.0, 0.0,
		0.0, 0.0,
		0.0, 1.0,
		1.0, 1.0
	};
	
	Mat44 m;
	glGetFloatv(GL_MODELVIEW_MATRIX, m.data());

	// Location Controller code:
	//CMAcceleration gravity = [[ARLocationController sharedInstance] currentGravity];
	//Vec3 f(gravity.x, gravity.y, gravity.z);

	Vec3 f(0, -1, 0);
	f.normalize();
	
	//NSLog(@"f: %0.3f, %0.3f, %0.3f", f.x, f.y, f.z);
	
	Vec3 up(0, 0, 1);
	
	// The x-axis we desire.
	Vec3 r = cross_product(up, f).normalize();
	
	Vec3 x(1.0, 0.0, 0.0);

	//NSLog(@"r: %0.3f, %0.3f, %0.3f", r.x, r.y, r.z);
	
	// Calculate the angle between what we want and regular x-axis
	float angle = acos(x.dot(r));

	auto mf = m.data();

	Vec3 scale(
		Vec3(mf[0], mf[4], mf[8]).length(),
		Vec3(mf[1], mf[5], mf[9]).length(),
		Vec3(mf[2], mf[6], mf[10]).length()
	);
	
	// Discard all transform except translation.
	mf[ 0] = 1; mf[ 4] = 0; mf[ 8] = 0;
	mf[ 1] = 0; mf[ 5] = 1; mf[ 9] = 0;
	mf[ 2] = 0; mf[ 6] = 0; mf[10] = 1;
	
	glMatrixMode(GL_MODELVIEW);
	glPushMatrix();
	glLoadIdentity();
	
	// Load the original translation and scale:
	glMultMatrixf(mf);
	glScalef(scale[X], scale[Y], scale[Z]);
	
	//NSLog(@"Angle: %0.3f degrees", angle * ARBrowser::R2D);
	
	if (angle > 0.01) {
		// Adjust view rotation:
		Vec3 axis = cross_product(x, r).normalize();
		
		glRotatef(angle * ARBrowser::R2D, axis[X], axis[Y], axis[Z]);
		
		//NSLog(@"Axis: %0.3f, %0.3f, %0.3f", axis.x, axis.y, axis.z);
	}
	
	glEnable(GL_TEXTURE_2D);
	glBindTexture(GL_TEXTURE_2D, billboardTexture);
	
	glEnable (GL_BLEND);
	glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);

	glColor4f(1, 1, 1, 1);
	glVertexPointer(3, GL_FLOAT, 0, verts);
	glTexCoordPointer(2, GL_FLOAT, 0, texCoords);
	glDrawArrays(GL_TRIANGLE_FAN, 0, 4);

	glDisableClientState(GL_VERTEX_ARRAY);
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	
	glDisable(GL_TEXTURE_2D);
	glDisable(GL_BLEND);
	
	glPopMatrix();
}

- (ARBoundingSphere) boundingSphere
{
	// Billboard is always bounded by the sphere of size _scale, because it is always pointing at the user.
	ARBoundingSphere sphere = {Vec3(0, 0, 0), _scale};
		
	return sphere;
}

- (ARBrowser::BoundingBox) boundingBox
{
	ARBrowser::BoundingBox box(Vec3(-_scale, -_scale, -_scale), Vec3(_scale, _scale, _scale));

	return box;
}

@end
