#include "widgettextarea.h"
#include <iostream>
#include <sstream>

WidgetTextArea::WidgetTextArea(LauncherWidget* parent)
    : WidgetPane(parent),
    m_padding(Vector2F(25.0F, 25.0F))
{
    m_font = FontListEntry::BABAS_NEUE_12;
}

WidgetTextArea::~WidgetTextArea()
{

}

void WidgetTextArea::initWithTextCommon(std::string line, std::string& linePart)
{
    std::stringstream ss(line);
    std::string item;
    std::cout << "Done" << std::endl;
    while (std::getline(ss, item, ' '))
    {
        item += " ";
        std::string combined(linePart + item);
        Vector2F vec = FontRenderer::getTextSize(m_font, combined);
        float sizeX = vec.x();
        if (sizeX >= getSize().x() - m_padding.x())
        {
            m_clippedText.push_back(linePart);
            linePart.clear();
        }
        linePart += item;
    }
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
    for (int i = 0; i < textVector.size(); ++i)
    {
        initWithTextCommon(textVector[i], linePart);
    }
}

void WidgetTextArea::draw()
{
    WidgetPane::draw();

    float yRenderSize = 0.0F;
    for (size_t i = 0; i < m_clippedText.size(); ++i)
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
