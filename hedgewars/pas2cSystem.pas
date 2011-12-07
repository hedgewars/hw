system;

type 
    LongInt = integer;
    LongWord = integer;
    Cardinal = integer;
    PtrInt = integer;

    pointer = pointer;
    PChar = pointer;

    double = float;
    real = float;
    float = float;

    boolean = boolean;
    LongBool = boolean;

    string = string;
    shortstring = string;
    ansistring = string;

    char = char;
var 
    false, true: boolean;
    write, writeln, read, readln: procedure;
    strlen : function : integer;
