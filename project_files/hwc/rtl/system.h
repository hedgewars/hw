#ifndef SYSTEM_H_
#define SYSTEM_H_

#include <stdlib.h>
#include <time.h>
#include "Types.h"
#include "misc.h"

extern double pi;

typedef TDate* PDate;

// dimension info for dynamic arrays
typedef struct {
    int dim;
    int a[4]; // at most 4
} fpcrtl_dimension_t;

/*
 * Copy returns a string which is a copy if the Count characters in S, starting at position Index.
 * If Count is larger than the length of the string S, the result is truncated.
 * If Index is larger than the length of the string S, then an empty string is returned.
 * Index is 1-based.
 */
string255   fpcrtl_copy(string255 s, Integer Index, Integer Count);
astring     fpcrtl_copyA(astring s, Integer Index, Integer Count);

/*
 * Insert a shortstring in another at a specified index
 */
void        __attribute__((overloadable))                   fpcrtl_insert__vars(string255 *src, string255 *dst, SizeInt index);
void        __attribute__((overloadable))                   fpcrtl_insert__vars(astring *src, astring *dst, SizeInt index);

#define     fpcrtl_insert(src, dst, index)                  fpcrtl_insert__vars(&(src), &(dst), index);
#define     fpcrtl_Insert                                   fpcrtl_insert

/*
 * Delete removes Count characters from string S, starting at position Index.
 * All characters after the deleted characters are shifted Count positions to the left,
 * and the length of the string is adjusted.
 */
#define     fpcrtl_delete(s, index, count)                  fpcrtl_delete__vars(&(s), index, count)
void        __attribute__((overloadable))                   fpcrtl_delete__vars(string255 *s, SizeInt index, SizeInt count);
void        __attribute__((overloadable))                   fpcrtl_delete__vars(astring *s, SizeInt index, SizeInt count);
#define     fpcrtl_Delete                                   fpcrtl_delete

string255   fpcrtl_floatToStr(double n);

/*
 * Move data from one location in memory to another
 */
void        fpcrtl_move__vars(void *src, void *dst, SizeInt count);
#define     fpcrtl_move(src, dst, count)                    fpcrtl_move__vars(&(src), &(dst), count);
#define     fpcrtl_Move                                     fpcrtl_move

Integer     __attribute__((overloadable))                   fpcrtl_pos(Char c, string255 str);
Integer     __attribute__((overloadable))                   fpcrtl_pos(string255 substr, string255 str);
Integer     __attribute__((overloadable))                   fpcrtl_pos(string255 substr, astring str);
Integer     __attribute__((overloadable))                   fpcrtl_pos(Char c, astring str);

Integer     fpcrtl_length(string255 s);
#define     fpcrtl_Length                                   fpcrtl_length
Integer     fpcrtl_lengthA(astring s);
#define     fpcrtl_LengthA                                  fpcrtl_lengthA

#define     fpcrtl_SetLengthA(s, l)                         do{(s).len = (l);}while(0)

#define     fpcrtl_sqr(x)                                   ((x) * (x))

#define     fpcrtl_odd(x)                                   ((x) % 2 != 0 ? true : false)

#define     fpcrtl_StrLen                                   strlen

#define     SizeOf                                          sizeof

string255   fpcrtl_lowerCase(string255 s);
#define     fpcrtl_LowerCase                                fpcrtl_lowerCase

void        fpcrtl_fillChar__vars(void *x, SizeInt count, Byte value);
#define     fpcrtl_fillChar(x, count, value)                fpcrtl_fillChar__vars(&(x), count, value)
#define     fpcrtl_FillChar                                 fpcrtl_fillChar

void        fpcrtl_new__vars(void **p, int size);
#define     fpcrtl_new(a)                                   fpcrtl_new__vars((void **)&(a), sizeof(*(a)))

#define     fpcrtl_dispose                                  free

#define     fpcrtl_freeMem(p, size)                         free(p)
#define     fpcrtl_FreeMem(p, size)                         free(p)

#define     fpcrtl_getMem(size)                             malloc(size)
#define     fpcrtl_GetMem                                   fpcrtl_getMem

#define     fpcrtl_assigned(p)                              ((p) != NULL)
#define     fpcrtl_Assigned                                 fpcrtl_assigned

Integer     fpcrtl_trunc(extended n);
Integer     fpcrtl_ceil(extended n);

#define     fpcrtl_val(s, a)                                fpcrtl_val__vars(s, &(a))
void        __attribute__((overloadable))                   fpcrtl_val__vars(string255 s, LongInt *a);
void        __attribute__((overloadable))                   fpcrtl_val__vars(string255 s, Byte *a);
void        __attribute__((overloadable))                   fpcrtl_val__vars(string255 s, LongWord *a);

