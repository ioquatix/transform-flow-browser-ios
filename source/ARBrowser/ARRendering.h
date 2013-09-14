//
//  ARRendering.h
//  This file is part of the "transform-flow" project, and is released under the MIT license.
//
//  Created by Samuel Williams on 11/11/10.
//  Copyright, 2013, by Samuel G. D. Williams.
//
 
#ifndef _ARBROWSER_RENDERING_H
#define _ARBROWSER_RENDERING_H

#include "Math/Vector.h"
#include "Math/Matrix.h"

#include "ARWorldPoint.h"

#include <string>
#include <vector>
#include <sstream>
#include <fstream>
#include <map>

#include <GLKit/GLKit.h>

// Draw a green bounding box around models.
//#define AR_DRAW_BOUNDING_BOX

/// The main namespace for the ARBrowser C++ implementation.
namespace ARBrowser {
	const double R2D = (180.0 / M_PI);
	const double D2R = (M_PI / 180.0);
	
	typedef std::vector<Vec3> VerticesT;
	
	void generateGrid (VerticesT & points);
	void generateGlobe (VerticesT & points, float radius);

	void renderVertices(const VerticesT & vertices, GLenum mode = GL_LINES);
	
	/// The size of the compass is fixed from -20 <-> 20.
	const float RadarDiameter = 40.0;
	
	/// Render a ring with radius r around the Z axis.
	void renderRing (float r);
	
	/// Render a radar using OpenGL at the origin.
	/// Points are points within the compass, edgePoints are points on the edge of the compass.
	void renderRadar (VerticesT & points, VerticesT & edgePoints, float pointScale = 1.0);
    
	void renderRadarFieldOfView();
	
	/// Renders a square box of size s.
	void renderMarker (float s);
	
	/// Renders an x,y,z axis at the origin.
	void renderAxis ();
	
	/// Simple representation of 4-component colour.
	struct Color4f {
		float r, g, b, a;
	};
	
	/// The position, texture coordinate and normal of a vertex.
	struct ObjMeshVertex {
		Vec3 pos;
		Vec2 texcoord;
		Vec3 normal;
	};

	/// A triangle that can be rendered as part of an object model.
	struct ObjMeshFace{
		ObjMeshVertex vertices[3];
	};

	/// A mesh consists of a list of triangle faces and an associated material
	struct ObjMesh{
		std::string material;
		std::vector<ObjMeshFace> faces;
	};
	
	/// A material references any required textures for rendering.
	struct ObjMaterial {
	public:
		ObjMaterial ();
		~ObjMaterial ();
		
		ObjMaterial (const ObjMaterial & other);
		ObjMaterial & operator= (const ObjMaterial & other);
		
		void enable ();
		void disable ();
		
		Color4f ambient;
		
		/// Path to the diffuse map texture (e.g. basic surface colour).
		std::string diffuseMapPath;
		
		/// The actual reference to the loaded texture.
		GLKTextureInfo * diffuseMapTexture;
	};
	
	/// An aligned bounding box class which provides basic intersection tests.
	struct BoundingBox {
		BoundingBox();
		BoundingBox(Vec3 _min, Vec3 _max);
		
		/// Add a point to the box.
		/// If the point is outside the box, the box is expanded to include the point.
		void add(Vec3 pt);
		
		/// The lower left coordinate of the box.
		Vec3 min;
		
		/// The upper right coordinate of the box.
		Vec3 max;
		
		/// Incremented when a point is added to the box.
		unsigned count;

		/// Convert to bounding sphere - this is the center of the box.
		Vec3 center() const;
		
		/// Convert to bounding sphere - this is the distance from the center to the corner.
		float radius() const;
		
		/// Check if a line from origin in direction intersects with the box.
		/// To calculate the point of entrace or exit, use t1 or t2 respectively: <tt>origin + (direction * tn)</tt>
		/// @returns t1 The time of entry of the line into the box.
		/// @returns t2 The time of exit of the line into the box.
		bool intersectsWith(Vec3 origin, Vec3 direction, float & t1, float & t2) const;

		BoundingBox transform(const Mat44 & transform) const;
	};

	/// Render a bounding box:
	void renderBoundingBox(const BoundingBox & box);
	
	/// A basic sphere that can be transformed and provides basic intersection tests.
	struct BoundingSphere {
		BoundingSphere(Vec3 _center, float _radius);
		
		BoundingSphere transform(const Mat44 & transform);
		
		Vec3 center;
		float radius;
		
		bool intersectsWith(Vec3 origin, Vec3 direction, float & t1, float & t2) const;
	};
	
	/// Main .obj format model loader.
	class Model {
		public:
			typedef std::map<std::string, ObjMaterial> MaterialMapT;
			
		protected:
			std::vector<ObjMesh> m_mesh;
			MaterialMapT m_materials;
			BoundingBox m_boundingBox;
			
			void updateBoundingBox();
			
		public:
			Model (std::string name, std::string directory);
			
			void render ();
			
			const BoundingBox & boundingBox () const { return m_boundingBox; }
	};
	
	/// Result of intersection tests using findIntersection().
	struct IntersectionResult {
		unsigned hits;
		Vec3 origin, direction;
		
		std::size_t index;
		float t1, t2;
	};
	
	/// Find intersections using a given point on the screen, and a set of bounding spheres.
	bool findIntersection(const Mat44 & proj, const Mat44 & view, float viewport[4], const Vec3 & origin, Vec2 screenCoords, const std::vector<BoundingSphere> & spheres, IntersectionResult & result);

	struct Ray {
		Vec3 origin, direction;
	};

	Ray calculateRayFromScreenCoordinates(const Mat44 & proj, const Mat44 & view, float viewport[4], Vec2 screenCoords);

	bool intersectAtY0(const Ray & ray, Vec3 & at);

	BoundingBox calculateViewFrustumBoundingBox(const Mat44 & proj, const Mat44 & view, float viewport[4]);

	float scaleFactorToFitFrustum(const BoundingBox & container, const BoundingBox & child);
}

#endif
