//
//  Mesh.cpp
//  HelloGL
//
//  Created by DongYifan on 6/19/15.
//  Copyright (c) 2015 vanille. All rights reserved.
//

#include <assert.h>

#import <GLKit/GLKit.h>

#include "mesh.h"

void getBoundingBoxForNode(const aiScene* pScene, const aiNode* nd, aiVector3D& min, aiVector3D& max, aiMatrix4x4& trafo)
{
    aiMatrix4x4 prev;
    unsigned int n = 0, t;
    
    prev = trafo;
    trafo = trafo * nd->mTransformation;
    
    for (; n < nd->mNumMeshes; ++n)
    {
        const aiMesh* mesh = pScene->mMeshes[nd->mMeshes[n]];
        for (t = 0; t < mesh->mNumVertices; ++t)
        {
            aiVector3D tmp = mesh->mVertices[t];
            tmp *= trafo;
            
            min.x = std::min(min.x,tmp.x);
            min.y = std::min(min.y,tmp.y);
            min.z = std::min(min.z,tmp.z);
            
            max.x = std::max(max.x,tmp.x);
            max.y = std::max(max.y,tmp.y);
            max.z = std::max(max.z,tmp.z);
        }
    }
    
    for (n = 0; n < nd->mNumChildren; ++n)
    {
        getBoundingBoxForNode(pScene, nd->mChildren[n], min, max, trafo);
    }
    
    trafo = prev;
}

void getBoundingBoxWithMinVector(const aiScene* pScene, aiVector3D& min, aiVector3D& max)
{
    aiMatrix4x4 trafo;
    
    min.x = min.y = min.z =  1e10f;
    max.x = max.y = max.z = -1e10f;
    
    getBoundingBoxForNode(pScene, pScene->mRootNode, min, max, trafo);
}

Mesh::MeshEntry::MeshEntry()
{
    VB = INVALID_OGL_VALUE;
    IB = INVALID_OGL_VALUE;
    NumIndices  = 0;
    MaterialIndex = INVALID_MATERIAL;
};

Mesh::MeshEntry::~MeshEntry()
{
    if (VB != INVALID_OGL_VALUE)
    {
        glDeleteBuffers(1, &VB);
    }
    
    if (IB != INVALID_OGL_VALUE)
    {
        glDeleteBuffers(1, &IB);
    }
}

void Mesh::MeshEntry::Init(const std::vector<Vertex>& Vertices,
                           const std::vector<unsigned int>& Indices)
{
    NumIndices = (unsigned int)Indices.size();
    
    glGenBuffers(1, &VB);
    glBindBuffer(GL_ARRAY_BUFFER, VB);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertex) * Vertices.size(), &Vertices[0], GL_STATIC_DRAW);
    
    glGenBuffers(1, &IB);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, IB);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(unsigned int) * NumIndices, &Indices[0], GL_STATIC_DRAW);
}

Mesh::Mesh()
{
}


Mesh::~Mesh()
{
    Clear();
}


void Mesh::Clear()
{
    for (unsigned int i = 0 ; i < m_Textures.size() ; i++) {
        SAFE_DELETE(m_Textures[i]);
    }
}


//bool Mesh::LoadMesh(const std::string& Filename)
//{
//    // Release the previously loaded mesh (if it exists)
//    Clear();
//    
//    bool Ret = false;
//    Assimp::Importer Importer;
//    
//    const aiScene* pScene = Importer.ReadFile(Filename.c_str(), aiProcess_Triangulate | aiProcess_GenSmoothNormals | aiProcess_FlipUVs);
//    aiVector3D min;
//    aiVector3D max;
//    aiMatrix4x4 trafo;
//    getBoundingBoxForNode(pScene, pScene->mRootNode, min, max, trafo);
//    
//    if (pScene) {
//        Ret = InitFromScene(pScene, Filename);
//    }
//    else {
//        printf("Error parsing '%s': '%s'\n", Filename.c_str(), Importer.GetErrorString());
//    }
//    
//    return Ret;
//}

