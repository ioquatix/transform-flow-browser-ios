//
//  ARWorldLocation.m
//  This file is part of the "transform-flow" project, and is released under the MIT license.
//
//  Created by Samuel Williams on 6/04/11.
//  Copyright, 2013, by Samuel G. D. Williams.
//

#import "ARWorldLocation.h"

#import "ARRendering.h"

// Convenience
const double D2R = (M_PI / 180.0);

#pragma mark -
#pragma mark Geodetic utilities definition

// WGS 84 semi-major axis constant in meters
const double WGS84_A = 6378137.0;
// WGS 84 eccentricity
const double WGS84_E = 8.1819190842622e-2;

// Converts latitude, longitude to ECEF coordinate system
void convertLocationToECEF(double lat, double lon, double alt, double *x, double *y, double *z) {
	double clat = cos(lat * D2R);
	double slat = sin(lat * D2R);
	double clon = cos(lon * D2R);
	double slon = sin(lon * D2R);
	
	double N = WGS84_A / sqrt(1.0 - WGS84_E * WGS84_E * slat * slat);
	
	*x = (N + alt) * clat * clon;
	*y = (N + alt) * clat * slon;
	*z = (N * (1.0 - WGS84_E * WGS84_E) + alt) * slat;
}

Vec3d convertToECEF(CLLocationCoordinate2D coordinate, ARLocationAltitude altitude) {
	double x, y, z;
	
	convertLocationToECEF(coordinate.latitude, coordinate.longitude, altitude, &x, &y, &z);
	
	return (Vec3d){x, y, z};
}

// Coverts ECEF to ENU coordinates centered at given lat, lon
void convertECEFtoENU(double lat, double lon, double x, double y, double z, double xr, double yr, double zr, double *e, double *n, double *u)
{
	double clat = cos(lat * D2R);
	double slat = sin(lat * D2R);
	double clon = cos(lon * D2R);
	double slon = sin(lon * D2R);
	double dx = x - xr;
	double dy = y - yr;
	double dz = z - zr;
	
	*e = -slon*dx  + clon*dy;
	*n = -slat*clon*dx - slat*slon*dy + clat*dz;
	*u = clat*clon*dx + clat*slon*dy + slat*dz;
}

CLLocationDirection calculateBearingBetween(ARLocationCoordinate from, ARLocationCoordinate to) {
	// We need to calculate the angle between <_location -> north pole>, and <_location -> marker>
	// http://www.movable-type.co.uk/scripts/latlong.html
	// Δlat = lat2− lat1
	// Δlong = long2− long1
	
	// θ =	atan2(	sin(Δlong).cos(lat2),
	//				cos(lat1).sin(lat2) − sin(lat1).cos(lat2).cos(Δlong) )
	
	CLLocationDirection bearing = atan2(sin(to.longitude - from.longitude) * cos(to.latitude), 
										cos(from.latitude) * sin(to.latitude) -
										sin(from.latitude) * cos(to.latitude) * cos(to.longitude - from.longitude));
	
	return bearing * ARBrowser::R2D;
}

CLLocationDistance calculateDistanceBetween(ARLocationCoordinate a, ARLocationCoordinate b, ARLocationAltitude altitude) {
	//Haversine formula:
	// a = sin²(Δlat/2) + cos(lat1).cos(lat2).sin²(Δlong/2)
	// c = 2.atan2(√a, √(1−a))
	// d = R.c
 	// where R is earth’s radius (mean radius = 6,371km);
	
	altitude += WGS84_A;
	
	ARLocationCoordinate delta;
	delta.latitude = b.latitude - a.latitude;
	delta.longitude = b.longitude - a.longitude;
	
	double sx = sin(delta.latitude/2.0), sy = sin(delta.longitude/2.0);
	double t = sx*sx + cos(a.latitude) * cos(b.latitude) * sy*sy;
	double c = 2.0 * atan2(sqrt(t), sqrt(1.0-t));
	
	double distance = fabs(altitude * c);
	
	return distance;
}

