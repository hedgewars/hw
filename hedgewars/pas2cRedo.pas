redo;
{This file contains functions that are re-implemented}
{pas2c will add prefix fpcrtl_ to all these functions}
type
    uinteger = uinteger;
    Integer = integer;
    LongInt = integer;
    LongWord = uinteger;
    Cardinal = uinteger;
    PtrInt = integer;
    Word = uinteger;
    Byte = integer;
    SmallInt = integer;
    ShortInt = integer;
    Int64 = integer;
    QWord = uinteger;
    GLint = integer;
    GLuint = integer;
    int = integer;
    size_t = integer;

    pointer = pointer;

    float = float;
    single = float;
    double = float;
    real = float;
    extended = float;
    GLfloat = float;

    boolean = boolean;
    LongBool = boolean;

    string = string;
    shortstring = string;
    ansistring = string;
    widechar = string;

    char = char;
    PChar = ^char;
    PPChar = ^Pchar;

    PByte = ^Byte;
    PLongInt = ^LongInt;
    PLongWord = ^LongWord;
    PInteger = ^Integer;

    Handle = integer;

var
    write, writeLn, read, readLn, flush, CreateDir: procedure;

    halt:procedure;

    GetEnumName:function:shortstring;
    TypeInfo:function:Integer;

    lo:function:Integer;

    init:procedure;

    StrLen:function : integer;
    odd, even : function : boolean;

    Length : function : integer;

    Now : function : integer;

    new, dispose, FillChar, Insert, Delete, Move : procedure;

    trunc, round, ceil : function : integer;
    abs, sqr : function : integer;

    StrPas, FormatDateTime, copy, str, PosS, LowerCase : function : shortstring;
    pos : function : integer;
    StrToInt : function : integer;
    SetLength, SetLengthA, val, StrDispose, StrCopy : procedure;
    _pchar, _pcharA, StrAlloc : function : PChar;
    pchar2str, astr2str : function : string;
    pchar2astr, str2astr : function : ansistring;
    memcpy : procedure;
    StrLength : function : integer;

     min, max:function:integer;
    assign, rewrite, rewrite_2, reset, reset_2, flush, BlockWrite, BlockRead, close : procedure;
    FileExists, DirectoryExists, eof : function : boolean;

    ParamCount : function : integer;
    ParamStr : function : string;

    arctan2, power: function : float;

    //TypeInfo, GetEnumName : function : shortstring;

    UTF8ToUnicode, WrapText: function : shortstring;

    GetMem : function : pointer;
    FreeMem : procedure;

    BeginThread, ThreadSwitch : procedure;
    InterlockedIncrement, InterlockedDecrement : procedure;

    random : function : integer;
    randomize : procedure;

    Assigned : function : boolean;

    //EnumToStr : function : string;

    initParams : procedure;

    Load_GL_VERSION_2_0 : procedure;

    GetCurrentDir : function : PChar;

