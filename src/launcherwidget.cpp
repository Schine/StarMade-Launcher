#include "launcherwidget.h"
#include <assert.h>

LauncherWidget::LauncherWidget(LauncherWidget* parent)
    : m_position(0, 0),
    m_size(0, 0)
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

void LauncherWidget::addChild(LauncherWidget *child)
{
    // Make sure child elements are inside the parent ones
    assert(child->getPosition().x() >= getPosition().x() &&
           child->getPosition().x() + child->getSize().x() <= getPosition().x() + getSize().x() &&
           child->getPosition().y() >= getPosition().y() &&
           child->getPosition().y() + child->getSize().y() <= getPosition().y() + getSize().y());
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
