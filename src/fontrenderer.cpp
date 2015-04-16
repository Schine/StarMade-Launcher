#include "fontrenderer.h"
#include <iostream>
#include FT_GLYPH_H

FT_Library FontRenderer::m_library;
std::vector<std::shared_ptr<FontType>> FontRenderer::m_fontTypes;

int FontRenderer::init(std::vector<FontListEntry> fonts)
{
    int error = FT_Init_FreeType(&m_library);
    if (error != FT_Err_Ok)
    {
        std::cerr << "An error occurred during freetype2 initialization" << std::endl;
        return error;
    }

    for (size_t i = 0; i < fonts.size(); ++i)
    {
        std::shared_ptr<FontType> type = std::shared_ptr<FontType>(new FontType());
        error = type->create(fonts[i], m_library);
        if (error != FT_Err_Ok)
        {
            return error;
        }
        m_fontTypes.push_back(type);
    }

    FT_Done_FreeType(m_library);

    return 0;
}

void FontRenderer::renderText(FontListEntry font, const std::string& text, Vector2I position)
{
    glPushAttrib(GL_ALL_ATTRIB_BITS);
    glEnable(GL_TEXTURE_2D);

    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_BLEND);
    glAlphaFunc(GL_GREATER, 0.0);
    glEnable(GL_ALPHA_TEST);

    glPushMatrix();
    glTranslatef((float)position.x(), (float)position.y(), 0.0F);
    for (size_t cPos = 0; cPos < text.size(); ++cPos)
    {
        char charAt = text[cPos];
        std::shared_ptr<FontChar> fontC = m_fontTypes[static_cast<int>(font)]->getFontChar((int)charAt);
        fontC->draw();
    }
    glPopMatrix();

    glBindTexture(GL_TEXTURE_2D, 0);
    glPopAttrib();
}

Vector2F FontRenderer::getTextSize(FontListEntry font, const std::string& text)
{
    Vector2F textSize(0, 0);
    std::shared_ptr<FontType> fontType = m_fontTypes[static_cast<int>(font)];
    for (size_t cPos = 0; cPos < text.size(); ++cPos)
    {
        char charAt = text[cPos];
        if ((int)charAt > 0)
        {
            std::shared_ptr<FontChar> fontC = fontType->getFontChar((int)charAt);
            if (fontC != nullptr)
            {
                textSize.setXY(textSize.x() + fontC->getSize().x(), std::max(fontC->getSize().y(), textSize.y()));
            }
        }
    }
    return Vector2F(textSize.x(), fontType->getFontSize());
}

