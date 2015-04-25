#ifndef ITEXTBOXCALLBACK_H
#define ITEXTBOXCALLBACK_H

#include <string>

class ITextBoxCallback
{
public:
    virtual void textChanged(int callbackIndex, const std::string& newString) = 0;
private:
};

#endif // ITEXTBOXCALLBACK_H
