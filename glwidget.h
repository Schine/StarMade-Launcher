#ifndef GLWIDGET_H
#define GLWIDGET_H

#include <QGLWidget>
#include "launcherwidget.h"

class GLWidget : public QGLWidget
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

    explicit GLWidget(QWidget* parent = 0);
    ~GLWidget();

    void initializeGL();
    void paintGL();
    void resizeGL(int w, int h);
private:
    GLuint m_schineLogo;
    GLuint m_background;
    LauncherWidget* m_mainWidget;
};

#endif // GLWIDGET_H