bool Mesh::LoadMesh(const void *buffer, size_t length, NSString* modelPath)
{
    // Release the previously loaded mesh (if it exists)
    Clear();
    
    bool Ret = false;
    
    
    //pScene = Importer.ReadFileFromMemory(buffer, length,aiProcess_Triangulate | aiProcess_GenSmoothNormals);
    pScene = Importer.ReadFileFromMemory(buffer, length,aiProcess_Triangulate | aiProcess_FlipUVs  | aiProcess_MakeLeftHanded);
    aiVector3D min;
    aiVector3D max;
    aiMatrix4x4 trafo;
    getBoundingBoxForNode(pScene, pScene->mRootNode, min, max, trafo);
    
    sceneCenter.x = (min.x + max.x) / 2.0f;
    sceneCenter.y = (min.y + max.y) / 2.0f;
    sceneCenter.z = (min.z + max.z) / 2.0f;
    
    // optional normalized scaling
    normalizedScale = max.x-min.x;
    normalizedScale = std::max(max.y - min.y,normalizedScale);
    normalizedScale = std::max(max.z - min.z,normalizedScale);
    normalizedScale = 1.f / normalizedScale;
    
    if (pScene) {
        Ret = InitFromScene(pScene, modelPath);
    }
    else {
        printf("Error parsing '%s': '%s'\n", modelPath.UTF8String, Importer.GetErrorString());
    }
    
    return Ret;
}

bool Mesh::InitFromScene(const aiScene* pScene, NSString* modelPath)
{
    m_Entries.resize(pScene->mNumMeshes);
    m_Textures.resize(pScene->mNumMaterials);
    m_DiffuseColors.resize(pScene->mNumMaterials);
    
    // Initialize the meshes in the scene one by one
    for (unsigned int i = 0 ; i < m_Entries.size() ; i++) {
        const aiMesh* paiMesh = pScene->mMeshes[i];
        InitMesh(i, paiMesh);
    }
    
    return InitMaterials(pScene, modelPath);
}

void Mesh::InitMesh(unsigned int Index, const aiMesh* paiMesh)
{
    if (paiMesh->mPrimitiveTypes == aiPrimitiveType_LINE) {
        m_Entries[Index].MaterialIndex = paiMesh->mMaterialIndex;
        
        std::vector<Vertex> Vertices;
        std::vector<unsigned int> Indices;
        
        const aiVector3D Zero3D(1.0f, 1.0f, 1.0f);

        for (unsigned int i = 0 ; i < paiMesh->mNumVertices ; i++) {
            const aiVector3D* pPos      = &(paiMesh->mVertices[i]);
            const aiVector3D* pNormal = paiMesh->HasNormals() ? &(paiMesh->mNormals[i]) : &Zero3D;
            const aiVector3D* pTexCoord = paiMesh->HasTextureCoords(0) ? &(paiMesh->mTextureCoords[0][i]) : &Zero3D;
            Vertex v(Vector3f(pPos->x, pPos->y, pPos->z),
                     Vector2f(pTexCoord->x, pTexCoord->y),
                     Vector3f(pNormal->x, pNormal->y, pNormal->z));
            Vertices.push_back(v);
        }
        
        for (unsigned int i = 0 ; i < paiMesh->mNumFaces ; i++) {
            const aiFace& Face = paiMesh->mFaces[i];
            assert(Face.mNumIndices == 2);
            Indices.push_back(Face.mIndices[0]);
            Indices.push_back(Face.mIndices[1]);
        }
        
        m_Entries[Index].Init(Vertices, Indices);
        m_Entries[Index].drawMode = GL_LINES;
        
    } else if (paiMesh->mPrimitiveTypes == aiPrimitiveType_TRIANGLE) {
        m_Entries[Index].MaterialIndex = paiMesh->mMaterialIndex;
        
        std::vector<Vertex> Vertices;
        std::vector<unsigned int> Indices;
        
        const aiVector3D Zero3D(0.0f, 0.0f, 0.0f);
        
        for (unsigned int i = 0 ; i < paiMesh->mNumVertices ; i++) {
            const aiVector3D* pPos      = &(paiMesh->mVertices[i]);
            const aiVector3D* pNormal = &(paiMesh->mNormals[i]);
            
            const aiVector3D* pTexCoord = paiMesh->HasTextureCoords(0) ? &(paiMesh->mTextureCoords[0][i]) : &Zero3D;
            Vertex v(Vector3f(pPos->x, pPos->y, pPos->z),
                     Vector2f(pTexCoord->x, pTexCoord->y),
                     Vector3f(pNormal->x, pNormal->y, pNormal->z));
            Vertices.push_back(v);
        }
        
        for (unsigned int i = 0 ; i < paiMesh->mNumFaces ; i++) {
            const aiFace& Face = paiMesh->mFaces[i];
            assert(Face.mNumIndices == 3);
            Indices.push_back(Face.mIndices[0]);
            Indices.push_back(Face.mIndices[1]);
            Indices.push_back(Face.mIndices[2]);
        }
        
        m_Entries[Index].Init(Vertices, Indices);
        m_Entries[Index].drawMode = GL_TRIANGLES;
    }
}

