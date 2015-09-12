/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2015 Andrey Korotaev <unC0Rr@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

#include "physfscompat.h"

#ifdef HW_PHYSFS_COMPAT

PHYSFS_DECL int PHYSFS_stat(const char *fname, PHYSFS_Stat *stat)
{
    PHYSFS_File * handle;

    if (PHYSFS_exists(fname))
    {
        handle = PHYSFS_openRead(fname);
        if (handle)
        {
            stat->filesize = PHYSFS_fileLength(handle);
            PHYSFS_close(handle);
            handle = 0;
        }
        else
            stat->filesize = -1;

        stat->modtime = PHYSFS_getLastModTime(fname);
        stat->createtime = -1;
        stat->accesstime = -1;

        if (PHYSFS_isSymbolicLink(fname))
            stat->filetype = PHYSFS_FILETYPE_SYMLINK;
        else if (PHYSFS_isDirectory(fname))
            stat->filetype = PHYSFS_FILETYPE_DIRECTORY;
        else stat->filetype = PHYSFS_FILETYPE_REGULAR;

        stat->readonly = 0; /* not supported */

        /* success */
        return 1;
    }

    /* does not exist, can't stat */
    return 0;
}

PHYSFS_DECL PHYSFS_sint64 PHYSFS_readBytes(PHYSFS_File *handle, void *buffer,
                                           PHYSFS_uint64 len)
{
    return PHYSFS_read(handle, buffer, 1, len);
}


PHYSFS_DECL PHYSFS_sint64 PHYSFS_writeBytes(PHYSFS_File *handle,
                                            const void *buffer,
                                            PHYSFS_uint64 len)
{
    return PHYSFS_write(handle, buffer, 1, len);
}

#endif /* HW_PHYSFS_COMPAT */
