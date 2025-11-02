/*
 * XXX: assume all files are text files
 */

#include "misc.h"
#include "fileio.h"
#include <string.h>
#include <stdlib.h>
#include <assert.h>
#include <sys/stat.h>
#include <unistd.h>

io_result_t IOResult;
int FileMode;
char cwd[1024];

static void init(File f) {
    f->fp = NULL;
    f->eof = 0;
    f->mode = NULL;
    f->record_len = 0;
}

void fpcrtl_assign__vars(File *f, string255 name) {
    FIX_STRING(name);
    *f = (File) malloc(sizeof(file_wrapper_t));
    strcpy((*f)->file_name, name.str);
    init(*f);
}

void fpcrtl_reset1(File f) {
    f->fp = fopen(f->file_name, "r");
    if (!f->fp) {
        IOResult = IO_ERROR_DUMMY;
        printf("Failed to open %s\n", f->file_name);
        return;
    } else {
#ifdef FPCRTL_DEBUG
        printf("Opened %s\n", f->file_name);
#endif
    }
    IOResult = IO_NO_ERROR;
    f->mode = "r";
}

void fpcrtl_reset2(File f, int l) {
    f->eof = 0;
    f->fp = fopen(f->file_name, "rb");
    if (!f->fp) {
        IOResult = IO_ERROR_DUMMY;
        printf("Failed to open %s\n", f->file_name);
        return;
    }
    IOResult = IO_NO_ERROR;
    f->mode = "rb";
    f->record_len = l;
}

void __attribute__((overloadable)) fpcrtl_rewrite(File f) {
    f->fp = fopen(f->file_name, "w+");
    if (!f->fp) {
        IOResult = IO_ERROR_DUMMY;
        return;
    }
    IOResult = IO_NO_ERROR;
    f->mode = "w+";
}

void __attribute__((overloadable)) fpcrtl_rewrite(File f, Integer l) {
    IOResult = IO_NO_ERROR;
    fpcrtl_rewrite(f);
    if (f->fp) {
        f->record_len = l;
    }
}

void fpcrtl_close(File f) {
    IOResult = IO_NO_ERROR;
    fclose(f->fp);
    free(f);
}

boolean fpcrtl_eof(File f) {
    IOResult = IO_NO_ERROR;
    if (f->eof || f->fp == NULL || feof(f->fp)) {
        return true;
    } else {
        return false;
    }
}

void __attribute__((overloadable)) fpcrtl_readLn(File f) {
    IOResult = IO_NO_ERROR;
    char line[256];
    if (fgets(line, sizeof(line), f->fp) == NULL) {
        f->eof = 1;
    }
    if (feof(f->fp)) {
        f->eof = 1;
    }
}

void __attribute__((overloadable)) fpcrtl_readLn__vars(File f, Integer *i) {
    string255 s;

    if (feof(f->fp)) {
        f->eof = 1;
        return;
    }

    fpcrtl_readLn__vars(f, &s);

    *i = atoi(s.str);
}

void __attribute__((overloadable)) fpcrtl_readLn__vars(File f, LongWord *i) {
    string255 s;

    if (feof(f->fp)) {
        f->eof = 1;
        return;
    }

    fpcrtl_readLn__vars(f, &s);

    *i = atoi(s.str);
}

void __attribute__((overloadable)) fpcrtl_readLn__vars(File f, string255 *s) {

    if (fgets(s->str, 255, f->fp) == NULL) {

        s->len = 0;
        s->str[0] = 0;

        f->eof = 1;
        return;
    }

    if (feof(f->fp)) {
        s->len = 0;
        f->eof = 1;
        return;
    }

    IOResult = IO_NO_ERROR;

    s->len = strlen(s->str);
    if ((s->len > 0) && (s->str[s->len - 1] == '\n')) {
        s->str[s->len - 1] = 0;
        s->len--;
    }
}

void __attribute__((overloadable)) fpcrtl_write(File f, string255 s) {
    FIX_STRING(s);
    fprintf(f->fp, "%s", s.str);
}

void __attribute__((overloadable)) fpcrtl_write(FILE *f, string255 s) {
    FIX_STRING(s);
    fprintf(f, "%s", s.str);
}

void __attribute__((overloadable)) fpcrtl_writeLn(File f, string255 s) {
    FIX_STRING(s);
    // filthy hack to write to stderr
    if (!f->fp)
        fprintf(stderr, "%s\n", s.str);
    else
        fprintf(f->fp, "%s\n", s.str);
}

void __attribute__((overloadable)) fpcrtl_writeLn(FILE *f, string255 s) {
    FIX_STRING(s);
    fprintf(f, "%s\n", s.str);
}

void fpcrtl_blockRead__vars(File f, void *buf, Integer count, Integer *result) {
    assert(f->record_len > 0);
    *result = fread(buf, f->record_len, count, f->fp);
}

/*
 * XXX: dummy blockWrite
 */
void fpcrtl_blockWrite__vars(File f, const void *buf, Integer count,
        Integer *result) {
    assert(f->record_len > 0);
    *result = fwrite(buf, f->record_len, count, f->fp);
}

bool fpcrtl_directoryExists(string255 dir) {

    struct stat st;
    FIX_STRING(dir);

    IOResult = IO_NO_ERROR;

#ifdef FPCRTL_DEBUG
    printf("Warning: directoryExists is called. This may not work when compiled to js.\n");
#endif

    if (stat(dir.str, &st) == 0) {
        return true;
    }

    return false;
}

bool fpcrtl_fileExists(string255 filename) {

    FIX_STRING(filename);

    IOResult = IO_NO_ERROR;

    FILE *fp = fopen(filename.str, "r");
    if (fp) {
        fclose(fp);
        return true;
    }
    return false;
}

char * fpcrtl_getCurrentDir(void) {

    IOResult = IO_NO_ERROR;

    if (getcwd(cwd, sizeof(cwd)) != NULL)
        return cwd;

    IOResult = IO_ERROR_DUMMY;
    return "";
}

void __attribute__((overloadable)) fpcrtl_flush(Text f) {
    fflush(f->fp);
}

void __attribute__((overloadable)) fpcrtl_flush(FILE *f) {
    fflush(f);
}

Int64 fpcrtl_fileSize(File f)
{
    assert(f->record_len > 0);

    IOResult = IO_NO_ERROR;
    int i = fseek(f->fp, 0, SEEK_END);
    if (i == -1) {
        IOResult = IO_ERROR_DUMMY;
        return -1;
    }
    long size = ftell(f->fp);
    if (size == -1) {
        IOResult = IO_ERROR_DUMMY;
        return -1;
    }
    return size / f->record_len;
}

bool fpcrtl_deleteFile(string255 filename)
{
    FIX_STRING(filename);

    int ret = remove(filename.str);
    if(ret == 0) {
       IOResult = IO_NO_ERROR;
       return true;
    } else {
       IOResult = IO_ERROR_DUMMY;
       return false;
    }
}

