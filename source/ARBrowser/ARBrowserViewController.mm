//
//  ARBrowserViewController.m
//  This file is part of the "transform-flow" project, and is released under the MIT license.
//
//  Created by Samuel Williams on 5/04/11.
//  Copyright, 2013, by Samuel G. D. Williams.
//

#import "ARBrowserViewController.h"

#import "ARWorldPoint.h"
#import "ARModel.h"

#import "ARBrowserView.h"
#import "ARMotionModelController.h"

#include <Euclid/Numerics/Vector.h>

#include <TransformFlow/BasicSensorMotionModel.h>
#include <TransformFlow/HybridMotionModel.h>

typedef enum {
	ARBasicSensorMotionModel = 1,
	ARHybridMotionModel = 2
} ARTrialMode;

@interface ARBrowserViewController () {
	float _targetDistance;
	float _targetFrameCounter;
}

@property ARTrialMode trialMode;

@property(nonatomic,retain) NSDictionary * targetModels;
@property(nonatomic,retain) UIImageView * crosshairsView;

@end

@implementation ARBrowserViewController

- (void)startTrial
{
	Dream::Core::TimeT now = Dream::Core::system_time();

	self.logger = [ARVSLogger loggerForDocumentName:@"Trial"];
	self.trialMode = ARHybridMotionModel;

	[self.logger logWithFormat:@"Start, %0.4f", now];

	[self updateTrialWaypoint];
}

- (void)toggleTrialMode
{
	switch (self.trialMode) {
		case ARBasicSensorMotionModel:
			self.trialMode = ARHybridMotionModel;
			break;
		case ARHybridMotionModel:
			self.trialMode = ARBasicSensorMotionModel;
			break;
	}
}

- (void)updateTrialWaypoint
{
	if (self.trialMode == ARBasicSensorMotionModel) {
		self.browserView.motionModelController.motionModel = new TransformFlow::BasicSensorMotionModel;

		[self performSelector:@selector(addMarker:) withObject:@"target-red" afterDelay:1.0];
	} else if (self.trialMode == ARHybridMotionModel) {
		self.browserView.motionModelController.motionModel = new TransformFlow::HybridMotionModel;

		[self performSelector:@selector(addMarker:) withObject:@"target-blue" afterDelay:1.0];
	}

	[self.browserView.motionModelController.locationManager startUpdatingLocation];
}

- (void)addMarker:(NSString *)name
{
	CLLocation * location = self.browserView.motionModelController.locationManager.location;

	if (location == nil || location.horizontalAccuracy > 100.0) {
		NSLog(@"Location not accurate enough: %@", location);

		[self performSelector:@selector(addMarker:) withObject:name afterDelay:1.0];

		return;
	} else {
		NSLog(@"Adding marker %@ at location: %@", name, location);
	}

	[self.browserView.motionModelController.locationManager stopUpdatingLocation];

	CLLocationCoordinate2D targetCoordinate = location.coordinate;

	ARWorldPoint * target = [ARWorldPoint new];

	Euclid::Numerics::Vec2 offset(rand(), rand());
	offset = (offset - (RAND_MAX / 2)).normalize(0.0002);

	targetCoordinate.latitude += offset[0];
	targetCoordinate.longitude += offset[1];

	[target setCoordinate:targetCoordinate altitude:0.0];
	[target setModel:self.targetModels[name]];

	ARWorldLocation * currentWorldLocation = [ARWorldLocation fromLocation:location];
	CLLocationDistance distance = [currentWorldLocation distanceFrom:target];

	// This name is used for debugging output.
	[target.metadata setObject:name forKey:@"name"];

	AudioServicesPlaySystemSound(1113);
	self.worldPoints = @[target];

	Dream::Core::TimeT now = Dream::Core::system_time();

	[self.logger logWithFormat:@"Origin, %0.4f, %0.8f, %0.8f", now, location.coordinate.latitude, location.coordinate.longitude];
	[self.logger logWithFormat:@"Marker, %0.4f, %@, %0.8f, %0.8f, %0.3f", now, name, targetCoordinate.latitude, targetCoordinate.longitude, distance];

	_targetDistance = 10.0;
}

