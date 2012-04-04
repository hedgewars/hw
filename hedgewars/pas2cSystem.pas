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
    gl_unsigned_byte = integer;
    Int = integer;

    pointer = pointer;
    PChar = pointer;

    float = float;
    single = float;
    double = float;
    real = float;
    extended = float;
    GLFloat = float;
    gl_float = float;

    boolean = boolean;
    LongBool = boolean;

    string = string;
    shortstring = string;
    ansistring = string;
    widechar = string;

    char = char;
    
    PByte = ^Byte;
    PLongInt = ^LongInt;
    PLongWord = ^LongWord;
    PInteger = ^Integer;
    
    Handle = integer;
    stderr = Handle;

var 
    false, true: boolean;
    
    write, writeLn, read, readLn: procedure;
    
    StrLen, ord, Succ, Pred : function : integer;
    inc, dec, Low, High, Lo, Hi : function : integer;
    odd, even : function : boolean;

    Now : function : integer;
    Length : function : integer;
    SetLength, val : procedure;

    new, dispose, FillChar, Move : procedure;

    trunc, round : function : integer;
    Abs, Sqr : function : integer;

    StrPas, FormatDateTime, copy, delete, str, pos, trim : function : shortstring;

    assign, rewrite, reset, flush, BlockWrite, BlockRead, close : procedure;
    IOResult : function : integer;
    exit, break, halt, continue : procedure;
    TextFile, file : Handle;
    FileMode : integer;
    FileExists, DirectoryExists, eof : function : boolean;
    ExtractFileName : function : string;
    exitcode : integer;
    
    ParamCount : function : integer;
    ParamStr : function : string;

    sqrt, arctan2, pi, cos, sin, power : function : float;

    TypeInfo, GetEnumName : function : shortstring;

    UTF8ToUnicode, WrapText: function : shortstring;

    sizeof : function : integer;

    GetMem : function : pointer;
    FreeMem : procedure;
    
    gl_texture_2d, glbindtexture, gltexparameterf, gl_rgba, 
    glteximage2d, glvertexpointer, gltexcoordpointer,
    gl_triangle_fan, gldrawarrays, glpushmatrix, glpopmatrix,
    gltranslatef, glscalef, glrotatef, gldisable, glenable,
    gl_line_smooth, gllinewidth, gl_lines, gl_line_loop,
    glcolor4ub, gl_texture_wrap_s, gltexparameteri,
    gl_texture_wrap_t, gl_texture_min_filter,
    gl_linear, gl_texture_mag_filter, glgentextures,
    gldeletetextures, glreadpixels, glclearcolor,
    gl_line_strip, gldeleterenderbuffersext,
    gldeleteframebuffersext, glext_loadextension,
    gl_max_texture_size, glgetintegerv, gl_renderer,
    glgetstring, gl_vendor, gl_version, glgenframebuffersext,
    glbindframebufferext, glgenrenderbuffersext,
    glbindrenderbufferext, glrenderbufferstorageext,
    glframebufferrenderbufferext, glframebuffertexture2dext,
    gl_framebuffer_ext, gl_depth_component, 
    gl_depth_attachment_ext, gl_renderbuffer_ext, gl_rgba8,
    gl_color_attachment0_ext, gl_modelview, gl_blend,
    gl_src_alpha, gl_one_minus_src_alpha,  
    gl_perspective_correction_hint, gl_fastest,
    gl_dither, gl_vertex_array, gl_texture_coord_array,
    glviewport, glloadidentity, glmatrixmode, glhint,
    glblendfunc, glenableclientstate, gl_color_buffer_bit,
    glclear : procedure;

    TThreadId : function : integer;
    BeginThread, ThreadSwitch : procedure;
    InterlockedIncrement, InterlockedDecrement : procedure;
    
    random : function : integer;
    randomize : procedure;
    
    Assigned : function : boolean;
    

