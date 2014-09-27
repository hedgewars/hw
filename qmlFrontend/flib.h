#ifndef FLIB_H
#define FLIB_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef union string255_
    {
        struct {
            unsigned char s[256];
        };
        struct {
            unsigned char len;
            unsigned char str[255];
        };
    } string255;

typedef void RunEngine_t(int argc, const char ** argv);
typedef void registerIPCCallback_t(void * context, void (*)(void * context, const char * msg, uint32_t len));
typedef void ipcToEngine_t(const char * msg, uint8_t len);
typedef void flibInit_t(const char * localPrefix, const char * userPrefix);
typedef void flibFree_t();

#ifdef __cplusplus
}
#endif

#endif // FLIB_H
