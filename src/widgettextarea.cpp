#include "widgettextarea.h"
#include <iostream>
#include <sstream>

WidgetTextArea::WidgetTextArea(LauncherWidget* parent)
    : WidgetPane(parent),
    m_padding(Vector2F(25.0F, 25.0F)),
    m_scrollBarColor(Vector3I(0, 0, 0)),
    m_scrollBarSliderColor(Vector3I(0, 0, 0)),
    m_scrollBarGrabbed(false)
{
    m_scroll = -m_padding.y();
}

WidgetTextArea::~WidgetTextArea()
{

}

void WidgetTextArea::initWithTextCommon(std::string line, std::string& linePart)
{
    size_t findLine = line.find("<line>");
    size_t findLineT = line.find("<linet>");
    size_t foundLinkPos = line.find("<link");
    bool foundLine = findLine != std::string::npos;
    bool foundLineT = findLineT != std::string::npos;
    bool foundLink = foundLinkPos != std::string::npos;
    if (foundLine || foundLineT)
    {
        std::string newString;

        if (foundLineT)
        {
            newString = line.substr(findLineT + 7, line.size() - 7);
        }
        else
        {
            newString = line.substr(findLine + 6, line.size() - 6);
        }

        size_t findPos;
        while ((findPos = newString.find("&amp;")) != std::string::npos)
        {
            newString.replace(findPos, 5, "&");
        }

        FontListEntry fontToUse = foundLineT ? FontListEntry::BLENDER_PRO_24 : FontListEntry::BLENDER_PRO_12;
        Vector3I colorToUse = foundLink ? Vector3I(6, 69, 173) : Vector3I(177, 177, 177);

        if (foundLink)
        {
            fontToUse = FontListEntry::BLENDER_PRO_16;
            size_t foundLinkPosEnd = line.find(">", foundLinkPos);

            std::string link(newString.substr(foundLinkPos + 1, foundLinkPosEnd - foundLinkPos - 8));
            newString.erase(foundLinkPos - 6, foundLinkPosEnd - foundLinkPos + 1);
            m_textAreaLinks.push_back({ m_text.size(), 0, link.size(), link });
        }

        std::stringstream ss(newString);
        std::string item;
        while (std::getline(ss, item, ' '))
        {
            std::string combined(linePart + item + " ");
            Vector2F vec = FontRenderer::getTextSize(fontToUse, combined);
            float sizeX = vec.x();
            if (sizeX >= getSize().x() - m_padding.x())
            {
                addText(linePart, fontToUse, colorToUse);
                linePart.clear();
            }
            linePart += item;
            if (item.size() > 0 && item.compare(" ") != 0)
            {
                linePart += " ";
            }
        }

        addText(linePart, fontToUse, colorToUse);
        linePart.clear();
    }
}

void WidgetTextArea::addText(const std::string& text, FontListEntry font, Vector3I color)
{
    m_text.push_back({ text, font, color });
}

void WidgetTextArea::initWithText(std::string* text, int tempTextLength)
{
    std::string linePart;
    for (int i = 0; i < tempTextLength; ++i)
    {
        initWithTextCommon(text[i], linePart);
    }
}

void WidgetTextArea::initWithText(std::vector<std::string> textVector)
{
    std::string linePart;
    for (size_t i = 0; i < textVector.size(); ++i)
    {
        initWithTextCommon(textVector[i], linePart);
    }
}

