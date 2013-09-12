//
//  MapController.mm
//  This file is part of the "transform-flow" project, and is released under the MIT license.
//
//  Created by Samuel Williams on 22/11/10.
//  Copyright 2010 Samuel Williams. All rights reserved.
//

#import "ARMapViewController.h"
#import "ARLocationController.h"

@interface ARMapViewController ()
- (void) _updateCurrentLocation: (CLLocation*)location;
@end

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
	ARLocationController * locationController = [ARLocationController sharedInstance];
	
	//[self addObserver:locationController forKeyPath:@"currentLocation" options:nil context:ARLocationChanged];
	//[self addObserver:locationController forKeyPath:@"currentHeading" options:nil context:ARHeadingChanged];

	if (_firstTime) {
		[self recenter:self];
		_firstTime = NO;
	}

	//self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;

	[_mapView removeAnnotations:[_mapView annotations]];
	[_mapView addAnnotations:_worldPoints];
	[_mapView setMapType:_mapType];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];

	NSLog(@"Window bounds: %@", NSStringFromCGRect(self.view.window.bounds));
	NSLog(@"Window frame: %@", NSStringFromCGRect(self.view.window.frame));
	NSLog(@"View bounds: %@", NSStringFromCGRect(self.view.bounds));
}

- (void) viewDidUnload {
	ARLocationController * locationController = [ARLocationController sharedInstance];

	[self removeObserver:locationController forKeyPath:@"currentLocation"];
	[self removeObserver:locationController forKeyPath:@"currentHeading"];
}

- (IBAction) recenter: (id)sender {
	ARLocationController * locationController = [ARLocationController sharedInstance];

	[self _updateCurrentLocation:[locationController currentLocation]];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
	//[self _updateCurrentLocation:newLocation];
}

- (void) _updateCurrentLocation: (CLLocation*)location {
	MKCoordinateRegion region;
	region.center = [location coordinate];
	
	// This defines the size of the region around the center
	region.span.latitudeDelta = 0.002;
	region.span.longitudeDelta = 0.002;
	
	[_mapView setRegion:region animated:YES];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
	//float r = -1 * newHeading.magneticHeading * (M_PI / 180);
	//_mapView.transform = CGAffineTransformMakeRotation(r);
	//_mapView.layer.transform = CATransform3DMakeRotation(r, 0.0, 0.0, 1.0);
}

- (void) setMapType:(MKMapType)mapType {
	_mapType = mapType;
	[_mapView setMapType:mapType];
}
		 
@end
