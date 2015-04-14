#include "mainwindow.h"

#include <iostream>
#include <fstream>
#include <chrono>
#ifdef _WIN32
#include <windows.h>
#include <shellapi.h>
#endif // _WIN32
#include <thread>
#include <cmath>
#include <GLFW/glfw3.h>
#include "ogl.h"
#include "widgetpane.h"
#include "widgetbutton.h"
#include "fontrenderer.h"

MainWindow::MainWindow(int borderSizeX, int borderSizeY)
    : m_size(0, 0),
    m_mousePosition(0, 0),
    m_mouseLastClickedPosition(0, 0),
    m_closeRequested(false),
    m_minimizeRequested(false),
    m_windowMoveRequest(0, 0),
    m_borderSize(borderSizeX, borderSizeY)
{
}

MainWindow::~MainWindow()
{
}

void MainWindow::init()
{
    glClearColor(0.1, 0.1, 0.1, 1.0F);
    glDisable(GL_DEPTH_TEST);

    WidgetPane* mainWidget = new WidgetPane();
    mainWidget->setPosition(Vector2I(0, 0));
    mainWidget->setSize(m_size);
    mainWidget->setColor(66, 66, 66);
    m_mainWidget = std::shared_ptr<WidgetPane>(mainWidget);

    WidgetPane* topBar = new WidgetPane(m_mainWidget.get());
    topBar->setPosition(Vector2I(0, 0));
    topBar->setSize(Vector2I(width(), 66));
    topBar->setColor(39, 39, 39);

    WidgetPane* schineLogo = new WidgetPane(m_mainWidget.get());
    schineLogo->setPosition(Vector2I(27, 16));
    schineLogo->setSize(Vector2I(42, 42));
    schineLogo->setTexture(std::string("data/textures/schine_small.png"));

    WidgetPane* rightBar = new WidgetPane(m_mainWidget.get());
    rightBar->setPosition(Vector2I(918, 66));
    rightBar->setSize(Vector2I(282, 685));
    rightBar->setColor(85, 85, 85);

    WidgetButton* launchButton = new WidgetButton("LAUNCH", nullptr, rightBar);
    launchButton->setPosition(Vector2I(929, 649));
    launchButton->setSize(Vector2I(256, 87));
    launchButton->setColor(255, 255, 255);
    launchButton->setTexture(std::string("data/textures/launch_button.png"));

    WidgetButton* skinSelection = new WidgetButton("Skin Selection", nullptr, rightBar);
    skinSelection->setPosition(Vector2I(929, 374));
    skinSelection->setSize(Vector2I(256, 38));
    skinSelection->setColor(255, 255, 255);
    skinSelection->setTexture(std::string("data/textures/button_small.png"));
}

void MainWindow::update(double deltaTime)
{
    m_mainWidget->update(deltaTime);
}

void MainWindow::render()
{
    glClearColor(0, 0, 0, 0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    this->m_mainWidget->draw();
}

void MainWindow::resize(int w, int h)
{
    m_size.setXY(w, h);
    glViewport(0, 0, w, h);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(0.0f, this->width(), this->height(), 0.0f, -1.0, 1.0);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
}

void MainWindow::mouseClicked(int button, bool press)
{
    if (press)
    {
        if (m_mousePosition.x() >= this->width() - CLOSE_BUTTON_OFFSET - CLOSE_BUTTON_SIZE / 2.0F &&
                m_mousePosition.x() <= this->width() - CLOSE_BUTTON_OFFSET + CLOSE_BUTTON_SIZE / 2.0F &&
                m_mousePosition.y() >= CLOSE_BUTTON_OFFSET - CLOSE_BUTTON_SIZE / 2.0F &&
                m_mousePosition.y() < CLOSE_BUTTON_OFFSET + CLOSE_BUTTON_SIZE / 2.0F)
        {
            m_closeRequested = true;
        }
        else if (m_mousePosition.x() >= this->width() - MINIMIZE_BUTTON_OFFSET_X - CLOSE_BUTTON_SIZE / 2.0F &&
                m_mousePosition.x() <= this->width() - MINIMIZE_BUTTON_OFFSET_X + CLOSE_BUTTON_SIZE / 2.0F &&
                m_mousePosition.y() >= CLOSE_BUTTON_OFFSET - CLOSE_BUTTON_SIZE / 2.0F &&
                m_mousePosition.y() < CLOSE_BUTTON_OFFSET + CLOSE_BUTTON_SIZE / 2.0F)
        {
            m_mouseLastClickedPosition.setXY(-1, -1);
            setMinimizeRequested(true);
        }
        else
        {
            m_mouseLastClickedPosition.setXY(m_mousePosition.x(), m_mousePosition.y());
        }
    }
    else
    {
        m_mouseLastClickedPosition.setXY(-1, -1);
    }
    m_mainWidget->mouseClicked(m_mousePosition, button, press);
}

void MainWindow::mouseMoved(double xPos, double yPos)
{
    m_mousePosition.setXY(xPos, yPos);
    if (m_mouseLastClickedPosition.y() > 0 && m_mouseLastClickedPosition.y() < this->height() * 0.05)
    {
        m_windowMoveRequest.setXY(xPos - m_mouseLastClickedPosition.x() + m_borderSize.x(), yPos - m_mouseLastClickedPosition.y() + 30);
    }
    m_mainWidget->mouseMoved(m_mousePosition);
}
