#ifndef FONTRENDERER_H
#define FONTRENDERER_H

#include <vector>
#include <string>
#include <memory>
#include <algorithm>

#include <ft2build.h>
#include FT_FREETYPE_H

#include "ogl.h"
#include "vector2.h"
#include "vector3.h"

enum class FontListEntry
{
    BABAS_NEUE_12,
    BABAS_NEUE_16,
    BABAS_NEUE_24,
    BABAS_NEUE_32,
    BABAS_NEUE_64,
    MARCELLUS_12,
    MARCELLUS_16,
    MARCELLUS_24,
    MARCELLUS_32,
    MARCELLUS_64
};

struct FontChar
{
    FontChar(Vector2I cSize, Vector2F tCoords, Vector2F cTrans, float advance)
        : m_charSize(cSize),
        m_texCoords(tCoords),
        m_trans(cTrans),
        m_advance(advance) {}
    void draw();
    void genTexture();
    void bindTexture();
    Vector2F getTranslation() const { return m_trans; }
    Vector2F getSize();
private:
    Vector2I m_charSize;
    Vector2F m_texCoords;
    Vector2F m_trans;
    float m_advance;
    GLuint m_texture;
};

class FontType
{
public:
    int create(FontListEntry font, const FT_Library& library);
    std::shared_ptr<FontChar> getFontChar(size_t index) { return m_fontChars[index]; }
    int getFontSize() const { return m_fontSize; }
    bool isGlyphMissing(char c) { return std::find(m_missingGlyphs.begin(), m_missingGlyphs.end(), c) != m_missingGlyphs.end(); }
private:
    int m_fontSize;
    std::vector<char> m_missingGlyphs;
    std::vector<std::shared_ptr<FontChar>> m_fontChars;
};

class FontRenderer
{
    public:
        static int init(std::vector<FontListEntry> font);
        static void renderText(FontListEntry font, const std::string& text, Vector2I position, Vector3I color = Vector3I(255, 255, 255));
        static Vector2F getTextSize(FontListEntry font, const std::string& text);
    protected:
    private:
        static FT_Library m_library;
        static std::vector<std::shared_ptr<FontType>> m_fontTypes;
};

#endif // FONTRENDERER_H
