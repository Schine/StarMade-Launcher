#ifndef IBUTTONCALLBACK_H
#define IBUTTONCALLBACK_H

class WidgetButton;

class IButtonCallback
{
public:
    virtual void buttonClicked(int callbackIndex) = 0;
private:
};

#endif // IBUTTONCALLBACK_H
