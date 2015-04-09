#include "mainwindow.h"
#include "ui_mainwindow.h"

#include <QMouseEvent>
#include <iostream>
#include <fstream>
#include <shellapi.h>
#include <chrono>
#include <thread>
#include <QMessageBox>

MainWindow::MainWindow(QWidget *parent) :
    QMainWindow(parent, Qt::FramelessWindowHint | Qt::WindowSystemMenuHint),
    // Pass flags so that no borders/frames appear on window
    ui(new Ui::MainWindow)
{
    ui->setupUi(this);
}

MainWindow::~MainWindow()
{
    delete ui;
}

void MainWindow::checkJavaVersion(int maxFileReadAttempts)
{
    ShellExecute(nullptr, L"open", L"cmd.exe", L"/C java -version 2> .javaversion", 0, SW_HIDE);
    std::string line;
    std::this_thread::sleep_for(std::chrono::seconds(1)); // Wait for version file to be written.
    std::ifstream verFile(".javaversion");
    int attemptCount = 0;
    bool javaOkay = false;
    while (attemptCount < maxFileReadAttempts)
    {
        if (verFile.is_open())
        {
            while (getline(verFile, line))
            {
                if (line.find("java version") != std::string::npos) // Found some version, could possibly check version
                {
                    javaOkay = true;
                }
            }
            verFile.close();
            break; // Stop attempts
        }

        std::this_thread::sleep_for(std::chrono::seconds(1)); // If attempt failed, wait for version file to be written, again

        ++attemptCount;
    }
    if (attemptCount >= maxFileReadAttempts)
    {
        QMessageBox::warning(nullptr, "Warning", "Failed to get Java version. If you don't have Java installed, install it before starting!");
    }
    else if (!javaOkay)
    {
        // Open message letting user choose to install java
        int button = QMessageBox::question(nullptr, "Java Not Found", "Java not found! Select Java installation type:", "Default", "Manual", "Ignore", 0, 2);
        std::wstring command;
        if (shouldInstall64Bit())
        {
            command = std::wstring(L"jre-8u40-windows-x64.exe");
        }
        else
        {
            command = std::wstring(L"jre-8u40-windows-i586.exe");
        }
        if (button == 0)
        {
            // Install java silently - using default location
            std::wstring combined = std::wstring(L"/C ") + command + std::wstring(L" /s");
            ShellExecute(nullptr, L"open", L"cmd.exe", combined.c_str(), 0, SW_HIDE);
        }
        else if (button == 1)
        {
            // Install java manually - user can change install directory
            std::wstring combined = std::wstring(L"/C ") + command;
            ShellExecute(nullptr, L"open", L"cmd.exe", combined.c_str(), 0, SW_HIDE);
        }
    }
}

BOOL MainWindow::shouldInstall64Bit()
{
#if defined(_WIN64)
    return TRUE;
#elif defined(_WIN32)
    BOOL f64 = FALSE;
    return IsWow64Process(GetCurrentProcess(), &f64) && f64;
#else
    return FALSE;
#endif
}

void MainWindow::mousePressEvent(QMouseEvent *event)
{
    if (event->pos().x() >= this->width() - GLWidget::CLOSE_BUTTON_OFFSET - GLWidget::CLOSE_BUTTON_SIZE / 2.0F &&
            event->pos().x() <= this->width() - GLWidget::CLOSE_BUTTON_OFFSET + GLWidget::CLOSE_BUTTON_SIZE / 2.0F &&
            event->pos().y() >= GLWidget::CLOSE_BUTTON_OFFSET - GLWidget::CLOSE_BUTTON_SIZE / 2.0F &&
            event->pos().y() < GLWidget::CLOSE_BUTTON_OFFSET + GLWidget::CLOSE_BUTTON_SIZE / 2.0F)
    {
        this->close();
    }
    else if (event->pos().x() >= this->width() - GLWidget::MINIMIZE_BUTTON_OFFSET_X - GLWidget::CLOSE_BUTTON_SIZE / 2.0F &&
            event->pos().x() <= this->width() - GLWidget::MINIMIZE_BUTTON_OFFSET_X + GLWidget::CLOSE_BUTTON_SIZE / 2.0F &&
            event->pos().y() >= GLWidget::CLOSE_BUTTON_OFFSET - GLWidget::CLOSE_BUTTON_SIZE / 2.0F &&
            event->pos().y() < GLWidget::CLOSE_BUTTON_OFFSET + GLWidget::CLOSE_BUTTON_SIZE / 2.0F)
    {
        m_mouseClickPos.setY(-1);
        this->setWindowState((this->windowState() & ~Qt::WindowActive) | Qt::WindowMinimized);
    }
    else
    {
        m_mouseClickPos = event->pos();
    }
}

void MainWindow::mouseMoveEvent(QMouseEvent *event)
{
    if (m_mouseClickPos.y() > 0 && event->buttons() && Qt::LeftButton && m_mouseClickPos.y() < this->height() * 0.05)
    {
        QPoint diff = event->pos() - m_mouseClickPos;
        QPoint newPos = this->pos() + diff;
        this->move(newPos);
    }
}
