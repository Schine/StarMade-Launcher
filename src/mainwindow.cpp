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
#include "widgettextarea.h"

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

    WidgetButton* launchButton = new WidgetButton("LAUNCH", FontListEntry::GEO_SANS_LIGHT_32, nullptr, rightBar);
    launchButton->setPosition(Vector2I(929, 649));
    launchButton->setSize(Vector2I(256, 87));
    launchButton->setColor(255, 255, 255);
    launchButton->setTexture(std::string("data/textures/launch_button.png"));

    WidgetButton* skinSelection = new WidgetButton("Skin Selection", FontListEntry::BABAS_NEUE_12, nullptr, rightBar);
    skinSelection->setPosition(Vector2I(929, 374));
    skinSelection->setSize(Vector2I(256, 38));
    skinSelection->setColor(255, 255, 255);
    skinSelection->setTexture(std::string("data/textures/button_small.png"));

    std::string text[18] = {
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit. In eu laoreet ex. Nulla quis est maximus, eleifend purus vel, ullamcorper ipsum. Proin arcu velit, imperdiet at suscipit quis, dapibus ut urna. Quisque odio eros, tempor sit amet sapien ac, pretium rhoncus nunc. Praesent auctor ut risus vel sollicitudin. Donec sed quam eu mi facilisis volutpat a et velit. Sed gravida ante augue, eget condimentum ante pretium blandit. Duis urna enim, scelerisque eget ligula a, accumsan fringilla neque. Morbi iaculis ante eu tellus ultricies pharetra. Suspendisse nec dui in nisl ullamcorper molestie."

        "Aliquam et odio sed felis aliquet placerat fermentum pellentesque turpis. Aliquam vitae nisi ut dui tristique tristique et volutpat lectus. Donec non ante elementum, aliquam lorem ac, blandit libero. Etiam condimentum fermentum elementum. Donec molestie nibh et maximus tincidunt. Vestibulum id magna ut elit egestas interdum. Proin maximus, metus vel faucibus semper, erat leo pretium mauris, sed convallis urna augue sed nunc. Aenean accumsan mi at facilisis mollis."

        "Donec varius mauris a pharetra commodo. In facilisis pulvinar purus, a tristique magna placerat a. Praesent hendrerit ex urna, at dignissim quam suscipit ut. Vestibulum quis mollis nunc, in dapibus odio. Curabitur ac faucibus arcu. Duis semper lorem orci, in rutrum elit rhoncus ut. Suspendisse varius magna ut velit elementum condimentum. Proin elementum non est ut vulputate. Quisque vel dictum elit. Pellentesque at condimentum justo, at iaculis sapien. Aliquam erat volutpat. Nulla facilisis nunc sed ante tristique, at vehicula nisl lobortis. Vivamus malesuada gravida ultricies."

        "Sed purus nisl, hendrerit id sapien eu, egestas luctus nisi. Ut vitae auctor dolor. Vestibulum eget massa eu leo eleifend dictum. Duis viverra mi leo, a iaculis justo feugiat ut. Aenean at dapibus nulla, eu imperdiet quam. Sed volutpat aliquam facilisis. Phasellus ut semper erat, sed elementum ligula. Nulla facilisi. Fusce maximus metus interdum lacinia ultrices. Nullam elementum magna id nisl facilisis dapibus in eu libero. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos."

        "Praesent condimentum ipsum sit amet quam suscipit blandit. Nunc ultrices commodo diam eget ullamcorper. Vivamus finibus nunc dui, ac mattis mauris dictum vel. In posuere euismod est at faucibus. Aliquam malesuada, est sed hendrerit aliquam, tellus mauris pretium lacus, eget tristique sem diam vitae sem. Curabitur pulvinar eleifend dignissim. Sed pulvinar ligula eget tortor laoreet tincidunt. Sed sit amet dui nulla."

        "Donec eu blandit enim. Ut eu tincidunt ante. Sed et maximus risus. Fusce et dolor sed ex tincidunt mollis. Donec pulvinar pulvinar justo non porttitor. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Vivamus sit amet fermentum augue. In lacinia mollis felis non convallis. Integer et blandit dui. Morbi venenatis neque vel metus convallis dapibus."

        "Lorem ipsum dolor sit amet, consectetur adipiscing elit. In eu laoreet ex. Nulla quis est maximus, eleifend purus vel, ullamcorper ipsum. Proin arcu velit, imperdiet at suscipit quis, dapibus ut urna. Quisque odio eros, tempor sit amet sapien ac, pretium rhoncus nunc. Praesent auctor ut risus vel sollicitudin. Donec sed quam eu mi facilisis volutpat a et velit. Sed gravida ante augue, eget condimentum ante pretium blandit. Duis urna enim, scelerisque eget ligula a, accumsan fringilla neque. Morbi iaculis ante eu tellus ultricies pharetra. Suspendisse nec dui in nisl ullamcorper molestie."

        "Aliquam et odio sed felis aliquet placerat fermentum pellentesque turpis. Aliquam vitae nisi ut dui tristique tristique et volutpat lectus. Donec non ante elementum, aliquam lorem ac, blandit libero. Etiam condimentum fermentum elementum. Donec molestie nibh et maximus tincidunt. Vestibulum id magna ut elit egestas interdum. Proin maximus, metus vel faucibus semper, erat leo pretium mauris, sed convallis urna augue sed nunc. Aenean accumsan mi at facilisis mollis."

        "Donec varius mauris a pharetra commodo. In facilisis pulvinar purus, a tristique magna placerat a. Praesent hendrerit ex urna, at dignissim quam suscipit ut. Vestibulum quis mollis nunc, in dapibus odio. Curabitur ac faucibus arcu. Duis semper lorem orci, in rutrum elit rhoncus ut. Suspendisse varius magna ut velit elementum condimentum. Proin elementum non est ut vulputate. Quisque vel dictum elit. Pellentesque at condimentum justo, at iaculis sapien. Aliquam erat volutpat. Nulla facilisis nunc sed ante tristique, at vehicula nisl lobortis. Vivamus malesuada gravida ultricies."

        "Sed purus nisl, hendrerit id sapien eu, egestas luctus nisi. Ut vitae auctor dolor. Vestibulum eget massa eu leo eleifend dictum. Duis viverra mi leo, a iaculis justo feugiat ut. Aenean at dapibus nulla, eu imperdiet quam. Sed volutpat aliquam facilisis. Phasellus ut semper erat, sed elementum ligula. Nulla facilisi. Fusce maximus metus interdum lacinia ultrices. Nullam elementum magna id nisl facilisis dapibus in eu libero. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos."

        "Praesent condimentum ipsum sit amet quam suscipit blandit. Nunc ultrices commodo diam eget ullamcorper. Vivamus finibus nunc dui, ac mattis mauris dictum vel. In posuere euismod est at faucibus. Aliquam malesuada, est sed hendrerit aliquam, tellus mauris pretium lacus, eget tristique sem diam vitae sem. Curabitur pulvinar eleifend dignissim. Sed pulvinar ligula eget tortor laoreet tincidunt. Sed sit amet dui nulla."

        "Donec eu blandit enim. Ut eu tincidunt ante. Sed et maximus risus. Fusce et dolor sed ex tincidunt mollis. Donec pulvinar pulvinar justo non porttitor. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Vivamus sit amet fermentum augue. In lacinia mollis felis non convallis. Integer et blandit dui. Morbi venenatis neque vel metus convallis dapibus."

        "Lorem ipsum dolor sit amet, consectetur adipiscing elit. In eu laoreet ex. Nulla quis est maximus, eleifend purus vel, ullamcorper ipsum. Proin arcu velit, imperdiet at suscipit quis, dapibus ut urna. Quisque odio eros, tempor sit amet sapien ac, pretium rhoncus nunc. Praesent auctor ut risus vel sollicitudin. Donec sed quam eu mi facilisis volutpat a et velit. Sed gravida ante augue, eget condimentum ante pretium blandit. Duis urna enim, scelerisque eget ligula a, accumsan fringilla neque. Morbi iaculis ante eu tellus ultricies pharetra. Suspendisse nec dui in nisl ullamcorper molestie."

        "Aliquam et odio sed felis aliquet placerat fermentum pellentesque turpis. Aliquam vitae nisi ut dui tristique tristique et volutpat lectus. Donec non ante elementum, aliquam lorem ac, blandit libero. Etiam condimentum fermentum elementum. Donec molestie nibh et maximus tincidunt. Vestibulum id magna ut elit egestas interdum. Proin maximus, metus vel faucibus semper, erat leo pretium mauris, sed convallis urna augue sed nunc. Aenean accumsan mi at facilisis mollis."

        "Donec varius mauris a pharetra commodo. In facilisis pulvinar purus, a tristique magna placerat a. Praesent hendrerit ex urna, at dignissim quam suscipit ut. Vestibulum quis mollis nunc, in dapibus odio. Curabitur ac faucibus arcu. Duis semper lorem orci, in rutrum elit rhoncus ut. Suspendisse varius magna ut velit elementum condimentum. Proin elementum non est ut vulputate. Quisque vel dictum elit. Pellentesque at condimentum justo, at iaculis sapien. Aliquam erat volutpat. Nulla facilisis nunc sed ante tristique, at vehicula nisl lobortis. Vivamus malesuada gravida ultricies."

        "Sed purus nisl, hendrerit id sapien eu, egestas luctus nisi. Ut vitae auctor dolor. Vestibulum eget massa eu leo eleifend dictum. Duis viverra mi leo, a iaculis justo feugiat ut. Aenean at dapibus nulla, eu imperdiet quam. Sed volutpat aliquam facilisis. Phasellus ut semper erat, sed elementum ligula. Nulla facilisi. Fusce maximus metus interdum lacinia ultrices. Nullam elementum magna id nisl facilisis dapibus in eu libero. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos."

        "Praesent condimentum ipsum sit amet quam suscipit blandit. Nunc ultrices commodo diam eget ullamcorper. Vivamus finibus nunc dui, ac mattis mauris dictum vel. In posuere euismod est at faucibus. Aliquam malesuada, est sed hendrerit aliquam, tellus mauris pretium lacus, eget tristique sem diam vitae sem. Curabitur pulvinar eleifend dignissim. Sed pulvinar ligula eget tortor laoreet tincidunt. Sed sit amet dui nulla."

        "Donec eu blandit enim. Ut eu tincidunt ante. Sed et maximus risus. Fusce et dolor sed ex tincidunt mollis. Donec pulvinar pulvinar justo non porttitor. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Vivamus sit amet fermentum augue. In lacinia mollis felis non convallis. Integer et blandit dui. Morbi venenatis neque vel metus convallis dapibus."
    };

    WidgetTextArea* textArea = new WidgetTextArea(text, 18, m_mainWidget.get());
    textArea->setPosition(Vector2I(24, 86));
    textArea->setSize(Vector2I(840, 607));
    textArea->setColor(55, 55, 55);
    textArea->init();
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

void MainWindow::mouseWheelScrolled(double xOffset, double yOffset)
{
    m_mainWidget->mouseWheelScrolled(xOffset, yOffset);
}
