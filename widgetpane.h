#ifndef WIDGETPANE_H
#define WIDGETPANE_H

#include "launcherwidget.h"
#include <QColor>
#include "gltexture.h"

class WidgetPane : public LauncherWidget
{
public:
    explicit WidgetPane(LauncherWidget* parent = nullptr);
    virtual ~WidgetPane();
    virtual void draw() override;
    virtual void init() override;
    void setColor(float r, float g, float b);
    void setTexture(QString fileName);
    void setTextureNull();
private:
    QColor m_color;
    std::shared_ptr<GLTexture> m_texture;
    bool m_hasTexture;
};

#endif // WIDGETPANE_H
