#include "glwidget.h"
#include <QFontDatabase>
#include <QMessageBox>
#include <QFile>
#include <iostream>

GLWidget::GLWidget(QWidget* parent)
    : QGLWidget(parent)
{

}

GLWidget::~GLWidget()
{

}

GLuint GLWidget::loadTexture(QString fileName)
{
    GLuint handle = 0;
    QString schineLogoFile(fileName);
    QImage image(schineLogoFile);
    image = QGLWidget::convertToGLFormat(image);
    glGenTextures(1, &handle);
    glBindTexture(GL_TEXTURE_2D, handle);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, image.width(), image.height(), 0, GL_RGBA, GL_UNSIGNED_BYTE, image.bits());
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    return handle;
}

void GLWidget::initializeGL()
{
    glClearColor(0.1, 0.1, 0.1, 1.0F);
    glDisable(GL_DEPTH_TEST);
    glEnable(GL_TEXTURE_2D);
    m_schineLogo = loadTexture("schine.png");
    m_background = loadTexture("backgroundtest.jpg");
}

void GLWidget::paintGL()
{
    glClearColor(0, 0, 0, 0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    // Bottom Bar
    glBegin(GL_QUADS);
        glColor3f(0.25, 0.25, 0.25);
        glVertex3f(0.0,             this->height() - BOTTOM_BAR_HEIGHT, 0.0);
        glVertex3f(this->width(),   this->height() - BOTTOM_BAR_HEIGHT, 0.0);
        glColor3f(0.1, 0.1, 0.1);
        glVertex3f(this->width(),   this->height(), 0.0);
        glVertex3f(0.0,             this->height(), 0.0);
    glEnd();

    // Bottom bar border
    glBegin(GL_QUADS);
        glColor3f(0.1, 0.1, 0.1);
        glVertex3f(0.0,             this->height() - BOTTOM_BAR_HEIGHT - BAR_BORDER, 0.0);
        glVertex3f(this->width(),   this->height() - BOTTOM_BAR_HEIGHT - BAR_BORDER, 0.0);
        glVertex3f(this->width(),   this->height() - BOTTOM_BAR_HEIGHT, 0.0);
        glVertex3f(0.0,             this->height() - BOTTOM_BAR_HEIGHT, 0.0);
    glEnd();

    // Top bar
    glBegin(GL_QUADS);
        glColor3f(0.1, 0.1, 0.1);
        glVertex3f(0.0,             0.0, 0.0);
        glVertex3f(this->width(),   0.0, 0.0);
        glColor3f(0.2, 0.2, 0.2);
        glVertex3f(this->width(),   100.0, 0.0);
        glVertex3f(0.0,             100.0, 0.0);
    glEnd();

    // Top bar border
    glBegin(GL_QUADS);
        glColor3f(0.1, 0.1, 0.1);
        glVertex3f(0.0,             100.0, 0.0);
        glVertex3f(this->width(),   100.0, 0.0);
        glVertex3f(this->width(),   100.0 + BAR_BORDER, 0.0);
        glVertex3f(0.0,             100.0 + BAR_BORDER, 0.0);
    glEnd();

    glBindTexture(GL_TEXTURE_2D, m_background);
    // Top bar border
    glBegin(GL_QUADS);
        glColor3f(0.5, 0.5, 0.5);
        glTexCoord2f(0.0F, 0.2F);
        glVertex3f(0.0,             100.0 + BAR_BORDER, 0.0);
        glTexCoord2f(1.0F, 0.2F);
        glVertex3f(this->width(),   100.0 + BAR_BORDER, 0.0);
        glTexCoord2f(1.0F, 0.8F);
        glVertex3f(this->width(),   this->height() - BOTTOM_BAR_HEIGHT - BAR_BORDER, 0.0);
        glTexCoord2f(0.0F, 0.8F);
        glVertex3f(0.0,             this->height() - BOTTOM_BAR_HEIGHT - BAR_BORDER, 0.0);
    glEnd();
    glBindTexture(GL_TEXTURE_2D, 0);

    // Launch button
    glBegin(GL_QUADS);
    glColor3f(0.1, 0.6, 0.1);
        glVertex3f(this->width() - LAUNCH_BUTTON_WIDTH - 25 - LAUNCH_BUTTON_BORDER_SIZE,    this->height() - 25 - LAUNCH_BUTTON_HEIGHT - LAUNCH_BUTTON_BORDER_SIZE, 0.0);
        glVertex3f(this->width() - 25 + LAUNCH_BUTTON_BORDER_SIZE,                          this->height() - 25 - LAUNCH_BUTTON_HEIGHT - LAUNCH_BUTTON_BORDER_SIZE, 0.0);
        glVertex3f(this->width() - 25 + LAUNCH_BUTTON_BORDER_SIZE,                          this->height() - 25 + LAUNCH_BUTTON_BORDER_SIZE, 0.0);
        glVertex3f(this->width() - LAUNCH_BUTTON_WIDTH - 25 - LAUNCH_BUTTON_BORDER_SIZE,    this->height() - 25 + LAUNCH_BUTTON_BORDER_SIZE, 0.0);
    glEnd();
    glBegin(GL_QUADS);
        glColor3f(0.25, 0.8, 0.25);
        glVertex3f(this->width() - LAUNCH_BUTTON_WIDTH - 25,    this->height() - 25 - LAUNCH_BUTTON_HEIGHT, 0.0);
        glVertex3f(this->width() - 25,                          this->height() - 25 - LAUNCH_BUTTON_HEIGHT, 0.0);
        glVertex3f(this->width() - 25,                          this->height() - 25, 0.0);
        glVertex3f(this->width() - LAUNCH_BUTTON_WIDTH - 25,    this->height() - 25, 0.0);
    glEnd();

    glPushMatrix();
    glTranslatef(this->width() - CLOSE_BUTTON_OFFSET, CLOSE_BUTTON_OFFSET, 0.0F);

    // "X" on exit button
    for (int i = 0; i < 2; ++i)
    {
        glPushMatrix();
        glRotatef(i == 0 ? -45.0F : 45.0F, 0.0, 0.0, 1.0);

        glBegin(GL_QUADS);
            glColor3f(1.0, 1.0, 1.0);
            glVertex3f(0.0, CLOSE_BUTTON_SIZE / 2.0F, 0.0);
            glVertex3f(1.0, CLOSE_BUTTON_SIZE / 2.0F, 0.0);
            glVertex3f(1.0, -CLOSE_BUTTON_SIZE / 2.0F, 0.0);
            glVertex3f(0.0, -CLOSE_BUTTON_SIZE / 2.0F, 0.0);
        glEnd();
        glPopMatrix();
    }

    glPopMatrix();

    glPushMatrix();
    glTranslatef(this->width() - MINIMIZE_BUTTON_OFFSET_X, MINIMIZE_BUTTON_OFFSET_Y, 0.0F);

    glBegin(GL_QUADS);
        glColor3f(1.0, 1.0, 1.0);
        glVertex3f(-MINIMIZE_BUTTON_SIZE / 2.5F, 1.5F, 0.0);
        glVertex3f(MINIMIZE_BUTTON_SIZE / 2.5F, 1.5F, 0.0);
        glVertex3f(MINIMIZE_BUTTON_SIZE / 2.5F, 0.0F, 0.0);
        glVertex3f(-MINIMIZE_BUTTON_SIZE / 2.5F, 0.0F, 0.0);
    glEnd();

    glPopMatrix();

    // Title
    QFont myFont("Arial", 14, QFont::Bold, false);
    QString str("StarMade Launcher");
    QFontMetrics fm(myFont);
    int width = fm.width(str);
    glColor3f(1.0, 1.0, 1.0);
    renderText(this->width() / 2 - width / 2, 25, 0, str, myFont);

    myFont = QFont("Arial", 24, QFont::Bold, false);
    str = QString("LAUNCH");
    fm = QFontMetrics(myFont);
    width = fm.width(str);
    glColor3f(1.0, 1.0, 1.0);
    renderText(this->width() - LAUNCH_BUTTON_WIDTH / 2 - 25 - width / 2, this->height() - 25 - LAUNCH_BUTTON_HEIGHT / 2 + 12, 0, str, myFont);

    // Render Logo
    glPushAttrib(GL_ALL_ATTRIB_BITS);
    glEnable(GL_TEXTURE_2D);

    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_BLEND);
    glAlphaFunc(GL_GREATER, 0.0);
    glEnable(GL_ALPHA_TEST);

    glBindTexture(GL_TEXTURE_2D, m_schineLogo);
    glBegin(GL_QUADS);
        glTexCoord2f(0.0F, 1.0F);
        glVertex3f(this->width() - 300 / 2.0F - 5, 50.0F, 0.0);
        glTexCoord2f(1.0F, 1.0F);
        glVertex3f(this->width() - 5, 50.0F, 0.0);
        glTexCoord2f(1.0F, 0.0F);
        glVertex3f(this->width() - 5, 81 / 2.0F + 50.0F, 0.0);
        glTexCoord2f(0.0F, 0.0F);
        glVertex3f(this->width() - 300 / 2.0F - 5, 81 / 2.0F + 50.0F, 0.0);
    glEnd();

    glPopAttrib();

}

void GLWidget::resizeGL(int w, int h)
{
    this->window()->resize(w, h);
    glViewport(0, 0, w, h);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(0.0f, this->width(), this->height(), 0.0f, -1.0, 1.0);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
}
