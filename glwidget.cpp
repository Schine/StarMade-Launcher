#include "glwidget.h"
#include <QFontDatabase>
#include <QMessageBox>
#include <QFile>
#include <iostream>
#include "widgetpane.h"

GLWidget::GLWidget(QWidget* parent)
    : QGLWidget(parent)
{

}

GLWidget::~GLWidget()
{

}

void GLWidget::initializeGL()
{
    glClearColor(0.1, 0.1, 0.1, 1.0F);
    glDisable(GL_DEPTH_TEST);

    WidgetPane* mainWidget = new WidgetPane();
    mainWidget->setPosition(QPoint(0, 0));
    mainWidget->setSize(QPoint(width(), height()));
    mainWidget->setColor(66, 66, 66);
    m_mainWidget = mainWidget;

    WidgetPane* topBar = new WidgetPane(m_mainWidget);
    topBar->setPosition(QPoint(0, 0));
    topBar->setSize(QPoint(width(), 66));
    topBar->setColor(39, 39, 39);

    WidgetPane* schineLogo = new WidgetPane(m_mainWidget);
    schineLogo->setPosition(QPoint(27, 16));
    schineLogo->setSize(QPoint(42, 42));
    schineLogo->setTexture(QString("schine_small.jpg"));

    WidgetPane* rightBar = new WidgetPane(m_mainWidget);
    rightBar->setPosition(QPoint(918, 66));
    rightBar->setSize(QPoint(282, 685));
    rightBar->setColor(85, 85, 85);
}

void GLWidget::paintGL()
{
    glClearColor(0, 0, 0, 0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    this->m_mainWidget->draw();
    update();
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
    this->m_mainWidget->setPosition(QPoint(0, 0));
    this->m_mainWidget->setSize(QPoint(w, h));
}
