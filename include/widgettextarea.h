#ifndef WIDGETTEXTAREA_H
#define WIDGETTEXTAREA_H

#include <vector>
#include <string>
#include "widgetpane.h"
#include "fontrenderer.h"

class WidgetTextArea : public WidgetPane
{
    public:
        WidgetTextArea(std::string* text, int tempTextLength, LauncherWidget* parent = nullptr);
        virtual ~WidgetTextArea();
        virtual void draw() override;
        virtual void init() override;
        virtual void update(double delta) override;
        virtual void mouseMoved(Vector2D newPos) override;
        virtual void mouseClicked(Vector2D clickPos, int button, bool press) override;
        virtual void mouseWheelScrolled(double xOffset, double yOffset) override;
    protected:
    private:
        int m_tempTextLength;
        std::string* m_tempText;
        std::vector<std::string> m_clippedText;
        FontListEntry m_font;
        Vector2F m_padding;
        float m_scroll;
};

#endif // WIDGETTEXTAREA_H
