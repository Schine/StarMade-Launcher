#ifndef GLUTIL_H
#define GLUTIL_H

#include <string>
#include "ogl.h"

class GLUtil
{
public:
    static GLuint loadTexture(std::string fileName, int *width, int *height);
};

#endif // GLUTIL_H
