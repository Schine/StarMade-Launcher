#include "gltexture.h"
#include "glutil.h"
#include <iostream>

GLTexture::GLTexture(QString fileName, GLuint handle)
    : m_fileName(fileName),
      m_handle(handle)
{
}

GLTexture *GLTexture::fromFile(QString fileName)
{
    return new GLTexture(fileName, GLUtil::loadTexture(fileName));
}

GLTexture *GLTexture::fromOGLHandle(QString fileName, GLuint handle)
{
    return new GLTexture(fileName, handle);
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
