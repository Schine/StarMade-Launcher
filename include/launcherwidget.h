#ifndef LAUNCHERWIDGET_H
#define LAUNCHERWIDGET_H

#include <memory>
#include "vector2.h"
#include <vector>

class LauncherWidget
{
public:
    explicit LauncherWidget(LauncherWidget* parent = nullptr);
    virtual ~LauncherWidget();
    bool isHidden() const { return m_hidden; }
    void setHidden(bool hidden) { m_hidden = hidden; }
    void deleteChildren();
    void drawChildren();
    void initChildren();
    void addChild(LauncherWidget* child);
    void setDirty(bool dirty) { m_dirty = dirty; }
    bool isDirty() const { return m_dirty; }
    bool isDirtyRecursive() const;
    virtual void draw() = 0;
    virtual void init() = 0;
    virtual void update(double delta);
    Vector2I getPosition() const { return m_position; }
    Vector2I getSize() const { return m_size; }
    void setPosition(Vector2I position) { m_position = position; }
    void setSize(Vector2I size) { m_size = size; }
    virtual void mouseMoved(Vector2D newPos, Vector2D deltaPos);
    virtual void mouseClicked(Vector2D clickPos, int button, bool press, bool inBackground);
    virtual void keyTyped(char keyTyped, bool repeat);
    virtual void mouseWheelScrolled(double xOffset, double yOffset);
private:
    bool m_hidden;
    Vector2I m_position;
    Vector2I m_size;
    std::vector<LauncherWidget*> m_children;
    bool m_dirty; // Should be re-rendered
    bool m_firstUpdate;
};

#endif // LAUNCHERWIDGET_H
