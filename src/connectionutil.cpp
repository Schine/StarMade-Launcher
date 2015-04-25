#include "connectionutil.h"
#include <stdlib.h>
#include <cstring>

size_t ConnectionUtil::writeMemoryCallback(void *ptr, size_t size, size_t nmemb, void *data)
{
    size_t realSize = size * nmemb;

    struct BufferStruct * mem = (struct BufferStruct *) data;
    mem->buffer = (char*)realloc(mem->buffer, mem->size + realSize + 1);

    if (mem->buffer)
    {
        memcpy(&(mem->buffer[mem->size]), ptr, realSize);
        mem->size += realSize;
        mem->buffer[mem->size] = 0;
    }

    return realSize;
}

void ConnectionUtil::setWriteOptions(CURL *curl, BufferStruct& output)
{
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, &ConnectionUtil::writeMemoryCallback);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, (void*)&output);
}

void ConnectionUtil::setClientCertificates(CURL *curl)
{
    curl_easy_setopt(curl, CURLOPT_CAINFO, "ca-bundle.crt");
    curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, true);
    curl_easy_setopt(curl, CURLOPT_SSL_VERIFYHOST, 2);
}
