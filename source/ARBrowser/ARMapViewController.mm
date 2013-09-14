//
//  MapController.mm
//  This file is part of the "transform-flow" project, and is released under the MIT license.
//
//  Created by Samuel Williams on 22/11/10.
//  Copyright 2010 Samuel Williams. All rights reserved.
//

#import "ARMapViewController.h"

@implementation ARMapViewController

@synthesize worldPoints = _worldPoints;

- (id) init
{
	self = [super initWithNibName:@"ARMapViewController" bundle:nil];
	
	if (self != nil) {
		_firstTime = YES;
	}
	
	return self;
}

- (void)dealloc {
    [self setWorldPoints:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

- (void) viewDidLoad {
	_mapView.mapType = _mapType;
	_mapView.showsUserLocation = YES;

	[_mapView removeAnnotations:_mapView.annotations];
	[_mapView addAnnotations:_worldPoints];

	if (_firstTime) {
		[self recenter:self];
		
		_firstTime = NO;
	}
}

- (IBAction) recenter: (id)sender
{
	_mapView.centerCoordinate = _mapView.userLocation.coordinate;
}

- (void) _updateCurrentLocation: (CLLocation*)location {
	MKCoordinateRegion region;
	region.center = [location coordinate];
	
	// This defines the size of the region around the center
	region.span.latitudeDelta = 0.002;
	region.span.longitudeDelta = 0.002;
	
	[_mapView setRegion:region animated:YES];
}

- (void) setMapType:(MKMapType)mapType {
	_mapType = mapType;
	[_mapView setMapType:mapType];
}
		 
@end
