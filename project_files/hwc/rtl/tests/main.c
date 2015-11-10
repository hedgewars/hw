#if 0
#include <stdio.h>
#include "fpcrtl.h"
#include "fileio.h"

string255 t = STRINIT("test");
string255 Pathz[1] = {STRINIT(".")};
//int ptCurrTheme = 0;
string255 cThemeCFGFilename = STRINIT("theme.cfg");
const string255 __str79 = STRINIT("object");
string255 c1 = STRINIT("=");
string255 c2 = STRINIT("\x2c");
string255 c3 = STRINIT("\x2f");

typedef struct __TResourceList {
            Integer count;
            string255 files[500 + 1];
} TResourceList;

TResourceList readThemeCfg_0()
{
    TResourceList readthemecfg_result;
    string255 s;
    string255 key;
    TextFile f;
    Integer i;
    TResourceList result;

    int t = 0;

    s = _strconcat(_strappend(Pathz[ptCurrTheme], '\x2f'), cThemeCFGFilename);

    assign(&f, s);

    reset(&f);

    if (f.fp == NULL) {
      readthemecfg_result.count = 0;
      return readthemecfg_result;
    }

    result.count = 0;
    while (!eof(&f)) {
        readLnS(&f, &s);

        if ((Length(s)) == (0)) {
            continue;
        }
        if ((s.s[1]) == ('\x3b')) {
            continue;
        }

        i = pos(c1, s);

        key = fpcrtl_trim(fpcrtl_copy(s, 1, i - 1));

        fpcrtl_delete(&s, 1, i);

        if (_strcompare(key, __str79)) {
            i = pos(c2, s);
            result.files[result.count] = _strconcat(_strappend(Pathz[ptCurrTheme], '\x2f'), trim(copy(s, 1, i - 1)));
            ++result.count;
        }
    }

    close(&f);
    readthemecfg_result = result;
    return readthemecfg_result;
}

int main(int argc, char** argv)
{
    int i;

    TResourceList result = readThemeCfg_0();
    for(i = 0; i < result.count; i++) {
        printf("%s\n", result.files[i].str);
    }
}
#endif
