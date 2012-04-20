#pragma once

#include <stdbool.h>

typedef union string255_
    {
        struct {
            char s[256];
        };
        struct {
            char len;
            char str[255];
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

typedef int SmallInt;
typedef int Word;
typedef int LongInt;
typedef int LongWord;
typedef int Byte;
typedef int Integer;
typedef long long int QWord;

typedef float extended;
typedef float real;

typedef bool boolean;

typedef void * pointer;
typedef Byte * PByte;
typedef char * PChar;
typedef LongInt * PLongInt;
typedef Integer * PInteger;

#define new(a) __new(a, sizeof(*(a)))
void __new(pointer p, int size);

#define dispose(a) __dispose(a, sizeof(*(a)))
void __dispose(pointer p, int size);

#define FillChar(a, b, c) __FillChar(&(a), b, c)

void __FillChar(pointer p, int size, char fill);
string255 _strconcat(string255 a, string255 b);

int Length(string255 a);
string255 copy(string255 a, int s, int l);
string255 delete(string255 a, int s, int l);

#define STRCONSTDECL(a, b) const string255 a = {.len = sizeof(b), .str = b}
