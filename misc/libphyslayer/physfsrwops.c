/*
 * This code provides a glue layer between PhysicsFS and Simple Directmedia
 *  Layer's (SDL) RWops i/o abstraction.
 *
 * License: this code is public domain. I make no warranty that it is useful,
 *  correct, harmless, or environmentally safe.
 *
 * This particular file may be used however you like, including copying it
 *  verbatim into a closed-source project, exploiting it commercially, and
 *  removing any trace of my name from the source (although I hope you won't
 *  do that). I welcome enhancements and corrections to this file, but I do
 *  not require you to send me patches if you make changes. This code has
 *  NO WARRANTY.
 *
 * Unless otherwise stated, the rest of PhysicsFS falls under the zlib license.
 *  Please see LICENSE.txt in the root of the source tree.
 *
 * SDL 1.2 falls under the LGPL license. SDL 1.3+ is zlib, like PhysicsFS.
 *  You can get SDL at http://www.libsdl.org/
 *
 *  This file was written by Ryan C. Gordon. (icculus@icculus.org).
 */

#include <stdio.h>  /* used for SEEK_SET, SEEK_CUR, SEEK_END ... */
#include "physfsrwops.h"

/* SDL's RWOPS interface changed a little in SDL 1.3... */
#if defined(SDL_VERSION_ATLEAST)
#if SDL_VERSION_ATLEAST(1, 3, 0)
#define TARGET_SDL13 1
#endif
#endif

#if TARGET_SDL13
static SDLCALL Sint64 physfsrwops_size(struct SDL_RWops *rw)
{
    PHYSFS_File *handle = (PHYSFS_File *) rw->hidden.unknown.data1;
    return PHYSFS_fileLength(handle);
}
#endif

#if TARGET_SDL13
static SDLCALL Sint64 physfsrwops_seek(struct SDL_RWops *rw, Sint64 offset, int whence)
#else
static int physfsrwops_seek(SDL_RWops *rw, int offset, int whence)
#endif
{
    PHYSFS_File *handle = (PHYSFS_File *) rw->hidden.unknown.data1;
    PHYSFS_sint64 pos = 0;

    if (whence == SEEK_SET)
        pos = (PHYSFS_sint64) offset;
    else if (whence == SEEK_CUR)
    {
        const PHYSFS_sint64 current = PHYSFS_tell(handle);
        if (current == -1)
        {
            SDL_SetError("Can't find position in file: %s",
                          PHYSFS_getLastError());
            return -1;
        } /* if */

        if (offset == 0)  /* this is a "tell" call. We're done. */
        {
            #if TARGET_SDL13
            return (long) current;
            #else
            return (int) current;
            #endif
        } /* if */

        pos = current + ((PHYSFS_sint64) offset);
    } /* else if */

    else if (whence == SEEK_END)
    {
        const PHYSFS_sint64 len = PHYSFS_fileLength(handle);
        if (len == -1)
        {
            SDL_SetError("Can't find end of file: %s", PHYSFS_getLastError());
            return -1;
        } /* if */

        pos = len + ((PHYSFS_sint64) offset);
    } /* else if */

    else
    {
        SDL_SetError("Invalid 'whence' parameter.");
        return -1;
    } /* else */

    if ( pos < 0 )
    {
        SDL_SetError("Attempt to seek past start of file.");
        return -1;
    } /* if */

    if (!PHYSFS_seek(handle, (PHYSFS_uint64) pos))
    {
        SDL_SetError("PhysicsFS error: %s", PHYSFS_getLastError());
        return -1;
    } /* if */

    #if TARGET_SDL13
    return (long) pos;
    #else
    return (int) pos;
    #endif
} /* physfsrwops_seek */


#if TARGET_SDL13
static size_t SDLCALL physfsrwops_read(struct SDL_RWops *rw, void *ptr,
                                       size_t size, size_t maxnum)
#else
static int physfsrwops_read(SDL_RWops *rw, void *ptr, int size, int maxnum)
#endif
{
    PHYSFS_File *handle = (PHYSFS_File *) rw->hidden.unknown.data1;
    const PHYSFS_uint64 readlen = (PHYSFS_uint64) (maxnum * size);
    const PHYSFS_sint64 rc = PHYSFS_readBytes(handle, ptr, readlen);
    if (rc != ((PHYSFS_sint64) readlen))
    {
        if (!PHYSFS_eof(handle)) /* not EOF? Must be an error. */
            SDL_SetError("PhysicsFS error: %s", PHYSFS_getLastError());
    } /* if */

    #if TARGET_SDL13
    return (size_t) rc;
    #else
    return (int) rc;
    #endif
} /* physfsrwops_read */


#if TARGET_SDL13
static size_t SDLCALL physfsrwops_write(struct SDL_RWops *rw, const void *ptr,
                                        size_t size, size_t num)
#else
static int physfsrwops_write(SDL_RWops *rw, const void *ptr, int size, int num)
#endif
{
    PHYSFS_File *handle = (PHYSFS_File *) rw->hidden.unknown.data1;
    const PHYSFS_uint64 writelen = (PHYSFS_uint64) (num * size);
    const PHYSFS_sint64 rc = PHYSFS_writeBytes(handle, ptr, writelen);
    if (rc != ((PHYSFS_sint64) writelen))
        SDL_SetError("PhysicsFS error: %s", PHYSFS_getLastError());

    #if TARGET_SDL13
    return (size_t) rc;
    #else
    return (int) rc;
    #endif
} /* physfsrwops_write */


static int physfsrwops_close(SDL_RWops *rw)
{
    PHYSFS_File *handle = (PHYSFS_File *) rw->hidden.unknown.data1;
    if (!PHYSFS_close(handle))
    {
        SDL_SetError("PhysicsFS error: %s", PHYSFS_getLastError());
        return -1;
    } /* if */

    SDL_FreeRW(rw);
    return 0;
} /* physfsrwops_close */


static SDL_RWops *create_rwops(PHYSFS_File *handle)
{
    SDL_RWops *retval = NULL;

    if (handle == NULL)
        SDL_SetError("PhysicsFS error: %s", PHYSFS_getLastError());
    else
    {
        retval = SDL_AllocRW();
        if (retval != NULL)
        {
#if TARGET_SDL13 && !defined(EMSCRIPTEN)
            retval->size  = physfsrwops_size;
#endif
            retval->seek  = physfsrwops_seek;
            retval->read  = physfsrwops_read;
            retval->write = physfsrwops_write;
            retval->close = physfsrwops_close;
            retval->hidden.unknown.data1 = handle;
        } /* if */
    } /* else */

    return retval;
} /* create_rwops */


SDL_RWops *PHYSFSRWOPS_makeRWops(PHYSFS_File *handle)
{
    SDL_RWops *retval = NULL;
    if (handle == NULL)
        SDL_SetError("NULL pointer passed to PHYSFSRWOPS_makeRWops().");
    else
        retval = create_rwops(handle);

    return retval;
} /* PHYSFSRWOPS_makeRWops */


SDL_RWops *PHYSFSRWOPS_openRead(const char *fname)
{
    return create_rwops(PHYSFS_openRead(fname));
} /* PHYSFSRWOPS_openRead */


SDL_RWops *PHYSFSRWOPS_openWrite(const char *fname)
{
    return create_rwops(PHYSFS_openWrite(fname));
} /* PHYSFSRWOPS_openWrite */


SDL_RWops *PHYSFSRWOPS_openAppend(const char *fname)
{
    return create_rwops(PHYSFS_openAppend(fname));
} /* PHYSFSRWOPS_openAppend */


/* end of physfsrwops.c ... */

