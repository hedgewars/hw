#pragma once

#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>
#include <wchar.h>
#include <math.h>

#define MAX_PARAMS 64
#define MAX_ANSISTRING_LENGTH 16383

typedef union string255_
    {
        struct {
            unsigned char s[256];
        };
        struct {
            unsigned char len;
            unsigned char str[255];
        };
    } string255;

typedef union astring_
    {
        struct {
            uint16_t len;
        };
        struct {
            unsigned char _dummy2;
            unsigned char s[MAX_ANSISTRING_LENGTH + 1];
        };
        struct {
            unsigned char _dummy1;
            string255 str255;
        };
    } astring;

typedef string255 shortstring;

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
typedef ptrdiff_t PtrInt;
typedef wchar_t widechar;
typedef wchar_t* PWideChar;
typedef char Char;
typedef PtrInt SizeInt;
typedef char ** PPChar;
typedef Word* PWord;

string255 _strconcat(string255 a, string255 b);
string255 _strappend(string255 s, unsigned char c);
string255 _strprepend(unsigned char c, string255 s);
string255 _chrconcat(unsigned char a, unsigned char b);
bool _strcompare(string255 a, string255 b);
bool _strcomparec(string255 a, unsigned char b);
bool _strncompare(string255 a, string255 b);
bool _strncompareA(astring a, astring b);


#define STRINIT(a) {.len = sizeof(a) - 1, .str = a}
#define UNUSED(x) (void)(x)

