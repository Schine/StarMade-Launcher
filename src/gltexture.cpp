#include "gltexture.h"
#include "glutil.h"
#include <iostream>
#include <string>
#include "ogl.h"

GLTexture::GLTexture(std::string fileName, GLuint handle, int width, int height)
    : m_fileName(fileName),
      m_handle(handle),
      m_textureSize(width, height)
{
}

GLTexture *GLTexture::fromFile(std::string fileName)
{
    int width, height;
    GLuint handle = GLUtil::loadTexture(fileName, &width, &height);
    return new GLTexture(fileName, handle, width, height);
}

GLTexture *GLTexture::fromOGLHandle(std::string fileName, GLuint handle, int width, int height)
{
    return new GLTexture(fileName, handle, width, height);
}

GLTexture::~GLTexture()
{
    glDeleteTextures(1, &m_handle);
}

void GLTexture::bind()
{
    glBindTexture(GL_TEXTURE_2D, m_handle);
}

void GLTexture::unbind()
{
    glBindTexture(GL_TEXTURE_2D, 0);
}
