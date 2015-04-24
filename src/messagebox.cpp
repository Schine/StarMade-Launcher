#include "messagebox.h"
#include <iostream>
#include "mainwindow.h"
#include "ogl.h"
#include "fontrenderer.h"

LauncherMessageBox::LauncherMessageBox(const std::string& title,
                   const std::string& message,
                   const Vector2I& size,
                   std::initializer_list<MessageBoxButton*> messageBoxes,
                   std::initializer_list<MessageBoxTextWidget*> textBoxes,
                   double timeOpened,
                   IButtonCallback* callback)
    : m_title(title),
    m_message(message),
    m_size(size),
    m_timeOpened(timeOpened),
    m_callback(callback)
{
    for (const auto& elem : messageBoxes)
    {
        m_buttons.push_back(elem);
    }

    for (const auto& elem : textBoxes)
    {
        m_textBoxes.push_back(elem);
    }
}

LauncherMessageBox::~LauncherMessageBox()
{
    //dtor
}

void LauncherMessageBox::render()
{
    const int halfWidth = MainWindow::getInstance()->width() / 2;
    const int halfHeight = MainWindow::getInstance()->height() / 2;
    const int borderSize = 1;
    glBegin(GL_QUADS);
    glColor3f(61 / 255.0F,
              61 / 255.0F,
              71 / 255.0F);
    glVertex2f(halfWidth - m_size.x() / 2, halfHeight - m_size.y() / 2);
    glVertex2f(halfWidth + m_size.x() / 2, halfHeight - m_size.y() / 2);
    glVertex2f(halfWidth + m_size.x() / 2, halfHeight + m_size.y() / 2);
    glVertex2f(halfWidth - m_size.x() / 2, halfHeight + m_size.y() / 2);
    glEnd();

    glColor3f(97 / 255.0F,
              97 / 255.0F,
              103 / 255.0F);

    glBegin(GL_QUADS);
    glVertex2f(halfWidth - m_size.x() / 2, halfHeight - m_size.y() / 2);
    glVertex2f(halfWidth - m_size.x() / 2 + borderSize, halfHeight - m_size.y() / 2);
    glVertex2f(halfWidth - m_size.x() / 2 + borderSize, halfHeight + m_size.y() / 2);
    glVertex2f(halfWidth - m_size.x() / 2, halfHeight + m_size.y() / 2);
    glEnd();

    glBegin(GL_QUADS);
    glVertex2f(halfWidth + m_size.x() / 2 - borderSize, halfHeight - m_size.y() / 2);
    glVertex2f(halfWidth + m_size.x() / 2, halfHeight - m_size.y() / 2);
    glVertex2f(halfWidth + m_size.x() / 2, halfHeight + m_size.y() / 2);
    glVertex2f(halfWidth + m_size.x() / 2 - borderSize, halfHeight + m_size.y() / 2);
    glEnd();

    glBegin(GL_QUADS);
    glVertex2f(halfWidth - m_size.x() / 2, halfHeight - m_size.y() / 2);
    glVertex2f(halfWidth + m_size.x() / 2, halfHeight - m_size.y() / 2);
    glVertex2f(halfWidth + m_size.x() / 2, halfHeight - m_size.y() / 2 + borderSize);
    glVertex2f(halfWidth - m_size.x() / 2, halfHeight - m_size.y() / 2 + borderSize);
    glEnd();

    glBegin(GL_QUADS);
    glVertex2f(halfWidth - m_size.x() / 2, halfHeight + m_size.y() / 2 - borderSize);
    glVertex2f(halfWidth + m_size.x() / 2, halfHeight + m_size.y() / 2 - borderSize);
    glVertex2f(halfWidth + m_size.x() / 2, halfHeight + m_size.y() / 2);
    glVertex2f(halfWidth - m_size.x() / 2, halfHeight + m_size.y() / 2);
    glEnd();

    for (int i = 0; i < m_buttons.size(); ++i)
    {
        const auto& button = m_buttons[i];
        int buttonSize = (m_size.x() - 60) / m_buttons.size();
        int buttonPos = ((buttonSize) + 60 / m_buttons.size()) * i + 30 / m_buttons.size();

        int posX0 = halfWidth - m_size.x() / 2 + buttonPos;
        int posX1 = posX0 + buttonSize;
        int posY0 = halfHeight + m_size.y() / 2 - 45;
        int posY1 = posY0 + 30;

        glColor3f(97 / 255.0F,
                  97 / 255.0F,
                  103 / 255.0F);

        glBegin(GL_QUADS);
        glVertex2f(posX0,   posY0);
        glVertex2f(posX1,   posY0);
        glVertex2f(posX1,   posY1);
        glVertex2f(posX0,   posY1);
        glEnd();

        glColor3f(61 * (button->hovered ? 1.2F : 1) / 255.0F,
                  61 * (button->hovered ? 1.2F : 1) / 255.0F,
                  71 * (button->hovered ? 1.2F : 1) / 255.0F);

        glBegin(GL_QUADS);
        glVertex2f(posX0 + 1,   posY0 + 1);
        glVertex2f(posX1 - 1,   posY0 + 1);
        glVertex2f(posX1 - 1,   posY1 - 1);
        glVertex2f(posX0 + 1,   posY1 - 1);
        glEnd();

        FontListEntry font = FontListEntry::BLENDER_PRO_16;
        Vector2F textSize = FontRenderer::getTextSize(font, button->text);
        FontRenderer::renderText(font, button->text, Vector2I((posX0 + posX1) / 2 - textSize.x() / 2, (posY0 + posY1) / 2 + 6));
    }

    for (int i = 0; i < m_textBoxes.size(); ++i)
    {
        const auto& textBox = m_textBoxes[i];

        int posX0 = halfWidth - textBox->size.x() / 2;
        int posX1 = posX0 + textBox->size.x();
        int posY0 = halfHeight + textBox->positionInBox.y();
        int posY1 = posY0 + textBox->size.y();

        glColor3f(97 / 255.0F,
                  97 / 255.0F,
                  103 / 255.0F);

        glBegin(GL_QUADS);
        glVertex2f(posX0,   posY0);
        glVertex2f(posX1,   posY0);
        glVertex2f(posX1,   posY1);
        glVertex2f(posX0,   posY1);
        glEnd();

        glColor3f(61 / 255.0F,
                  61 / 255.0F,
                  71 / 255.0F);

        glBegin(GL_QUADS);
        glVertex2f(posX0 + 1,   posY0 + 1);
        glVertex2f(posX1 - 1,   posY0 + 1);
        glVertex2f(posX1 - 1,   posY1 - 1);
        glVertex2f(posX0 + 1,   posY1 - 1);
        glEnd();

        FontListEntry font = FontListEntry::BLENDER_PRO_16;
        Vector2F textSize = FontRenderer::getTextSize(font, textBox->text);
        FontRenderer::renderText(font, textBox->text + (textBox->showSelector ? "|" : ""), Vector2I((posX0 + posX1) / 2 - textSize.x() / 2, (posY0 + posY1) / 2 + 6));
    }
}

