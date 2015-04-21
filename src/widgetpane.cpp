#include "widgetpane.h"
#include <iostream>
#include "ogl.h"
#include <string>

WidgetPane::WidgetPane(LauncherWidget* parent)
    : LauncherWidget(parent),
      m_color(255, 255, 255),
      m_hasTexture(false),
      m_drawOffset{ Vector2F(0.0F, 0.0F), Vector2F(0.0F, 0.0F) },
      m_texCoords{ Vector2F(0.0F, 0.0F), Vector2F(1.0F, 1.0F)},
      m_border({ 0, Vector3I(0, 0, 0) })
{

}

WidgetPane::~WidgetPane()
{

}

void WidgetPane::draw()
{
    if (m_hasTexture)
    {
        glPushAttrib(GL_ALL_ATTRIB_BITS);
        glEnable(GL_TEXTURE_2D);

        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        glEnable(GL_BLEND);
        glAlphaFunc(GL_GREATER, 0.0);
        glEnable(GL_ALPHA_TEST);
        m_texture->bind();
    }
    else
    {
        glDisable(GL_TEXTURE_2D);
    }

    glBegin(GL_QUADS);
    glColor3f(m_color.x() / 255.0F, m_color.y() / 255.0F, m_color.z() / 255.0F);

    float posX0 = getPosition().x() +                   m_drawOffset.m_position.x();
    float posX1 = getPosition().x() + getSize().x() +   m_drawOffset.m_position.x() + m_drawOffset.m_size.x();
    float posY0 = getPosition().y() +                   m_drawOffset.m_position.y();
    float posY1 = getPosition().y() + getSize().y() +   m_drawOffset.m_position.y() + m_drawOffset.m_size.y();

    float texX0 = m_texCoords.m_position.x();
    float texX1 = m_texCoords.m_position.x() + m_texCoords.m_size.x();
    float texY0 = 1.0F - m_texCoords.m_position.y();
    float texY1 = 1.0F - m_texCoords.m_position.y() - m_texCoords.m_size.y();

    if (m_hasTexture) glTexCoord2f(texX0, texY0);

    glVertex2f(posX0, posY0);

    if (m_hasTexture) glTexCoord2f(texX1, texY0);

    glVertex2f(posX1, posY0);

    if (m_hasTexture) glTexCoord2f(texX1, texY1);

    glVertex2f(posX1, posY1);

    if (m_hasTexture) glTexCoord2f(texX0, texY1);

    glVertex2f(posX0, posY1);
    glEnd();

    if (m_border.borderWidth > 0)
    {
        glColor3f(m_border.color.x() / 255.0F, m_border.color.y() / 255.0F, m_border.color.z() / 255.0F);

        if (m_border.mode == BorderMode::ALL ||
            m_border.mode == BorderMode::LEFT ||
            m_border.mode == BorderMode::LEFT_RIGHT)
        {
            glBegin(GL_QUADS);
            glVertex2f(getPosition().x(), getPosition().y());
            glVertex2f(getPosition().x() + m_border.borderWidth, getPosition().y());
            glVertex2f(getPosition().x() + m_border.borderWidth, getPosition().y() + getSize().y());
            glVertex2f(getPosition().x(), getPosition().y() + getSize().y());
            glEnd();
        }

        if (m_border.mode == BorderMode::ALL ||
            m_border.mode == BorderMode::RIGHT ||
            m_border.mode == BorderMode::LEFT_RIGHT)
        {
            glBegin(GL_QUADS);
            glVertex2f(getPosition().x() + getSize().x() - m_border.borderWidth, getPosition().y());
            glVertex2f(getPosition().x() + getSize().x(), getPosition().y());
            glVertex2f(getPosition().x() + getSize().x(), getPosition().y() + getSize().y());
            glVertex2f(getPosition().x() + getSize().x() - m_border.borderWidth, getPosition().y() + getSize().y());
            glEnd();
        }

        if (m_border.mode == BorderMode::ALL ||
            m_border.mode == BorderMode::TOP ||
            m_border.mode == BorderMode::TOP_BOTTOM)
        {
            glBegin(GL_QUADS);
            glVertex2f(getPosition().x(), getPosition().y());
            glVertex2f(getPosition().x() + getSize().x(), getPosition().y());
            glVertex2f(getPosition().x() + getSize().x(), getPosition().y() + m_border.borderWidth);
            glVertex2f(getPosition().x(), getPosition().y() + m_border.borderWidth);
            glEnd();
        }

        if (m_border.mode == BorderMode::ALL ||
            m_border.mode == BorderMode::BOTTOM ||
            m_border.mode == BorderMode::TOP_BOTTOM)
        {
            glBegin(GL_QUADS);
            glVertex2f(getPosition().x(), getPosition().y() + getSize().y() - m_border.borderWidth);
            glVertex2f(getPosition().x() + getSize().x(), getPosition().y() + getSize().y() - m_border.borderWidth);
            glVertex2f(getPosition().x() + getSize().x(), getPosition().y() + getSize().y());
            glVertex2f(getPosition().x(), getPosition().y() + getSize().y());
            glEnd();
        }
    }

    if (m_hasTexture)
    {
        m_texture->unbind();
        glPopAttrib();
    }

    drawChildren();
    setDirty(false);
}

void WidgetPane::init()
{
    initChildren();
}

void WidgetPane::setColor(float r, float g, float b)
{
    m_color.setXYZ(r, g, b);
}

void WidgetPane::setTexture(const std::string& fileName)
{
    m_texture = std::shared_ptr<GLTexture>(GLTexture::fromFile(fileName));
    m_hasTexture = true;
}

void WidgetPane::setTextureNull()
{
    m_hasTexture = false;
}

