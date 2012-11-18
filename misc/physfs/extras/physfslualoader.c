#include <lua.h>
#include <physfs.h>

#define BUFSIZE 1024

void * physfsReaderBuffer;

const char * physfsReader(lua_State *L, PHYSFS_File *f, size_t *size)
{

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
