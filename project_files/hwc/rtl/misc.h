#ifndef _FPCRTL_MISC_H_
#define _FPCRTL_MISC_H_

#include "pas2c.h"
#include <assert.h>
#include <stdbool.h>

#ifdef EMSCRIPTEN
#include <GL/gl.h>
#else
#include <GL/glew.h>
#endif

#define     VA_NUM_ARGS(...)                        VA_NUM_ARGS_IMPL(__VA_ARGS__, 5,4,3,2,1)
#define     VA_NUM_ARGS_IMPL(_1,_2,_3,_4,_5,N,...)  N

#define     macro_dispatcher(func, ...)             macro_dispatcher_(func, VA_NUM_ARGS(__VA_ARGS__))
#define     macro_dispatcher_(func, nargs)          macro_dispatcher__(func, nargs)
#define     macro_dispatcher__(func, nargs)         func ## nargs

#define     FPCRTL_DEBUG

#define     FIX_STRING(s)                           (s.str[s.len] = 0)

//#define fpcrtl_check_string(s)     do{ if(strlen((s).str) != (s).len){ \
//                                        printf("String %s internal inconsistency error. Length should be %d but actually is %d.\n", (s).str, strlen((s).str), (s).len); \
//                                        assert(0);\
//                                    }}while(0)

void        fpcrtl_assert(int);
void        fpcrtl_print_trace (void);

int         fpcrtl_round(double number);
void        fpcrtl_printf(const char* format, ...);

string255   fpcrtl_make_string(const char* s);

string255   fpcrtl_strconcat(string255 str1, string255 str2);
string255   fpcrtl_strappend(string255 s, char c);
string255   fpcrtl_strprepend(char c, string255 s);
string255   fpcrtl_chrconcat(char a, char b);

// return true if str1 == str2
bool        fpcrtl_strcompare(string255 str1, string255 str2);
bool        fpcrtl_strcomparec(string255 a, char b);
bool        fpcrtl_strncompare(string255 a, string255 b);

#define     fpcrtl__pchar(s)                        ((s).str)
string255   fpcrtl_pchar2str(char *s);

#define     fpcrtl_TypeInfo                         sizeof // dummy

#ifdef EMSCRIPTEN
#define     GLEW_OK                                 1
GLenum      glewInit();
#endif

#endif
