//
//  ARModel.m
//  This file is part of the "transform-flow" project, and is released under the MIT license.
//
//  Created by Samuel Williams on 13/04/11.
//  Copyright, 2013, by Samuel G. D. Williams.
//

#import "ARModel.h"

#import "ARObjectModel.h"
#import "ARViewModel.h"

@implementation ARModel

+ (id<ARRenderable>) objectModelWithName:(NSString*)name inDirectory:(NSString*)directory
{
	return [[ARObjectModel alloc] initWithName:name inDirectory:directory];
}

+ (id<ARRenderable>) viewModelWithView: (UIView*)view
{
	ARViewModel * model = [[ARViewModel alloc] init];
	
	[model setOverlay:view];

	return model;
}

@end
