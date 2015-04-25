#include "messagebox.h"
#include <iostream>
#include "mainwindow.h"
#include "ogl.h"
#include "fontrenderer.h"

LauncherMessageBox::LauncherMessageBox(const Vector2I& size,
                   std::initializer_list<MessageBoxButton*> messageBoxes,
                   std::initializer_list<MessageBoxTextWidget*> textBoxes,
                   std::initializer_list<MessageBoxLabelWidget*> labels,
                   double timeOpened,
                   IButtonCallback* callback)
    : m_size(size),
    m_callback(callback),
    m_timeOpened(timeOpened)
{
    for (const auto& elem : messageBoxes)
    {
        m_buttons.push_back(elem);
    }

    for (const auto& elem : textBoxes)
    {
        m_textBoxes.push_back(elem);
    }

    for (const auto& elem : labels)
    {
        m_labels.push_back(elem);
    }
}

LauncherMessageBox::~LauncherMessageBox()
{
    for (auto elem : m_buttons)
    {
        delete elem;
    }

    for (auto elem : m_textBoxes)
    {
        delete elem;
    }

    for (auto elem : m_labels)
    {
        delete elem;
    }
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

    for (size_t i = 0; i < m_buttons.size(); ++i)
    {
        const auto& button = m_buttons[i];
        int buttonWidth = button->size.x() - button->padding;
        int buttonPos = ((m_size.x() / button->numInlineButtons) / 2) - (buttonWidth / 2) + ((m_size.x() / button->numInlineButtons) * button->indexInLine);

        int posX0 = halfWidth - m_size.x() / 2 + buttonPos;
        int posX1 = posX0 + buttonWidth;
        int posY0 = halfHeight + m_size.y() / 2 - button->size.y() / 2 + button->positionInBox.y();
        int posY1 = posY0 + button->size.y();

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

    for (size_t i = 0; i < m_textBoxes.size(); ++i)
    {
        const auto& textBox = m_textBoxes[i];
        std::string newString = textBox->text;
        if (textBox->hideCharacters)
        {
            newString = "";
            for (size_t j = 0; j < textBox->text.size(); ++j)
            {
                newString += "*";
            }
        }

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
        Vector2F textSize = FontRenderer::getTextSize(font, newString);
        FontRenderer::renderText(font, newString + (textBox->showSelector ? "|" : ""), Vector2I((posX0 + posX1) / 2 - textSize.x() / 2, (posY0 + posY1) / 2 + 6));
    }

    for (size_t i = 0; i < m_labels.size(); ++i)
    {
        const auto& label = m_labels[i];

        FontListEntry font = FontListEntry::BLENDER_PRO_16;
        Vector2F textSize = FontRenderer::getTextSize(font, label->text);

        int posX0 = halfWidth - textSize.x() / 2;
        int posX1 = posX0 + textSize.x();
        int posY0 = halfHeight + label->positionInBox.y();
        int posY1 = posY0 + textSize.y();

        FontRenderer::renderText(font, label->text, Vector2I((posX0 + posX1) / 2 - textSize.x() / 2, (posY0 + posY1) / 2 + 6));
    }
}

void LauncherMessageBox::mouseClicked(Vector2D clickPos, int mouseButton, bool press)
{
    const int halfWidth = MainWindow::getInstance()->width() / 2;
    const int halfHeight = MainWindow::getInstance()->height() / 2;

    for (size_t i = 0; i < m_buttons.size(); ++i)
    {
        const auto& button = m_buttons[i];
        int buttonWidth = button->size.x() - button->padding;
        int buttonPos = ((m_size.x() / button->numInlineButtons) / 2) - (buttonWidth / 2) + ((m_size.x() / button->numInlineButtons) * button->indexInLine);

        int posX0 = halfWidth - m_size.x() / 2 + buttonPos;
        int posX1 = posX0 + buttonWidth;
        int posY0 = halfHeight + m_size.y() / 2 - button->size.y() / 2 + button->positionInBox.y();
        int posY1 = posY0 + button->size.y();

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

    for (size_t i = 0; i < m_textBoxes.size(); ++i)
    {
        auto& textBox = m_textBoxes[i];
        textBox->mouseClicked(clickPos, mouseButton, press);
    }
}

void LauncherMessageBox::mouseMoved(Vector2D newPos, Vector2D deltaPos)
{
    const int halfWidth = MainWindow::getInstance()->width() / 2;
    const int halfHeight = MainWindow::getInstance()->height() / 2;

    for (size_t i = 0; i < m_buttons.size(); ++i)
    {
        auto& button = m_buttons[i];
        int buttonWidth = button->size.x() - button->padding;
        int buttonPos = ((m_size.x() / button->numInlineButtons) / 2) - (buttonWidth / 2) + ((m_size.x() / button->numInlineButtons) * button->indexInLine);

        int posX0 = halfWidth - m_size.x() / 2 + buttonPos;
        int posX1 = posX0 + buttonWidth;
        int posY0 = halfHeight + m_size.y() / 2 - button->size.y() / 2 + button->positionInBox.y();
        int posY1 = posY0 + button->size.y();

        button->hovered = newPos.x() >= posX0 &&
                            newPos.x() <= posX1 &&
                            newPos.y() >= posY0 &&
                            newPos.y() <= posY1;
    }
}

void LauncherMessageBox::keyPressed(int key, int action, int mods)
{
    int setBoxFocused = -1;
    bool setNextBoxFocused = false;
    for (size_t i = 0; i < m_textBoxes.size(); ++i)
    {
        auto& textBox = m_textBoxes[i];
        if (!setNextBoxFocused && key == GLFW_KEY_TAB && m_textBoxes.size() > 1 && action == GLFW_PRESS)
        {
            if (textBox->focused)
            {
                textBox->focused = false;
                setNextBoxFocused = true;
                setBoxFocused = i + ((mods & GLFW_MOD_SHIFT) ? -1 : 1);
            }
        }
        textBox->keyPressed(key, action, mods);
    }
    if (setNextBoxFocused)
    {
        int textBoxToFocus = setBoxFocused;
        if (textBoxToFocus >= static_cast<int>(m_textBoxes.size()))
        {
            textBoxToFocus = 0;
        }
        if (setBoxFocused < 0)
        {
            textBoxToFocus = m_textBoxes.size() - 1;
        }
        m_textBoxes[textBoxToFocus]->focused = true;
    }
}

void LauncherMessageBox::charTyped(unsigned int codePoint, int mods)
{
    for (size_t i = 0; i < m_textBoxes.size(); ++i)
    {
        auto& textBox = m_textBoxes[i];
        textBox->charTyped(codePoint, mods);
    }
}

void LauncherMessageBox::update(double deltaTime)
{
    for (size_t i = 0; i < m_textBoxes.size(); ++i)
    {
        auto& textBox = m_textBoxes[i];
        textBox->update(deltaTime);
    }
}

MessageBoxButton* LauncherMessageBox::getButtonByID(int id)
{
    for (size_t i = 0; i < m_buttons.size(); ++i)
    {
        auto button = m_buttons[i];
        if (button->index == id)
        {
            return button;
        }
    }
    return nullptr;
}

MessageBoxTextWidget* LauncherMessageBox::getTextBoxByID(int id)
{
    for (size_t i = 0; i < m_textBoxes.size(); ++i)
    {
        auto button = m_textBoxes[i];
        if (button->index == id)
        {
            return button;
        }
    }
    return nullptr;
}

MessageBoxLabelWidget* LauncherMessageBox::getLabelByID(int id)
{
    for (size_t i = 0; i < m_labels.size(); ++i)
    {
        auto button = m_labels[i];
        if (button->index == id)
        {
            return button;
        }
    }
    return nullptr;
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
    if (focused)
    {
        if (key == GLFW_KEY_BACKSPACE && action != GLFW_RELEASE)
        {
            text = text.substr(0, text.size() - 1);
        }
    }
}

void MessageBoxTextWidget::charTyped(unsigned int codePoint, int mods)
{
    if (focused)
    {
        text += (char)codePoint;
    }
}

void MessageBoxTextWidget::update(double deltaTime)
{
    showSelector = focused && ((int)(glfwGetTime() * 2)) % 2 == 0;
}
