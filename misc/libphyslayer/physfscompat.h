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

#ifndef _HEDGEWARS_PHYSFSCOMPAT_C_
#define _HEDGEWARS_PHYSFSCOMPAT_C_

#include "physfs.h"

#if PHYSFS_VER_MAJOR == 2
#if PHYSFS_VER_MINOR == 0

#define HW_PHYSFS_COMPAT

#ifdef __cplusplus
extern "C" {
#endif

#define PHYSFS_DECL __EXPORT__

typedef enum PHYSFS_FileType
{
    PHYSFS_FILETYPE_REGULAR,
    PHYSFS_FILETYPE_DIRECTORY,
    PHYSFS_FILETYPE_SYMLINK,
    PHYSFS_FILETYPE_OTHER
} PHYSFS_FileType;

typedef struct PHYSFS_Stat
{
    PHYSFS_sint64 filesize;
    PHYSFS_sint64 modtime;
    PHYSFS_sint64 createtime;
    PHYSFS_sint64 accesstime;
    PHYSFS_FileType filetype;
    int readonly;
} PHYSFS_Stat;

PHYSFS_DECL int PHYSFS_stat(const char *fname, PHYSFS_Stat *stat);

PHYSFS_DECL PHYSFS_sint64 PHYSFS_readBytes(PHYSFS_File *handle, void *buffer,
                                           PHYSFS_uint64 len);


PHYSFS_DECL PHYSFS_sint64 PHYSFS_writeBytes(PHYSFS_File *handle,
                                            const void *buffer,
                                            PHYSFS_uint64 len);


#ifdef __cplusplus
}
#endif

#endif /* PHYSFS_VER_MAJOR == 2 */
#endif /* PHYSFS_VER_MINOR == 0 */

#endif /* _HEDGEWARS_PHYSFSCOMPAT_C_ */
