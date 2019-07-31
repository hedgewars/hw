#include "misc.h"
#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#include <assert.h>

char strbuf[512];

void fpcrtl_assert(int i)
{
    if(!i){
        assert(0);
    }
}

// EFFECTS: return the nearest integer of the given number
int fpcrtl_round(double number)
{
    return (number >= 0) ? (int)(number + 0.5) : (int)(number - 0.5);
}

void fpcrtl_printf(const char* format, ...)
{
#ifdef FPCRTL_DEBUG
    va_list args;
    va_start (args, format);
    vprintf (format, args);
    va_end (args);
#endif
}

//
//void fpcrtl_check_string(string255 str)
//{
//#ifdef FPCRTL_DEBUG
//    int len = strlen(str.str);
//    if(len != str.len){
//        printf("String %s internal inconsistency error. Length should be %d but actually is %d.\n", str.str, len, str.len);
//    }
//    //assert(len == str.len);
//#endif
//}

string255 fpcrtl_strconcat(string255 str1, string255 str2)
{
    int newlen = str1.len + str2.len;
    if(newlen > 255) newlen = 255;

    memcpy(&(str1.str[str1.len]), str2.str, newlen - str1.len);
    str1.len = newlen;

    return str1;
}

astring fpcrtl_strconcatA(astring str1, astring str2)
{
    int newlen = str1.len + str2.len;
    if(newlen > MAX_ANSISTRING_LENGTH) newlen = MAX_ANSISTRING_LENGTH;

    memcpy(&(str1.s[str1.len + 1]), &str2.s[1], newlen - str1.len);
    str1.len = newlen;

    return str1;
}

string255 fpcrtl_strappend(string255 s, char c)
{
    if(s.len < 255)
    {
        ++s.len;
        s.s[s.len] = c;
    }

    return s;
}

astring fpcrtl_strappendA(astring s, char c)
{
    if(s.len < MAX_ANSISTRING_LENGTH)
    {
        ++s.len;
        s.s[s.len] = c;
    }

    return s;
}

string255 fpcrtl_strprepend(char c, string255 s)
{
    uint8_t newlen = s.len < 255 ? s.len + 1 : 255;
    memmove(s.str + 1, s.str, newlen); // also move '/0'
    s.str[0] = c;
    s.len = newlen;

    return s;
}

string255 fpcrtl_chrconcat(char a, char b)
{
    string255 result;

    result.len = 2;
    result.str[0] = a;
    result.str[1] = b;

    return result;
}

bool fpcrtl_strcompare(string255 str1, string255 str2)
{
    return memcmp(str1.s, str2.s, str1.len + 1) == 0;
}

bool fpcrtl_strcomparec(string255 a, char b)
{
    if(a.len == 1 && a.str[0] == b){
        return true;
    }

    return false;
}

bool fpcrtl_strncompare(string255 a, string255 b)
{
    return !fpcrtl_strcompare(a, b);
}

bool fpcrtl_strncompareA(astring a, astring b)
{
    return (a.len != b.len) || (memcmp(a.str, b.str, a.len) != 0);
}


string255 fpcrtl_pchar2str(const char *s)
{
    string255 result;

    if(!s)
    {
        result.len = 0;
    } else
    {
        int rlen = strlen(s);

        if(rlen > 255){
            rlen = 255;
        }

        result.len = rlen;
        memcpy(result.str, s, rlen);
    }

    return result;
}


string255 fpcrtl_make_string(const char* s) {
    return fpcrtl_pchar2str(s);
}


astring fpcrtl_pchar2astr(const char *s)
{
    astring result;

    if(!s) 
    {
        result.len = 0;
    } else
    {
        int rlen = strlen(s);

        if(rlen > MAX_ANSISTRING_LENGTH){
            rlen = MAX_ANSISTRING_LENGTH;
        }

        result.len = rlen;
        memcpy(result.str, s, rlen);
    }

    return result;
}

astring fpcrtl_str2astr(const string255 s)
{
    astring result;

    result.str255 = s;
    result.len = s.len;

    return result;
}

string255 fpcrtl_astr2str(const astring s)
{
    string255 result;

    result = s.str255;
    result.len = s.len > 255 ? 255 : s.len;

    return result;
}

char __pcharBuf[256];

char* fpcrtl__pchar__vars(const string255 * s)
{
    memcpy(__pcharBuf, &s->s[1], s->len);
    __pcharBuf[s->len] = 0;
    return __pcharBuf;
}

char* fpcrtl__pcharA__vars(astring * s)
{
    if(s->len == MAX_ANSISTRING_LENGTH)
        --s->len;

    s->s[s->len + 1] = 0;
    return &s->s[1];
}

#ifdef EMSCRIPTEN
GLenum glewInit()
{
    return GLEW_OK;
}
#endif