ARLocationCoordinate convertFromDegrees(CLLocationCoordinate2D location) {
	ARLocationCoordinate result;
	
	result.latitude = location.latitude * D2R;
	result.longitude = location.longitude * D2R;
	
	return result;
}

@implementation ARWorldLocation

@synthesize coordinate = _coordinate, altitude = _altitude, position = _position, rotation = _rotation;

- initWithCoordinate:(CLLocationCoordinate2D)coordinate altitude:(ARLocationAltitude)altitude
{
	self = [super init];

	if (self) {
		[self setCoordinate:coordinate altitude:altitude];
	}

	return self;
}

+ (ARWorldLocation *) fromLocation: (CLLocation *)location {
	ARWorldLocation * worldLocation = [ARWorldLocation new];
	
	[worldLocation setCoordinate:location.coordinate altitude:location.altitude];
	
	return worldLocation;
}

- (void) setCoordinate:(CLLocationCoordinate2D)coordinate altitude:(ARLocationAltitude)altitude {
	// Retain original coordinates
	_coordinate = coordinate;
	_altitude = altitude;
	
	double x, y, z;
	convertLocationToECEF(_coordinate.latitude, _coordinate.longitude, altitude, &x, &y, &z);
	
	_position = Vec3(x, y, z);
}

- (Vec3) calculateRelativePositionOf:(ARWorldLocation*)other
{
	ARLocationCoordinate from = convertFromDegrees(_coordinate), to = convertFromDegrees(other->_coordinate);
	
	ARLocationCoordinate horizontal = {from.latitude, to.longitude};
	ARLocationCoordinate vertical = {to.latitude, from.longitude};
		
	Vec3 r;
	// We calculate x by varying longitude (east <-> west)
	r.x = calculateDistanceBetween(from, horizontal, _altitude);
	
	// We calculate y by varying latitude (north <-> south)
	r.y = calculateDistanceBetween(from, vertical, _altitude);
	
	// If longitude is less than origin, inverse x coordinate.
	if (to.longitude < from.longitude)
		r.x *= -1.0;
	
	// If latitude is less than origin, inverse y coordinate
	if (to.latitude < from.latitude)
		r.y *= -1.0;
	
	r.z = other.altitude - _altitude;
	
	return r;
}

- (void) setLocation:(CLLocation*)location
{
	[self setCoordinate:location.coordinate altitude:location.altitude];
}

- (void) setBearing: (float)bearing
{
	_rotation = bearing;
}

- (NSString*) description
{
	return [NSString stringWithFormat:@"<ARWorldPoint: %0.8f %0.8f>", _coordinate.latitude, _coordinate.longitude];
}

- (CLLocationDistance) sphericalDistanceFrom:(ARWorldLocation *)location {
	ARLocationCoordinate to = convertFromDegrees(_coordinate), from = convertFromDegrees(location->_coordinate);
	
	return calculateDistanceBetween(from, to, (_altitude + location->_altitude) / 2.0);
}

- (CLLocationDistance) distanceFrom:(ARWorldLocation *)location {
	return (_position - location.position).length();
}

- (void)setLocationByInterpolatingFrom:(ARWorldLocation*)from to:(ARWorldLocation*)to atTime:(float)time {
	// We have two GPS coordinates, interpolate between them, this method is a bit inexact.. the correct method would be to use SLERP.
	CLLocationCoordinate2D coordinate;
	
	coordinate.latitude = from.coordinate.latitude * (1.0 - time) + to.coordinate.latitude * time;
	coordinate.longitude = from.coordinate.longitude * (1.0 - time) + to.coordinate.longitude * time;
	
	[self setCoordinate:coordinate altitude:self.altitude];
}

- (CGPoint)normalizedDirection {
	return (CGPoint){sinf(_rotation * ARBrowser::D2R), -cosf(_rotation * ARBrowser::D2R)};
}

@end
