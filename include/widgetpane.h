#ifndef WIDGETPANE_H
#define WIDGETPANE_H

#include "launcherwidget.h"
#include "gltexture.h"
#include <string>
#include "vector3.h"

enum class BorderMode
{
    ALL,
    TOP,
    BOTTOM,
    LEFT,
    RIGHT,
    TOP_BOTTOM,
    LEFT_RIGHT
};

struct Border
{
    float borderWidth;
    Vector3I color;
    BorderMode mode;
};

struct DrawOffset
{
    Vector2F m_position;
    Vector2F m_size;
};

struct TextureCoordinates
{
    Vector2F m_position;
    Vector2F m_size;
};

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
    void setBorder(const Border& border) { m_border = border; }
    void setTextureCoordinates(const TextureCoordinates& texCoords) { m_texCoords = texCoords; }
    void setDrawOffset(const DrawOffset& drawOffset) { m_drawOffset = drawOffset; }
private:
    Vector3F m_color;
    std::shared_ptr<GLTexture> m_texture;
    bool m_hasTexture;
    DrawOffset m_drawOffset;
    TextureCoordinates m_texCoords;
    Border m_border;
};

#endif // WIDGETPANE_H
