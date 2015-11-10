/*
 * Hedgewars, a free turn based strategy game
 * Copyright (C) 2012 Simeon Maxein <smaxein@googlemail.com>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

/**
 * Simple dynamic array manipulation functions.
 */

#ifndef LIST_H_
#define LIST_H_

#include <stddef.h>
#include <string.h>
#include <stdlib.h>
#include "util.h"
#include "logging.h"

/**
 * Generate a static function that inserts a new value into a heap array of the given type,
 * using realloc and memmove to increase the capacity and shift existing values.
 * The function takes a pointer to the array variable and a pointer to the size variable
 * because both can be changed by this operation (realloc / increment).
 * The function returns 0 on success and leaves the array unchanged on error.
 */
#define GENERATE_STATIC_LIST_INSERT(fname, type) \
    static int fname(type **listptr, int *listSizePtr, type element, int pos) { \
        int result = -1; \
        if(!log_badargs_if4(listptr==NULL, listSizePtr==NULL, pos < 0, pos > *listSizePtr)) { \
            type *newList = flib_realloc(*listptr, ((*listSizePtr)+1)*sizeof(type)); \
            if(newList) { \
                memmove(newList + (pos+1), newList + pos, ((*listSizePtr)-pos)*sizeof(type)); \
                newList[pos] = element; \
                (*listSizePtr)++; \
                *listptr = newList; \
                result = 0; \
            } \
        } \
        return result; \
    }

/**
 * Generate a static function that deletes a value from a heap array of the given type,
 * using realloc and memmove to decrease the capacity and shift existing values.
 * The function takes a pointer to the array variable and a pointer to the size variable
 * because both can be changed by this operation (realloc / decrement).
 * The function returns 0 on success and leaves the array unchanged on error.
 */
#define GENERATE_STATIC_LIST_DELETE(fname, type) \
    static int fname(type **listPtr, int *listSizePtr, int pos) { \
        int result = -1; \
        if(!log_badargs_if4(listPtr==NULL, listSizePtr==NULL, pos < 0, pos >= *listSizePtr)) { \
            memmove((*listPtr) + pos, (*listPtr) + (pos+1), ((*listSizePtr)-(pos+1))*sizeof(type)); \
            (*listSizePtr)--; \
            \
            size_t newCharSize = (*listSizePtr)*sizeof(type); \
            type *newList = flib_realloc((*listPtr), newCharSize); \
            if(newList || newCharSize==0) { \
                (*listPtr) = newList; \
            } /* If the realloc fails, just keep using the old buffer...*/ \
            result = 0; \
        } \
        return result; \
    }

#endif /* LIST_H_ */
