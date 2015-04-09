#ifndef LAUNCHERWIDGET_H
#define LAUNCHERWIDGET_H

#include <memory>
#include <QPoint>

class LauncherWidget
{
public:
    explicit LauncherWidget(LauncherWidget* parent = nullptr);
    virtual ~LauncherWidget();
    bool isHidden() const { return m_hidden; }
    void setHidden(bool hidden) { m_hidden = hidden; }
    void deleteChildren();
    void drawChildren();
    void addChild(LauncherWidget* child);
    void setDirty(bool dirty) { m_dirty = dirty; }
    bool isDirty() const { return m_dirty; }
    bool isDirtyRecursive() const;
    virtual void draw() = 0;
    virtual void init() = 0;
    QPoint getPosition() const { return m_position; }
    QPoint getSize() const { return m_size; }
    void setPosition(QPoint position) { m_position = position; }
    void setSize(QPoint size) { m_size = size; }
private:
    bool m_hidden;
    QPoint m_position;
    QPoint m_size;
    std::vector<LauncherWidget*> m_children;
    bool m_dirty; // Should be re-rendered
};

#endif // LAUNCHERWIDGET_H
