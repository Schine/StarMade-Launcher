#ifndef WIDGETPANE_H
#define WIDGETPANE_H

#include "launcherwidget.h"
#include "gltexture.h"
#include <string>
#include "vector3.h"

class WidgetPane : public LauncherWidget
{
public:
    explicit WidgetPane(LauncherWidget* parent = nullptr);
    virtual ~WidgetPane();
    virtual void draw() override;
    virtual void init() override;
    void setColor(float r, float g, float b);
    void setTexture(const std::string& fileName);
    void setTextureNull();
private:
    Vector3F m_color;
    std::shared_ptr<GLTexture> m_texture;
    bool m_hasTexture;
};

#endif // WIDGETPANE_H
