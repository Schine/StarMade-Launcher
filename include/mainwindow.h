#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <vector2.h>
#include <memory>
#include <string>
#include <ibuttoncallback.h>

class LauncherWidget;

class MainWindow : public IButtonCallback
{
public:
    static const int CLOSE_BUTTON_SIZE = 20;
    static const int CLOSE_BUTTON_OFFSET = 20;
    static const int MINIMIZE_BUTTON_SIZE = 20;
    static const int MINIMIZE_BUTTON_OFFSET_X = 50;
    static const int MINIMIZE_BUTTON_OFFSET_Y = 27;
    static const int BAR_BORDER = 4;
    static const int BOTTOM_BAR_HEIGHT = 175;
    static const int LAUNCH_BUTTON_WIDTH = 200;
    static const int LAUNCH_BUTTON_HEIGHT = 90;
    static const int LAUNCH_BUTTON_BORDER_SIZE = 5;

    explicit MainWindow(int borderSizeX, int borderSizeY);
    ~MainWindow();

    void init();
    void update(double deltaTime);
    void render();
    void resize(int w, int h);
    int width() { return m_size.x(); }
    int height() { return m_size.y(); }
    void mouseClicked(int button, bool press);
    void mouseMoved(double xPos, double yPos);
    void mouseWheelScrolled(double xOffset, double yOffset);
    bool isCloseRequested() const { return m_closeRequested; }
    bool isMinimizeRequested() const { return m_minimizeRequested; }
    void setMinimizeRequested(bool request) { m_minimizeRequested = request; }
    void setWindowMoveRequest(Vector2I deltaPos) { m_windowMoveRequest = deltaPos; }
    Vector2I getWindowMoveRequest() const { return m_windowMoveRequest; }
    virtual void buttonClicked(WidgetButton* button, int callbackIndex);
private:
    void replaceAllInLine(std::string& lineToChange, const std::string& toReplace, const std::string& replaceWith = std::string(""));
    std::shared_ptr<LauncherWidget> m_mainWidget;
    Vector2I m_size;
    Vector2D m_mousePosition;
    Vector2D m_mousePositionLast;
    Vector2D m_mouseLastClickedPosition;
    bool m_closeRequested;
    bool m_minimizeRequested;
    Vector2I m_windowMoveRequest;
    Vector2I m_borderSize;
    bool m_windowGrabbed;
};

#endif // MAINWINDOW_H
