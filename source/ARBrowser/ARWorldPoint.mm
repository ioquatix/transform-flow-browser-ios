//
//  ARWorldPoint.m
//  This file is part of the "transform-flow" project, and is released under the MIT license.
//
//  Created by Samuel Williams on 13/04/11.
//  Copyright, 2013, by Samuel G. D. Williams.
//

#import "ARWorldPoint.h"

@implementation ARWorldPoint

- (id)init
{
    self = [super init];
    if (self) {
        self.metadata = [[NSMutableDictionary alloc] init];
		
		MatrixIdentity(_transform);
    }
    
    return self;
}

- (void)dealloc
{
	self.metadata = nil;
}

- (NSString*) description {
	id name = [_metadata objectForKey:@"name"];
	
	if (name)
		return [NSString stringWithFormat:@"<ARWorldPoint: %0.8f %0.8f '%@'>", _coordinate.latitude, _coordinate.longitude, name];
	else
		return [super description];
}

- (NSString*) title
{
	NSString * title = [_metadata objectForKey:@"title"];
	
	if (title)
		return title;
	
	NSString * name = [_metadata objectForKey:@"name"];
	
	if (name)
		return name;
	
	return @"ARWorldPoint";
}

- (NSString*) subtitle
{
	NSString * subtitle = [_metadata objectForKey:@"subtitle"];
	
	if (subtitle)
		return subtitle;
	
	return [self description];
}

@end
