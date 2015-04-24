#ifndef OAUTHCONTROLLER_H
#define OAUTHCONTROLLER_H

#include <string>
#include "ibuttoncallback.h"

class OAuthController : public IButtonCallback
{
    public:
        OAuthController();
        virtual ~OAuthController();
        static std::string loginRequest(const std::string& username, const std::string& password);
        virtual void buttonClicked(int callbackIndex) override;
    protected:
    private:
};

#endif // OAUTHCONTROLLER_H