void WidgetTextArea::draw()
{
    WidgetPane::draw();

    float yRenderedLength = 0.0F;
    m_onScreenLinks.clear();
    for (size_t i = 0; i < m_text.size(); ++i)
    {
        TextLine& line = m_text[i];
        Vector2F textSize = FontRenderer::getTextSize(line.font, line.text);
        if (yRenderedLength + textSize.y() < getSize().y() - m_padding.y() * 2 + m_scroll &&
            yRenderedLength + textSize.y() > m_padding.y() + m_scroll)
        {
            for (int j = 0; j < m_textAreaLinks.size(); ++j)
            {
                TextAreaLink& link = m_textAreaLinks[j];
                if (link.lineIndex == i)
                {
                    int xPos0 = getPosition().x() + getSize().x() / 2 - textSize.x() / 2;
                    int xPos1 = getPosition().x() + getSize().x() / 2 + textSize.x() / 2;
                    int yPos0 = getPosition().y() + yRenderedLength + m_padding.y() - m_scroll;
                    int yPos1 = getPosition().y() + yRenderedLength + m_padding.y() - m_scroll + textSize.y();
                    m_onScreenLinks.push_back({ Vector2F(xPos0, yPos0), Vector2F(xPos1 - xPos0, yPos1 - yPos0), link.link });
                }
            }
            FontRenderer::renderText(line.font, line.text, Vector2I(getPosition().x() + getSize().x() / 2 - textSize.x() / 2, getPosition().y() + yRenderedLength + m_padding.y() + textSize.y() - m_scroll), line.color);
        }
        yRenderedLength += textSize.y() + 5.0F;
    }

    m_maxScroll = yRenderedLength - m_padding.y() * 2 - getSize().y();

    int xPos0 = getPosition().x() + getSize().x() + m_scrollBarOffsetX;
    int xPos1 = getPosition().x() + getSize().x() + m_scrollBarOffsetX + m_scrollBarSizeX;
    int yPos0 = getPosition().y();
    int yPos1 = getPosition().y() + getSize().y();
    // Scroll bar rendering
    glBegin(GL_QUADS);
    glColor3f(m_scrollBarColor.x() / 255.0F, m_scrollBarColor.y() / 255.0F, m_scrollBarColor.z() / 255.0F);
    glVertex2f(xPos0,   yPos0);
    glVertex2f(xPos1,   yPos0);
    glVertex2f(xPos1,   yPos1);
    glVertex2f(xPos0,   yPos1);
    glEnd();

    Border border = getBorder();

    glColor3f(border.color.x() / 255.0F, border.color.y() / 255.0F, border.color.z() / 255.0F);

    if (border.mode == BorderMode::ALL ||
        border.mode == BorderMode::LEFT ||
        border.mode == BorderMode::LEFT_RIGHT)
    {
        glBegin(GL_QUADS);
        glVertex2f(xPos0, yPos0);
        glVertex2f(xPos0 + border.borderWidth, yPos0);
        glVertex2f(xPos0 + border.borderWidth, yPos1);
        glVertex2f(xPos0, yPos1);
        glEnd();
    }

    if (border.mode == BorderMode::ALL ||
        border.mode == BorderMode::RIGHT ||
        border.mode == BorderMode::LEFT_RIGHT)
    {
        glBegin(GL_QUADS);
        glVertex2f(xPos1 - border.borderWidth, yPos0);
        glVertex2f(xPos1, yPos0);
        glVertex2f(xPos1, yPos1);
        glVertex2f(xPos1 - border.borderWidth, yPos1);
        glEnd();
    }

    if (border.mode == BorderMode::ALL ||
        border.mode == BorderMode::TOP ||
        border.mode == BorderMode::TOP_BOTTOM)
    {
        glBegin(GL_QUADS);
        glVertex2f(xPos0, yPos0);
        glVertex2f(xPos1, yPos0);
        glVertex2f(xPos1, yPos0 + border.borderWidth);
        glVertex2f(xPos0, yPos0 + border.borderWidth);
        glEnd();
    }

    if (border.mode == BorderMode::ALL ||
        border.mode == BorderMode::BOTTOM ||
        border.mode == BorderMode::TOP_BOTTOM)
    {
        glBegin(GL_QUADS);
        glVertex2f(xPos0, yPos1 - border.borderWidth);
        glVertex2f(xPos1, yPos1 - border.borderWidth);
        glVertex2f(xPos1, yPos1);
        glVertex2f(xPos0, yPos1);
        glEnd();
    }

    int slider = static_cast<int>((getSize().y() - 36) * getScrollPercentage()) + 3;

    xPos0 = getPosition().x() + getSize().x() + m_scrollBarOffsetX + 3;
    xPos1 = getPosition().x() + getSize().x() + m_scrollBarOffsetX - 3 + m_scrollBarSizeX;
    yPos0 = getPosition().y() + slider;
    yPos1 = getPosition().y() + 30 + slider;

    glBegin(GL_QUADS);
    glColor3f(m_scrollBarSliderColor.x() / 255.0F, m_scrollBarSliderColor.y() / 255.0F, m_scrollBarSliderColor.z() / 255.0F);
    glVertex2f(xPos0,   yPos0);
    glVertex2f(xPos1,   yPos0);
    glVertex2f(xPos1,   yPos1);
    glVertex2f(xPos0,   yPos1);
    glEnd();
}

