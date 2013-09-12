//
//  ARModel.h
//  This file is part of the "transform-flow" project, and is released under the MIT license.
//
//  Created by Samuel Williams on 13/04/11.
//  Copyright, 2013, by Samuel G. D. Williams.
//

#import <Foundation/Foundation.h>

#import "ARWorldPoint.h"

/// Provides a simple interface for loading ARRenderable models for use with ARWorldPoint.
@interface ARModel : NSObject

/// Load a given .obj model.
/// Because .obj models consist of more than one file, we need to know the files <tt>[name].obj</tt> and <tt>[name].mtl</tt> and the associated directory for loading texture data.
+ (id<ARRenderable>) objectModelWithName:(NSString*)name inDirectory:(NSString*)directory;

/// Create a billboad mesh with the given view.
/// Currently, for best results, the view must be a 2^n size.
+ (id<ARRenderable>) viewModelWithView: (UIView*)view;

@end
