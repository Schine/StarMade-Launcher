#include "mainwindow.h"
#include <GL/glew.h>
#ifdef _WIN32
#include <windows.h>
#include <windef.h>
#define GLFW_EXPOSE_NATIVE_WIN32
#define GLFW_EXPOSE_NATIVE_WGL
#endif
#include <GLFW/glfw3.h>
#include <GLFW/glfw3native.h>
#include <memory>
#include <iostream>
#include "fontrenderer.h"

std::shared_ptr<MainWindow> m_mainWindow;

void scrollCallback(GLFWwindow* window, double xOffset, double yOffset)
{
    if (m_mainWindow != nullptr)
    {
        m_mainWindow->mouseWheelScrolled(xOffset, yOffset);
    }
}

void mouseButtonCallback(GLFWwindow* window, int button, int action, int mods)
{
    if (m_mainWindow != nullptr)
    {
        m_mainWindow->mouseClicked(button, action == GLFW_PRESS);
    }
}

void mousePositionCallback(GLFWwindow* window, double xPos, double yPos)
{
    if (m_mainWindow != nullptr)
    {
        m_mainWindow->mouseMoved(xPos, yPos);
    }
}

int main(int argc, char *argv[])
{
    GLFWwindow* window;
    if (!glfwInit())
    {
        return -1;
    }

    const int windowSizeX = 1200;
    const int windowSizeY = 750;
    window = glfwCreateWindow(windowSizeX, windowSizeY, "StarMade Launcher", NULL, NULL);

    glfwSetMouseButtonCallback(window, &mouseButtonCallback);
    glfwSetCursorPosCallback(window, &mousePositionCallback);
    glfwSetScrollCallback(window, &scrollCallback);

    int borderSizeX = 0;

    // Remove window "Decoration" on windows
    // http://stackoverflow.com/questions/2398746/removing-window-border
#ifdef _WIN32
    HWND hwnd = glfwGetWin32Window(window);

    RECT windowRect;
    GetWindowRect(hwnd, &windowRect);

    RECT clientRect;
    GetClientRect(hwnd, &clientRect);

    borderSizeX = ((windowRect.right - windowRect.left) - (clientRect.right - clientRect.left)) / 2;

    LONG lStyle = GetWindowLong(hwnd, GWL_STYLE);
    lStyle &= ~(WS_CAPTION | WS_THICKFRAME | WS_MINIMIZE | WS_MAXIMIZE | WS_SYSMENU);
    SetWindowLong(hwnd, GWL_STYLE, lStyle);

    LONG lExStyle = GetWindowLong(hwnd, GWL_EXSTYLE);
    lExStyle &= ~(WS_EX_DLGMODALFRAME | WS_EX_CLIENTEDGE | WS_EX_STATICEDGE);
    SetWindowLong(hwnd, GWL_EXSTYLE, lExStyle);

    SetWindowPos(hwnd, NULL, 0,0,windowSizeX,windowSizeY, SWP_FRAMECHANGED | SWP_NOMOVE | SWP_NOZORDER | SWP_NOOWNERZORDER);
#endif // _WIN32


    glfwMakeContextCurrent(window);

    std::vector<FontListEntry> fontList;
    fontList.push_back(FontListEntry::BABAS_NEUE_12);
    fontList.push_back(FontListEntry::BABAS_NEUE_16);
    fontList.push_back(FontListEntry::BABAS_NEUE_24);
    fontList.push_back(FontListEntry::BABAS_NEUE_32);
    fontList.push_back(FontListEntry::BABAS_NEUE_64);
    fontList.push_back(FontListEntry::MARCELLUS_12);
    fontList.push_back(FontListEntry::MARCELLUS_16);
    fontList.push_back(FontListEntry::MARCELLUS_24);
    fontList.push_back(FontListEntry::MARCELLUS_32);
    fontList.push_back(FontListEntry::MARCELLUS_64);
    FontRenderer::init(fontList);

    m_mainWindow = std::shared_ptr<MainWindow>(new MainWindow(borderSizeX, 0));
    m_mainWindow->resize(windowSizeX, windowSizeY);
    m_mainWindow->init();
    //w.checkJavaVersion(3);

    double lastTime = glfwGetTime();
    while (!glfwWindowShouldClose(window) && !m_mainWindow->isCloseRequested())
    {
        m_mainWindow->update(glfwGetTime() - lastTime);
        m_mainWindow->render();

        glfwSwapBuffers(window);
        glfwPollEvents();
        lastTime = glfwGetTime();
        if (m_mainWindow->isMinimizeRequested())
        {
            glfwIconifyWindow(window);
            m_mainWindow->setMinimizeRequested(false);
        }
        Vector2I moveVec = m_mainWindow->getWindowMoveRequest();
        if (moveVec.x() != 0 && moveVec.y() != 0)
        {
            int posX, posY;
            glfwGetWindowPos(window, &posX, &posY);
            glfwSetWindowPos(window, posX + moveVec.x(), posY + moveVec.y());
            m_mainWindow->setWindowMoveRequest(Vector2I(0, 0));
        }
    }

    glfwTerminate();

    return 0;
}
