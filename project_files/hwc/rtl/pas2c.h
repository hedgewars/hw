#pragma once

#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>
#include <wchar.h>
#include <math.h>

#define MAX_PARAMS	64

typedef union string255_
    {
        struct {
            char s[257];
        };
        struct {
            unsigned char len;
            char str[256];
        };
    } string255;
typedef struct string192_
    {
        char s[193];
    } string192;
typedef struct string31_
    {
        char s[32];
    } string31;
typedef struct string15_
    {
        char s[16];
    } string15;

typedef string255 shortstring;
typedef string255 ansistring;

typedef uint8_t Byte;
typedef int8_t ShortInt;
typedef uint16_t Word;
typedef int16_t SmallInt;
typedef uint32_t LongWord;
typedef int32_t LongInt;
typedef uint64_t QWord;
typedef int64_t Int64;
typedef LongWord Cardinal;

typedef LongInt Integer;
typedef float extended;
typedef float real;
typedef float single;

typedef bool boolean;
typedef int LongBool;

typedef void * pointer;
typedef Byte * PByte;
typedef char * PChar;
typedef LongInt * PLongInt;
typedef LongWord * PLongWord;
typedef Integer * PInteger;
typedef int PtrInt;
typedef wchar_t widechar;
typedef wchar_t* PWideChar;
typedef char Char;
typedef LongInt SizeInt;
typedef char ** PPChar;
typedef Word* PWord;

string255 _strconcat(string255 a, string255 b);
string255 _strappend(string255 s, char c);
string255 _strprepend(char c, string255 s);
string255 _chrconcat(char a, char b);
bool _strcompare(string255 a, string255 b);
bool _strcomparec(string255 a, char b);
bool _strncompare(string255 a, string255 b);


#define STRINIT(a) {.len = sizeof(a) - 1, .str = a}


