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

struct MessageBoxWidget
{
    MessageBoxWidget(int pIndex,
                     const Vector2I&
                     pSize, const Vector2I&
                     pPositionInBox,
                     bool pCentered)
        : index(pIndex),
        size(pSize),
        positionInBox(pPositionInBox),
        centered(pCentered) {}
    virtual ~MessageBoxWidget() {};
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

struct MessageBoxButton : public MessageBoxWidget
{
    MessageBoxButton(int pIndex,
                     const Vector2I& pSize,
                     const Vector2I& pPositionInBox,
                     bool pCentered,
                     const std::string& pText,
                     int pNumInlineButtons,
                     int pIndexInLine,
                     int pPadding)
        : MessageBoxWidget(pIndex, pSize, pPositionInBox, pCentered),
        text(pText),
        hovered(false),
        numInlineButtons(pNumInlineButtons),
        indexInLine(pIndexInLine),
        padding(pPadding) {}
    virtual ~MessageBoxButton() {};
    std::string text;
    bool hovered;
    int numInlineButtons;
    int indexInLine;
    int padding;
};

struct MessageBoxTextWidget : public MessageBoxWidget
{
    MessageBoxTextWidget(int pIndex,
                         const Vector2I& pSize,
                         const Vector2I& pPositionInBox,
                         bool pCentered,
                         bool pHideCharacters)
        : MessageBoxWidget(pIndex, pSize, pPositionInBox, pCentered),
        text(""),
        focused(false),
        showSelector(false),
        hideCharacters(pHideCharacters) { }
    virtual ~MessageBoxTextWidget() {};
    virtual void mouseClicked(Vector2D clickPos, int mouseButton, bool press) override;
    virtual void mouseMoved(Vector2D newPos, Vector2D deltaPos) override;
    virtual void keyPressed(int key, int action, int mods) override;
    virtual void charTyped(unsigned int codePoint, int mods) override;
    virtual void update(double deltaTime);
    void setText(const std::string& newText) { text = newText; }
    std::string text;
    bool focused;
    bool showSelector;
    bool hideCharacters;
};

struct MessageBoxLabelWidget : public MessageBoxWidget
{
    MessageBoxLabelWidget(int pIndex,
                     const Vector2I& pSize,
                     const Vector2I& pPositionInBox,
                     bool pCentered,
                     const std::string& pText)
        : MessageBoxWidget(pIndex, pSize, pPositionInBox, pCentered),
        text(pText) {}
    virtual ~MessageBoxLabelWidget() {};
    std::string text;
};

class LauncherMessageBox
{
    public:
        LauncherMessageBox(const Vector2I& size,
                           std::initializer_list<MessageBoxButton*> messageBoxes,
                           std::initializer_list<MessageBoxTextWidget*> textBoxes,
                           std::initializer_list<MessageBoxLabelWidget*> labels,
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
        MessageBoxButton* getButtonByID(int id);
        MessageBoxTextWidget* getTextBoxByID(int id);
        MessageBoxLabelWidget* getLabelByID(int id);
    protected:
    private:
        Vector2I m_size;
        std::vector<MessageBoxButton*> m_buttons;
        std::vector<MessageBoxTextWidget*> m_textBoxes;
        std::vector<MessageBoxLabelWidget*> m_labels;
        IButtonCallback* m_callback;
        double m_timeOpened;
};

#endif // MESSAGEBOX_H
