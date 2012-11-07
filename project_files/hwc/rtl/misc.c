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
    //printf("str1 = %d, %d\n", str1.len, strlen(str1.str));
    //printf("str2 = %d, %d\n", str2.len, strlen(str2.str));

#ifdef FPCRTL_DEBUG
    if(str1.len + (int)(str2.len) > 255){
        printf("String overflow\n");
        printf("str1(%d): %s\nstr2(%d): %s\n", str1.len, str1.str, str2.len, str2.str);
        printf("String will be truncated.\n");

        strbuf[0] = 0;
        strcpy(strbuf, str1.str);
        strcat(strbuf, str2.str);
        memcpy(str1.str, strbuf, 255);
        str1.str[254] = 0;

        return str1;
    }
#endif

    memcpy(&(str1.str[str1.len]), str2.str, str2.len);
    str1.str[str1.len + str2.len] = 0;
    str1.len += str2.len;

    return str1;
}

string255 fpcrtl_strappend(string255 s, char c)
{
    s.str[s.len] = c;
    s.str[s.len + 1] = 0;
    s.len ++;

    return s;
}

string255 fpcrtl_strprepend(char c, string255 s)
{
    FIX_STRING(s);

    memmove(s.str + 1, s.str, s.len + 1); // also move '/0'
    s.str[0] = c;
    s.len++;

    return s;
}

string255 fpcrtl_chrconcat(char a, char b)
{
    string255 result;

    result.len = 2;
    result.str[0] = a;
    result.str[1] = b;
    result.str[2] = 0;

    return result;
}

bool fpcrtl_strcompare(string255 str1, string255 str2)
{
    //printf("str1 = %d, %d\n", str1.len, strlen(str1.str));
    //printf("str2 = %d, %d\n", str2.len, strlen(str2.str));
    FIX_STRING(str1);
    FIX_STRING(str2);

    if(strcmp(str1.str, str2.str) == 0){
        return true;
    }

    return false;
}

bool fpcrtl_strcomparec(string255 a, char b)
{
    FIX_STRING(a);

    if(a.len == 1 && a.str[0] == b){
        return true;
    }

    return false;
}

bool fpcrtl_strncompare(string255 a, string255 b)
{
    return !fpcrtl_strcompare(a, b);
}

//char* fpcrtl_pchar(string255 s)
//{
//    return s.str;
//}

string255 fpcrtl_pchar2str(char *s)
{
    string255 result;
    int t = strlen(s);

    if(t > 255){
        printf("pchar2str, length > 255\n");
        assert(0);
    }

    result.len = t;
    memcpy(result.str, s, t);
    result.str[t] = 0;

    return result;
}

string255 fpcrtl_make_string(const char* s) {
    string255 result;
    strcpy(result.str, s);
    result.len = strlen(s);
    return result;
}

#ifdef EMSCRIPTEN
GLenum glewInit()
{
    return GLEW_OK;
}
#endif
