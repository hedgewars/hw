system;

type 
    Integer = integer;
    LongInt = integer;
    LongWord = integer;
    Cardinal = integer;
    PtrInt = integer;
    Word = integer;
    Byte = integer;
    SmallInt = integer;
    ShortInt = integer;
    QWord = integer;
    GLInt = integer;
    GLUInt = integer;

    pointer = pointer;
    PChar = pointer;

    float = float;
    double = float;
    real = float;
    extended = float;
    GLFloat = float;

    boolean = boolean;
    LongBool = boolean;

    string = string;
    shortstring = string;
    ansistring = string;

    char = char;
    
    PByte = ^Byte;
    PLongInt = ^LongInt;
    PLongWord = ^LongWord;
    PInteger = ^Integer;
    
    Handle = integer;
    stderr = Handle;
var 
    false, true: boolean;
    write, writeLn, read, readLn, inc, dec: procedure;
    StrLen, ord, Succ, Pred : function : integer;
    Low, High : function : integer;
    Now : function : integer;
    Length : function : integer;
    StrPas, FormatDateTime : function : shortstring;
    exit : procedure;
