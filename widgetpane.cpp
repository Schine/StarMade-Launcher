#include "widgetpane.h"
#include <QtGui/qopengl.h>
#include <iostream>

WidgetPane::WidgetPane(LauncherWidget* parent)
    : LauncherWidget(parent),
      m_color(255, 255, 255),
      m_hasTexture(false)
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
    glColor3f(m_color.red() / 255.0F, m_color.green() / 255.0F, m_color.blue() / 255.0F);
    if (m_hasTexture) glTexCoord2f(0.0F, 1.0F);
    glVertex3f(this->getPosition().x(),                         this->getPosition().y(), 0.0);
    if (m_hasTexture) glTexCoord2f(1.0F, 1.0F);
    glVertex3f(this->getPosition().x() + this->getSize().x(),   this->getPosition().y(), 0.0);
    if (m_hasTexture) glTexCoord2f(1.0F, 0.0F);
    glVertex3f(this->getPosition().x() + this->getSize().x(),   this->getPosition().y() + this->getSize().y(), 0.0);
    if (m_hasTexture) glTexCoord2f(0.0F, 0.0F);
    glVertex3f(this->getPosition().x(),                         this->getPosition().y() + this->getSize().y(), 0.0);
    glEnd();

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

}

void WidgetPane::setColor(float r, float g, float b)
{
    m_color.setRgb(r, g, b);
}

void WidgetPane::setTexture(QString fileName)
{
    m_texture = std::shared_ptr<GLTexture>(GLTexture::fromFile(fileName));
    m_hasTexture = true;
}

void WidgetPane::setTextureNull()
{
    m_hasTexture = false;
}

