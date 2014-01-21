
#include "pas2c.h"

#include "fpcrtl.h"

char Pathz[1][128] = {"./"};
int ptCurrTheme = 0;
cThemeCFGFilename = "theme.cfg";
const string255 __str79 = STRINIT("object");

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
    s = _strconcat(_strappend(Pathz[ptCurrTheme], '\x2f'), cThemeCFGFilename);

    assign(f, s);
    FileMode = 0;
    reset(f);
    result.count = 0;
    while(!eof(f))
    {
        readLnS(f, s);
        if((Length(s)) == (0))
        {
            continue;
        }
        if((s.s[1]) == ('\x3b'))
        {
            continue;
        }
        i = pos('\x3d', s);
        key = trim(copy(s, 1, i - 1));
        delete(s, 1, i);
        if(_strcompare(key, __str79))
        {
            i = pos('\x2c', s);
            result.files[result.count] = _strconcat(_strappend(Pathz[ptCurrTheme], '\x2f'), trim(copy(s, 1, i - 1)));
            ++result.count;
        }
    }
    close(f);
    readthemecfg_result = result;
    return readthemecfg_result;
};

int main(int argc, char** argv)
{
    readThemeCfg_0();
}
