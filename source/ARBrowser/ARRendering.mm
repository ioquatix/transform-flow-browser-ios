//
//  ARRendering.mm
//  This file is part of the "transform-flow" project, and is released under the MIT license.
//
//  Created by Samuel Williams on 11/11/10.
//  Copyright, 2013, by Samuel G. D. Williams.
//

#include "ARRendering.h"
#include <algorithm>
#include <iostream>

/**
 * The MIT License
 *
 * Copyright (c) 2010 Wouter Lindenhof (http://limegarden.net)
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

namespace ARBrowser {
	
	void renderRing (float r) {
		const unsigned STEPS = 32;
		
		Vec3 k(r, 0, 0);
		Mat44 rotation = rotate<Z>(R360 / STEPS);

		VerticesT vertices;
		for (unsigned i = 0; i < STEPS; i++) {
			vertices.push_back(k);

			k = rotation * k;
		}
		
		renderVertices(vertices, GL_LINE_LOOP);
	}
    
	void renderRadarFieldOfView()
	{
		VerticesT vertices;
		vertices.push_back(Vec3(0, 0, 0));
		vertices.push_back(Vec3(-8, 20, 0));
		vertices.push_back(Vec3(8, 20, 0));
		
		glEnable(GL_BLEND);
		glBlendFunc(GL_SRC_ALPHA, GL_DST_ALPHA);
		
		glColor4f(0.8, 0.8, 0.8, 0.5);
		renderVertices(vertices, GL_TRIANGLES);
		
		glDisable(GL_BLEND);
	}
	
	void renderRadar (VerticesT & points, VerticesT & edgePoints, float pointScale) {
		glDisable(GL_DEPTH_TEST);
		
		VerticesT ring;
		
		glLineWidth(2);
		glColor4f(0.5, 0.5, 1.0, 1.0);
		renderRing(5);
		renderRing(10);
		renderRing(15);
		renderRing(20);
		
		VerticesT vertices;
		vertices.push_back(Vec3(-20, 0, 0));
		vertices.push_back(Vec3( 20, 0, 0));
		vertices.push_back(Vec3(0, -20, 0));
		vertices.push_back(Vec3(0,  0, 0));
		glColor4f(1.0, 1.0, 1.0, 0.8);
		renderVertices(vertices, GL_LINES);
		
		vertices.clear();
		
		vertices.push_back(Vec3(0,  0, 0));		
		vertices.push_back(Vec3(0, 20, 0));
		glColor4f(0.8, 0.8, 1.0, 0.8);
		renderVertices(vertices, GL_LINES);
		
		glLineWidth(3);
		
		// Points within compass
		glPointSize(8.0 * pointScale);
		glColor4f(0.0, 0.0, 0.0, 1.0);
		renderVertices(points, GL_POINTS);
		
		glPointSize(6.0 * pointScale);
		glColor4f(1.0, 1.0, 1.0, 1.0);
		renderVertices(points, GL_POINTS);
		
		// Edge points
		glPointSize(8.0 * pointScale);
		glColor4f(0.0, 0.0, 0.0, 1.0);
		renderVertices(edgePoints, GL_POINTS);
		
		glPointSize(6.0 * pointScale);
		glColor4f(0.2, 0.2, 1.0, 1.0);
		renderVertices(edgePoints, GL_POINTS);
		
		glEnable(GL_DEPTH_TEST);
		glPointSize(1.0);
	}
	
	void generateGrid (VerticesT & points) {		
		const float LOWER = -10;
		const float UPPER = 10;
		const float STEP = 0.5;
		
		for (float x = LOWER; x <= UPPER; x += STEP) {		
			points.push_back(Vec3(x, LOWER, 0));
			points.push_back(Vec3(x, UPPER, 0));
			
			points.push_back(Vec3(LOWER, x, 0));
			points.push_back(Vec3(UPPER, x, 0));
		}
	}

	void renderVertices(const VerticesT & vertices, GLenum mode) {
		glVertexPointer(3, GL_FLOAT, 0, &vertices[0]);
		glEnableClientState(GL_VERTEX_ARRAY);
		
		glDrawArrays(mode, 0, vertices.size());
		
		glDisableClientState(GL_VERTEX_ARRAY);
	}
	
	void renderMarker (float s) {
		float verts[] = {
			s, s,-s,
			-s, s,-s,
			-s, s, s,
			s, s, s,
			
			s,-s, s,
			-s,-s, s,
			-s,-s,-s,
			s,-s,-s,
			
			s, s, s,
			-s, s, s,
			-s,-s, s,
			s,-s, s,
			
			s,-s,-s,
			-s,-s,-s,
			-s, s,-s,
			s, s,-s,
			
			s, s,-s,
			s, s, s,
			s,-s, s,
			s,-s,-s,
			
			-s, s, s,
			-s, s,-s,
			-s,-s,-s,
			-s,-s, s
		};
		
		glEnableClientState(GL_VERTEX_ARRAY);
		
		glColor4f(0, 1, 0, 1);
		glVertexPointer(3, GL_FLOAT, 0, verts);
		glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
		
		glColor4f(1, 0, 1, 1);
		glVertexPointer(3, GL_FLOAT, 0, verts + 12);
		glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
		
		glColor4f(0, 0, 1, 1);
		glVertexPointer(3, GL_FLOAT, 0, verts + 24);
		glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
		
		glColor4f(1, 1, 0, 1);
		glVertexPointer(3, GL_FLOAT, 0, verts + 36);
		glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
		
		glColor4f(1, 0, 0, 1);
		glVertexPointer(3, GL_FLOAT, 0, verts + 48);
		glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
		
		glColor4f(0, 1, 1, 1);
		glVertexPointer(3, GL_FLOAT, 0, verts + 60);
		glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
	}
	
	void renderAxis ()
	{
		std::vector<Vec3> vertices;
		std::vector<Vec4> colors;
		
		vertices.push_back(Vec3(0, 0, 0));
		colors.push_back(Vec4(1.0, 0.0, 0.0, 1.0));
		
		vertices.push_back(Vec3(10.0, 0.0, 0.0));
		colors.push_back(Vec4(1.0, 0.0, 0.0, 1.0));
		
		vertices.push_back(Vec3(0, 0, 0));
		colors.push_back(Vec4(0.0, 1.0, 0.0, 1.0));
		
		vertices.push_back(Vec3(0.0, 10.0, 0.0));
		colors.push_back(Vec4(0.0, 1.0, 0.0, 1.0));
		
		vertices.push_back(Vec3(0, 0, 0));
		colors.push_back(Vec4(0.0, 0.0, 1.0, 1.0));
		
		vertices.push_back(Vec3(0.0, 0.0, 10.0));
		colors.push_back(Vec4(0.0, 0.0, 1.0, 1.0));
		
		glLineWidth(5.0);
		
		glColorPointer(4, GL_FLOAT, 0, &colors[0]);
		glEnableClientState(GL_COLOR_ARRAY);
		
		glVertexPointer(3, GL_FLOAT, 0, &vertices[0]);
		glEnableClientState(GL_VERTEX_ARRAY);
		
		glDrawArrays(GL_LINES, 0, vertices.size());
		
		glDisableClientState(GL_VERTEX_ARRAY);
		glDisableClientState(GL_COLOR_ARRAY);
		
		glLineWidth(1.0);
	}

	void renderBoundingBox(const BoundingBox & box)
	{
		// Bounding Box Debug
		VerticesT vertices;
		Vec3 a = box.min;
		Vec3 b = box.max;
		
		vertices.push_back(Vec3(a[X], a[Y], a[Z]));
		vertices.push_back(Vec3(b[X], a[Y], a[Z]));

		vertices.push_back(Vec3(a[X], a[Y], a[Z]));
		vertices.push_back(Vec3(a[X], b[Y], a[Z]));
		
		vertices.push_back(Vec3(a[X], a[Y], a[Z]));
		vertices.push_back(Vec3(a[X], a[Y], b[Z]));
		
		vertices.push_back(Vec3(b[X], b[Y], b[Z]));
		vertices.push_back(Vec3(a[X], b[Y], b[Z]));
		
		vertices.push_back(Vec3(b[X], b[Y], b[Z]));
		vertices.push_back(Vec3(b[X], a[Y], b[Z]));
		
		vertices.push_back(Vec3(b[X], b[Y], b[Z]));
		vertices.push_back(Vec3(b[X], b[Y], a[Z]));
		
		glColor4f(0.0, 1.0, 0.0, 1.0);
		renderVertices(vertices, GL_LINES);
	}
	
	const char * TOKEN_VERTEX_POS = "v";
	const char * TOKEN_VERTEX_NOR = "vn";
	const char * TOKEN_VERTEX_TEX = "vt";
	const char * TOKEN_FACE = "f";
	const char * TOKEN_USE_MATERIAL = "usemtl";
	
	struct _ObjMeshFaceIndex {
		_ObjMeshFaceIndex() {
			pos_index[0] = pos_index[1] = pos_index[2] = 0;
			tex_index[0] = tex_index[1] = tex_index[2] = -1;
			nor_index[0] = nor_index[1] = nor_index[2] = -1;
		}
		
		std::string material;
		int pos_index[3];
		int tex_index[3];
		int nor_index[3];
	};
	
	/// Call this function to load a model, only loads triangulated meshes.
	static void loadMesh(std::string filename, std::vector<ObjMesh> & mesh) {
		std::vector<Vec3> positions;
		std::vector<Vec2> texcoords;
		std::vector<Vec3> normals;
		std::vector<_ObjMeshFaceIndex> faces;
		std::string currentMaterial = "";
		
		unsigned materialCount = 1;
		
		/**
		 * Load file, parse it
		 * Lines beginning with:
		 * '#'  are comments can be ignored
		 * 'v'  are vertices positions (3 floats that can be positive or negative)
		 * 'vt' are vertices texcoords (2 floats that can be positive or negative)
		 * 'vn' are vertices normals   (3 floats that can be positive or negative)
		 * 'f'  are faces, 3 values that contain 3 values which are separated by / and <space>
		 */
		
		std::ifstream filestream;
		filestream.open(filename.c_str());
		
		if (!filestream) {
			std::cerr << "Couldn't load file: " << filename << std::endl;
		}
		
		// No longer depending on char arrays thanks to: Dale Weiler
		std::string line_stream;
		while(std::getline(filestream, line_stream)) {
			std::stringstream str_stream(line_stream);
			std::string type_str;
			str_stream >> type_str;
			if (type_str == TOKEN_VERTEX_POS) {
				Vec3 pos;
				str_stream >> pos[X] >> pos[Y] >> pos[Z];
				positions.push_back(pos);
			} else if (type_str == TOKEN_VERTEX_TEX) {
				Vec2 tex;
				str_stream >> tex[X] >> tex[Y];
				// Inverse y coordinates
				tex[Y] = 1.0 - tex[Y];
				texcoords.push_back(tex);
			} else if (type_str == TOKEN_VERTEX_NOR) {
				Vec3 nor;
				str_stream >> nor[X] >> nor[Y] >> nor[Z];
				normals.push_back(nor);
			} else if (type_str == TOKEN_FACE) {
				_ObjMeshFaceIndex face_index;
				face_index.material = currentMaterial;
				
				char interrupt;
				for(int i = 0; i < 3; ++i) {
					std::string vertex;
					str_stream >> vertex;
					
					std::stringstream vertex_stream;
					vertex_stream.str(vertex);
					
					vertex_stream >> face_index.pos_index[i] >> interrupt
					>> face_index.tex_index[i] >> interrupt
					>> face_index.nor_index[i];
				}
				faces.push_back(face_index);
			} else if (type_str == TOKEN_USE_MATERIAL) {
				str_stream >> currentMaterial;
				materialCount++;
			}
		}
		// Explicit closing of the file
		filestream.close();
		
		currentMaterial = "";
		mesh.reserve(materialCount);
		ObjMesh * currentMesh = NULL;
		
		for (size_t i = 0; i < faces.size(); ++i) {
			ObjMeshFace face;
			
			if (currentMesh != NULL && currentMaterial != faces[i].material) {
				currentMesh = NULL;
			}
			
			if (currentMesh == NULL) {
				mesh.resize(mesh.size() + 1);
				currentMesh = &mesh.back();
				currentMesh->material = faces[i].material;
				
				currentMaterial = faces[i].material;				
			}
			
			for(size_t j = 0; j < 3; ++j) {
				face.vertices[j].pos        = positions[faces[i].pos_index[j] - 1];
				
				if (faces[i].tex_index[j] != -1)
					face.vertices[j].texcoord   = texcoords[faces[i].tex_index[j] - 1];
				
				if (faces[i].nor_index[j] != -1)
					face.vertices[j].normal     = normals[faces[i].nor_index[j] - 1];
			}
			
			currentMesh->faces.push_back(face);
		}

		std::cerr << "Loaded " << faces.size() << " faces..." << std::endl;
	}
	
	static void loadMaterials(std::string filename, Model::MaterialMapT & materials) {
		std::ifstream filestream;
		filestream.open(filename.c_str());
		
		ObjMaterial * material = NULL;
		
		std::string line_stream;
		while (std::getline(filestream, line_stream)) {
			std::stringstream str_stream(line_stream);
			std::string type_str;
			str_stream >> type_str;
			
			if (type_str == "newmtl") {
				std::string name;
				str_stream >> name;
				
				material = &materials[name];
			} else if (type_str == "Ka" && material) {
				str_stream >> material->ambient.r >> material->ambient.g >> material->ambient.b;
				material->ambient.a = 1.0;
			} else if (type_str == "map_Kd") {
				std::string map_path;
				str_stream >> material->diffuseMapPath;
			}
		}
	}
	
	/// Loads textures from a directory for the given materials.
	static void loadTextures(std::string directory, Model::MaterialMapT & materials) {
		for (Model::MaterialMapT::iterator i = materials.begin(); i != materials.end(); i++) {
			ObjMaterial & material = (*i).second;
			
			std::string fullPath = directory + "/" + material.diffuseMapPath;
			NSString * imagePath = [NSString stringWithCString:fullPath.c_str() encoding:NSUTF8StringEncoding];

			material.diffuseMapTexture = [GLKTextureLoader textureWithContentsOfFile:imagePath options:nil error:nil];
		}
	}
	
	ObjMaterial::ObjMaterial () : diffuseMapTexture(NULL)
	{
		ambient.r = ambient.g = ambient.b = ambient.a = 1.0;
	}
	
	ObjMaterial::~ObjMaterial () {
	}
	
	ObjMaterial::ObjMaterial (const ObjMaterial & other) {
		(*this) = other;
	}
	
	ObjMaterial & ObjMaterial::operator= (const ObjMaterial & other) {
		this->diffuseMapTexture = other.diffuseMapTexture;
		this->ambient = other.ambient;
		
		return *this;
	}
	
	void ObjMaterial::enable () {
		if (diffuseMapTexture) {
			glBindTexture(GL_TEXTURE_2D, [diffuseMapTexture name]);
			glColor4f(ambient.r, ambient.g, ambient.b, ambient.a);
		}
	}
	
	void ObjMaterial::disable () {
		glBindTexture(GL_TEXTURE_2D, 0);
		glColor4f(1.0, 1.0, 1.0, 1.0);
	}
	
	Model::Model (std::string name, std::string directory) {
		assert(sizeof(Vec2) == (sizeof(float) * 2));
		assert(sizeof(Vec3) == (sizeof(float) * 3));
		
		loadMesh(directory + "/" + name + ".obj", m_mesh);
		
		if (m_mesh.size() == 0) {
			std::cerr << "Mesh " << name << " in directory " << directory << " had 0 faces!" << std::endl;
		}
		
		loadMaterials(directory + "/" + name + ".mtl", m_materials);
		loadTextures(directory, m_materials);
		updateBoundingBox();
	}
	
	void Model::updateBoundingBox() {
		for (std::size_t i = 0; i < m_mesh.size(); i++) {
			ObjMesh & mesh = m_mesh[i];
			
			for (std::size_t j = 0; j < mesh.faces.size(); j++) {
				m_boundingBox.add(mesh.faces[j].vertices[0].pos);
				m_boundingBox.add(mesh.faces[j].vertices[1].pos);
				m_boundingBox.add(mesh.faces[j].vertices[2].pos);
			}
		}
	}
	
	void Model::render () {		
		if (m_mesh.size() > 0) {			
			for (std::size_t i = 0; i < m_mesh.size(); i++) {
				MaterialMapT::iterator m = m_materials.find(m_mesh[i].material);
				std::vector<ObjMeshFace> & faces = m_mesh[i].faces;
				
				// Keep track of whether textures have been enabled:
				bool texturingEnabled = false;
				
				if (m != m_materials.end()) {
					m->second.enable();
					
					if (m->second.diffuseMapTexture) {
						glEnable(GL_TEXTURE_2D);
						
						glEnableClientState(GL_TEXTURE_COORD_ARRAY);
						glTexCoordPointer(2, GL_FLOAT, sizeof(ObjMeshVertex), (void*)&(faces[0].vertices[0].texcoord));
						
						texturingEnabled = true;
					}
				}
				
				glEnableClientState(GL_VERTEX_ARRAY);
				glVertexPointer(3, GL_FLOAT, sizeof(ObjMeshVertex), (void*)&(faces[0].vertices[0].pos));
				
				glEnableClientState(GL_NORMAL_ARRAY);
				glNormalPointer(GL_FLOAT, sizeof(ObjMeshVertex), (void*)&(faces[0].vertices[0].normal));
				
				glDrawArrays(GL_TRIANGLES, 0, faces.size() * 3);
				
				if (m != m_materials.end()) {
					m->second.disable();
					
					if (texturingEnabled) {
						glDisable(GL_TEXTURE_2D);
						
						glDisableClientState(GL_TEXTURE_COORD_ARRAY);
					}
				}
			}
			
			glDisableClientState(GL_VERTEX_ARRAY);
			glDisableClientState(GL_NORMAL_ARRAY);

#ifdef AR_DRAW_BOUNDING_BOX
			// Bounding Box Debug
			VerticesT vertices;
			Vec3 a = m_boundingBox.min;
			Vec3 b = m_boundingBox.max;
			
			vertices.push_back(Vec3(a[X], a[Y], a[Z]));
			vertices.push_back(Vec3(b[X], a[Y], a[Z]));

			vertices.push_back(Vec3(a[X], a[Y], a[Z]));
			vertices.push_back(Vec3(a[X], b[Y], a[Z]));
			
			vertices.push_back(Vec3(a[X], a[Y], a[Z]));
			vertices.push_back(Vec3(a[X], a[Y], b[Z]));
			
			vertices.push_back(Vec3(b[X], b[Y], b[Z]));
			vertices.push_back(Vec3(a[X], b[Y], b[Z]));
			
			vertices.push_back(Vec3(b[X], b[Y], b[Z]));
			vertices.push_back(Vec3(b[X], a[Y], b[Z]));
			
			vertices.push_back(Vec3(b[X], b[Y], b[Z]));
			vertices.push_back(Vec3(b[X], b[Y], a[Z]));
			
			glColor4f(0.0, 1.0, 0.0, 1.0);
			renderVertices(vertices, GL_LINES);
#endif
		}
	}

	BoundingBox::BoundingBox() : count(0) {
		min = Vec3(0, 0, 0);
		max = Vec3(0, 0, 0);
	}
	
	BoundingBox::BoundingBox(Vec3 _min, Vec3 _max) : min(_min), max(_max), count(0) {
		
	}
	
	static bool raySlabsIntersection(float start, float dir, float min, float max, float & tfirst, float & tlast)
	{
		if (dir == 0.0)
			return (start < max && start > min);
		
		float tmin = (min - start) / dir;
		float tmax = (max - start) / dir;
		
		if (tmin > tmax) std::swap(tmin, tmax);
		
		if (tmax < tfirst || tmin > tlast)
			return false;
		
		if (tmin > tfirst) tfirst = tmin;
		if (tmax < tlast) tlast = tmax;
		
		return true;
	}
	
	bool BoundingBox::intersectsWith(Vec3 origin, Vec3 direction, float & t1, float & t2) const {
		t1 = 0;
		t2 = 1;

		if (!raySlabsIntersection(origin[X], direction[X], min[X], max[X], t1, t2))
			return false;
		
		if (!raySlabsIntersection(origin[Y], direction[Y], min[Y], max[Y], t1, t2))
			return false;
		
		if (!raySlabsIntersection(origin[Z], direction[Z], min[Z], max[Z], t1, t2))
			return false;
		
		return true;
	}

	BoundingBox BoundingBox::transform(const Mat44 & transform) const {
		return BoundingBox(transform * min, transform * max);
	}

	BoundingSphere::BoundingSphere(Vec3 _center, float _radius) : center(_center), radius(_radius) {
		
	}

	bool BoundingSphere::intersectsWith(Vec3 origin, Vec3 direction, float & t1, float & t2) const {
		//Optimized method sphere/ray intersection
		Vec3 dst = origin - center;
		
		float b = dst.dot(direction);
		float c = dst.dot(dst) - (radius * radius);
		
		// If d is negative there are no real roots, so return 
		// false as ray misses sphere
		float d = b * b - c;
		
		if (d == 0.0) {
			t1 = (-b) - sqrtf(d);
			t2 = t1;
			return true; // Edges intersect
		} 
		
		if (d > 0) {
			t1 = (-b) - sqrtf(d);
			t2 = (-b) + sqrtf(d);
			return true; // Line passes through shape
		}
		
		return false;
	}
	
	BoundingSphere BoundingSphere::transform(const Mat44 & transform) {
		Vec3 edge = center + (Vec3(1, 0, 0) * radius);

		Vec3 newCenter = transform * center;
		Vec3 newEdge = transform * edge;

		return BoundingSphere(newCenter, (newEdge - newCenter).length());
	}
	
	void BoundingBox::add(Vec3 pt) {
		if (count == 0) {
			min = pt;
			max = pt;
		} else {
			if (pt[X] < min[X])
				min[X] = pt[X];
			
			if (pt[Y] < min[Y])
				min[Y] = pt[Y];
			
			if (pt[Z] < min[Z])
				min[Z] = pt[Z];
			
			if (pt[X] > max[X])
				max[X] = pt[X];
			
			if (pt[Y] > max[Y])
				max[Y] = pt[Y];
			
			if (pt[Z] > max[Z])
				max[Z] = pt[Z];
		}
		
		count++;
	}
	
	Vec3 BoundingBox::center() const {
		return (min + max) / 2.0;
	}

	float BoundingBox::radius() const {
		return (max - min).length() / 2.0;
	}
}
