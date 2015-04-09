#ifndef GLTEXTURE_H
#define GLTEXTURE_H

#include <QGLWidget>

class GLTexture
{
public:
    static GLTexture* fromFile(QString fileName);
    static GLTexture* fromOGLHandle(QString fileName, GLuint handle);
    ~GLTexture();
    void bind();
    void unbind();
private:
    GLTexture(QString fileName, GLuint handle);
    QString m_fileName;
    GLuint m_handle;
};

#endif // GLTEXTURE_H