bool Mesh::InitMaterials(const aiScene* pScene, NSString* modelPath)
{
    // Extract the directory part from the file name
//    std::string::size_type SlashIndex = Filename.find_last_of("/");
//    std::string Dir;
//    
//    if (SlashIndex == std::string::npos) {
//        Dir = ".";
//    }
//    else if (SlashIndex == 0) {
//        Dir = "/";
//    }
//    else {
//        Dir = Filename.substr(0, SlashIndex);
//    }
    
    bool Ret = true;
    
    // Initialize the materials
    for (unsigned int i = 0 ; i < pScene->mNumMaterials ; i++) {
        const aiMaterial* pMaterial = pScene->mMaterials[i];
        m_Textures[i] = NULL;
        
        aiColor4D dcolor;
        
        if(AI_SUCCESS == aiGetMaterialColor(pMaterial, AI_MATKEY_COLOR_DIFFUSE, &dcolor)){
            m_DiffuseColors[i] = dcolor;
        } else {
            m_DiffuseColors[i] = aiColor4D(1,1,1,1);
        }
        
        if (pMaterial->GetTextureCount(aiTextureType_DIFFUSE) > 0) {
            aiString Path;
            
            if (pMaterial->GetTexture(aiTextureType_DIFFUSE, 0, &Path, NULL, NULL, NULL, NULL, NULL) == AI_SUCCESS) {
                NSString * modelFolder = [modelPath stringByDeletingLastPathComponent];
                NSString * fullPath = [modelFolder stringByAppendingPathComponent:[NSString stringWithUTF8String:Path.data]];
                
                m_Textures[i] = new Texture(GL_TEXTURE_2D, fullPath.UTF8String);
                
                if (!m_Textures[i]->Load()) {
                    printf("Error loading texture '%s'\n", fullPath.UTF8String);
                    delete m_Textures[i];
                    m_Textures[i] = NULL;
                    Ret = false;
                }
                else {
                    printf("Loaded texture '%s'\n", fullPath.UTF8String);
                }
            }
        }
        
        // Load a white texture in case the model does not include its own texture
        if (!m_Textures[i]) {
            m_Textures[i] = new Texture(GL_TEXTURE_2D, "white.png");
            
            Ret = m_Textures[i]->Load();
        }
    }
    
    return Ret;
}

void Mesh::Render(float width, float height, std::array<GLint, NUM_UNIFORMS>uniforms, std::array<float, 2> rotate)
{
    glEnableVertexAttribArray(0);
    glEnableVertexAttribArray(1);
    glEnableVertexAttribArray(2);
    
    aiMatrix4x4 rotateM;
    aiMatrix4x4 rotateX;
    aiMatrix4x4 rotateY;
    aiMatrix4x4::RotationY(-rotate[0], rotateX);
    aiMatrix4x4::RotationX(-rotate[1], rotateY);
    rotateMatrix = rotateX * rotateY * rotateMatrix;
    
    recursiveRender(pScene->mRootNode, aiMatrix4x4(), width, height, uniforms);
    
    glDisableVertexAttribArray(0);
    glDisableVertexAttribArray(1);
    glDisableVertexAttribArray(2);
}


aiMatrix4x4 Ortho(float left, float right,
                  float bottom, float top,
                  float nearZ, float farZ)
{
    float ral = right + left;
    float rsl = right - left;
    float tab = top + bottom;
    float tsb = top - bottom;
    float fan = farZ + nearZ;
    float fsn = farZ - nearZ;
    aiMatrix4x4 m(2.0f / rsl, 0.0f, 0.0f, -ral / rsl,
                  0.0f, 2.0f / tsb, 0.0f, -tab / tsb,
                  0.0f, 0.0f, -2.0f / fsn, -fan / fsn,
                  0.0f, 0.0f, 0.0f, 1.0f);
    return m;
}

