#ifndef WIDGETBUTTON_H
#define WIDGETBUTTON_H

#include <string>
#include "widgetpane.h"
#include "fontrenderer.h"

class WidgetButton;

class IButtonCallback
{
public:
    void buttonClicked(WidgetButton* button);
private:
};

class WidgetButton : public WidgetPane
{
    public:
        WidgetButton(const std::string& text, FontListEntry font = FontListEntry::BABAS_NEUE_16, IButtonCallback* callback = nullptr, LauncherWidget* parent = nullptr);
        virtual ~WidgetButton();
        virtual void draw() override;
        virtual void init() override;
        virtual void update(double delta) override;
        virtual void mouseMoved(Vector2D newPos) override;
        virtual void mouseClicked(Vector2D clickPos, int button, bool press) override;
    protected:
    private:
        IButtonCallback* m_callback;
        bool m_isHovered;
        std::string m_text;
        FontListEntry m_font;
};

#endif // WIDGETBUTTON_H
