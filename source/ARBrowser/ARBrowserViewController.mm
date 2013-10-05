//
//  ARBrowserViewController.m
//  This file is part of the "transform-flow" project, and is released under the MIT license.
//
//  Created by Samuel Williams on 5/04/11.
//  Copyright, 2013, by Samuel G. D. Williams.
//

#import "ARBrowserViewController.h"
#import "ARWorldPoint.h"

@implementation ARBrowserViewController

- (void)loadView {
	// Standard view size for iOS UIWindow
	CGRect frame = CGRectMake(0, 0, 320, 480);

	// Initialize the OpenGL view
	ARBrowserView * browserView = [[ARBrowserView alloc] initWithFrame:frame];

	// Print out FPS information.
	[browserView setDebug:YES];

	// Turn off the grid.
	//[browserView setDisplayGrid:NO];
	[browserView setDisplayGrid:NO];

	[browserView setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];

	[browserView setDelegate:self];

	// Change the minimum and maximum distance of objects.
	[browserView setMinimumDistance:1.0];
	
	// Icons will never get bigger past this point until the minimumDistance where they are culled.
	[browserView setNearDistance:3.0];
	
	// Icons will never get smaller past this point until the maximumDistance where they are culled.
	[browserView setFarDistance:25.0];
	
	[browserView setMaximumDistance:400.0];

	UIImageView * imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
	imageView.image = [UIImage imageNamed:@"crosshairs"];
	imageView.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin);

	[browserView addSubview:imageView];
	imageView.center = browserView.center;

	[self setView:browserView];
}

- (void)viewDidAppear:(BOOL)animated {
	NSLog(@"ARBrowserViewController: Resuming Rendering.");
		
	ARBrowserView * browserView = (ARBrowserView*)[self view];
	
	[browserView startRendering];
	
	[super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
	NSLog(@"ARBrowserViewController: Pausing Rendering.");
	
	ARBrowserView * browserView = (ARBrowserView*)[self view];
	
	[browserView stopRendering];
	
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