void Mesh::recursiveRender(const aiNode* nd, aiMatrix4x4 parentModelMatrix, float width, float height, std::array<GLint, NUM_UNIFORMS>uniforms)
{
    aiMatrix4x4 parentModelM = parentModelMatrix * nd->mTransformation;
    aiMatrix4x4 scaleM;
    aiMatrix4x4::Scaling(aiVector3D(normalizedScale, normalizedScale, normalizedScale), scaleM);
    aiMatrix4x4 transM;
    aiMatrix4x4::Translation(aiVector3D(-sceneCenter.x, -sceneCenter.y, -sceneCenter.z), transM);
    
    aiMatrix4x4 modelM =    scaleM * rotateMatrix * transM *  parentModelM ;
    

    
    PersProjInfo persProjInfo;
    persProjInfo.FOV = 60.0f;
    persProjInfo.Height = height;
    persProjInfo.Width = width;
    persProjInfo.zNear = 0.3f;
    persProjInfo.zFar = 1000.0f;
    
    Vector3f Pos(0.f, 0.f, -1.35f);
    Vector3f Target(0.0f, 0.f, 1.0f);
    Vector3f Up(0.0, 1.0f, 0.0f);
    Camera gameCamera(width, height, Pos, Target, Up);
    gameCamera.OnRender();
    
    
    Pipeline p;
    //p.Scale(0.3f, 0.3f, 0.3f);
    p.WorldPos(0, 0, 0);
    //p.Rotate(rotate[1], rotate[0], 0);
    p.SetCamera(gameCamera.GetPos(), gameCamera.GetTarget(), gameCamera.GetUp());
    p.SetPerspectiveProj(persProjInfo);
    
    Matrix4f vp = p.GetWVPTrans();
    
    if (nd->mNumMeshes > 0) {
        
        //GLKMatrix4 modelViewMatrix = GLKMatrix4Multiply(rotateMatrix, modelMatrix);
        //GLKMatrix3 normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(modelViewMatrix), NULL);
        //glUniformMatrix3fv(normalUniform, 1, 0, normalMatrix.m);
        //GLKMatrix4 modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
        
        Matrix4f modelMatrix(modelM);
        Matrix4f mvp = vp * modelMatrix;
        Matrix4f transPorseMvp = mvp.Transpose();
        
//        glUniformMatrix4fv(mvpUniform, 1, 0, modelViewProjectionMatrix.m);
        glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, GL_FALSE, (float*)&transPorseMvp);
        for (int n = 0; n < nd->mNumMeshes; ++n) {
            int meshIndex = nd->mMeshes[n];
            glBindBuffer(GL_ARRAY_BUFFER, m_Entries[meshIndex].VB);
            glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), 0);
            glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid*)12);
            glVertexAttribPointer(2, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid*)20);
            
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, m_Entries[meshIndex].IB);
            
            const unsigned int MaterialIndex = m_Entries[meshIndex].MaterialIndex;
            
            if (MaterialIndex < m_Textures.size() && m_Textures[MaterialIndex]) {
                m_Textures[MaterialIndex]->Bind(GL_TEXTURE0);
            }
            
            if (MaterialIndex < m_DiffuseColors.size()) {
                glUniform4fv(uniforms[UNIFORM_DIFFUSECOLOR], 1, (float*)&m_DiffuseColors[MaterialIndex]);
            }
            
            glDrawElements(m_Entries[meshIndex].drawMode, m_Entries[meshIndex].NumIndices, GL_UNSIGNED_INT, 0);
        }
    }
    
    for (int i = 0; i < nd->mNumChildren; ++i) {
        recursiveRender(nd->mChildren[i], parentModelM, width, height, uniforms);
    }
//    for (unsigned int i = 0 ; i < m_Entries.size() ; i++) {
//        glBindBuffer(GL_ARRAY_BUFFER, m_Entries[i].VB);
//        glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), 0);
//        glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid*)12);
//        glVertexAttribPointer(2, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid*)20);
//        
//        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, m_Entries[i].IB);
//        
//        const unsigned int MaterialIndex = m_Entries[i].MaterialIndex;
//        
//        if (MaterialIndex < m_Textures.size() && m_Textures[MaterialIndex]) {
//            m_Textures[MaterialIndex]->Bind(GL_TEXTURE0);
//        }
//        
//        glDrawElements(m_Entries[i].drawMode, m_Entries[i].NumIndices, GL_UNSIGNED_INT, 0);
//    }
    
}
