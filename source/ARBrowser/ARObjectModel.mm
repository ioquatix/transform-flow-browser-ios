//
//  ARObjectModel.m
//  This file is part of the "transform-flow" project, and is released under the MIT license.
//
//  Created by Samuel Williams on 27/06/11.
//  Copyright, 2013, by Samuel G. D. Williams.
//

#import "ARObjectModel.h"


@implementation ARObjectModel

- initWithName: (NSString*)name inDirectory: (NSString*)directory
{
    self = [super init];
	
    if (self) {
		_name = [name copy];
		_directory = [directory copy];
    }
    
    return self;
}

- (void)dealloc
{
	if (mesh)
		delete mesh;
}

- (void) loadMesh
{
	if (!mesh) {
        mesh = new ARBrowser::Model([_name UTF8String], [_directory UTF8String]);
	}
}

- (void) draw
{	
	[self loadMesh];
	
	glColor4f(1.0, 1.0, 1.0, 1.0);

	mesh->render();
}

- (ARBoundingSphere) boundingSphere
{
	[self loadMesh];

	if (mesh) {
		ARBrowser::BoundingBox box = mesh->boundingBox();
		
		ARBoundingSphere sphere = {box.center(), box.radius()};
		
		return sphere;
	} else {
		ARBoundingSphere sphere = {Vec3(0, 0, 0), 0};
		
		return sphere;
	}
}

- (ARBrowser::BoundingBox) boundingBox
{
	[self loadMesh];

	if (mesh) {
		return mesh->boundingBox();
	} else {
		ARBrowser::BoundingBox box;
		
		return box;
	}
}

@end
