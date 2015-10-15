//
//  Shader.fsh
//  HelloGL
//
//  Created by DongYifan on 6/16/15.
//  Copyright (c) 2015 vanille. All rights reserved.
//

varying lowp vec4 colorVarying;
varying lowp vec2 varTexcoord;
uniform mediump sampler2D s_diffuse;
void main()
{
    gl_FragColor = texture2D(s_diffuse, varTexcoord) * colorVarying;
}
