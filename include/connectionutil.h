#ifndef CONNECTIONUTIL_H
#define CONNECTIONUTIL_H

#include <cstddef>
#include <curl/curl.h>

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
    protected:
    private:
};

#endif // CONNECTIONUTIL_H
