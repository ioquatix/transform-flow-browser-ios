//
//  MapController.h
//  This file is part of the "transform-flow" project, and is released under the MIT license.
//
//  Created by Samuel Williams on 22/11/10.
//  Copyright 2010 Samuel Williams. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface ARMapViewController : UIViewController <CLLocationManagerDelegate> {
	IBOutlet MKMapView * _mapView;
	
	BOOL _firstTime;
	
	MKMapType _mapType;
	
	NSArray * _worldPoints;
}

@property(nonatomic,retain) NSArray * worldPoints;

- (IBAction) recenter: (id)sender;
- (void) setMapType:(MKMapType)mapType;

@end
