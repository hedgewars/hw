#include "system.h"
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <wchar.h>
#include "pmath.h"

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

    result.len = count;

    return result;
}

astring fpcrtl_copyA(astring s, Integer index, Integer count) {
    astring result;

    result.len = 0;

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

    memcpy(result.s + 1, s.s + index, count);

    result.len = count;

    return result;
}

void fpcrtl_insert__vars(string255 *src, string255 *dst, SizeInt index) {
    int num_insert;
    int num_shift;
    int num_preshift;

    // nothing to do if empty string is inserted or index invalid
    if ((src->len == 0) || (index < 1) || (index > 255)) {
        return;
    }

    num_insert = src->len;
    // number of chars from start of destination string to end of insertion
    num_preshift = index - 1 + num_insert;

    // don't overflow on insert
    if (num_preshift > 255) {
        num_insert = 255 - (index - 1);
        num_shift = 0;
    }
    // shift trailing chars
    else {
        // number of bytes to be shifted
        num_shift = dst->len - (index - 1);

        if (num_shift > 0) {
            // don't overflow when shifting
            if (num_shift + num_preshift > 255)
                num_shift = 255 - num_preshift;

            // time to move some bytes!
            memmove(dst->str + num_preshift, dst->str + index - 1, num_shift);
        }
    }

    // actual byte insertion
    memmove(dst->str + index - 1, src->str, num_insert);
    // store new length
    dst->len = num_shift + num_preshift;
}

void __attribute__((overloadable)) fpcrtl_delete__vars(string255 *s, SizeInt index, SizeInt count) {
    // number of chars to be move
    int num_move;
    int new_length;

    if (index < 1) {
        // in fpc, if index < 1, the string won't be modified
        return;
    }

    if(index > s->len){
        return;
    }

    if (count > s->len - index + 1) {
        s->len = index - 1;
        return;
    }

    num_move = s->len - index + 1 - count;
    new_length = s->len - count;

    memmove(s->str + index - 1, s->str + index - 1 + count, num_move);
    s->str[new_length] = 0;

    s->len = new_length;

}

void __attribute__((overloadable)) fpcrtl_delete__vars(astring *s, SizeInt index, SizeInt count) {
    // number of chars to be move
    int num_move;
    int new_length;

    if (index < 1) {
        // in fpc, if index < 1, the string won't be modified
        return;
    }

    if(index > s->len){
        return;
    }

    if (count > s->len - index + 1) {
        s->len = index - 1;
        return;
    }

    num_move = s->len - index + 1 - count;
    new_length = s->len - count;

    memmove(s->s + index, s->s + index + count, num_move);

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

    unsigned char* p;

    if (str.len == 0) {
        return 0;
    }

    FIX_STRING(str);

    p = strchr(str.str, c);

    if (p == NULL) {
        return 0;
    }

    return p - (unsigned char*)&str.s;
}

Integer __attribute__((overloadable)) fpcrtl_pos(string255 substr, string255 str) {

    unsigned char* p;

    if (str.len == 0) {
        return 0;
    }

    if (substr.len == 0) {
        return 0;
    }

    FIX_STRING(substr);
    FIX_STRING(str);

    p = strstr(str.str, substr.str);

    if (p == NULL) {
        return 0;
    }

    return p - (unsigned char*)&str.s;
}

Integer __attribute__((overloadable)) fpcrtl_pos(Char c, astring str) {
    unsigned char* p;

    if (str.len == 0) {
        return 0;
    }

    p = strchr(str.s + 1, c);

    if (p == NULL) {
        return 0;
    }

    return p - (unsigned char*)&str.s;

}

Integer __attribute__((overloadable)) fpcrtl_pos(string255 substr, astring str) {

    unsigned char* p;

    if (str.len == 0) {
        return 0;
    }

    if (substr.len == 0) {
        return 0;
    }

    FIX_STRING(substr);
    str.s[str.len] = 0;

    p = strstr(str.s + 1, substr.str);

    if (p == NULL) {
        return 0;
    }

    return p - (unsigned char *)&str.s;
}

Integer fpcrtl_length(string255 s) {
    return s.len;
}

Integer fpcrtl_lengthA(astring s)
{
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

Integer fpcrtl_ceil(extended n) {
    return (int) (ceil(n));
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

void __attribute__((overloadable)) fpcrtl_val__vars(string255 s, LongInt *a)
{
    FIX_STRING(s);
    *a = str_to_int(s.str);
}

void __attribute__((overloadable)) fpcrtl_val__vars(string255 s, Byte *a)
{
    FIX_STRING(s);
    *a = str_to_int(s.str);
}

void __attribute__((overloadable)) fpcrtl_val__vars(string255 s, LongWord *a)
{
    FIX_STRING(s);
    *a = str_to_int(s.str);
}

LongInt fpcrtl_random(LongInt l) {
    // random(0) is undefined in docs but effectively returns 0 in free pascal
    if (l == 0) {
        printf("WARNING: random(0) called!\n");
        return 0;
    }
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

