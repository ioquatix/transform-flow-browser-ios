//
//  ARBrowserAppDelegate.h
//  This file is part of the "transform-flow" project, and is released under the MIT license.
//
//  Created by Samuel Williams on 5/04/11.
//  Copyright, 2013, by Samuel G. D. Williams.
//

#import <UIKit/UIKit.h>

@class ARBrowserViewController;
@class ARMapViewController;



/// The main application delegate which initialises the window and manages the associated view controller.
@interface ARBrowserAppDelegate : NSObject <UIApplicationDelegate> {
	NSArray * _worldPoints;
	UIView * _informationView;
}

@property(nonatomic, retain) IBOutlet UIWindow *window;
@property(nonatomic, retain) IBOutlet UITabBarController * mainViewController;
@property(nonatomic, retain) IBOutlet ARBrowserViewController * browserViewController;
@property(nonatomic, retain) IBOutlet ARMapViewController * mapViewController;
@property(nonatomic, retain) IBOutlet UIView * informationView;

@property(nonatomic,retain) NSArray * worldPoints;

@end
