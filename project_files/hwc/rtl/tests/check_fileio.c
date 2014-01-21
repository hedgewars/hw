#include <check.h>
#include <stdlib.h>
#include <stdio.h>
#include "check_check.h"
#include "../src/fpcrtl.h"

typedef struct __TResourceList
{
    Integer count;
    string255 files[500 + 1];
} TResourceList;

string255 t = STRINIT("test");
string255 Pathz[1] =
{ STRINIT("../../") };
int ptCurrTheme = 0;
string255 cThemeCFGFilename = STRINIT("theme.cfg");
const string255 __str79 = STRINIT("object");
string255 c1 = STRINIT("=");
string255 c2 = STRINIT("\x2c");
string255 c3 = STRINIT("\x2f");

static string255 make_string(const char* str)
{
    string255 s;
    s.len = strlen(str);
    memcpy(s.str, str, s.len + 1);
    return s;
}

TResourceList readThemeCfg_0()
{
    TResourceList readthemecfg_result;
    string255 s;
    string255 key;
    TextFile f;
    Integer i;
    TResourceList res;

    s = _strconcat(_strappend(Pathz[ptCurrTheme], '\x2f'), cThemeCFGFilename);
    //umisc_log(s);

    fpcrtl_assign(f, s);

    FileMode = 0;
    fpcrtl_reset(f);

    res.count = 0;
    while (!(fpcrtl_eof(f)))
    {
        fpcrtl_readLnS(f, s);
        if ((fpcrtl_Length(s)) == (0))
        {
            continue;
        }
        if ((s.s[1]) == ('\x3b'))
        {
            continue;
        }
        i = fpcrtl_pos('\x3d', s);
        key = fpcrtl_trim(fpcrtl_copy(s, 1, i - 1));
        fpcrtl_delete(s, 1, i);
        if (_strcompare(key, __str79))
        {
            i = fpcrtl_pos('\x2c', s);
            res.files[res.count] = _strconcat(
                    _strappend(Pathz[ptCurrTheme], '\x2f'),
                    fpcrtl_trim(fpcrtl_copy(s, 1, i - 1)));
            ++res.count;
            //umisc_log(fpcrtl_trim(fpcrtl_copy(s, 1, i - 1)));
        }
    }
    fpcrtl_close(f);
    readthemecfg_result = res;
    return readthemecfg_result;
}

START_TEST(test_readthemecfg)
    {
        int i;
        TResourceList result;

        printf("-----Entering test readthemecfg-----\n");
        result = readThemeCfg_0();
        for (i = 0; i < result.count; i++)
        {
            printf("%s\n", result.files[i].str);
        }
        printf("-----Leaving test readthemecfg-----\n");
    }END_TEST

Suite* fileio_suite(void)
{
    Suite *s = suite_create("fileio");

    TCase *tc_core = tcase_create("Core");

    tcase_add_test(tc_core, test_readthemecfg);

    suite_add_tcase(s, tc_core);

    return s;
}