// This may be called from a rendering thread, so we do any interactions back on the main queue:
- (void) didPointTowards:(ARWorldPoint *)worldPoint withDistanceFromCenter:(float)distance
{
	Dream::Core::TimeT now = Dream::Core::system_time();

	if (distance < 0.1) {
		_targetFrameCounter += 1;

		dispatch_async(dispatch_get_main_queue(), ^{
			CGPoint center = self.crosshairsView.center;
			CGRect frame = self.crosshairsView.frame;

			frame.size.width = 60 - _targetFrameCounter;
			frame.size.height = 60 - _targetFrameCounter;

			self.crosshairsView.frame = frame;
			self.crosshairsView.center = center;
		});
	} else {
		if (_targetFrameCounter != 0) {
			_targetFrameCounter = 0;

			dispatch_async(dispatch_get_main_queue(), ^{
				CGPoint center = self.crosshairsView.center;
				CGRect frame = self.crosshairsView.frame;

				frame.size.width = 60;
				frame.size.height = 60;

				self.crosshairsView.frame = frame;
				self.crosshairsView.center = center;
			});
		}
	}

	if (distance < 0.1 && _targetFrameCounter > 30) {
		dispatch_async(dispatch_get_main_queue(), ^{
			AudioServicesPlayAlertSound(1022);
			[self.logger logWithFormat:@"Hit, %0.4f, %0.3f", now, distance];

			// Reset size of frame:
			CGPoint center = self.crosshairsView.center;
			CGRect frame = self.crosshairsView.frame;

			frame.size.width = 60;
			frame.size.height = 60;

			self.crosshairsView.frame = frame;
			self.crosshairsView.center = center;

			//AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
			self.worldPoints = @[];

			[self toggleTrialMode];
			[self updateTrialWaypoint];
		});
	} else if (distance < 2.0) {
		if (_targetDistance > 2.0) {
			dispatch_async(dispatch_get_main_queue(), ^{
				AudioServicesPlayAlertSound(1050);
				[self.logger logWithFormat:@"Found, %0.4f, %0.3f", now, distance];
			});
		}

		_targetDistance = distance;
	} else if (distance > 4.5) {
		_targetDistance = distance;
	}
}

- (void)loadView {
	// Standard view size for iOS UIWindow
	CGRect frame = CGRectMake(0, 0, 320, 480);

	// Initialize the OpenGL view
	self.browserView = [[ARBrowserView alloc] initWithFrame:frame];

	// Print out FPS information.
	[self.browserView setDebug:YES];

	// Turn off the grid.
	//[self.browserView setDisplayGrid:NO];
	[self.browserView setDisplayGrid:NO];

	[self.browserView setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];

	[self.browserView setDelegate:self];

	// Change the minimum and maximum distance of objects.
	[self.browserView setMinimumDistance:1.0];
	
	// Icons will never get bigger past this point until the minimumDistance where they are culled.
	[self.browserView setNearDistance:3.0];
	
	// Icons will never get smaller past this point until the maximumDistance where they are culled.
	[self.browserView setFarDistance:25.0];
	
	[self.browserView setMaximumDistance:400.0];

	UIImageView * imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
	imageView.image = [UIImage imageNamed:@"crosshairs"];
	imageView.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin);

	self.crosshairsView = imageView;

	UIView * containerView = [[UIView alloc] initWithFrame:frame];
	containerView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;

	[containerView addSubview:self.browserView];

	[containerView addSubview:imageView];
	imageView.center = containerView.center;

	[self setView:containerView];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];

	NSLog(@"ARBrowserViewController: Resuming Rendering.");

	[self.browserView setCurrentContext];

	UIImageView * billboardView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 128, 128)];

	NSMutableDictionary * targets = [NSMutableDictionary new];

	billboardView.image = [UIImage imageNamed:@"target-red"];
	targets[@"target-red"] = [ARModel viewModelWithView:billboardView];

	billboardView.image = [UIImage imageNamed:@"target-blue"];
	targets[@"target-blue"] = [ARModel viewModelWithView:billboardView];

	self.targetModels = targets;

	[self.browserView clearCurrentContext];

	[self startTrial];

	[self.browserView startRendering];
	
	[super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
	NSLog(@"ARBrowserViewController: Pausing Rendering.");

	[self.browserView stopRendering];
	
	[super viewWillDisappear:animated];
}

- (void) update: (ARGLView*) view {
	// Additional OpenGL Rendering here.
}

- (void) browserView: (ARBrowserView*)view didSelect:(ARWorldPoint*)point {
	NSLog(@"Browser view did select: %@", point);
	
	NSString * developer = [point.metadata objectForKey:@"developer"];
	NSString * address = [point.metadata objectForKey:@"address"];
	
	NSLog(@"Developer %@ at %@", developer, address);
}

- (void)didResizeSurfaceForView:(ARGLView *)view
{
}

// Optional - supply either -worldPoints or this:
//- (NSArray *)worldPointsFromLocation:(ARWorldLocation *)origin withinDistance:(float)distance {
	// You can apply your own filtering or asynchronous fetching here.
//	return self.worldPoints;
//}

// This method may be deprecated in the future..
- (void)renderInLocalCoordinatesForBrowserView:(ARBrowserView *)view {
	
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	[super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
	
	[UIView setAnimationsEnabled:NO];
	[self adjustForOrientation:toInterfaceOrientation];
	[UIView setAnimationsEnabled:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return TRUE;
}

// This code rotates the ARGLView in the opporsite direction so that the camera is always oriented correctly:
-(void)adjustForOrientation:(UIInterfaceOrientation)orientation {
	if (orientation == UIInterfaceOrientationLandscapeLeft) {
		self.view.transform = CGAffineTransformMakeRotation(0.5 * M_PI);
	} else if (orientation == UIInterfaceOrientationLandscapeRight) {
		self.view.transform = CGAffineTransformMakeRotation(-0.5 * M_PI);
	} else {
		self.view.transform = CGAffineTransformIdentity;
	}

	CGSize frameSize = self.view.frame.size;
	CGPoint center = CGPointMake(frameSize.width / 2.0, frameSize.height / 2.0);
	self.view.center = center;
}

@end
