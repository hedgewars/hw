#include "system.h"
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <wchar.h>

#ifndef M_PI
// some math.h do not have M_PI macros
# define M_PI    3.14159265358979323846  /* pi */
# define M_PI_2  1.57079632679489661923  /* pi/2 */
# define M_PI_4  0.78539816339744830962  /* pi/4 */
# define M_PIl   3.1415926535897932384626433832795029L  /* pi */
# define M_PI_2l 1.5707963267948966192313216916397514L  /* pi/2 */
# define M_PI_4l 0.7853981633974483096156608458198757L  /* pi/4 */
#endif

double pi = M_PI;

int paramCount;
string255 params[MAX_PARAMS];

string255 fpcrtl_copy(string255 s, Integer index, Integer count) {
    string255 result = STRINIT("");

    if (count < 1) {
        return result;
    }

    if (index < 1) {
        index = 1;
    }

    if (index > s.len) {
        return result;
    }

    if (index + count > s.len + 1) {
        count = s.len + 1 - index;
    }

    memcpy(result.str, s.str + index - 1, count);

    result.str[count] = 0;
    result.len = count;

    return result;
}

void fpcrtl_delete__vars(string255 *s, SizeInt index, SizeInt count) {
    // number of chars to be move
    int num_move;
    int new_length;

    string255 temp = *s;

    if (index < 1) {
        // in fpc, if index < 1, the string won't be modified
        return;
    }

    if(index > s->len){
        return;
    }

    if (count > s->len - index + 1) {
        s->str[index - 1] = 0;
        s->len = index - 1;
        return;
    }

    num_move = s->len - index + 1 - count;
    new_length = s->len - count;

    memmove(s->str + index - 1, temp.str + index - 1 + count, num_move);
    s->str[new_length] = 0;

    s->len = new_length;

}

string255 fpcrtl_floatToStr(double n) {
    string255 t;
    sprintf(t.str, "%f", n);
    t.len = strlen(t.str);

    return t;
}

void fpcrtl_move__vars(void *src, void *dst, SizeInt count) {
    memmove(dst, src, count);
}

Integer __attribute__((overloadable)) fpcrtl_pos(Char c, string255 str) {
    string255 t;
    t.len = 1;
    t.str[0] = c;
    t.str[1] = 0;
    return fpcrtl_pos(t, str);
}

Integer __attribute__((overloadable)) fpcrtl_pos(string255 substr, string255 str) {

    char* p;

    FIX_STRING(substr);
    FIX_STRING(str);

    if (str.len == 0) {
        return 0;
    }

    if (substr.len == 0) {
        return 0;
    }

    str.str[str.len] = 0;
    substr.str[substr.len] = 0;

    p = strstr(str.str, substr.str);

    if (p == NULL) {
        return 0;
    }

    return strlen(str.str) - strlen(p) + 1;
}

Integer fpcrtl_length(string255 s) {
    return s.len;
}

string255 fpcrtl_lowerCase(string255 s) {
    int i;

    for (i = 0; i < s.len; i++) {
        if (s.str[i] >= 'A' && s.str[i] <= 'Z') {
            s.str[i] += 'a' - 'A';
        }
    }

    return s;
}

void fpcrtl_fillChar__vars(void *x, SizeInt count, Byte value) {
    memset(x, value, count);
}

void fpcrtl_new__vars(void **p, int size) {
    *p = malloc(size);
}

Integer fpcrtl_trunc(extended n) {
    return (int) n;
}

LongInt str_to_int(char *src)
{
    int i;
    int len = strlen(src);
    char *end;
    for(i = 0; i < len; i++)
    {
        if(src[i] == '$'){
            // hex
            return strtol(src + i + 1, &end, 16);
        }
    }

    // decimal
    return atoi(src);
}
void __attribute__((overloadable)) fpcrtl_val__vars(string255 s, LongInt *a,
        LongInt *c) {
    *c = 0; // no error
    FIX_STRING(s);
    *a = str_to_int(s.str);
}

void __attribute__((overloadable)) fpcrtl_val__vars(string255 s, Byte *a,
        LongInt *c) {
    *c = 0; // no error
    FIX_STRING(s);
    *a = str_to_int(s.str);
}

void __attribute__((overloadable)) fpcrtl_val__vars(string255 s, LongWord *a,
        LongInt *c) {
    *c = 0; // no error
    FIX_STRING(s);
    *a = str_to_int(s.str);
}

LongInt fpcrtl_random(LongInt l) {
    return (LongInt) (rand() / (double) RAND_MAX * l);
}

void __attribute__((overloadable)) fpcrtl_str__vars(float x, string255 *s) {
    sprintf(s->str, "%f", x);
    s->len = strlen(s->str);
}
void __attribute__((overloadable)) fpcrtl_str__vars(double x, string255 *s) {
    sprintf(s->str, "%f", x);
    s->len = strlen(s->str);
}
void __attribute__((overloadable)) fpcrtl_str__vars(uint8_t x, string255 *s) {
    sprintf(s->str, "%u", x);
    s->len = strlen(s->str);
}
void __attribute__((overloadable)) fpcrtl_str__vars(int8_t x, string255 *s) {
    sprintf(s->str, "%d", x);
    s->len = strlen(s->str);
}
void __attribute__((overloadable)) fpcrtl_str__vars(uint16_t x, string255 *s) {
    sprintf(s->str, "%u", x);
    s->len = strlen(s->str);
}
void __attribute__((overloadable)) fpcrtl_str__vars(int16_t x, string255 *s) {
    sprintf(s->str, "%d", x);
    s->len = strlen(s->str);
}
void __attribute__((overloadable)) fpcrtl_str__vars(uint32_t x, string255 *s) {
    sprintf(s->str, "%u", x);
    s->len = strlen(s->str);
}
void __attribute__((overloadable)) fpcrtl_str__vars(int32_t x, string255 *s) {
    sprintf(s->str, "%d", x);
    s->len = strlen(s->str);
}
void __attribute__((overloadable)) fpcrtl_str__vars(uint64_t x, string255 *s) {
    sprintf(s->str, "%llu", x);
    s->len = strlen(s->str);
}
void __attribute__((overloadable)) fpcrtl_str__vars(int64_t x, string255 *s) {
    sprintf(s->str, "%lld", x);
    s->len = strlen(s->str);
}

/*
 * XXX No protection currently!
 */
void fpcrtl_interlockedIncrement__vars(int *i) {
    (*i)++;
}

void fpcrtl_interlockedDecrement__vars(int *i) {
    (*i)--;
}

/*
 * This function should be called when entering main
 */
void fpcrtl_init(int argc, char** argv) {
    int i;
    paramCount = argc;

    printf("ARGC = %d\n", paramCount);

    for (i = 0; i < argc; i++) {
        if (strlen(argv[i]) > 255) {
            assert(0);
        }
        strcpy(params[i].str, argv[i]);
        params[i].len = strlen(params[i].str);
    }

}

int fpcrtl_paramCount() {
    return paramCount - 1; // ignore the first one
}

string255 fpcrtl_paramStr(int i) {
    return params[i];
}

int fpcrtl_UTF8ToUnicode(PWideChar dest, PChar src, SizeInt maxLen) {
    //return swprintf(dest, maxLen, L"%hs", "src"); //doesn't work in emscripten
    return 0;
}

uint32_t __attribute__((overloadable)) fpcrtl_lo(uint64_t i) {
    return (i & 0xFFFFFFFF);
}

