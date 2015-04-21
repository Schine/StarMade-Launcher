#ifndef WIDGETTEXTAREA_H
#define WIDGETTEXTAREA_H

#include <vector>
#include <string>
#include "widgetpane.h"
#include "fontrenderer.h"

struct TextAreaLink
{
    int lineIndex;
    size_t startLinkIndex;
    size_t endLinkIndex;
    std::string link;
};

struct OnScreenLink
{
    Vector2F position;
    Vector2F size;
    std::string link;
};

struct TextLine
{
    std::string text;
    FontListEntry font;
    Vector3I color;
};

class WidgetTextArea : public WidgetPane
{
    public:
        WidgetTextArea(LauncherWidget* parent = nullptr);
        virtual ~WidgetTextArea();
        void initWithText(std::string* text, int tempTextLength);
        void initWithText(std::vector<std::string> textVector);
        virtual void draw() override;
        virtual void init() override;
        virtual void update(double delta) override;
        virtual void mouseMoved(Vector2D newPos, Vector2D deltaPos) override;
        virtual void mouseClicked(Vector2D clickPos, int button, bool press) override;
        virtual void mouseWheelScrolled(double xOffset, double yOffset) override;
        float getScrollPercentage() { return std::min(std::max(0.0F, (m_scroll + m_padding.y()) / m_maxScroll), 1.0F); }
        void setScrollBar(int offsetX, int sizeX, Vector3I barColor, Vector3I sliderColor);
    protected:
    private:
        void initWithTextCommon(std::string line, std::string& linePart);
        void addText(const std::string& text, FontListEntry font, Vector3I color);
        std::vector<TextLine> m_text;
        std::vector<TextAreaLink> m_textAreaLinks;
        std::vector<OnScreenLink> m_onScreenLinks;
        Vector2F m_padding;
        float m_scroll;
        float m_maxScroll;
        int m_scrollBarOffsetX;
        int m_scrollBarSizeX;
        Vector3I m_scrollBarColor;
        Vector3I m_scrollBarSliderColor;
        bool m_scrollBarGrabbed;
};

#endif // WIDGETTEXTAREA_H
