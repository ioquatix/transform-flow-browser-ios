//
//  ARWorldPoint.h
//  This file is part of the "transform-flow" project, and is released under the MIT license.
//
//  Created by Samuel Williams on 13/04/11.
//  Copyright, 2013, by Samuel G. D. Williams.
//

#import <Foundation/Foundation.h>
#import "ARWorldLocation.h"
#import <MapKit/MapKit.h>

/// Simple bounding sphere data structure.
typedef struct {
	Vec3 center;
	float radius;
} ARBoundingSphere;

namespace ARBrowser {
	class BoundingBox;
};

/// Provides the basic interface for renderable objects on the screen.
@protocol ARRenderable
/// Draw the object.
- (void) draw;

/// Return a bounding sphere for the object.
- (ARBoundingSphere) boundingSphere;

/// Returns a bounding box for the object.
- (ARBrowser::BoundingBox) boundingBox;
@end

/// Provides a renderable model and associated metadata for a given ARWorldLocation.
@interface ARWorldPoint : ARWorldLocation <MKAnnotation>

/// The renderable model for the given location.
@property(nonatomic,retain) id<ARRenderable> model;

/// The local transform applied to the model.
@property(nonatomic,assign) Mat44 transform;

/// The associated metadata for the given location.
/// This property is the primary method by which additional data should be managed for a specific point, e.g. street address, telephone number.
@property(nonatomic,retain) NSMutableDictionary * metadata;

/// Return true of the point will render using earth-centered earth-fixed coordinates:
@property(nonatomic,assign) BOOL fixed;

/// Title for MKAnnotation (returns metadata.title)
- (NSString *)title;

/// Subtitle for MKAnnotation (returns metadata.subtitle)
- (NSString *)subtitle;

@end
