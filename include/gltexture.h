#ifndef GLTEXTURE_H
#define GLTEXTURE_H

#include <string>
#include "vector2.h"

typedef unsigned int GLuint;

class GLTexture
{
public:
    static GLTexture* fromFile(std::string fileName);
    static GLTexture* fromOGLHandle(std::string fileName, GLuint handle, int width, int height);
    ~GLTexture();
    void bind();
    void unbind();
private:
    GLTexture(std::string fileName, GLuint handle, int width, int height);
    std::string m_fileName;
    GLuint m_handle;
    Vector2I m_textureSize;
};

#endif // GLTEXTURE_H
