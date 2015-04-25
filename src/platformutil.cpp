#include "platformutil.h"
#include <stdarg.h>
#include <stdio.h>
#include <iostream>

#include <GL/glew.h>
#ifdef _WIN32
#include <windows.h>
#include <windef.h>
#define GLFW_EXPOSE_NATIVE_WIN32
#define GLFW_EXPOSE_NATIVE_WGL
#endif
#include <GLFW/glfw3.h>
#include <GLFW/glfw3native.h>



void PlatformUtil::removeWindowBorder(GLFWwindow* window, int& borderSize, int windowSizeX, int windowSizeY)
{
    // Remove window "Decoration" on windows
    // http://stackoverflow.com/questions/2398746/removing-window-border
#ifdef _WIN32
    HWND hwnd = glfwGetWin32Window(window);

    RECT windowRect;
    GetWindowRect(hwnd, &windowRect);

    RECT clientRect;
    GetClientRect(hwnd, &clientRect);

    borderSize = ((windowRect.right - windowRect.left) - (clientRect.right - clientRect.left)) / 2;

    LONG lStyle = GetWindowLong(hwnd, GWL_STYLE);
    lStyle &= ~(WS_CAPTION | WS_THICKFRAME | WS_MINIMIZE | WS_MAXIMIZE | WS_SYSMENU);
    SetWindowLong(hwnd, GWL_STYLE, lStyle);

    LONG lExStyle = GetWindowLong(hwnd, GWL_EXSTYLE);
    lExStyle &= ~(WS_EX_DLGMODALFRAME | WS_EX_CLIENTEDGE | WS_EX_STATICEDGE);
    SetWindowLong(hwnd, GWL_EXSTYLE, lExStyle);

    SetWindowPos(hwnd, NULL, 0,0,windowSizeX,windowSizeY, SWP_FRAMECHANGED | SWP_NOMOVE | SWP_NOZORDER | SWP_NOOWNERZORDER);
#endif // _WIN32
}

void PlatformUtil::openWebPage(const std::string& page)
{
    // Open links - platform specific

#ifdef _WIN32
    ShellExecute(NULL, "open", page.c_str(), NULL, NULL, SW_SHOWNORMAL);
#endif // _WIN32
}
