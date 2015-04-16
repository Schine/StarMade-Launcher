#include "launcherwidget.h"
#include <assert.h>
#include <iostream>

LauncherWidget::LauncherWidget(LauncherWidget* parent)
    : m_position(0, 0),
    m_size(0, 0),
    m_firstUpdate(true)
{
    if (parent != nullptr)
    {
        parent->addChild(this);
    }
}

LauncherWidget::~LauncherWidget()
{
    if (!m_children.empty())
    {
        deleteChildren();
    }
}

void LauncherWidget::deleteChildren()
{
    for (size_t i = 0; i < m_children.size(); ++i)
    {
        delete m_children[i];
    }

    m_children.clear();
}

void LauncherWidget::drawChildren()
{
    for (size_t i = 0; i < m_children.size(); ++i)
    {
        m_children[i]->draw();
    }
}

void LauncherWidget::initChildren()
{
    for (size_t i = 0; i < m_children.size(); ++i)
    {
        m_children[i]->init();
    }
}

void LauncherWidget::addChild(LauncherWidget *child)
{
    // Make sure child elements are inside the parent ones
    m_children.push_back(child);
}

bool LauncherWidget::isDirtyRecursive() const
{
    if (isDirty())
    {
        return true;
    }

    for (size_t i = 0; i < m_children.size(); ++i)
    {
        if (m_children[i]->isDirty())
        {
            return true;
        }
    }

    return false;
}

void LauncherWidget::update(double delta)
{
    for (size_t i = 0; i < m_children.size(); ++i)
    {
        LauncherWidget* child = m_children[i];
        if (m_firstUpdate)
        {
            child->init();
            assert(child->getPosition().x() >= getPosition().x());
            assert(child->getPosition().x() + child->getSize().x() <= getPosition().x() + getSize().x());
            assert(child->getPosition().y() >= getPosition().y());
            assert(child->getPosition().y() + child->getSize().y() <= getPosition().y() + getSize().y());
        }
        child->update(delta);
    }
    m_firstUpdate = false;
}

void LauncherWidget::mouseMoved(Vector2D newPos)
{
    for (size_t i = 0; i < m_children.size(); ++i)
    {
        m_children[i]->mouseMoved(newPos);
    }
}

void LauncherWidget::mouseWheelScrolled(double xOffset, double yOffset)
{
    for (size_t i = 0; i < m_children.size(); ++i)
    {
        m_children[i]->mouseWheelScrolled(xOffset, yOffset);
    }
}

void LauncherWidget::mouseClicked(Vector2D clickPos, int button, bool press)
{
    for (size_t i = 0; i < m_children.size(); ++i)
    {
        m_children[i]->mouseClicked(clickPos, button, press);
    }
}

void LauncherWidget::keyTyped(char keyTyped, bool repeat)
{
    for (size_t i = 0; i < m_children.size(); ++i)
    {
        m_children[i]->keyTyped(keyTyped, repeat);
    }
}
