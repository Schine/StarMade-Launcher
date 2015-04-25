#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <memory>
#include <vector>
#include <string>
#include "ibuttoncallback.h"
#include "itextboxcallback.h"
#include "vector2.h"

class LauncherWidget;
class LauncherMessageBox;
class OAuthController;
class WidgetButton;

class MainWindow : public IButtonCallback, ITextBoxCallback
{
public:
    static const int CLOSE_BUTTON_SIZE = 20;
    static const int CLOSE_BUTTON_OFFSET = 20;
    static const int MINIMIZE_BUTTON_SIZE = 20;
    static const int MINIMIZE_BUTTON_OFFSET_X = 50;
    static const int MINIMIZE_BUTTON_OFFSET_Y = 27;
    static const int BAR_BORDER = 4;
    static const int BOTTOM_BAR_HEIGHT = 175;
    static const int LAUNCH_BUTTON_WIDTH = 200;
    static const int LAUNCH_BUTTON_HEIGHT = 90;
    static const int LAUNCH_BUTTON_BORDER_SIZE = 5;

    static void newInstance(int borderSize);
    static std::shared_ptr<MainWindow> getInstance();

    explicit MainWindow(int borderSize);
    ~MainWindow();

    void init();
    void update(double deltaTime);
    void render();
    void resize(int w, int h);
    int width() { return m_size.x(); }
    int height() { return m_size.y(); }
    void mouseClicked(int button, bool press);
    void mouseMoved(double xPos, double yPos);
    void mouseWheelScrolled(double xOffset, double yOffset);
    void keyPressed(int key, int action, int mods);
    void charTyped(unsigned int codePoint, int mods);
    bool isCloseRequested() const { return m_closeRequested; }
    bool isMinimizeRequested() const { return m_minimizeRequested; }
    void setMinimizeRequested(bool request) { m_minimizeRequested = request; }
    void setWindowMoveRequest(Vector2I deltaPos) { m_windowMoveRequest = deltaPos; }
    Vector2I getWindowMoveRequest() const { return m_windowMoveRequest; }
    virtual void buttonClicked(int callbackIndex) override;
    virtual void textChanged(int callbackIndex, const std::string& newString) override;
    bool shouldDisplayMessageBox() const { return !m_messageBoxes.empty(); }
    void addMessageBox(std::shared_ptr<LauncherMessageBox> messageBox) { m_messageBoxes.push_back(messageBox); }
    void removeCurrentMessageBox() { m_messageBoxes.erase(m_messageBoxes.begin()); }
    std::shared_ptr<LauncherMessageBox> getCurrentMessageBox() { return m_messageBoxes[0]; }
    WidgetButton* getUserNameButton() { return m_usernameButton; }
private:
    void updateAccountWidgets(const std::string& newUsername);
    void replaceAllInLine(std::string& lineToChange, const std::string& toReplace, const std::string& replaceWith = std::string(""));
    static std::shared_ptr<MainWindow> m_instance;
    std::shared_ptr<LauncherWidget> m_mainWidget;
    Vector2I m_size;
    Vector2D m_mousePosition;
    Vector2D m_mousePositionLast;
    Vector2D m_mouseLastClickedPosition;
    bool m_closeRequested;
    bool m_minimizeRequested;
    Vector2I m_windowMoveRequest;
    int m_borderSize;
    bool m_windowGrabbed;
    std::vector<std::shared_ptr<LauncherMessageBox>> m_messageBoxes;
    std::shared_ptr<OAuthController> m_oauthController;
    static const int BUTTON_LAUNCH = 0;
    static const int BUTTON_DEDICATED_SERVER = 1;
    static const int BUTTON_NEWS = 2;
    static const int BUTTON_UPDATE = 3;
    static const int BUTTON_OPTIONS = 4;
    static const int BUTTON_TOOLS = 5;
    static const int BUTTON_COMMUNITY = 6;
    static const int BUTTON_HELP = 7;
    static const int BUTTON_USERNAME = 8;
    static const int BUTTON_MINIMIZE = 9;
    static const int BUTTON_CLOSE = 10;
    static const int BUTTON_USERNAME_OK = 11;
    static const int BUTTON_USERNAME_CANCEL = 12;
    static const int BUTTON_UPLINK = 13;
    static const int LABEL_USERNAME = 14;
    static const int TEXT_BOX_USERNAME = 15;
    static const int BUTTON_UPLINK_OK = 16;
    static const int BUTTON_UPLINK_CANCEL = 17;
    static const int BUTTON_UPLINK_RESET_CREDENTIALS = 18;
    static const int BUTTON_UPLINK_NEW_ACCOUNT = 19;
    static const int TEXT_BOX_UPLINK_USERNAME = 20;
    static const int TEXT_BOX_UPLINK_PASSWORD = 21;
    static const int LABEL_UPLINK_USERNAME = 22;
    static const int LABEL_UPLINK_PASSWORD = 23;
    static const int LABEL_UPLINK_STATUS = 24;
    WidgetButton* m_usernameButton;
    WidgetButton* m_accountActivatedIndicator;
};

#endif // MAINWINDOW_H
