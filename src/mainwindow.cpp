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
#include <sstream>
#include <string>
#include <vector>
#include <curl/curl.h>
#include <GLFW/glfw3.h>
#include "ogl.h"
#include "widgetpane.h"
#include "widgetbutton.h"
#include "fontrenderer.h"
#include "widgettextarea.h"

struct BufferStruct
{
    char* buffer;
    size_t size;
};

static size_t writeMemoryCallback(void *ptr, size_t size, size_t nmemb, void *data)
{
    size_t realSize = size * nmemb;

    struct BufferStruct * mem = (struct BufferStruct *) data;
    mem->buffer = (char*)realloc(mem->buffer, mem->size + realSize + 1);

    if (mem->buffer)
    {
        memcpy(&(mem->buffer[mem->size]), ptr, realSize);
        mem->size += realSize;
        mem->buffer[mem->size] = 0;
    }

    return realSize;
}

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
    mainWidget->setColor(0, 0, 0);
    m_mainWidget = std::shared_ptr<WidgetPane>(mainWidget);

    WidgetPane* topBar = new WidgetPane(m_mainWidget.get());
    topBar->setPosition(Vector2I(0, 0));
    topBar->setSize(Vector2I(width(), 66));
    topBar->setColor(28, 107, 127);

    /**
    WidgetPane* schineLogo = new WidgetPane(m_mainWidget.get());
    schineLogo->setPosition(Vector2I(27, 16));
    schineLogo->setSize(Vector2I(42, 42));
    schineLogo->setTexture(std::string("data/textures/schine_small.png"));
    */

    WidgetPane* rightBar = new WidgetPane(m_mainWidget.get());
    rightBar->setPosition(Vector2I(906, 66));
    rightBar->setSize(Vector2I(294, 684));
    rightBar->setColor(34, 34, 40);

    WidgetButton* launchButton = new WidgetButton("LAUNCH", -1,
                                                  FontListEntry::MARCELLUS_32,
                                                  nullptr, rightBar);
    launchButton->setPosition(Vector2I(929, 649));
    launchButton->setSize(Vector2I(256, 87));
    launchButton->setColor(255, 255, 255);
    launchButton->setTexture(std::string("data/textures/launch_button.png"));

    WidgetButton* skinSelection = new WidgetButton("Dedicated Server", -1,
                                                    FontListEntry::MARCELLUS_16,
                                                    nullptr, rightBar);
    skinSelection->setPosition(Vector2I(929, 597));
    skinSelection->setSize(Vector2I(256, 38));
    skinSelection->setColor(255, 255, 255);
    skinSelection->setTexture(std::string("data/textures/button_small.png"));

    WidgetButton* closeButton = new WidgetButton("", 0, FontListEntry::MARCELLUS_16, this, topBar);
    closeButton->setPosition(Vector2I(1162, 22));
    closeButton->setSize(Vector2I(22, 24));
    closeButton->setColor(255, 255, 255);
    closeButton->setTexture(std::string("data/textures/close_button.png"));
    closeButton->setTextureCoordinates({ Vector2F(0.0F, 0.0F), Vector2F(0.6875F, 0.75F) });

    WidgetButton* minimizeButton = new WidgetButton("", 1, FontListEntry::MARCELLUS_16, this, topBar);
    minimizeButton->setPosition(Vector2I(1118, 22));
    minimizeButton->setSize(Vector2I(22, 24));
    minimizeButton->setColor(255, 255, 255);
    minimizeButton->setTexture(std::string("data/textures/close_button.png"));
    minimizeButton->setTextureCoordinates({ Vector2F(0.0F, 0.75F), Vector2F(0.90625F, 0.1875F) });
    minimizeButton->setDrawOffset({ Vector2F(0.0F, 17.0F), Vector2F(0.0F, -18.0F) });

    WidgetTextArea* textArea = new WidgetTextArea(m_mainWidget.get());
    textArea->setPosition(Vector2I(24, 86));
    textArea->setSize(Vector2I(840, 607));
    textArea->setColor(0, 0, 0);
    Border textAreaBorder({ 1, Vector3I(42, 42, 52) });
    textArea->setBorder(textAreaBorder);

    curl_global_init(CURL_GLOBAL_ALL);
    CURL *curl;
    CURLcode res;
    struct BufferStruct output;
    output.buffer = NULL;
    output.size = 0;

    curl = curl_easy_init();
    if (curl)
    {
        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, writeMemoryCallback);
        curl_easy_setopt(curl, CURLOPT_WRITEDATA, (void*)&output);
        curl_easy_setopt(curl, CURLOPT_URL, "http://star-made.org/news.rss");

        res = curl_easy_perform(curl);

        if (res != CURLE_OK)
        {
            std::cerr << "curl_easy_perform failed " << curl_easy_strerror(res) << std::endl;
        }

        curl_easy_cleanup(curl);

        std::stringstream ss(output.buffer);
        std::string item;
        using namespace std;
        vector<string> splitLines;
        bool inDescription = false;
        while (std::getline(ss, item, '\n'))
        {
            std::string line = item;
            int lastFoundPos = -1;
            int lastFoundPos0 = -1;
            size_t findPos = 0;
            replaceAllInLine(line, "&lt;", "<");
            replaceAllInLine(line, "lt;", "<");
            replaceAllInLine(line, "-&amp;gt;", "->");

            replaceAllInLine(line, "&gt;", ">");
            replaceAllInLine(line, "gt;", ">");

            replaceAllInLine(line, "&amp;#39;", "'");
            replaceAllInLine(line, "&amp;rsquo;", "'");
            replaceAllInLine(line, "&rsquo;", "'");

            replaceAllInLine(line, "&amp;quot;", "'");
            replaceAllInLine(line, "&quot;", "'");

            replaceAllInLine(line, "&ldquo;", "\"");
            replaceAllInLine(line, "&amp;ldquo;", "\"");
            replaceAllInLine(line, "ldquo;", "\"");
            replaceAllInLine(line, "&rdquo;", "\"");
            replaceAllInLine(line, "&amp;rdquo;", "\"");
            replaceAllInLine(line, "rdquo;", "\"");

            //ldquo;

            if (line.find("<pubDate>") != std::string::npos ||
                line.find("<link>") != std::string::npos ||
                line.find("<guid>") != std::string::npos)
            {
                continue;
            }

            lastFoundPos = -1;

            // Remove some HTML:
            while ((findPos = line.find("&amp;nbsp;")) != std::string::npos)
            {
                line.erase(findPos, 10);
            }
            findPos = line.find("<title>");
            if (findPos != std::string::npos)
            {
                size_t findPos0 = line.find("</title>");
                if (findPos0 != std::string::npos)
                {
                    std::string title(line.substr(findPos + 7, findPos0 - findPos - 7));
                    if (title.compare("starmade") != 0)
                    {
                        splitLines.push_back("<linet>" + title + "\n");
                        splitLines.push_back("<linet>\n");
                    }
                }
            }
            else
            {
                findPos = line.find("<description>");
                if (!inDescription && findPos != std::string::npos)
                {
                    inDescription = true;
                }
                if (inDescription)
                {
                    while ((findPos = line.find("<", (lastFoundPos >= 0 ? lastFoundPos + 1 : 0))) != std::string::npos)
                    {
                        size_t findPos0 = line.find(">", (lastFoundPos0 >= 0 ? lastFoundPos0 + 1 : 0));
                        if (findPos0 != std::string::npos)
                        {
                            std::string toRemove(line.substr(findPos, findPos0 + 1 - findPos));
                            if (toRemove.find("<br />") != std::string::npos)
                            {
                                lastFoundPos0 = findPos0;
                                lastFoundPos = findPos;
                            }
                            else if (toRemove.find("<a ") != std::string::npos)
                            {
                                lastFoundPos0 = findPos0;
                                lastFoundPos = findPos;
                                size_t findPos1 = toRemove.find("href=");
                                size_t findPos2 = toRemove.find_first_of("\"", findPos1 + 6);
                                std::string link(toRemove.substr(findPos1 + 5, findPos2 - 4 - findPos1));
                                std::string replaceWith("<link " + link + ">");
                                line.replace(findPos, findPos0 + 1 - findPos, replaceWith);
                                lastFoundPos0 = findPos + replaceWith.size() - 1;
                                lastFoundPos = findPos + replaceWith.size() - 1;
                            }
                            else
                            {
                                line.replace(findPos, findPos0 + 1 - findPos, "");
                            }
                        }
                    }

                    findPos = line.find("</description>");
                    if (findPos != std::string::npos)
                    {
                        inDescription = false;
                    }
                    else
                    {
                        replaceAllInLine(line, "</description>", "");
                        replaceAllInLine(line, "<description>", "");
                        bool forceLineEnd = line.find("<br />") != std::string::npos;

                        while (forceLineEnd)
                        {
                            std::string preLine = line.substr(0, line.find("<br />"));
                            line = line.substr(line.find("<br />"), line.size() - line.find("<br />") - 7);
                            splitLines.push_back("<line>" + preLine);
                            forceLineEnd = line.find("<br />") != std::string::npos;
                        }

                        splitLines.push_back("<line>" + line);
                    }
                }
            }
        }
        textArea->initWithText(splitLines);

        if (output.buffer)
        {
            free(output.buffer);
            output.buffer = NULL;
            output.size = 0;
        }
    }
}

void MainWindow::replaceAllInLine(std::string& lineToChange, const std::string& toReplace, const std::string& replaceWith)
{
    int lastFoundPos = -1;
    size_t findPos;
    while ((findPos = lineToChange.find(toReplace, (lastFoundPos >= 0 ? lastFoundPos + replaceWith.size() : 0))) != std::string::npos)
    {
        lineToChange.replace(findPos, toReplace.size(), replaceWith);
    }
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
        if (m_mousePosition.x() >= this->width() - MINIMIZE_BUTTON_OFFSET_X - CLOSE_BUTTON_SIZE / 2.0F &&
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

void MainWindow::buttonClicked(WidgetButton* button, int callbackIndex)
{
    switch (callbackIndex)
    {
    case 0:
        m_closeRequested = true;
        break;
    case 1:
        m_minimizeRequested = true;
        break;
    default:
        std::cerr << "Unknown button index: " << callbackIndex << std::endl;
        break;
    }
}
