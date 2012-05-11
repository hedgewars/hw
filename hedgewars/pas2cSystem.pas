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
    GLint = integer;
    GLuint = integer;
    gl_unsigned_byte = integer;
    int = integer;

    pointer = pointer;

    float = float;
    single = float;
    double = float;
    real = float;
    extended = float;
    GLfloat = float;
    gl_float = float;

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
    stderr = Handle;

    png_structp = pointer;
    png_size_t = integer;

var 
    false, true: boolean;
    
    write, writeLn, read, readLn: procedure;
    
    StrLen, ord, Succ, Pred : function : integer;
    inc, dec, Low, High, Lo, Hi : function : integer;
    odd, even : function : boolean;

    Now : function : integer;

    new, dispose, FillChar, Move : procedure;

    trunc, round : function : integer;
    abs, sqr : function : integer;

    StrPas, FormatDateTime, copy, delete, str, pos, trim, LowerCase : function : shortstring;
    Length, StrToInt : function : integer;
    SetLength, val : procedure;
    _pchar : function : PChar;

    assign, rewrite, reset, flush, BlockWrite, BlockRead, close : procedure;
    IOResult : integer;
    exit, break, halt, continue : procedure;
    TextFile, file : Handle;
    FileMode : integer;
    FileExists, DirectoryExists, eof : function : boolean;
    ExtractFileName : function : string;
    exitcode : integer;
    
    ParamCount : function : integer;
    ParamStr : function : string;

    sqrt, arctan2, cos, sin, power : function : float;
    pi : float;

    TypeInfo, GetEnumName : function : shortstring;

    UTF8ToUnicode, WrapText: function : shortstring;

    sizeof : function : integer;

    GetMem : function : pointer;
    FreeMem : procedure;
   
    glGetString : function : pchar;
 
    glBegin, glBindTexture, glBlendFunc, glClear, glClearColor,
    glColor4ub, glColorMask, glColorPointer, glDeleteTextures,
    glDisable, glDisableClientState, glDrawArrays, glEnable,
    glEnableClientState, glEnd, glGenTextures, glGetIntegerv,
    glHint, glLineWidth, glLoadIdentity, glMatrixMode, glPopMatrix,
    glPushMatrix, glReadPixels, glRotatef, glScalef, glTexCoord2f,
    glTexCoordPointer, glTexImage2D, glTexParameterf,
    glTexParameteri, glTranslatef, glVertex2d, glVertexPointer,
    glViewport : procedure;

    GL_BGRA, GL_BLEND, GL_CLAMP_TO_EDGE, GL_COLOR_ARRAY,
    GL_COLOR_BUFFER_BIT, GL_DEPTH_BUFFER_BIT, GL_DEPTH_COMPONENT,
    GL_DITHER, GL_EXTENSIONS, GL_FALSE, GL_FASTEST, GL_LINEAR,
    GL_LINE_LOOP, GL_LINES, GL_LINE_SMOOTH, GL_LINE_STRIP,
    GL_MAX_TEXTURE_SIZE, GL_MODELVIEW, GL_ONE_MINUS_SRC_ALPHA,
    GL_PERSPECTIVE_CORRECTION_HINT, GL_PROJECTION, GL_QUADS,
    GL_RENDERER, GL_RGBA, GL_RGBA8, GL_SRC_ALPHA, GL_TEXTURE_2D,
    GL_TEXTURE_COORD_ARRAY, GL_TEXTURE_MAG_FILTER,
    GL_TEXTURE_MIN_FILTER, GL_TEXTURE_PRIORITY, GL_TEXTURE_WRAP_S,
    GL_TEXTURE_WRAP_T, GL_TRIANGLE_FAN, GL_TRUE, GL_VENDOR,
    GL_VERSION, GL_VERTEX_ARRAY : integer;

    TThreadId : function : integer;
    BeginThread, ThreadSwitch : procedure;
    InterlockedIncrement, InterlockedDecrement : procedure;
    
    random : function : integer;
    randomize : procedure;
    
    Assigned : function : boolean;
    
    _strconcat, _strappend, _strprepend : function : string;
    _strcompare, _strncompare, _strcomparec : function : boolean;

    png_structp, png_set_write_fn, png_get_io_ptr,
    png_get_libpng_ver, png_create_write_struct,
    png_create_info_struct, png_destroy_write_struct,
    png_write_row, png_set_ihdr, png_write_info,
    png_write_end : procedure;

    EnumToStr : function : string;
function glGetString
