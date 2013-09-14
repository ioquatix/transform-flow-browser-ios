//
//  ARViewModel.h
//  This file is part of the "transform-flow" project, and is released under the MIT license.
//
//  Created by Samuel Williams on 3/08/11.
//  Copyright, 2013, by Samuel G. D. Williams.
//

#import "ARModel.h"

#import "ARRendering.h"

@interface ARViewModel : NSObject<ARRenderable> {
	GLuint billboardTexture;
	
	BOOL _dirty;
	UIView * _overlay;
	
	float _scale;
}

@property(nonatomic, retain) IBOutlet UIView * overlay;
@property(nonatomic, assign) float scale;

/// Next time the billboard is generated, update the view.
- (void) setNeedsUpdate;
- (void) updateNow;

@end
