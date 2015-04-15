#include "widgetbutton.h"
#include "fontrenderer.h"
#include <iostream>

WidgetButton::WidgetButton(const std::string& text, FontListEntry font, IButtonCallback* callback, LauncherWidget* parent)
    : WidgetPane(parent),
    m_callback(callback),
    m_isHovered(false),
    m_text(text),
    m_font(font)
{
}

WidgetButton::~WidgetButton()
{
    if (m_callback != nullptr)
    {
        delete m_callback;
    }
}

void WidgetButton::draw()
{
    if (!m_isHovered)
    {
        setColor(240, 240, 240);
    }
    else
    {
        setColor(255, 255, 255);
    }
    WidgetPane::draw();
    Vector2F textSize = FontRenderer::getTextSize(m_font, m_text);
    FontRenderer::renderText(m_font, m_text, Vector2I(getPosition().x() + getSize().x() / 2 - textSize.x() / 2, getPosition().y() + getSize().y() / 2 + textSize.y() / 2));
}

void WidgetButton::init()
{
    WidgetPane::init();
}

void WidgetButton::update(double delta)
{
    LauncherWidget::update(delta);
}

void WidgetButton::mouseMoved(Vector2D newPos)
{
    LauncherWidget::mouseMoved(newPos);

    if (newPos.x() >= getPosition().x() &&
        newPos.x() <= getPosition().x() + getSize().x() &&
        newPos.y() >= getPosition().y() &&
        newPos.y() <= getPosition().y() + getSize().y())
    {
        m_isHovered = true;
    }
    else
    {
        m_isHovered = false;
    }
}

void WidgetButton::mouseClicked(Vector2D clickPos, int button, bool press)
{
    LauncherWidget::mouseClicked(clickPos, button, press);
}
