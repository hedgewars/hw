system;
{This file contains functions that are external}
type
    uinteger = uinteger;
    Integer = integer;
    LongInt = integer;
    LongWord = uinteger;
    Cardinal = uinteger;
    PtrInt = integer;
    SizeInt = PtrInt;
    Word = uinteger;
    Byte = integer;
    SmallInt = integer;
    ShortInt = integer;
    Int64 = integer;
    QWord = uinteger;
    GLint = integer;
    GLsizei = integer;
    GLuint = integer;
    GLenum = integer;

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
    PWideChar = ^WideChar;

    PByte = ^Byte;
    PWord = ^Word;
    PLongInt = ^LongInt;
    PLongWord = ^LongWord;
    PInteger = ^Integer;

    Handle = integer;

    png_structp = pointer;
    png_size_t = integer;

var
    false, true: boolean;

    ord, Succ, Pred : function : integer;
    inc, dec, Low, High, Lo, Hi : function : integer;

    IOResult : integer;
    exit, break, halt, continue : procedure;

    TextFile, File : Handle;
    FileMode : integer;
    exitcode : integer;
    stdout, stderr : Handle;

    sqrt, cos, sin: function : float;
    pi : float;

    sizeof : function : integer;

    glGetString : function : pchar;

    glBegin, glBindTexture, glBlendFunc, glClear, glClearColor,
    glColor4ub, glColorMask, glColorPointer, glDeleteTextures,
    glDisable, glDisableClientState, glDrawArrays, glEnable,
    glEnableClientState, glEnd, glGenTextures, glGetIntegerv,
    glHint, glLineWidth, glLoadIdentity, glMatrixMode, glPopMatrix,
    glPushMatrix, glReadPixels, glRotatef, glScalef, glTexCoord2f,
    glTexCoordPointer, glTexImage2D, glTexParameterf,
    glTexParameteri, glTranslatef, glVertex2d, glVertexPointer,
    glViewport, glext_LoadExtension, glDeleteRenderbuffersEXT,
    glDeleteFramebuffersEXT, glGenFramebuffersEXT,
    glGenRenderbuffersEXT, glBindFramebufferEXT,
    glBindRenderbufferEXT, glRenderbufferStorageEXT,
    glFramebufferRenderbufferEXT, glFramebufferTexture2DEXT,
    glUniformMatrix4fv, glVertexAttribPointer, glCreateShader,
    glShaderSource, glCompileShader, glGetShaderiv, glGetShaderInfoLog,
    glCreateProgram, glAttachShader, glBindAttribLocation, glLinkProgram,
    glDeleteShader, glGetProgramiv, glGetProgramInfoLog, glUseProgram,
    glUniform1i, glGetUniformLocation, glEnableVertexAttribArray,
    glGetError, glDeleteProgram, glDeleteBuffers,
    glGenBuffers, glBufferData, glBindBuffer, glewInit,
    glUniform4f, glDisableVertexAttribArray, glTexEnvi,
    glLoadMatrixf, glMultMatrixf, glGetFloatv: procedure;

    GL_BGRA, GL_BLEND, GL_CLAMP_TO_EDGE, GL_COLOR_ARRAY,
    GL_COLOR_BUFFER_BIT, GL_DEPTH_BUFFER_BIT, GL_DEPTH_COMPONENT,
    GL_DITHER, GL_EXTENSIONS, GL_FALSE, GL_FASTEST, GL_LINEAR,
    GL_LINE_LOOP, GL_LINES, GL_LINE_SMOOTH, GL_LINE_STRIP,
    GL_MAX_TEXTURE_SIZE, GL_MODELVIEW, GL_ONE_MINUS_SRC_ALPHA,
    GL_PERSPECTIVE_CORRECTION_HINT, GL_PROJECTION, GL_QUADS,
    GL_RENDERER, GL_RGB, GL_RGB8, GL_RGBA, GL_RGBA8, GL_SRC_ALPHA, GL_TEXTURE_2D,
    GL_TEXTURE_COORD_ARRAY, GL_TEXTURE_MAG_FILTER,
    GL_TEXTURE_MIN_FILTER, GL_TEXTURE_PRIORITY, GL_TEXTURE_WRAP_S,
    GL_TEXTURE_WRAP_T, GL_TRIANGLE_STRIP, GL_TRIANGLE_FAN, GL_TRUE, GL_VENDOR,
    GL_VERSION, GL_VERTEX_ARRAY, GLenum,  GL_FRAMEBUFFER_EXT,
    GL_RENDERBUFFER_EXT, GL_DEPTH_ATTACHMENT_EXT,
    GL_COLOR_ATTACHMENT0_EXT, GL_FLOAT, GL_UNSIGNED_BYTE, GL_COMPILE_STATUS,
    GL_INFO_LOG_LENGTH, GL_LINK_STATUS, GL_VERTEX_SHADER, GL_FRAGMENT_SHADER,
    GL_NO_ERROR, GL_ARRAY_BUFFER, GL_STATIC_DRAW, GLEW_OK,
    GL_AUX_BUFFERS, GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE, GL_ADD,
    GL_MODELVIEW_MATRIX: integer;

    TThreadId : function : integer;

    _strconcat, _strappend, _strprepend, _chrconcat : function : string;
    _strcompare, _strncompare, _strcomparec, _strncompareA : function : boolean;
    _strconcatA, _strappendA : function : ansistring;

    png_structp, png_set_write_fn, png_get_io_ptr,
    png_get_libpng_ver, png_create_write_struct,
    png_create_info_struct, png_destroy_write_struct,
    png_write_row, png_set_ihdr, png_write_info,
    png_write_end : procedure;

    clear_filelist_hook, add_file_hook, idb_loader_hook, mainloop_hook, drawworld_hook : procedure;
    SDL_InitPatch : procedure;

    PHYSFS_init, PHYSFS_deinit, PHYSFS_mount, PHYSFS_readBytes, PHYSFS_writeBytes, PHYSFS_read : function : LongInt;
    PHYSFSRWOPS_openRead, PHYSFSRWOPS_openWrite, PHYSFS_openRead, PHYSFS_openWrite : function : pointer;
    PHYSFS_eof, PHYSFS_close, PHYSFS_exists, PHYSFS_mkdir, PHYSFS_flush, PHYSFS_setWriteDir : function : boolean;
    PHYSFS_getLastError : function : PChar;
    PHYSFS_enumerateFiles : function : PPChar;
    PHYSFS_freeList : procedure;

    hedgewarsMountPackages, physfsReaderSetBuffer, hedgewarsMountPackage : procedure;
    physfsReader : function : pointer;
