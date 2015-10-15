//
//  Shader.vsh
//  HelloGL
//
//  Created by DongYifan on 6/16/15.
//  Copyright (c) 2015 vanille. All rights reserved.
//

attribute vec3 position;
attribute vec3 normal;
attribute vec2 texcoord0;

varying lowp vec4 colorVarying;
varying lowp vec2 varTexcoord;

uniform mat4 modelViewProjectionMatrix;
uniform mat3 normalMatrix;
uniform vec4 diffuseColor;

void main()
{
    vec3 eyeNormal = normalize(normalMatrix * normal);
    vec3 lightPosition = vec3(0.0, 0.0, 1.0);
    //vec4 diffuseColor = vec4(1.0, 1.0, 1.0, 1.0);
    
    //float nDotVP = max(0.0, dot(eyeNormal, normalize(lightPosition)));
    
    //colorVarying = diffuseColor * nDotVP;
    colorVarying = diffuseColor;
    varTexcoord = texcoord0;
    
    gl_Position = modelViewProjectionMatrix * vec4(position, 1.0);
}
