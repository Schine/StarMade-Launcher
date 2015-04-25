#ifndef PLATFORMUTIL_H
#define PLATFORMUTIL_H

#include <string>

class GLFWwindow;

class PlatformUtil
{
    public:
        static void removeWindowBorder(GLFWwindow* window, int& borderSize, int windowSizeX, int windowSizeY);
        static void openWebPage(const std::string& page);
    protected:
    private:
};

#endif // PLATFORMUTIL_H
