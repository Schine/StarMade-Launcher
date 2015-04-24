#ifndef MESSAGEBOX_H
#define MESSAGEBOX_H

#include <string>
#include <vector>
#include <initializer_list>
#include <iostream>
#include <glfw/glfw3.h>
#include "vector2.h"
#include "ibuttoncallback.h"
#include "mainwindow.h"

struct MessageBoxButton
{
    MessageBoxButton(int pIndex, const std::string& pText)
        : index(pIndex),
        text(pText),
        hovered(false) {}
    int index;
    std::string text;
    bool hovered;
};

struct MessageBoxWidget
{
    MessageBoxWidget(int pIndex, const Vector2I& pSize, const Vector2I& pPositionInBox, bool pCentered)
        : index(pIndex),
        size(pSize),
        positionInBox(pPositionInBox),
        centered(pCentered) {}
    virtual void mouseClicked(Vector2D clickPos, int button, bool press) {};
    virtual void mouseMoved(Vector2D newPos, Vector2D deltaPos) {};
    virtual void keyPressed(int key, int action, int mods) {};
    virtual void charTyped(unsigned int codePoint, int mods) {};
    virtual void update(double deltaTime) {};
    int index;
    Vector2I size;
    Vector2I positionInBox;
    bool centered;
};

struct MessageBoxTextWidget : public MessageBoxWidget
{
    MessageBoxTextWidget(int pIndex, const Vector2I& pSize, const Vector2I& pPositionInBox, bool pCentered)
        : MessageBoxWidget(pIndex, pSize, pPositionInBox, pCentered),
        text(""),
        focused(false),
        showSelector(false)
    {

    }
    virtual void mouseClicked(Vector2D clickPos, int mouseButton, bool press) override;
    virtual void mouseMoved(Vector2D newPos, Vector2D deltaPos) override;
    virtual void keyPressed(int key, int action, int mods) override;
    virtual void charTyped(unsigned int codePoint, int mods) override;
    virtual void update(double deltaTime);
    std::string text;
    bool focused;
    bool showSelector;
};

class LauncherMessageBox
{
    public:
        LauncherMessageBox(const std::string& title,
                           const std::string& message,
                           const Vector2I& size,
                           std::initializer_list<MessageBoxButton*> messageBoxes,
                           std::initializer_list<MessageBoxTextWidget*> textBoxes,
                           double timeOpened,
                           IButtonCallback* callback);
        virtual ~LauncherMessageBox();
        void render();
        void mouseClicked(Vector2D clickPos, int button, bool press);
        void mouseMoved(Vector2D newPos, Vector2D deltaPos);
        void keyPressed(int key, int action, int mods);
        void charTyped(unsigned int codePoint, int mods);
        double getTimeOpened() const { return m_timeOpened; }
        void update(double deltaTime);
    protected:
    private:
        std::string m_title;
        std::string m_message;
        Vector2I m_size;
        std::vector<MessageBoxButton*> m_buttons;
        std::vector<MessageBoxTextWidget*> m_textBoxes;
        IButtonCallback* m_callback;
        double m_timeOpened;
};

#endif // MESSAGEBOX_H
