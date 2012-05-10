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
    Int = integer;

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
    glclear, gldisableclientstate, gl_color_array,
    glcolorpointer, gl_depth_buffer_bit, gl_quads,
    glbegin, glend, gltexcoord2f, glvertex2d,
    gl_true, gl_false, glcolormask, gl_projection,
    gl_texture_priority, glenum, gl_clamp_to_edge,
    gl_extensions, gl_bgra : procedure;

    TThreadId : function : integer;
    BeginThread, ThreadSwitch : procedure;
    InterlockedIncrement, InterlockedDecrement : procedure;
    
    random : function : integer;
    randomize : procedure;
    
    Assigned : function : boolean;
    
    _strconcat, _strappend, _strprepend : function : string;
    _strcompare, _strncompare : function : boolean;

    png_structp, png_set_write_fn, png_get_io_ptr,
    png_get_libpng_ver, png_create_write_struct,
    png_create_info_struct, png_destroy_write_struct,
    png_write_row, png_set_ihdr, png_write_info,
    png_write_end : procedure;

    EnumToStr : function : string;