void WidgetTextArea::init()
{
}

void WidgetTextArea::update(double delta)
{
}

void WidgetTextArea::mouseMoved(Vector2D newPos, Vector2D deltaPos)
{
    LauncherWidget::mouseMoved(newPos, deltaPos);

    if (m_scrollBarGrabbed)
    {
        m_scroll += deltaPos.y() * 30;
        m_scroll = std::max(m_scroll, -m_padding.y());
        m_scroll = std::min(m_scroll, m_maxScroll);
    }
}

void WidgetTextArea::mouseClicked(Vector2D clickPos, int button, bool press, bool inBackground)
{
    LauncherWidget::mouseClicked(clickPos, button, press, inBackground);

    for (int i = 0; i < m_onScreenLinks.size(); ++i)
    {
        Vector2F& linkPos = m_onScreenLinks[i].position;
        Vector2F& linkSize = m_onScreenLinks[i].size;
        if (button == 0 && press &&
            clickPos.x() >= linkPos.x() &&
            clickPos.x() <= linkPos.x() + linkSize.x() &&
            clickPos.y() >= linkPos.y() &&
            clickPos.y() <= linkPos.y() + linkSize.y())
        {
            // Open links - platform specific

#ifdef _WIN32
            std::cout << m_onScreenLinks[i].link.c_str() << std::endl;
            ShellExecute(NULL, "open", m_onScreenLinks[i].link.c_str(), NULL, NULL, SW_SHOWNORMAL);
#endif // _WIN32
            break;
        }
    }

    int slider = static_cast<int>((getSize().y() - 36) * getScrollPercentage()) + 3;

    int xPos0 = getPosition().x() + getSize().x() + m_scrollBarOffsetX + 3;
    int xPos1 = getPosition().x() + getSize().x() + m_scrollBarOffsetX - 3 + m_scrollBarSizeX;
    int yPos0 = getPosition().y() + slider;
    int yPos1 = getPosition().y() + 30 + slider;
    if (button == 0 && press &&
        clickPos.x() >= xPos0 &&
        clickPos.x() <= xPos1 &&
        clickPos.y() >= yPos0 &&
        clickPos.y() <= yPos1)
    {
        m_scrollBarGrabbed = true;
    }

    if (m_scrollBarGrabbed && !press)
    {
        m_scrollBarGrabbed = false;
    }
}

void WidgetTextArea::mouseWheelScrolled(double xOffset, double yOffset)
{
    m_scroll -= yOffset * 150;
    m_scroll = std::max(m_scroll, -m_padding.y());
    m_scroll = std::min(m_scroll, m_maxScroll);
}

void WidgetTextArea::setScrollBar(int offsetX, int sizeX, Vector3I barColor, Vector3I sliderColor)
{
    m_scrollBarOffsetX = offsetX;
    m_scrollBarSizeX = sizeX;
    m_scrollBarColor = barColor;
    m_scrollBarSliderColor = sliderColor;
}