void LauncherMessageBox::mouseClicked(Vector2D clickPos, int mouseButton, bool press)
{
    const int halfWidth = MainWindow::getInstance()->width() / 2;
    const int halfHeight = MainWindow::getInstance()->height() / 2;

    for (int i = 0; i < m_buttons.size(); ++i)
    {
        const auto& button = m_buttons[i];
        int buttonSize = (m_size.x() - 60) / m_buttons.size();
        int buttonPos = ((buttonSize) + 60 / m_buttons.size()) * i + 30 / m_buttons.size();

        int posX0 = halfWidth - m_size.x() / 2 + buttonPos;
        int posX1 = posX0 + buttonSize;
        int posY0 = halfHeight + m_size.y() / 2 - 45;
        int posY1 = posY0 + 30;

        if (mouseButton == 0 && press &&
            clickPos.x() >= posX0 &&
            clickPos.x() <= posX1 &&
            clickPos.y() >= posY0 &&
            clickPos.y() <= posY1)
        {
            if (m_callback != nullptr)
            {
                m_callback->buttonClicked(button->index);
            }
        }
    }

    for (int i = 0; i < m_textBoxes.size(); ++i)
    {
        auto& textBox = m_textBoxes[i];
        int buttonSize = (m_size.x() - 60) / m_buttons.size();
        int buttonPos = ((buttonSize) + 60 / m_buttons.size()) * i + 30 / m_buttons.size();

        int posX0 = halfWidth - textBox->size.x() / 2;
        int posX1 = posX0 + textBox->size.x();
        int posY0 = halfHeight + textBox->positionInBox.y();
        int posY1 = posY0 + textBox->size.y();

        if (mouseButton == 0 && press &&
            clickPos.x() >= posX0 &&
            clickPos.x() <= posX1 &&
            clickPos.y() >= posY0 &&
            clickPos.y() <= posY1)
        {
            if (m_callback != nullptr)
            {
                m_callback->buttonClicked(textBox->index);
            }
        }

        textBox->mouseClicked(clickPos, mouseButton, press);
    }
}

