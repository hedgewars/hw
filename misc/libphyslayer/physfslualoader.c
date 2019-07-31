#include "lua.h"
#include "physfs.h"

#include "physfscompat.h"

#define BUFSIZE 1024
#define UNUSED(x) (void)(x)

void *physfsReaderBuffer;

PHYSFS_DECL const char * physfsReader(lua_State *L, PHYSFS_File *f, size_t *size)
{
    UNUSED(L);

    if(PHYSFS_eof(f))
    {
        return NULL;
    }
    else
    {
        *size = PHYSFS_readBytes(f, physfsReaderBuffer, BUFSIZE);

        if(*size == 0)
            return NULL;
        else
            return physfsReaderBuffer;
    }
}

PHYSFS_DECL void physfsReaderSetBuffer(void *buffer)
{
    physfsReaderBuffer = buffer;
}

