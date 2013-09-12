//
//  ARBrowserView.h
//  This file is part of the "transform-flow" project, and is released under the MIT license.
//
//  Created by Samuel Williams on 9/04/11.
//  Copyright, 2013, by Samuel G. D. Williams.
//

#import <UIKit/UIKit.h>

#import "ARGLView.h"
#import "ARVideoFrameController.h"
#import "ARVideoBackground.h"

@class ARBrowserView, ARWorldLocation, ARWorldPoint, ARLocationController;

/// The main data source/delegate for ARBrowserView
@protocol ARBrowserViewDelegate <ARGLViewDelegate>

/// Return a list of world points, e.g. instances of ARWorldPoint objects.
- (NSArray*)worldPoints;

@optional
/// Returns a list of world points that will be rendered from a given point
- (NSArray*)worldPointsFromLocation:(ARWorldLocation *)origin withinDistance:(float)distance;

/// Called when an object is selected on screen by the user.
- (void)browserView: (ARBrowserView*)view didSelect:(ARWorldPoint*)point;

/// Render things like grids, markers, etc:
- (void) renderInLocalCoordinatesForBrowserView:(ARBrowserView *)view;

@end

/// The main augmented reality view, which combines the ARVideoBackground with the ARLocationController.
@interface ARBrowserView : ARGLView

/// The delegate for the ARBrowserView must implement ARBrowserViewDelegate.
@property(nonatomic,assign) id<ARBrowserViewDelegate> delegate;

/// Controls culling of near objects. Objects closer than this distance are not rendered.
@property(nonatomic,assign) float minimumDistance;

/// Controls culling of distance objects. Objects further away than this are not rendered.
@property(nonatomic,assign) float maximumDistance;

/// Objects closer than this appear the same size.
@property(nonatomic,assign) float nearDistance;

/// Objects further away than this size appear the same size.
@property(nonatomic,assign) float farDistance;

/// Display a small on-screen compass.
@property(assign) BOOL displayRadar;

/// The center of the radar on the screen, expressed in relative coordinates.
/// (-1, -1) is the top left, (1, 1) is the bottom right. 
@property(assign) CGPoint radarCenter;

/// Display a background horizon grid.
@property(assign) BOOL displayGrid;

/// The location controller to use for position information.
@property(nonatomic,retain) ARLocationController * locationController;

@end
