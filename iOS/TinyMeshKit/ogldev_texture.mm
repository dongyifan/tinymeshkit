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

#include <iostream>
#include "ogldev_texture.h"
#import <UIKit/UIKit.h>

Texture::Texture(GLenum TextureTarget, const std::string& FileName)
{
    m_textureTarget = TextureTarget;
    m_fileName      = FileName;
}


bool Texture::Load()
{
    GLubyte * textureData = nullptr;
    size_t width;
    size_t height;
    
    if (m_fileName == "white.png") {
        width = 1;
        height = 1;
        textureData = (GLubyte *)calloc(width*height*4, sizeof(GLubyte));
        memset(textureData, 255, width * height * 4);
    } else {
        NSData *data = [NSData dataWithContentsOfFile:[NSString stringWithUTF8String:m_fileName.c_str()]];
        UIImage * image = [[UIImage alloc]initWithData:data];
        
        CGImageRef spriteImage = image.CGImage;
        if (!spriteImage) {
            NSLog(@"Failed to load image %s", m_fileName.c_str());
            return false;
        }
        
        // 2
        width = CGImageGetWidth(spriteImage);
        height = CGImageGetHeight(spriteImage);
        
        textureData = (GLubyte *) calloc(width*height*4, sizeof(GLubyte));
        
        CGContextRef spriteContext = CGBitmapContextCreate(textureData, width, height, 8, width*4,
                                                           CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
        
        // 3
        CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), spriteImage);
        
        CGContextRelease(spriteContext);
    }


    glGenTextures(1, &m_textureObj);
    glBindTexture(m_textureTarget, m_textureObj);
    
    // Set up filter and wrap modes for this texture object
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    
    //glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    
    glTexImage2D(m_textureTarget, 0, GL_RGBA, (int)width, (int)height, 0, GL_RGBA, GL_UNSIGNED_BYTE, textureData);
   
    //glGenerateMipmap(GL_TEXTURE_2D);
    glBindTexture(m_textureTarget, 0);
    free(textureData);
    
    return true;
}

void Texture::Bind(GLenum TextureUnit)
{
    glActiveTexture(TextureUnit);
    glBindTexture(m_textureTarget, m_textureObj);
}
