//
//  ARObjectModel.h
//  This file is part of the "transform-flow" project, and is released under the MIT license.
//
//  Created by Samuel Williams on 27/06/11.
//  Copyright, 2013, by Samuel G. D. Williams.
//

// This file is a private header and should not be included directly.

#import <Foundation/Foundation.h>

#include "ARModel.h"
#include "ARRendering.h"

/// Provides a wrapper for ARBrowser::Model which implements ARRenderable
@interface ARObjectModel : NSObject<ARRenderable> {
@private
	NSString * _name;
	NSString * _directory;
	
	ARBrowser::Model * mesh;
}

/// Load a model with the given name from the given directory.
/// Because .obj models consist of more than one file, we need to know the files <tt>[name].obj</tt> and <tt>[name].mtl</tt> and the associated directory for loading texture data.
- initWithName: (NSString*)name inDirectory: (NSString*)directory;

- (void) draw;
- (ARBoundingSphere) boundingSphere;

@end
