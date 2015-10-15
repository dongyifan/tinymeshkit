/*
 
	Copyright 2011 Etay Meiri
 
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef MESH_H
#define	MESH_H

#include <map>
#include <vector>
#include <array>
#import <OpenGLES/ES2/glext.h>
#include <Importer.hpp>      // C++ importer interface
#include <scene.h>       // Output data structure
#include <postprocess.h> // Post processing flags

#include "ogldev_util.h"
#include "ogldev_math_3d.h"
#include "ogldev_texture.h"
#include "ogldev_camera.h"
#include "ogldev_pipeline.h"

#import <Foundation/Foundation.h>

enum
{
    UNIFORM_MODELVIEWPROJECTION_MATRIX,
    UNIFORM_NORMAL_MATRIX,
    UNIFORM_DIFFUSECOLOR,
    UNIFORM_S_DIFFERUSE,
    NUM_UNIFORMS
};

struct Vertex
{
    Vector3f m_pos;
    Vector2f m_tex;
    Vector3f m_normal;
    
    Vertex() {}
    
    Vertex(const Vector3f& pos, const Vector2f& tex, const Vector3f& normal)
    {
        m_pos    = pos;
        m_tex    = tex;
        m_normal = normal;
    }
};


class Mesh
{
public:
    aiVector3D sceneCenter;
    float normalizedScale;
    Mesh();
    ~Mesh();
    
    bool LoadMesh(const void* buffer, size_t length, NSString* modelPath);
    
    void Render(float width, float height, std::array<GLint, NUM_UNIFORMS>uniforms, std::array<float, 2> rotate);
    
private:
    bool InitFromScene(const aiScene* pScene, NSString* modelPath);
    void InitMesh(unsigned int Index, const aiMesh* paiMesh);
    bool InitMaterials(const aiScene* pScene, NSString* modelPath);
    void Clear();
    void recursiveRender(const aiNode* nd, aiMatrix4x4 parentModelMatrix, float width, float height, std::array<GLint, NUM_UNIFORMS>uniforms);
    
#define INVALID_MATERIAL 0xFFFFFFFF
    
    struct MeshEntry {
        MeshEntry();
        
        ~MeshEntry();
        
        void Init(const std::vector<Vertex>& Vertices,
                  const std::vector<unsigned int>& Indices);
        
        GLuint VB;
        GLuint IB;
        unsigned int NumIndices;
        unsigned int MaterialIndex;
        GLenum drawMode;
    };
    
    std::vector<MeshEntry> m_Entries;
    std::vector<Texture*> m_Textures;
    std::vector<aiColor4D> m_DiffuseColors;
    Assimp::Importer Importer;
    const aiScene* pScene;
    aiMatrix4x4 rotateMatrix;
};


#endif	/* MESH_H */

