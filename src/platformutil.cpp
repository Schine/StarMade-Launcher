#include "platformutil.h"
#include <stdarg.h>
#include <stdio.h>
#include <iostream>
#include <thread>
#include "ogl.h"

#ifdef _WIN32
DWORD WINAPI showMessageBoxWin32(void* data)
{
    std::string dataC = *((std::string*)data);
    MessageBox(NULL, dataC.c_str(), "StarMade Launcher", MB_OK | MB_ICONQUESTION | MB_SYSTEMMODAL);
}
#endif

void PlatformUtil::messageBox(const char* str, ...)
{
    va_list args;
    va_start(args, str);
    char buff[1024];
    vsprintf(buff, str, args);
    std::cerr << buff << std::endl;
    static std::string test(buff);

    #ifdef _WIN32
    HANDLE thread = CreateThread(NULL, 0, showMessageBoxWin32, &test, 0, NULL);
    #endif

    va_end(args);
}
