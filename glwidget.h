#ifndef GLWIDGET_H
#define GLWIDGET_H

#include "vector2.h"
#include "launcherwidget.h"

class GLWidget
{
public:

    explicit GLWidget();
    ~GLWidget();

    void initializeGL();
    void paintGL();
    void resizeGL(int w, int h);
private:
};

#endif // GLWIDGET_H
