#ifndef WIDGETTEXTAREA_H
#define WIDGETTEXTAREA_H

#include <vector>
#include <string>
#include "widgetpane.h"
#include "fontrenderer.h"

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
        virtual void mouseMoved(Vector2D newPos) override;
        virtual void mouseClicked(Vector2D clickPos, int button, bool press) override;
        virtual void mouseWheelScrolled(double xOffset, double yOffset) override;
        float getScrollPercentage() { return std::min(std::max(0.0F, (m_scroll + m_padding.y()) / m_maxScroll), 1.0F); }
    protected:
    private:
        void initWithTextCommon(std::string line, std::string& linePart);
        void addText(const std::string& text, FontListEntry font);
        std::vector<std::string> m_clippedText;
        std::vector<FontListEntry> m_fonts;
        Vector2F m_padding;
        float m_scroll;
        float m_maxScroll;
};

#endif // WIDGETTEXTAREA_H
