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

#include "util.h"
#include "logging.h"

#include <stddef.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <ctype.h>
#include <limits.h>

char *flib_asprintf(const char *fmt, ...) {
    va_list argp;
    va_start(argp, fmt);
    char *result = flib_vasprintf(fmt, argp);
    va_end(argp);
    return result;
}

char *flib_vasprintf(const char *fmt, va_list args) {
    char *result = NULL;
    if(!log_badargs_if(fmt==NULL)) {
        int requiredSize = vsnprintf(NULL, 0, fmt, args)+1;                 // Figure out how much memory we need,
        if(!log_e_if(requiredSize<0, "Error formatting string with template \"%s\"", fmt)) {
            char *tmpbuf = flib_malloc(requiredSize);                       // allocate it
            if(tmpbuf && vsnprintf(tmpbuf, requiredSize, fmt, args)>=0) {   // and then do the actual formatting.
                result = tmpbuf;
                tmpbuf = NULL;
            }
            free(tmpbuf);
        }
    }
    return result;
}

char *flib_join(char **parts, int partCount, const char *delimiter) {
    char *result = NULL;
    if(!log_badargs_if2(parts==NULL, delimiter==NULL)) {
        size_t totalSize = 1;
        size_t delimLen = strlen(delimiter);
        for(int i=0; i<partCount; i++) {
            totalSize += strlen(parts[i]) + delimLen;
        }
        result = flib_malloc(totalSize);

        if(result) {
            size_t outpos = 0;
            for(int i=0; i<partCount; i++) {
                if(i>0) {
                    strcpy(result+outpos, delimiter);
                    outpos += delimLen;
                }
                strcpy(result+outpos, parts[i]);
                outpos += strlen(parts[i]);
            }
        }
    }
    return result;
}

char *flib_strdupnull(const char *str) {
    return str==NULL ? NULL : flib_asprintf("%s", str);
}

void *flib_bufdupnull(const void *buf, size_t size) {
    void *result = NULL;
    if(!log_badargs_if(buf==NULL && size>0)) {
        result = flib_malloc(size);
        if(result) {
            memcpy(result, buf, size);
        }
    }
    return result;
}

void *flib_malloc(size_t size) {
    void *result = malloc(size);
    if(!result && size>0) {
        flib_log_e("Out of memory trying to malloc %zu bytes.", size);
    }
    return result;
}

void *flib_calloc(size_t count, size_t elementsize) {
    void *result = calloc(count, elementsize);
    if(!result && count>0 && elementsize>0) {
        flib_log_e("Out of memory trying to calloc %zu objects of %zu bytes each.", count, elementsize);
    }
    return result;
}

void *flib_realloc(void *ptr, size_t size) {
    void *result = realloc(ptr, size);
    if(!result && size>0) {
        flib_log_e("Out of memory trying to realloc %zu bytes.", size);
    }
    return result;
}

static bool isAsciiAlnum(char c) {
    return (c>='0' && c<='9') || (c>='a' && c <='z') || (c>='A' && c <='Z');
}

char *flib_urlencode(const char *inbuf) {
    return flib_urlencode_pred(inbuf, isAsciiAlnum);
}

static size_t countCharsToEscape(const char *inbuf, bool (*needsEscaping)(char c)) {
    size_t result = 0;
    for(const char *c=inbuf; *c; c++) {
        if(needsEscaping(*c)) {
            result++;
        }
    }
    return result;
}

char *flib_urlencode_pred(const char *inbuf, bool (*needsEscaping)(char c)) {
    char *result = NULL;
    if(inbuf && !log_badargs_if(needsEscaping == NULL)) {
        size_t insize = strlen(inbuf);
        if(!log_e_if(insize > SIZE_MAX/4, "String too long: %zu bytes.", insize)) {
            size_t escapeCount = countCharsToEscape(inbuf, needsEscaping);
            result = flib_malloc(insize + escapeCount*2 + 1);
        }
        if(result) {
            char *out = result;
            for(const char *in = inbuf; *in; in++) {
                if(!needsEscaping(*in)) {
                    *out = *in;
                    out++;
                } else {
                    snprintf(out, 4, "%%%02x", (unsigned)(*(uint8_t*)in));
                    out += 3;
                }
            }
            *out = 0;
        }
    }
    return result;
}

char *flib_urldecode(const char *inbuf) {
    if(!inbuf) {
        return NULL;
    }
    char *outbuf = flib_malloc(strlen(inbuf)+1);
    if(!outbuf) {
        return NULL;
    }

    size_t inpos = 0, outpos = 0;
    while(inbuf[inpos]) {
        if(inbuf[inpos] == '%' && isxdigit(inbuf[inpos+1]) && isxdigit(inbuf[inpos+2])) {
            char temp[3] = {inbuf[inpos+1],inbuf[inpos+2],0};
            outbuf[outpos++] = strtol(temp, NULL, 16);
            inpos += 3;
        } else {
            outbuf[outpos++] = inbuf[inpos++];
        }
    }
    outbuf[outpos] = 0;
    char *shrunk = realloc(outbuf, outpos+1);
    return shrunk ? shrunk : outbuf;
}

bool flib_contains_dir_separator(const char *str) {
    if(!log_badargs_if(!str)) {
        for(;*str;str++) {
            if(*str=='\\' || *str=='/') {
                return true;
            }
        }
    }
    return false;
}

bool flib_strempty(const char *str) {
    return !str || !*str;
}

int flib_gets(char *str, size_t strlen) {
    if(fgets(str, strlen, stdin)) {
        for(char *s=str; *s; s++) {
            if(*s=='\r' || *s=='\n') {
                *s = 0;
                break;
            }
        }
        return 0;
    }
    return -1;
}
