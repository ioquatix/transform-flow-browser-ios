//
//  ARViewModel.m
//  This file is part of the "transform-flow" project, and is released under the MIT license.
//
//  Created by Samuel Williams on 3/08/11.
//  Copyright, 2013, by Samuel G. D. Williams.
//

#import "ARViewModel.h"
#import "ARLocationController.h"

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
	glGetFloatv(GL_MODELVIEW_MATRIX, m.f);

	CMAcceleration gravity = [[ARLocationController sharedInstance] currentGravity];		
	Vec3 f(gravity.x, gravity.y, gravity.z);
	f.normalize();
	
	//NSLog(@"f: %0.3f, %0.3f, %0.3f", f.x, f.y, f.z);
	
	Vec3 up(0, 0, 1);
	
	// The x-axis we desire.
	Vec3 r = up.cross(f);
	r.normalize();
	
	Vec3 x(1.0, 0.0, 0.0);

	//NSLog(@"r: %0.3f, %0.3f, %0.3f", r.x, r.y, r.z);
	
	// Calculate the angle between what we want and regular x-axis
	float angle = acos(x.dot(r));
	
	Vec3 scale(
		Vec3(m.f[0], m.f[4], m.f[8]).length(),
		Vec3(m.f[1], m.f[5], m.f[9]).length(),
		Vec3(m.f[2], m.f[6], m.f[10]).length()
	);
	
	// Discard all transform except translation.
	m.f[ 0] = 1; m.f[ 4] = 0; m.f[ 8] = 0;
	m.f[ 1] = 0; m.f[ 5] = 1; m.f[ 9] = 0;
	m.f[ 2] = 0; m.f[ 6] = 0; m.f[10] = 1;
	
	glMatrixMode(GL_MODELVIEW);
	glPushMatrix();
	glLoadIdentity();
	
	// Load the original translation and scale:
	glMultMatrixf(m.f);
	glScalef(scale.x, scale.y, scale.z);
	
	//NSLog(@"Angle: %0.3f degrees", angle * ARBrowser::R2D);
	
	if (angle > 0.01) {
		// Adjust view rotation:
		Vec3 axis = x.cross(r);
		axis.normalize();
		
		glRotatef(angle * ARBrowser::R2D, axis.x, axis.y, axis.z);
		
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
