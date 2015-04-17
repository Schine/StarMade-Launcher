#include "widgettextarea.h"
#include <iostream>
#include <sstream>

WidgetTextArea::WidgetTextArea(LauncherWidget* parent)
    : WidgetPane(parent),
    m_padding(Vector2F(25.0F, 25.0F))
{
    m_scroll = -m_padding.y();
}

WidgetTextArea::~WidgetTextArea()
{

}

void WidgetTextArea::initWithTextCommon(std::string line, std::string& linePart)
{
    size_t findLine = line.find("<line>");
    size_t findLineT = line.find("<linet>");
    bool foundLine = findLine != std::string::npos;
    bool foundLineT = findLineT != std::string::npos;
    if ((foundLine || foundLineT))
    {
        std::string newString;

        if (foundLineT)
        {
            newString = line.substr(findLineT + 7, line.size() - 7);
        }
        else
        {
            newString = line.substr(findLine + 6, line.size() - 6);
        }

        size_t findPos;
        while ((findPos = newString.find("&amp;")) != std::string::npos)
        {
            newString.replace(findPos, 5, "&");
        }

        FontListEntry fontToUse = foundLineT ? FontListEntry::MARCELLUS_24 : FontListEntry::MARCELLUS_12;

        std::stringstream ss(newString);
        std::string item;
        while (std::getline(ss, item, ' '))
        {
            std::string combined(linePart + item + " ");
            Vector2F vec = FontRenderer::getTextSize(fontToUse, combined);
            float sizeX = vec.x();
            if (sizeX >= getSize().x() - m_padding.x())
            {
                addText(linePart, fontToUse);
                linePart.clear();
            }
            linePart += item;
            if (item.size() > 0 && item.compare(" ") != 0)
            {
                linePart += " ";
            }
        }

        addText(linePart, fontToUse);
        linePart.clear();
    }
}

void WidgetTextArea::addText(const std::string& text, FontListEntry font)
{
    m_clippedText.push_back(text);
    m_fonts.push_back(font);
}

void WidgetTextArea::initWithText(std::string* text, int tempTextLength)
{
    std::string linePart;
    for (int i = 0; i < tempTextLength; ++i)
    {
        initWithTextCommon(text[i], linePart);
    }
}

void WidgetTextArea::initWithText(std::vector<std::string> textVector)
{
    std::string linePart;
    for (size_t i = 0; i < textVector.size(); ++i)
    {
        initWithTextCommon(textVector[i], linePart);
    }
}

void WidgetTextArea::draw()
{
    WidgetPane::draw();

    float yRenderedLength = 0.0F;
    for (size_t i = 0; i < m_clippedText.size(); ++i)
    {
        std::string& line = m_clippedText[i];
        Vector2F textSize = FontRenderer::getTextSize(m_fonts[i], line);
        if (yRenderedLength + textSize.y() < getSize().y() - m_padding.y() * 2 + m_scroll &&
            yRenderedLength + textSize.y() > m_padding.y() + m_scroll)
        {
            FontRenderer::renderText(m_fonts[i], line, Vector2I(getPosition().x() + getSize().x() / 2 - textSize.x() / 2, getPosition().y() + yRenderedLength + m_padding.y() + textSize.y() - m_scroll));
        }
        yRenderedLength += textSize.y() + 5.0F;
    }

    m_maxScroll = yRenderedLength - m_padding.y() * 2 - getSize().y();

    glBegin(GL_QUADS);
    glColor3f(55 / 255.0F, 55 / 255.0F, 55 / 255.0F);
    glVertex3f(879,        81,          0.0);
    glVertex3f(879 + 12,   81,          0.0);
    glVertex3f(879 + 12,   81 + 612,    0.0);
    glVertex3f(879,        81 + 612,    0.0);
    glEnd();

    glBegin(GL_QUADS);
    glColor3f(142 / 255.0F, 142 / 255.0F, 142 / 255.0F);
    int slider = static_cast<int>((612 - 35) * getScrollPercentage());
    glVertex3f(882,         84 + slider,         0.0);
    glVertex3f(882 + 7,     84 + slider,         0.0);
    glVertex3f(882 + 7,     84 + 30 + slider,    0.0);
    glVertex3f(882,         84 + 30 + slider,     0.0);
    glEnd();
}

void WidgetTextArea::init()
{
}

void WidgetTextArea::update(double delta)
{
}

void WidgetTextArea::mouseMoved(Vector2D newPos)
{
    LauncherWidget::mouseMoved(newPos);
}

void WidgetTextArea::mouseClicked(Vector2D clickPos, int button, bool press)
{
    LauncherWidget::mouseClicked(clickPos, button, press);
}

void WidgetTextArea::mouseWheelScrolled(double xOffset, double yOffset)
{
    m_scroll -= yOffset * 150;
    m_scroll = std::max(m_scroll, -m_padding.y());
    m_scroll = std::min(m_scroll, m_maxScroll);
}