int FontType::create(FontListEntry font, const FT_Library& library)
{
    std::string fileName = "";
    m_fontSize = 0;

    switch (font)
    {
    case FontListEntry::BABAS_NEUE_12:
    case FontListEntry::BABAS_NEUE_16:
    case FontListEntry::BABAS_NEUE_24:
    case FontListEntry::BABAS_NEUE_32:
    case FontListEntry::BABAS_NEUE_64:
        fileName = "data/fonts/BebasNeue.otf";
        break;
    case FontListEntry::GEO_SANS_LIGHT_12:
    case FontListEntry::GEO_SANS_LIGHT_16:
    case FontListEntry::GEO_SANS_LIGHT_24:
    case FontListEntry::GEO_SANS_LIGHT_32:
    case FontListEntry::GEO_SANS_LIGHT_64:
        fileName = "data/fonts/GeosansLight.ttf";
        break;
    default:
        std::cerr << "Unknown font entry" << std::endl;
    }

    switch (font)
    {
    case FontListEntry::GEO_SANS_LIGHT_12:
    case FontListEntry::BABAS_NEUE_12:
        m_fontSize = 12;
        break;
    case FontListEntry::GEO_SANS_LIGHT_16:
    case FontListEntry::BABAS_NEUE_16:
        m_fontSize = 16;
        break;
    case FontListEntry::GEO_SANS_LIGHT_24:
    case FontListEntry::BABAS_NEUE_24:
        m_fontSize = 23;
        break;
    case FontListEntry::GEO_SANS_LIGHT_32:
    case FontListEntry::BABAS_NEUE_32:
        m_fontSize = 32;
        break;
    case FontListEntry::GEO_SANS_LIGHT_64:
    case FontListEntry::BABAS_NEUE_64:
        m_fontSize = 64;
        break;
    }

    // Font face describes a given typeface and style
    FT_Face face;
    int error = FT_New_Face(library, fileName.c_str(), 0, &face);

    if (error == FT_Err_Unknown_File_Format)
    {
        std::cerr << "Unknown file format: " << fileName << std::endl;
        return error;
    }
    else if (error != FT_Err_Ok)
    {
        std::cerr << "Error opening font: " << fileName << std::endl;
        return error;
    }

    FT_Set_Char_Size(face, m_fontSize << 6, m_fontSize << 6, 96, 96);

    for (size_t i = 0; i < 128; ++i)
    {
        error = FT_Load_Glyph(face, FT_Get_Char_Index(face, i), FT_LOAD_DEFAULT);

        if (error != FT_Err_Ok)
        {
            std::cerr << "Error loading freetype glyph" << std::endl;
            break;
        }

        FT_Glyph glyph;
        error = FT_Get_Glyph(face->glyph, &glyph);

        if (error != FT_Err_Ok)
        {
            std::cerr << "Error getting freetype glyph" << std::endl;
            break;
        }

        // Glyph to bitmap
        FT_Glyph_To_Bitmap(&glyph, ft_render_mode_normal, 0, 1);
        FT_BitmapGlyph bitmapGlyph = (FT_BitmapGlyph)glyph;

        FT_Bitmap& bitmap = bitmapGlyph->bitmap;

        size_t bmSize = 1;
        while (bmSize < bitmap.width || bmSize < bitmap.rows)
        {
            bmSize <<= 1;
        }

        int bitDepth = 2;
        size_t width = bmSize;
        size_t height = bmSize;

        GLubyte* expandedData = new GLubyte[bitDepth * width * height];

        GLubyte byte = 0;
        for (size_t j = 0; j < height; ++j)
        {
            for (size_t k = 0; k < width; ++k)
            {
                byte = (k >= bitmap.width || j >= bitmap.rows) ? 0 : bitmap.buffer[k + j * bitmap.width];
                for (int b = 0; b < bitDepth; ++b)
                {
                    expandedData[bitDepth * (k + j * width) + b] = byte;
                }
            }
        }

        std::shared_ptr<FontChar> fChar = std::shared_ptr<FontChar>(new FontChar(
                            Vector2I(bitmap.width, bitmap.rows),
                            Vector2F((float)bitmap.width / (float)width, (float)bitmap.rows / (float)height),
                            Vector2F(bitmapGlyph->left, bitmapGlyph->top-bitmap.rows),
                            face->glyph->advance.x >> 6));

        fChar->genTexture();
        fChar->bindTexture();

        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);

        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_LUMINANCE_ALPHA, GL_UNSIGNED_BYTE, expandedData);
        m_fontChars.push_back(fChar);

        delete[] expandedData;
    }

    FT_Done_Face(face);

    return error;
}

void FontChar::draw()
{
    glPushMatrix();

    glScalef(1.0F, -1.0F, 1.0F);
    glTranslatef(m_trans.x(), 0.0F, 0.0F);

    glColor3f(1.0F, 1.0F, 1.0F);
    glEnable(GL_TEXTURE_2D);
    glBindTexture(GL_TEXTURE_2D, m_texture);

    glBegin(GL_QUADS);
    glTexCoord2d(0,                 m_texCoords.y());   glVertex2f(0.0F,            0.0F);
    glTexCoord2d(0,                 0.0F);              glVertex2f(0.0F,            m_charSize.y());
    glTexCoord2d(m_texCoords.x(),   0.0F);              glVertex2f(m_charSize.x(),  m_charSize.y());
    glTexCoord2d(m_texCoords.x(),   m_texCoords.y());   glVertex2f(m_charSize.x(),  0.0F);
    glEnd();

    glPopMatrix();

    glTranslatef(m_advance, 0.0F, 0.0F);
}

void FontChar::genTexture()
{
    glGenTextures(1, &m_texture);
}

void FontChar::bindTexture()
{
    glBindTexture(GL_TEXTURE_2D, m_texture);
}

Vector2F FontChar::getSize()
{
    return Vector2F(m_advance, m_charSize.y());
}