#define     fpcrtl_randomize()                              srand(time(NULL))

/*
 * Random returns a random number larger or equal to 0 and strictly less than L
 */
LongInt     fpcrtl_random(LongInt l);

string255   fpcrtl_paramStr(LongInt);
#define     fpcrtl_ParamStr                                 fpcrtl_paramStr

/*
 * Str returns a string which represents the value of X. X can be any numerical type.
 */
#define     fpcrtl_str(x, s)                                fpcrtl_str__vars(x, &(s))
void        __attribute__((overloadable))                   fpcrtl_str__vars(float x, string255 *s);
void        __attribute__((overloadable))                   fpcrtl_str__vars(double x, string255 *s);
void        __attribute__((overloadable))                   fpcrtl_str__vars(uint8_t x, string255 *s);
void        __attribute__((overloadable))                   fpcrtl_str__vars(int8_t x, string255 *s);
void        __attribute__((overloadable))                   fpcrtl_str__vars(uint16_t x, string255 *s);
void        __attribute__((overloadable))                   fpcrtl_str__vars(int16_t x, string255 *s);
void        __attribute__((overloadable))                   fpcrtl_str__vars(uint32_t x, string255 *s);
void        __attribute__((overloadable))                   fpcrtl_str__vars(int32_t x, string255 *s);
void        __attribute__((overloadable))                   fpcrtl_str__vars(uint64_t x, string255 *s);
void        __attribute__((overloadable))                   fpcrtl_str__vars(int64_t x, string255 *s);

void        fpcrtl_interlockedIncrement__vars(int *i);
void        fpcrtl_interlockedDecrement__vars(int *i);

#define     fpcrtl_interlockedIncrement(i)                  fpcrtl_interlockedIncrement__vars(&(i))
#define     fpcrtl_interlockedDecrement(i)                  fpcrtl_interlockedDecrement__vars(&(i))

#define     fpcrtl_InterlockedIncrement                     fpcrtl_interlockedIncrement
#define     fpcrtl_InterlockedDecrement                     fpcrtl_interlockedDecrement

void        fpcrtl_init(int argc, char** argv);

int         fpcrtl_paramCount();
#define     fpcrtl_ParamCount                               fpcrtl_paramCount

string255   fpcrtl_paramStr(int i);
#define     fpcrtl_ParamStr                                 fpcrtl_paramStr

int         fpcrtl_UTF8ToUnicode(PWideChar dest, PChar src, SizeInt maxLen);

// #define     fpcrtl_halt(t)                                  assert(0)
#define     fpcrtl_halt(t)                                  exit(t)

#define     fpcrtl_Load_GL_VERSION_2_0()                    1

uint32_t    __attribute__((overloadable))                   fpcrtl_lo(uint64_t);
#define     fpcrtl_Lo                                       fpcrtl_lo

#define     __SET_LENGTH2(arr, d, b) do{\
                d.dim = 1;\
                arr = realloc(arr, b * sizeof(typeof(*arr)));\
                d.a[0] = b;\
            }while(0)

#define     SET_LENGTH2(arr, b)                             __SET_LENGTH2(arr, arr##_dimension_info, (b))

#define     __SET_LENGTH3(arr, d, b, c) do{\
                d.dim = 2;\
                for (int i = 0; i < d.a[0]; i++) {\
                    arr[i] = realloc(arr[i], c * sizeof(typeof(**arr)));\
                }\
                if (d.a[0] > b) {\
                    for (int i = b; i < d.a[0]; i++) {\
                        free(arr[i]);\
                    }\
                    arr = realloc(arr, b * sizeof(typeof(*arr)));\
                } else if (d.a[0] < b) {\
                    arr = realloc(arr, b * sizeof(typeof(*arr)));\
                    for (int i = d.a[0]; i < b; i++) {\
                        arr[i] = malloc(c * sizeof(typeof(**arr)));\
                        memset(arr[i], 0, c * sizeof(typeof(**arr)));\
                    }\
                }\
                d.a[0] = b;\
                d.a[1] = c;\
            }while(0)

#define     SET_LENGTH3(arr, b, c)                          __SET_LENGTH3(arr, arr##_dimension_info, (b), (c))

#define     fpcrtl_SetLength(...)                           macro_dispatcher(SET_LENGTH, __VA_ARGS__)(__VA_ARGS__)

#endif /* SYSTEM_H_ */
