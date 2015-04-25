#include "oauthcontroller.h"
#include <curl/curl.h>
#include <iostream>
#include <string>
#include <rapidjson/document.h>
#include <rapidjson/writer.h>
#include <rapidjson/stringbuffer.h>
#include <glfw/glfw3.h>
#include "platformutil.h"
#include "connectionutil.h"
#include "mainwindow.h"
#include "messagebox.h"

const char* OAuthController::STATUS_CONNECTION_ERROR = "%err_conn%";
const char* OAuthController::STATUS_CREDENTIALS_INVALID = "%err_cred%";

OAuthController::OAuthController()
{
    //ctor
}

OAuthController::~OAuthController()
{
    //dtor
}

/**
  * Make a login request
  */
std::string OAuthController::loginRequest(const std::string& username, const std::string& password)
{
    const std::string tokenServerUrl("https://registry.star-made.org/oauth/token");

    curl_global_init(CURL_GLOBAL_ALL);
    CURL *curl;
    CURLcode res;
    ConnectionUtil::BufferStruct output;

    curl = curl_easy_init();
    if (curl)
    {
        {
            OwnedCurlString grant_type = curl_easy_escape(curl, "grant_type", 0);
            OwnedCurlString grant_type_value = curl_easy_escape(curl, "password", 0);
            OwnedCurlString user_name = curl_easy_escape(curl, "username", 0);
            OwnedCurlString user_name_value = curl_easy_escape(curl, username.c_str(), 0);
            OwnedCurlString password_encoded = curl_easy_escape(curl, "password", 0);
            OwnedCurlString password_encoded_value = curl_easy_escape(curl, password.c_str(), 0);
            OwnedCurlString scope = curl_easy_escape(curl, "scope", 0);
            std::string fullPostFields(grant_type.asString() + "=" + grant_type_value.asString() + "&" +
                                  user_name.asString() + "=" + user_name_value.asString() + "&" +
                                  password_encoded.asString() + "=" + password_encoded_value.asString() + "&" +
                                  scope.asString() + "=" + "public+read_citizen_info+client");

            ConnectionUtil::setWriteOptions(curl, output);
            curl_easy_setopt(curl, CURLOPT_URL, tokenServerUrl.c_str());
            curl_easy_setopt(curl, CURLOPT_POSTFIELDS, fullPostFields.c_str());
            ConnectionUtil::setClientCertificates(curl);
            res = curl_easy_perform(curl);

            if (res != CURLE_OK)
            {
                return STATUS_CONNECTION_ERROR;
            }

            long http_code = 0;
            curl_easy_getinfo (curl, CURLINFO_RESPONSE_CODE, &http_code);

            if (http_code == 401)
            {
                return STATUS_CREDENTIALS_INVALID;
            }
        }

        curl_easy_cleanup(curl);

        JSONDocPtr doc = getResponseJSON(output);
        return (*doc)["access_token"].GetString();
    }

    return STATUS_CONNECTION_ERROR;
}

void OAuthController::buttonClicked(int callbackIndex)
{
}

JSONDocPtr OAuthController::getResponseJSON(const ConnectionUtil::BufferStruct& output)
{
    if (output.buffer != nullptr)
    {
        JSONDocPtr d(new JSONDoc());
        d->Parse(output.buffer);
        return d;
    }

    return nullptr;
}

TokenRequestResult OAuthController::checkTokenValidity(const std::string& token)
{
    if (token.compare(STATUS_CONNECTION_ERROR) == 0)
    {
        return TokenRequestResult::CONNECTION_ERROR;
    }
    if (token.compare(STATUS_CREDENTIALS_INVALID) == 0)
    {
        return TokenRequestResult::INVALID_CREDENTIALS;
    }
    if (token.empty())
    {
        return TokenRequestResult::UNKOWN_ERROR;
    }
    return TokenRequestResult::OK;
}
