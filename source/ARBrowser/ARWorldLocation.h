//
//  ARWorldLocation.h
//  This file is part of the "transform-flow" project, and is released under the MIT license.
//
//  Created by Samuel Williams on 6/04/11.
//  Copyright, 2013, by Samuel G. D. Williams.
//

#import <Foundation/Foundation.h>

#import <CoreLocation/CoreLocation.h>

#import <Euclid/Numerics/Vector.h>
#import <Euclid/Numerics/Matrix.h>

typedef double ARLocationRadians;
typedef double ARLocationAltitude;

struct ARLocationCoordinate {
	ARLocationRadians latitude;
	ARLocationRadians longitude;
};

using Euclid::Numerics::Vec3;
using Euclid::Numerics::Mat44;
typedef Euclid::Numerics::Vector<3, double> Vec3d;


/// Convert latitude/longitude/altitude to Earth-Centered Earth-Fixed coordinates:
Vec3d convertToECEF(CLLocationCoordinate2D coordinate, ARLocationAltitude altitude);

/// Calculate the bearing between two points on the surface of the earth, where from -> north represents a bearing of zero.
CLLocationDirection calculateBearingBetween(ARLocationCoordinate from, ARLocationCoordinate to);

/// Calculate the distance between two points at a given altitude:
CLLocationDistance calculateDistanceBetween(ARLocationCoordinate from, ARLocationCoordinate to, ARLocationAltitude altitude);

/// Convert a CLLocationCoordinate2D from degrees to an ARLocationCoordinate in radians:
ARLocationCoordinate convertFromDegrees(CLLocationCoordinate2D location);

/// A location on the surface of the earth.
/// Provides functionality to convert between spherical and cartesian coordinates.
@interface ARWorldLocation : NSObject {
	CLLocationCoordinate2D _coordinate;
	ARLocationAltitude _altitude;
	
	Vec3 _position;
	CLLocationDirection _rotation;
}

/// The location in latitude/longitude.
@property(readonly) CLLocationCoordinate2D coordinate;

/// The distance from the center of the sphere.
@property(readonly) ARLocationAltitude altitude;

/// The cartesian location in x,y,z.
@property(readonly) Vec3 position;

/// The rotation from north, i.e. heading direction.
@property(readonly) CLLocationDirection rotation;

- initWithCoordinate:(CLLocationCoordinate2D)coordinate altitude:(ARLocationAltitude)altitude;

+ (ARWorldLocation *) fromLocation: (CLLocation *)location;

/// Calculates the position in cartesian coordinates from a given latitude/longitude pair and altitude.
- (void) setCoordinate:(CLLocationCoordinate2D)location altitude:(ARLocationAltitude)radius;

/// Calculate the relative position of one object to another.
/// This function may fail at the north and south pole due to inherent limitations of spherical coordinates.
/// @returns <tt>x</tt> corresponding to longitude (east, west)
/// @returns <tt>y</tt> corresponding to latitude (north, south)
/// @returns <tt>z</tt> corresponding to altitude (up, down).
- (Vec3) calculateRelativePositionOf:(ARWorldLocation*)other;

/// Helper function to set location from a given CLLocation.
/// @internal
- (void) setLocation: (CLLocation*)location;

/// Helper function to set heading from a given CLHeading.
/// @internal
- (void) setBearing: (float)bearing;

- (CLLocationDistance) sphericalDistanceFrom:(ARWorldLocation *)destination;
- (CLLocationDistance) distanceFrom:(ARWorldLocation *)destination;

- (void)setLocationByInterpolatingFrom:(ARWorldLocation*)from to:(ARWorldLocation*)to atTime:(float)time;

// A helper that returns a unit vector pointing in the direction of the bearing.
- (CGPoint) normalizedDirection;

@end
