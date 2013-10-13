//
//  ARBrowserViewController.h
//  This file is part of the "transform-flow" project, and is released under the MIT license.
//
//  Created by Samuel Williams on 5/04/11.
//  Copyright, 2013, by Samuel G. D. Williams.
//

#import <UIKit/UIKit.h>

#import "ARBrowserView.h"
#import "ARVSLogger.h"

typedef struct {
	CGFloat distance;
	CGFloat scale;
} ARScaleMarker;

/// Simple example of an ARBrowserViewDelegate.
@interface ARBrowserViewController : UIViewController <ARGLViewDelegate, ARBrowserViewDelegate> {
	NSArray * _worldPoints;
}

@property(nonatomic,retain) NSArray * worldPoints;
@property(nonatomic,retain) ARVSLogger * logger;
@property(nonatomic,retain) ARBrowserView * browserView;

- (void)startTrial;

@end
