#ifndef OAUTHCONTROLLER_H
#define OAUTHCONTROLLER_H

#include <string>

class OAuthController
{
    public:
        OAuthController();
        virtual ~OAuthController();
        static std::string loginRequest(const std::string& username, const std::string& password);
    protected:
    private:
};

#endif // OAUTHCONTROLLER_H
