#ifndef MESSAGEBOX_H
#define MESSAGEBOX_H

#include <string>

class MessageBox
{
    public:
        MessageBox(const std::string& title, const std::string& message);
        virtual ~MessageBox();
    protected:
    private:
        std::string m_title;
        std::string m_message;
};

#endif // MESSAGEBOX_H
