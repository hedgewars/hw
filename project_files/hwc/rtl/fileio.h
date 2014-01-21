#ifndef FILEIO_H_
#define FILEIO_H_

#include <stdio.h>
#include "Types.h"
#include "misc.h"

extern        int                                       FileMode;

typedef enum{
    IO_NO_ERROR = 0,
    IO_ERROR_DUMMY = 1
}io_result_t;

extern        io_result_t                               IOResult;

typedef struct{
    FILE        *fp;
    const char* mode;
    char        file_name[256];
    int         eof;
    int            record_len;
}file_wrapper_t;

typedef     file_wrapper_t*                             File;
typedef     File                                        Text;
typedef     Text                                        TextFile;

void        __attribute__((overloadable))               fpcrtl_readLn(File f);
#define     fpcrtl_readLn1(f)                           fpcrtl_readLn(f)

void        __attribute__((overloadable))               fpcrtl_readLn__vars(File f, Integer *i);
void        __attribute__((overloadable))               fpcrtl_readLn__vars(File f, LongWord *i);
void        __attribute__((overloadable))               fpcrtl_readLn__vars(File f, string255 *s);
#define     fpcrtl_readLn2(f, t)                        fpcrtl_readLn__vars(f, &(t))

#define     fpcrtl_readLn(...)                          macro_dispatcher(fpcrtl_readLn, __VA_ARGS__)(__VA_ARGS__)


void        fpcrtl_blockRead__vars(File f, void *buf, Integer count, Integer *result);
#define     fpcrtl_blockRead(f, buf, count, result)     fpcrtl_blockRead__vars(f, &(buf), count, &(result))
#define     fpcrtl_BlockRead                            fpcrtl_blockRead

#define     fpcrtl_assign(f, name)                      fpcrtl_assign__vars(&f, name)
void        fpcrtl_assign__vars(File *f, string255 name);

boolean     fpcrtl_eof(File f);

void        fpcrtl_reset1(File f);
void        fpcrtl_reset2(File f, Integer l);
#define     fpcrtl_reset1(f)                            fpcrtl_reset1(f)
#define     fpcrtl_reset2(f, l)                         fpcrtl_reset2(f, l)
#define     fpcrtl_reset(...)                           macro_dispatcher(fpcrtl_reset, __VA_ARGS__)(__VA_ARGS__)

void        fpcrtl_close(File f);

void        __attribute__((overloadable))               fpcrtl_rewrite(File f);
void        __attribute__((overloadable))               fpcrtl_rewrite(File f, Integer l);

void        __attribute__((overloadable))               fpcrtl_flush(Text f);
void        __attribute__((overloadable))               fpcrtl_flush(FILE *f);

void        __attribute__((overloadable))               fpcrtl_write(File f, string255 s);
void        __attribute__((overloadable))               fpcrtl_write(FILE *f, string255 s);
void        __attribute__((overloadable))               fpcrtl_writeLn(File f, string255 s);
void        __attribute__((overloadable))               fpcrtl_writeLn(FILE *f, string255 s);

void        fpcrtl_blockWrite__vars(File f, const void *buf, Integer count, Integer *result);
#define     fpcrtl_blockWrite(f, buf, count, result)    fpcrtl_blockWrite__vars(f, &(buf), count, &(result))
#define     fpcrtl_BlockWrite                           fpcrtl_blockWrite

bool        fpcrtl_directoryExists(string255 dir);
#define     fpcrtl_DirectoryExists                      fpcrtl_directoryExists

bool        fpcrtl_fileExists(string255 filename);
#define     fpcrtl_FileExists                           fpcrtl_fileExists

#endif /* FILEIO_H_ */
