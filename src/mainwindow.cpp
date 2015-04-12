#include "mainwindow.h"

#include <iostream>
#include <fstream>
#include <chrono>
#ifdef _WIN32
#include <windows.h>
#include <shellapi.h>
#endif // _WIN32
#include <thread>
#include "ogl.h"
#include "widgetpane.h"

MainWindow::MainWindow(int borderSizeX, int borderSizeY)
    : m_size(0, 0),
    m_mousePosition(0, 0),
    m_mouseLastClickedPosition(0, 0),
    m_closeRequested(false),
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
    mainWidget->setSize(Vector2I(width(), height()));
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
}

void MainWindow::update(double deltatTime)
{

}

void MainWindow::render()
{
    glClearColor(0, 0, 0, 0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    this->m_mainWidget->draw();
}

void MainWindow::resize(int w, int h)
{
    std::cout << w << " " << h << std::endl;
    m_size.setXY(w, h);
    glViewport(0, 0, w, h);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(0.0f, this->width(), this->height(), 0.0f, -1.0, 1.0);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    this->m_mainWidget->setPosition(Vector2I(0, 0));
    this->m_mainWidget->setSize(Vector2I(w, h));
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
}

void MainWindow::mouseMoved(double xPos, double yPos)
{
    m_mousePosition.setXY(xPos, yPos);
    if (m_mouseLastClickedPosition.y() > 0 && m_mouseLastClickedPosition.y() < this->height() * 0.05)
    {
        std::cout << (yPos - m_mouseLastClickedPosition.y()) << std::endl;

        m_windowMoveRequest.setXY(xPos - m_mouseLastClickedPosition.x() + m_borderSize.x(), yPos - m_mouseLastClickedPosition.y() + 30);
    }
}
