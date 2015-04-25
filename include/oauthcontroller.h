#ifndef OAUTHCONTROLLER_H
#define OAUTHCONTROLLER_H

#include <string>
#include <memory>
#include <rapidjson/document.h>
#include "ibuttoncallback.h"
#include "connectionutil.h"

enum class TokenRequestResult
{
    OK,
    CONNECTION_ERROR,
    INVALID_CREDENTIALS,
    UNKOWN_ERROR
};

typedef rapidjson::Document JSONDoc;
typedef std::shared_ptr<JSONDoc> JSONDocPtr;

class OAuthController : public IButtonCallback
{
    public:
        OAuthController();
        virtual ~OAuthController();
        std::string loginRequest(const std::string& username, const std::string& password);
        virtual void buttonClicked(int callbackIndex) override;
        JSONDocPtr getResponseJSON(const ConnectionUtil::BufferStruct& output);
        TokenRequestResult checkTokenValidity(const std::string& token);
    protected:
    private:
        static const int BUTTON_OK = 0;
        static const int BUTTON_CANCEL = 1;
        static const int BUTTON_RESET_CREDENTIALS = 7;
        static const int BUTTON_NEW_ACCOUNT = 8;
        static const int TEXT_BOX_USERNAME = 2;
        static const int TEXT_BOX_PASSWORD = 3;
        static const int LABEL_USERNAME = 4;
        static const int LABEL_PASSWORD = 5;
        static const int LABEL_STATUS = 6;
        static const char* STATUS_CONNECTION_ERROR;
        static const char* STATUS_CREDENTIALS_INVALID;
};

#endif // OAUTHCONTROLLER_H
