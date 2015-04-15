#include "widgettextarea.h"
#include <iostream>
#include <sstream>

WidgetTextArea::WidgetTextArea(std::string* text, int tempTextLength, LauncherWidget* parent)
    : WidgetPane(parent),
    m_tempTextLength(tempTextLength),
    m_tempText(text),
    m_padding(Vector2F(0.0F, 0.0F))
{
    m_font = FontListEntry::BABAS_NEUE_12;
    m_padding = Vector2F(25.0F, 25.0F);
}

WidgetTextArea::~WidgetTextArea()
{

}

void WidgetTextArea::draw()
{
    WidgetPane::draw();

    float yRenderSize = 0.0F;
    for (int i = 0; i < m_clippedText.size(); ++i)
    {
        std::string& line = m_clippedText[i];
        Vector2F textSize = FontRenderer::getTextSize(m_font, line);
        if (yRenderSize + textSize.y() < getSize().y() - m_padding.y() + m_scroll &&
            yRenderSize + textSize.y() > m_padding.y() + m_scroll)
        {
            FontRenderer::renderText(m_font, line, Vector2I(getPosition().x() + getSize().x() / 2 - textSize.x() / 2, getPosition().y() + i * textSize.y() + m_padding.y() - m_scroll));
        }
        yRenderSize += textSize.y();
    }
}

void WidgetTextArea::init()
{
    WidgetPane::init();

    std::string linePart;
    for (size_t i = 0; i < m_tempTextLength; ++i)
    {
        std::string& line = m_tempText[i];
        std::stringstream ss(line);
        std::string item;
        while (std::getline(ss, item, ' '))
        {
            item += " ";
            if (FontRenderer::getTextSize(m_font, linePart + item).x() >= getSize().x() - m_padding.x())
            {
                m_clippedText.push_back(linePart);
                linePart.clear();
            }
            linePart += item;
        }
    }
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
    m_scroll -= yOffset * 5;
}