void LauncherMessageBox::mouseMoved(Vector2D newPos, Vector2D deltaPos)
{
    const int halfWidth = MainWindow::getInstance()->width() / 2;
    const int halfHeight = MainWindow::getInstance()->height() / 2;

    for (int i = 0; i < m_buttons.size(); ++i)
    {
        auto& button = m_buttons[i];
        int buttonSize = (m_size.x() - 60) / m_buttons.size();
        int buttonPos = ((buttonSize) + 60 / m_buttons.size()) * i + 30 / m_buttons.size();

        int posX0 = halfWidth - m_size.x() / 2 + buttonPos;
        int posX1 = posX0 + buttonSize;
        int posY0 = halfHeight + m_size.y() / 2 - 45;
        int posY1 = posY0 + 30;

        button->hovered = newPos.x() >= posX0 &&
                            newPos.x() <= posX1 &&
                            newPos.y() >= posY0 &&
                            newPos.y() <= posY1;
    }
}

void LauncherMessageBox::keyPressed(int key, int action, int mods)
{
    for (int i = 0; i < m_textBoxes.size(); ++i)
    {
        auto& textBox = m_textBoxes[i];
        textBox->keyPressed(key, action, mods);
    }
}

void LauncherMessageBox::charTyped(unsigned int codePoint, int mods)
{
    for (int i = 0; i < m_textBoxes.size(); ++i)
    {
        auto& textBox = m_textBoxes[i];
        textBox->charTyped(codePoint, mods);
    }
}

void LauncherMessageBox::update(double deltaTime)
{
    for (int i = 0; i < m_textBoxes.size(); ++i)
    {
        auto& textBox = m_textBoxes[i];
        textBox->update(deltaTime);
    }
}

void MessageBoxTextWidget::mouseClicked(Vector2D clickPos, int mouseButton, bool press)
{
    const int halfWidth = MainWindow::getInstance()->width() / 2;
    const int halfHeight = MainWindow::getInstance()->height() / 2;
    int posX0 = halfWidth - size.x() / 2;
    int posX1 = posX0 + size.x();
    int posY0 = halfHeight + positionInBox.y();
    int posY1 = posY0 + size.y();

    if (mouseButton == 0 && press &&
        clickPos.x() >= posX0 &&
        clickPos.x() <= posX1 &&
        clickPos.y() >= posY0 &&
        clickPos.y() <= posY1)
    {
        focused = true;
    }
    else if (press)
    {
        focused = false;
    }
}

void MessageBoxTextWidget::mouseMoved(Vector2D newPos, Vector2D deltaPos)
{

}

void MessageBoxTextWidget::keyPressed(int key, int action, int mods)
{
    if (key == GLFW_KEY_BACKSPACE && action != GLFW_RELEASE)
    {
        text = text.substr(0, text.size() - 1);
    }
}

void MessageBoxTextWidget::charTyped(unsigned int codePoint, int mods)
{
    text += (char)codePoint;
}

void MessageBoxTextWidget::update(double deltaTime)
{
    showSelector = focused && ((int)(glfwGetTime() * 2)) % 2 == 0;
}
