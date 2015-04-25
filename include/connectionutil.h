#ifndef CONNECTIONUTIL_H
#define CONNECTIONUTIL_H

#include <cstddef>
#include <curl/curl.h>
#include <string>
#include <iostream>

/**
 * RAII class for curl string ownership
*/
class OwnedCurlString
{
public:
    OwnedCurlString(char* str)
        : cString(str) {}
    ~OwnedCurlString()
    {
        curl_free(cString);
        cString = nullptr;
    }
    std::string asString() const { return std::string(cString); }
    char* asCString() const { return cString; }
private:
    char* cString;
};

class ConnectionUtil
{
    public:
        static size_t writeMemoryCallback(void *ptr, size_t size, size_t nmemb, void *data);

        struct BufferStruct
        {
            BufferStruct()
                : buffer(nullptr),
                size(0)
            {}
            char* buffer;
            size_t size;
        };

        static void setWriteOptions(CURL *curl, BufferStruct& output);
        static void setClientCertificates(CURL *curl);
    protected:
    private:
};

#endif // CONNECTIONUTIL_H
