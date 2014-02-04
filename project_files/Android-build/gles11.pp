(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2011 Richard Deurwaarder <xeli@xelification.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 *)

{$mode objfpc}
unit gles11;
interface

{
  Automatically converted by H2Pas 1.0.0 from gl.hh
  The following command line parameters were used:
    -P
    -l
    GLESv1_CM
    -o
    gles11.pp
    -D
    gl.hh
}

  procedure initModule;
  procedure freeModule;

  const
    External_library='GLESv1_CM'; {Setup as you need}

  Type
 
//     khronos_int32_t = int32_t;
//     khronos_uint32_t = uint32_t;
//     khronos_int64_t = int64_t;
//     khronos_uint64_t = uint64_t;

  khronos_int32_t = longint;
  khronos_uint32_t = longword;
  khronos_int64_t = Int64;
  khronos_uint64_t = QWord;
  khronos_int8_t = char;
  khronos_uint8_t = byte;
  khronos_int16_t = smallint;
  khronos_uint16_t = word;
  khronos_intptr_t = longint;
  khronos_uintptr_t = dword;
  khronos_ssize_t = longint;
  khronos_usize_t = dword;
  khronos_float_t = single;

  GLvoid = pointer;
  GLenum = dword;
  GLboolean = byte;
  GLbitfield = dword;
  GLshort = smallint;
  GLint = longint;
  GLsizei = longint;
  GLushort = word;
  GLuint = dword;

  GLbyte = khronos_int8_t;
  GLubyte = khronos_uint8_t;
  GLfloat = khronos_float_t;
  GLclampf = khronos_float_t;
  GLfixed = khronos_int32_t;
  GLclampx = khronos_int32_t;
  GLintptr = khronos_intptr_t;
  GLsizeiptr = khronos_ssize_t;

  PGLboolean  = ^GLboolean;
  PGLfixed  = ^GLfixed;
  PGLfloat  = ^GLfloat;
  PGLint  = ^GLint;
  PGLuint  = ^GLuint;
  PGLvoid  = ^GLvoid;
  PGLubyte = ^GLubyte;
{$IFDEF FPC}
{$PACKRECORDS C}
{$ENDIF}

  const
//    GL_API = KHRONOS_APICALL;     
{$define KHRONOS_APIENTRY}  
     GL_DIRECT_TEXTURE_2D_QUALCOMM = $7E80;     

  {*********************************************************** }
  { OpenGL ES core versions  }

  const
     GL_VERSION_ES_CM_1_0 = 1;     
     GL_VERSION_ES_CL_1_0 = 1;     
     GL_VERSION_ES_CM_1_1 = 1;     
     GL_VERSION_ES_CL_1_1 = 1;     
  { ClearBufferMask  }
     GL_DEPTH_BUFFER_BIT = $00000100;     
     GL_STENCIL_BUFFER_BIT = $00000400;     
     GL_COLOR_BUFFER_BIT = $00004000;     
  { Boolean  }
     GL_FALSE = 0;     
     GL_TRUE = 1;     
  { BeginMode  }
     GL_POINTS = $0000;     
     GL_LINES = $0001;     
     GL_LINE_LOOP = $0002;     
     GL_LINE_STRIP = $0003;     
     GL_TRIANGLES = $0004;     
     GL_TRIANGLE_STRIP = $0005;     
     GL_TRIANGLE_FAN = $0006;     
  { AlphaFunction  }
     GL_NEVER = $0200;     
     GL_LESS = $0201;     
     GL_EQUAL = $0202;     
     GL_LEQUAL = $0203;     
     GL_GREATER = $0204;     
     GL_NOTEQUAL = $0205;     
     GL_GEQUAL = $0206;     
     GL_ALWAYS = $0207;     
  { BlendingFactorDest  }
     GL_ZERO = 0;     
     GL_ONE = 1;     
     GL_SRC_COLOR = $0300;     
     GL_ONE_MINUS_SRC_COLOR = $0301;     
     GL_SRC_ALPHA = $0302;     
     GL_ONE_MINUS_SRC_ALPHA = $0303;     
     GL_DST_ALPHA = $0304;     
     GL_ONE_MINUS_DST_ALPHA = $0305;     
  { BlendingFactorSrc  }
  {      GL_ZERO  }
  {      GL_ONE  }
     GL_DST_COLOR = $0306;     
     GL_ONE_MINUS_DST_COLOR = $0307;     
     GL_SRC_ALPHA_SATURATE = $0308;     
  {      GL_SRC_ALPHA  }
  {      GL_ONE_MINUS_SRC_ALPHA  }
  {      GL_DST_ALPHA  }
  {      GL_ONE_MINUS_DST_ALPHA  }
  { ClipPlaneName  }
     GL_CLIP_PLANE0 = $3000;     
     GL_CLIP_PLANE1 = $3001;     
     GL_CLIP_PLANE2 = $3002;     
     GL_CLIP_PLANE3 = $3003;     
     GL_CLIP_PLANE4 = $3004;     
     GL_CLIP_PLANE5 = $3005;     
  { ColorMaterialFace  }
  {      GL_FRONT_AND_BACK  }
  { ColorMaterialParameter  }
  {      GL_AMBIENT_AND_DIFFUSE  }
  { ColorPointerType  }
  {      GL_UNSIGNED_BYTE  }
  {      GL_FLOAT  }
  {      GL_FIXED  }
  { CullFaceMode  }
     GL_FRONT = $0404;     
     GL_BACK = $0405;     
     GL_FRONT_AND_BACK = $0408;     
  { DepthFunction  }
  {      GL_NEVER  }
  {      GL_LESS  }
  {      GL_EQUAL  }
  {      GL_LEQUAL  }
  {      GL_GREATER  }
  {      GL_NOTEQUAL  }
  {      GL_GEQUAL  }
  {      GL_ALWAYS  }
  { EnableCap  }
     GL_FOG = $0B60;     
     GL_LIGHTING = $0B50;     
     GL_TEXTURE_2D = $0DE1;     
     GL_CULL_FACE = $0B44;     
     GL_ALPHA_TEST = $0BC0;     
     GL_BLEND = $0BE2;     
     GL_COLOR_LOGIC_OP = $0BF2;     
     GL_DITHER = $0BD0;     
     GL_STENCIL_TEST = $0B90;     
     GL_DEPTH_TEST = $0B71;     
  {      GL_LIGHT0  }
  {      GL_LIGHT1  }
  {      GL_LIGHT2  }
  {      GL_LIGHT3  }
  {      GL_LIGHT4  }
  {      GL_LIGHT5  }
  {      GL_LIGHT6  }
  {      GL_LIGHT7  }
     GL_POINT_SMOOTH = $0B10;     
     GL_LINE_SMOOTH = $0B20;     
     GL_SCISSOR_TEST = $0C11;     
     GL_COLOR_MATERIAL = $0B57;     
     GL_NORMALIZE = $0BA1;     
     GL_RESCALE_NORMAL = $803A;     
     GL_POLYGON_OFFSET_FILL = $8037;     
     GL_VERTEX_ARRAY = $8074;     
     GL_NORMAL_ARRAY = $8075;     
     GL_COLOR_ARRAY = $8076;     
     GL_TEXTURE_COORD_ARRAY = $8078;     
     GL_MULTISAMPLE = $809D;     
     GL_SAMPLE_ALPHA_TO_COVERAGE = $809E;     
     GL_SAMPLE_ALPHA_TO_ONE = $809F;     
     GL_SAMPLE_COVERAGE = $80A0;     
  { ErrorCode  }
     GL_NO_ERROR = 0;     
     GL_INVALID_ENUM = $0500;     
     GL_INVALID_VALUE = $0501;     
     GL_INVALID_OPERATION = $0502;     
     GL_STACK_OVERFLOW = $0503;     
     GL_STACK_UNDERFLOW = $0504;     
     GL_OUT_OF_MEMORY = $0505;     
  { FogMode  }
  {      GL_LINEAR  }
     GL_EXP = $0800;     
     GL_EXP2 = $0801;     
  { FogParameter  }
     GL_FOG_DENSITY = $0B62;     
     GL_FOG_START = $0B63;     
     GL_FOG_END = $0B64;     
     GL_FOG_MODE = $0B65;     
     GL_FOG_COLOR = $0B66;     
  { FrontFaceDirection  }
     GL_CW = $0900;     
     GL_CCW = $0901;     
  { GetPName  }
     GL_CURRENT_COLOR = $0B00;     
     GL_CURRENT_NORMAL = $0B02;     
     GL_CURRENT_TEXTURE_COORDS = $0B03;     
     GL_POINT_SIZE = $0B11;     
     GL_POINT_SIZE_MIN = $8126;     
     GL_POINT_SIZE_MAX = $8127;     
     GL_POINT_FADE_THRESHOLD_SIZE = $8128;     
     GL_POINT_DISTANCE_ATTENUATION = $8129;     
     GL_SMOOTH_POINT_SIZE_RANGE = $0B12;     
     GL_LINE_WIDTH = $0B21;     
     GL_SMOOTH_LINE_WIDTH_RANGE = $0B22;     
     GL_ALIASED_POINT_SIZE_RANGE = $846D;     
     GL_ALIASED_LINE_WIDTH_RANGE = $846E;     
     GL_CULL_FACE_MODE = $0B45;     
     GL_FRONT_FACE = $0B46;     
     GL_SHADE_MODEL = $0B54;     
     GL_DEPTH_RANGE = $0B70;     
     GL_DEPTH_WRITEMASK = $0B72;     
     GL_DEPTH_CLEAR_VALUE = $0B73;     
     GL_DEPTH_FUNC = $0B74;     
     GL_STENCIL_CLEAR_VALUE = $0B91;     
     GL_STENCIL_FUNC = $0B92;     
     GL_STENCIL_VALUE_MASK = $0B93;     
     GL_STENCIL_FAIL = $0B94;     
     GL_STENCIL_PASS_DEPTH_FAIL = $0B95;     
     GL_STENCIL_PASS_DEPTH_PASS = $0B96;     
     GL_STENCIL_REF = $0B97;     
     GL_STENCIL_WRITEMASK = $0B98;     
     GL_MATRIX_MODE = $0BA0;     
     GL_VIEWPORT = $0BA2;     
     GL_MODELVIEW_STACK_DEPTH = $0BA3;     
     GL_PROJECTION_STACK_DEPTH = $0BA4;     
     GL_TEXTURE_STACK_DEPTH = $0BA5;     
     GL_MODELVIEW_MATRIX = $0BA6;     
     GL_PROJECTION_MATRIX = $0BA7;     
     GL_TEXTURE_MATRIX = $0BA8;     
     GL_ALPHA_TEST_FUNC = $0BC1;     
     GL_ALPHA_TEST_REF = $0BC2;     
     GL_BLEND_DST = $0BE0;     
     GL_BLEND_SRC = $0BE1;     
     GL_LOGIC_OP_MODE = $0BF0;     
     GL_SCISSOR_BOX = $0C10;     
//     GL_SCISSOR_TEST = $0C11;     
     GL_COLOR_CLEAR_VALUE = $0C22;     
     GL_COLOR_WRITEMASK = $0C23;     
     GL_UNPACK_ALIGNMENT = $0CF5;     
     GL_PACK_ALIGNMENT = $0D05;     
     GL_MAX_LIGHTS = $0D31;     
     GL_MAX_CLIP_PLANES = $0D32;     
     GL_MAX_TEXTURE_SIZE = $0D33;     
     GL_MAX_MODELVIEW_STACK_DEPTH = $0D36;     
     GL_MAX_PROJECTION_STACK_DEPTH = $0D38;     
     GL_MAX_TEXTURE_STACK_DEPTH = $0D39;     
     GL_MAX_VIEWPORT_DIMS = $0D3A;     
     GL_MAX_TEXTURE_UNITS = $84E2;     
     GL_SUBPIXEL_BITS = $0D50;     
     GL_RED_BITS = $0D52;     
     GL_GREEN_BITS = $0D53;     
     GL_BLUE_BITS = $0D54;     
     GL_ALPHA_BITS = $0D55;     
     GL_DEPTH_BITS = $0D56;     
     GL_STENCIL_BITS = $0D57;     
     GL_POLYGON_OFFSET_UNITS = $2A00;     
//     GL_POLYGON_OFFSET_FILL = $8037;     
     GL_POLYGON_OFFSET_FACTOR = $8038;     
     GL_TEXTURE_BINDING_2D = $8069;     
     GL_VERTEX_ARRAY_SIZE = $807A;     
     GL_VERTEX_ARRAY_TYPE = $807B;     
     GL_VERTEX_ARRAY_STRIDE = $807C;     
     GL_NORMAL_ARRAY_TYPE = $807E;     
     GL_NORMAL_ARRAY_STRIDE = $807F;     
     GL_COLOR_ARRAY_SIZE = $8081;     
     GL_COLOR_ARRAY_TYPE = $8082;     
     GL_COLOR_ARRAY_STRIDE = $8083;     
     GL_TEXTURE_COORD_ARRAY_SIZE = $8088;     
     GL_TEXTURE_COORD_ARRAY_TYPE = $8089;     
     GL_TEXTURE_COORD_ARRAY_STRIDE = $808A;     
     GL_VERTEX_ARRAY_POINTER = $808E;     
     GL_NORMAL_ARRAY_POINTER = $808F;     
     GL_COLOR_ARRAY_POINTER = $8090;     
     GL_TEXTURE_COORD_ARRAY_POINTER = $8092;     
     GL_SAMPLE_BUFFERS = $80A8;     
     GL_SAMPLES = $80A9;     
     GL_SAMPLE_COVERAGE_VALUE = $80AA;     
     GL_SAMPLE_COVERAGE_INVERT = $80AB;     
  { GetTextureParameter  }
  {      GL_TEXTURE_MAG_FILTER  }
  {      GL_TEXTURE_MIN_FILTER  }
  {      GL_TEXTURE_WRAP_S  }
  {      GL_TEXTURE_WRAP_T  }
     GL_NUM_COMPRESSED_TEXTURE_FORMATS = $86A2;     
     GL_COMPRESSED_TEXTURE_FORMATS = $86A3;     
  { HintMode  }
     GL_DONT_CARE = $1100;     
     GL_FASTEST = $1101;     
     GL_NICEST = $1102;     
  { HintTarget  }
     GL_PERSPECTIVE_CORRECTION_HINT = $0C50;     
     GL_POINT_SMOOTH_HINT = $0C51;     
     GL_LINE_SMOOTH_HINT = $0C52;     
     GL_FOG_HINT = $0C54;     
     GL_GENERATE_MIPMAP_HINT = $8192;     
  { LightModelParameter  }
     GL_LIGHT_MODEL_AMBIENT = $0B53;     
     GL_LIGHT_MODEL_TWO_SIDE = $0B52;     
  { LightParameter  }
     GL_AMBIENT = $1200;     
     GL_DIFFUSE = $1201;     
     GL_SPECULAR = $1202;     
     GL_POSITION = $1203;     
     GL_SPOT_DIRECTION = $1204;     
     GL_SPOT_EXPONENT = $1205;     
     GL_SPOT_CUTOFF = $1206;     
     GL_CONSTANT_ATTENUATION = $1207;     
     GL_LINEAR_ATTENUATION = $1208;     
     GL_QUADRATIC_ATTENUATION = $1209;     
  { DataType  }
     GL_BYTE = $1400;     
     GL_UNSIGNED_BYTE = $1401;     
     GL_SHORT = $1402;     
     GL_UNSIGNED_SHORT = $1403;     
     GL_FLOAT = $1406;     
     GL_FIXED = $140C;     
  { LogicOp  }
     GL_CLEAR = $1500;     
     GL_AND = $1501;     
     GL_AND_REVERSE = $1502;     
     GL_COPY = $1503;     
     GL_AND_INVERTED = $1504;     
     GL_NOOP = $1505;     
     GL_XOR = $1506;     
     GL_OR = $1507;     
     GL_NOR = $1508;     
     GL_EQUIV = $1509;     
     GL_INVERT = $150A;     
     GL_OR_REVERSE = $150B;     
     GL_COPY_INVERTED = $150C;     
     GL_OR_INVERTED = $150D;     
     GL_NAND = $150E;     
     GL_SET = $150F;     
  { MaterialFace  }
  {      GL_FRONT_AND_BACK  }
  { MaterialParameter  }
     GL_EMISSION = $1600;     
     GL_SHININESS = $1601;     
     GL_AMBIENT_AND_DIFFUSE = $1602;     
  {      GL_AMBIENT  }
  {      GL_DIFFUSE  }
  {      GL_SPECULAR  }
  { MatrixMode  }
     GL_MODELVIEW = $1700;     
     GL_PROJECTION = $1701;     
     GL_TEXTURE = $1702;     
  { NormalPointerType  }
  {      GL_BYTE  }
  {      GL_SHORT  }
  {      GL_FLOAT  }
  {      GL_FIXED  }
  { PixelFormat  }
     GL_ALPHA = $1906;     
     GL_RGB = $1907;     
     GL_RGBA = $1908;     
     GL_LUMINANCE = $1909;     
     GL_LUMINANCE_ALPHA = $190A;     
  { PixelStoreParameter  }
//     GL_UNPACK_ALIGNMENT = $0CF5;     
//     GL_PACK_ALIGNMENT = $0D05;     
  { PixelType  }
  {      GL_UNSIGNED_BYTE  }
     GL_UNSIGNED_SHORT_4_4_4_4 = $8033;     
     GL_UNSIGNED_SHORT_5_5_5_1 = $8034;     
     GL_UNSIGNED_SHORT_5_6_5 = $8363;     
  { ShadingModel  }
     GL_FLAT = $1D00;     
     GL_SMOOTH = $1D01;     
  { StencilFunction  }
  {      GL_NEVER  }
  {      GL_LESS  }
  {      GL_EQUAL  }
  {      GL_LEQUAL  }
  {      GL_GREATER  }
  {      GL_NOTEQUAL  }
  {      GL_GEQUAL  }
  {      GL_ALWAYS  }
  { StencilOp  }
  {      GL_ZERO  }
     GL_KEEP = $1E00;     
     GL_REPLACE = $1E01;     
     GL_INCR = $1E02;     
     GL_DECR = $1E03;     
  {      GL_INVERT  }
  { StringName  }
     GL_VENDOR = $1F00;     
     GL_RENDERER = $1F01;     
     GL_VERSION = $1F02;     
     GL_EXTENSIONS = $1F03;     
  { TexCoordPointerType  }
  {      GL_SHORT  }
  {      GL_FLOAT  }
  {      GL_FIXED  }
  {      GL_BYTE  }
  { TextureEnvMode  }
     GL_MODULATE = $2100;     
     GL_DECAL = $2101;     
  {      GL_BLEND  }
     GL_ADD = $0104;     
  {      GL_REPLACE  }
  { TextureEnvParameter  }
     GL_TEXTURE_ENV_MODE = $2200;     
     GL_TEXTURE_ENV_COLOR = $2201;     
  { TextureEnvTarget  }
     GL_TEXTURE_ENV = $2300;     
  { TextureMagFilter  }
     GL_NEAREST = $2600;     
     GL_LINEAR = $2601;     
  { TextureMinFilter  }
  {      GL_NEAREST  }
  {      GL_LINEAR  }
     GL_NEAREST_MIPMAP_NEAREST = $2700;     
     GL_LINEAR_MIPMAP_NEAREST = $2701;     
     GL_NEAREST_MIPMAP_LINEAR = $2702;     
     GL_LINEAR_MIPMAP_LINEAR = $2703;     
  { TextureParameterName  }
     GL_TEXTURE_MAG_FILTER = $2800;     
     GL_TEXTURE_MIN_FILTER = $2801;     
     GL_TEXTURE_WRAP_S = $2802;     
     GL_TEXTURE_WRAP_T = $2803;     
     GL_GENERATE_MIPMAP = $8191;     
  { TextureTarget  }
  {      GL_TEXTURE_2D  }
  { TextureUnit  }
     GL_TEXTURE0 = $84C0;     
     GL_TEXTURE1 = $84C1;     
     GL_TEXTURE2 = $84C2;     
     GL_TEXTURE3 = $84C3;     
     GL_TEXTURE4 = $84C4;     
     GL_TEXTURE5 = $84C5;     
     GL_TEXTURE6 = $84C6;     
     GL_TEXTURE7 = $84C7;     
     GL_TEXTURE8 = $84C8;     
     GL_TEXTURE9 = $84C9;     
     GL_TEXTURE10 = $84CA;     
     GL_TEXTURE11 = $84CB;     
     GL_TEXTURE12 = $84CC;     
     GL_TEXTURE13 = $84CD;     
     GL_TEXTURE14 = $84CE;     
     GL_TEXTURE15 = $84CF;     
     GL_TEXTURE16 = $84D0;     
     GL_TEXTURE17 = $84D1;     
     GL_TEXTURE18 = $84D2;     
     GL_TEXTURE19 = $84D3;     
     GL_TEXTURE20 = $84D4;     
     GL_TEXTURE21 = $84D5;     
     GL_TEXTURE22 = $84D6;     
     GL_TEXTURE23 = $84D7;     
     GL_TEXTURE24 = $84D8;     
     GL_TEXTURE25 = $84D9;     
     GL_TEXTURE26 = $84DA;     
     GL_TEXTURE27 = $84DB;     
     GL_TEXTURE28 = $84DC;     
     GL_TEXTURE29 = $84DD;     
     GL_TEXTURE30 = $84DE;     
     GL_TEXTURE31 = $84DF;     
     GL_ACTIVE_TEXTURE = $84E0;     
     GL_CLIENT_ACTIVE_TEXTURE = $84E1;     
  { TextureWrapMode  }
     GL_REPEAT = $2901;     
     GL_CLAMP_TO_EDGE = $812F;     
  { VertexPointerType  }
  {      GL_SHORT  }
  {      GL_FLOAT  }
  {      GL_FIXED  }
  {      GL_BYTE  }
  { LightName  }
     GL_LIGHT0 = $4000;     
     GL_LIGHT1 = $4001;     
     GL_LIGHT2 = $4002;     
     GL_LIGHT3 = $4003;     
     GL_LIGHT4 = $4004;     
     GL_LIGHT5 = $4005;     
     GL_LIGHT6 = $4006;     
     GL_LIGHT7 = $4007;     
  { Buffer Objects  }
     GL_ARRAY_BUFFER = $8892;     
     GL_ELEMENT_ARRAY_BUFFER = $8893;     
     GL_ARRAY_BUFFER_BINDING = $8894;     
     GL_ELEMENT_ARRAY_BUFFER_BINDING = $8895;     
     GL_VERTEX_ARRAY_BUFFER_BINDING = $8896;     
     GL_NORMAL_ARRAY_BUFFER_BINDING = $8897;     
     GL_COLOR_ARRAY_BUFFER_BINDING = $8898;     
     GL_TEXTURE_COORD_ARRAY_BUFFER_BINDING = $889A;     
     GL_STATIC_DRAW = $88E4;     
     GL_DYNAMIC_DRAW = $88E8;     
     GL_BUFFER_SIZE = $8764;     
     GL_BUFFER_USAGE = $8765;     
  { Texture combine + dot3  }
     GL_SUBTRACT = $84E7;     
     GL_COMBINE = $8570;     
     GL_COMBINE_RGB = $8571;     
     GL_COMBINE_ALPHA = $8572;     
     GL_RGB_SCALE = $8573;     
     GL_ADD_SIGNED = $8574;     
     GL_INTERPOLATE = $8575;     
     GL_CONSTANT = $8576;     
     GL_PRIMARY_COLOR = $8577;     
     GL_PREVIOUS = $8578;     
     GL_OPERAND0_RGB = $8590;     
     GL_OPERAND1_RGB = $8591;     
     GL_OPERAND2_RGB = $8592;     
     GL_OPERAND0_ALPHA = $8598;     
     GL_OPERAND1_ALPHA = $8599;     
     GL_OPERAND2_ALPHA = $859A;     
     GL_ALPHA_SCALE = $0D1C;     
     GL_SRC0_RGB = $8580;     
     GL_SRC1_RGB = $8581;     
     GL_SRC2_RGB = $8582;     
     GL_SRC0_ALPHA = $8588;     
     GL_SRC1_ALPHA = $8589;     
     GL_SRC2_ALPHA = $858A;     
     GL_DOT3_RGB = $86AE;     
     GL_DOT3_RGBA = $86AF;     
  {------------------------------------------------------------------------*
   * required OES extension tokens
   *------------------------------------------------------------------------ }
  { OES_read_format  }
     GL_IMPLEMENTATION_COLOR_READ_TYPE_OES = $8B9A;     
     GL_IMPLEMENTATION_COLOR_READ_FORMAT_OES = $8B9B;     
  { GL_OES_compressed_paletted_texture  }
     GL_PALETTE4_RGB8_OES = $8B90;     
     GL_PALETTE4_RGBA8_OES = $8B91;     
     GL_PALETTE4_R5_G6_B5_OES = $8B92;     
     GL_PALETTE4_RGBA4_OES = $8B93;     
     GL_PALETTE4_RGB5_A1_OES = $8B94;     
     GL_PALETTE8_RGB8_OES = $8B95;     
     GL_PALETTE8_RGBA8_OES = $8B96;     
     GL_PALETTE8_R5_G6_B5_OES = $8B97;     
     GL_PALETTE8_RGBA4_OES = $8B98;     
     GL_PALETTE8_RGB5_A1_OES = $8B99;     
  { OES_point_size_array  }
     GL_POINT_SIZE_ARRAY_OES = $8B9C;     
     GL_POINT_SIZE_ARRAY_TYPE_OES = $898A;     
     GL_POINT_SIZE_ARRAY_STRIDE_OES = $898B;     
     GL_POINT_SIZE_ARRAY_POINTER_OES = $898C;     
     GL_POINT_SIZE_ARRAY_BUFFER_BINDING_OES = $8B9F;     
  { GL_OES_point_sprite  }
     GL_POINT_SPRITE_OES = $8861;     
     GL_COORD_REPLACE_OES = $8862;     
  {*********************************************************** }
  { Available only in Common profile  }

  var
    glAlphaFunc : procedure(func:GLenum; ref:GLclampf);cdecl;
    glClearColor : procedure(red:GLclampf; green:GLclampf; blue:GLclampf; alpha:GLclampf);cdecl;
    glClearDepthf : procedure(depth:GLclampf);cdecl;
(* Const before type ignored *)
    glClipPlanef : procedure(plane:GLenum; equation:pGLfloat);cdecl;
    glColor4f : procedure(red:GLfloat; green:GLfloat; blue:GLfloat; alpha:GLfloat);cdecl;
    glDepthRangef : procedure(zNear:GLclampf; zFar:GLclampf);cdecl;
    glFogf : procedure(pname:GLenum; param:GLfloat);cdecl;
(* Const before type ignored *)
    glFogfv : procedure(pname:GLenum; params:pGLfloat);cdecl;
    glFrustumf : procedure(left:GLfloat; right:GLfloat; bottom:GLfloat; top:GLfloat; zNear:GLfloat; 
      zFar:GLfloat);cdecl;
    glGetClipPlanef : procedure(pname:GLenum; eqn:array of GLfloat);cdecl;
    glGetFloatv : procedure(pname:GLenum; params:pGLfloat);cdecl;
    glGetLightfv : procedure(light:GLenum; pname:GLenum; params:pGLfloat);cdecl;
    glGetMaterialfv : procedure(face:GLenum; pname:GLenum; params:pGLfloat);cdecl;
    glGetTexEnvfv : procedure(env:GLenum; pname:GLenum; params:pGLfloat);cdecl;
    glGetTexParameterfv : procedure(target:GLenum; pname:GLenum; params:pGLfloat);cdecl;
    glLightModelf : procedure(pname:GLenum; param:GLfloat);cdecl;
(* Const before type ignored *)
    glLightModelfv : procedure(pname:GLenum; params:pGLfloat);cdecl;
    glLightf : procedure(light:GLenum; pname:GLenum; param:GLfloat);cdecl;
(* Const before type ignored *)
    glLightfv : procedure(light:GLenum; pname:GLenum; params:pGLfloat);cdecl;
    glLineWidth : procedure(width:GLfloat);cdecl;
(* Const before type ignored *)
    glLoadMatrixf : procedure(m:pGLfloat);cdecl;
    glMaterialf : procedure(face:GLenum; pname:GLenum; param:GLfloat);cdecl;
(* Const before type ignored *)
    glMaterialfv : procedure(face:GLenum; pname:GLenum; params:pGLfloat);cdecl;
(* Const before type ignored *)
    glMultMatrixf : procedure(m:pGLfloat);cdecl;
    glMultiTexCoord4f : procedure(target:GLenum; s:GLfloat; t:GLfloat; r:GLfloat; q:GLfloat);cdecl;
    glNormal3f : procedure(nx:GLfloat; ny:GLfloat; nz:GLfloat);cdecl;
    glOrthof : procedure(left:GLfloat; right:GLfloat; bottom:GLfloat; top:GLfloat; zNear:GLfloat; 
      zFar:GLfloat);cdecl;
    glPointParameterf : procedure(pname:GLenum; param:GLfloat);cdecl;
(* Const before type ignored *)
    glPointParameterfv : procedure(pname:GLenum; params:pGLfloat);cdecl;
    glPointSize : procedure(size:GLfloat);cdecl;
    glPolygonOffset : procedure(factor:GLfloat; units:GLfloat);cdecl;
    glRotatef : procedure(angle:GLfloat; x:GLfloat; y:GLfloat; z:GLfloat);cdecl;
    glScalef : procedure(x:GLfloat; y:GLfloat; z:GLfloat);cdecl;
    glTexEnvf : procedure(target:GLenum; pname:GLenum; param:GLfloat);cdecl;
(* Const before type ignored *)
    glTexEnvfv : procedure(target:GLenum; pname:GLenum; params:pGLfloat);cdecl;
    glTexParameterf : procedure(target:GLenum; pname:GLenum; param:GLfloat);cdecl;
(* Const before type ignored *)
    glTexParameterfv : procedure(target:GLenum; pname:GLenum; params:pGLfloat);cdecl;
    glTranslatef : procedure(x:GLfloat; y:GLfloat; z:GLfloat);cdecl;
  { Available in both Common and Common-Lite profiles  }
    glActiveTexture : procedure(texture:GLenum);cdecl;
    glAlphaFuncx : procedure(func:GLenum; ref:GLclampx);cdecl;
    glBindBuffer : procedure(target:GLenum; buffer:GLuint);cdecl;
    glBindTexture : procedure(target:GLenum; texture:GLuint);cdecl;
    glBlendFunc : procedure(sfactor:GLenum; dfactor:GLenum);cdecl;
(* Const before type ignored *)
    glBufferData : procedure(target:GLenum; size:GLsizeiptr; data:pGLvoid; usage:GLenum);cdecl;
(* Const before type ignored *)
    glBufferSubData : procedure(target:GLenum; offset:GLintptr; size:GLsizeiptr; data:pGLvoid);cdecl;
    glClear : procedure(mask:GLbitfield);cdecl;
    glClearColorx : procedure(red:GLclampx; green:GLclampx; blue:GLclampx; alpha:GLclampx);cdecl;
    glClearDepthx : procedure(depth:GLclampx);cdecl;
    glClearStencil : procedure(s:GLint);cdecl;
    glClientActiveTexture : procedure(texture:GLenum);cdecl;
(* Const before type ignored *)
    glClipPlanex : procedure(plane:GLenum; equation:pGLfixed);cdecl;
    glColor4ub : procedure(red:GLubyte; green:GLubyte; blue:GLubyte; alpha:GLubyte);cdecl;
    glColor4x : procedure(red:GLfixed; green:GLfixed; blue:GLfixed; alpha:GLfixed);cdecl;
    glColorMask : procedure(red:GLboolean; green:GLboolean; blue:GLboolean; alpha:GLboolean);cdecl;
(* Const before type ignored *)
    glColorPointer : procedure(size:GLint; _type:GLenum; stride:GLsizei; pointer:pGLvoid);cdecl;
(* Const before type ignored *)
    glCompressedTexImage2D : procedure(target:GLenum; level:GLint; internalformat:GLenum; width:GLsizei; height:GLsizei; 
      border:GLint; imageSize:GLsizei; data:pGLvoid);cdecl;
(* Const before type ignored *)
    glCompressedTexSubImage2D : procedure(target:GLenum; level:GLint; xoffset:GLint; yoffset:GLint; width:GLsizei; 
      height:GLsizei; format:GLenum; imageSize:GLsizei; data:pGLvoid);cdecl;
    glCopyTexImage2D : procedure(target:GLenum; level:GLint; internalformat:GLenum; x:GLint; y:GLint; 
      width:GLsizei; height:GLsizei; border:GLint);cdecl;
    glCopyTexSubImage2D : procedure(target:GLenum; level:GLint; xoffset:GLint; yoffset:GLint; x:GLint; 
      y:GLint; width:GLsizei; height:GLsizei);cdecl;
    glCullFace : procedure(mode:GLenum);cdecl;
(* Const before type ignored *)
    glDeleteBuffers : procedure(n:GLsizei; buffers:pGLuint);cdecl;
(* Const before type ignored *)
    glDeleteTextures : procedure(n:GLsizei; textures:pGLuint);cdecl;
    glDepthFunc : procedure(func:GLenum);cdecl;
    glDepthMask : procedure(flag:GLboolean);cdecl;
    glDepthRangex : procedure(zNear:GLclampx; zFar:GLclampx);cdecl;
    glDisable : procedure(cap:GLenum);cdecl;
    glDisableClientState : procedure(arry:GLenum);cdecl;
    glDrawArrays : procedure(mode:GLenum; first:GLint; count:GLsizei);cdecl;
(* Const before type ignored *)
    glDrawElements : procedure(mode:GLenum; count:GLsizei; _type:GLenum; indices:pGLvoid);cdecl;
    glEnable : procedure(cap:GLenum);cdecl;
    glEnableClientState : procedure(arry:GLenum);cdecl;
    glFinish : procedure;cdecl;
    glFlush : procedure;cdecl;
    glFogx : procedure(pname:GLenum; param:GLfixed);cdecl;
(* Const before type ignored *)
    glFogxv : procedure(pname:GLenum; params:pGLfixed);cdecl;
    glFrontFace : procedure(mode:GLenum);cdecl;
    glFrustumx : procedure(left:GLfixed; right:GLfixed; bottom:GLfixed; top:GLfixed; zNear:GLfixed; 
      zFar:GLfixed);cdecl;
    glGetBooleanv : procedure(pname:GLenum; params:pGLboolean);cdecl;
    glGetBufferParameteriv : procedure(target:GLenum; pname:GLenum; params:pGLint);cdecl;
    glGetClipPlanex : procedure(pname:GLenum; eqn:array of GLfixed);cdecl;
    glGenBuffers : procedure(n:GLsizei; buffers:pGLuint);cdecl;
    glGenTextures : procedure(n:GLsizei; textures:pGLuint);cdecl;
    glGetError : function:GLenum;cdecl;
    glGetFixedv : procedure(pname:GLenum; params:pGLfixed);cdecl;
    glGetIntegerv : procedure(pname:GLenum; params:pGLint);cdecl;
    glGetLightxv : procedure(light:GLenum; pname:GLenum; params:pGLfixed);cdecl;
    glGetMaterialxv : procedure(face:GLenum; pname:GLenum; params:pGLfixed);cdecl;
    glGetPointerv : procedure(pname:GLenum; params:Ppointer);cdecl;
(* Const before type ignored *)
    glGetString : function(name:GLenum):PGLubyte;cdecl;
    glGetTexEnviv : procedure(env:GLenum; pname:GLenum; params:pGLint);cdecl;
    glGetTexEnvxv : procedure(env:GLenum; pname:GLenum; params:pGLfixed);cdecl;
    glGetTexParameteriv : procedure(target:GLenum; pname:GLenum; params:pGLint);cdecl;
    glGetTexParameterxv : procedure(target:GLenum; pname:GLenum; params:pGLfixed);cdecl;
    glHint : procedure(target:GLenum; mode:GLenum);cdecl;
    glIsBuffer : function(buffer:GLuint):GLboolean;cdecl;
    glIsEnabled : function(cap:GLenum):GLboolean;cdecl;
    glIsTexture : function(texture:GLuint):GLboolean;cdecl;
    glLightModelx : procedure(pname:GLenum; param:GLfixed);cdecl;
(* Const before type ignored *)
    glLightModelxv : procedure(pname:GLenum; params:pGLfixed);cdecl;
    glLightx : procedure(light:GLenum; pname:GLenum; param:GLfixed);cdecl;
(* Const before type ignored *)
    glLightxv : procedure(light:GLenum; pname:GLenum; params:pGLfixed);cdecl;
    glLineWidthx : procedure(width:GLfixed);cdecl;
    glLoadIdentity : procedure;cdecl;
(* Const before type ignored *)
    glLoadMatrixx : procedure(m:pGLfixed);cdecl;
    glLogicOp : procedure(opcode:GLenum);cdecl;
    glMaterialx : procedure(face:GLenum; pname:GLenum; param:GLfixed);cdecl;
(* Const before type ignored *)
    glMaterialxv : procedure(face:GLenum; pname:GLenum; params:pGLfixed);cdecl;
    glMatrixMode : procedure(mode:GLenum);cdecl;
(* Const before type ignored *)
    glMultMatrixx : procedure(m:pGLfixed);cdecl;
    glMultiTexCoord4x : procedure(target:GLenum; s:GLfixed; t:GLfixed; r:GLfixed; q:GLfixed);cdecl;
    glNormal3x : procedure(nx:GLfixed; ny:GLfixed; nz:GLfixed);cdecl;
(* Const before type ignored *)
    glNormalPointer : procedure(_type:GLenum; stride:GLsizei; pointer:pGLvoid);cdecl;
    glOrthox : procedure(left:GLfixed; right:GLfixed; bottom:GLfixed; top:GLfixed; zNear:GLfixed; 
      zFar:GLfixed);cdecl;
    glPixelStorei : procedure(pname:GLenum; param:GLint);cdecl;
    glPointParameterx : procedure(pname:GLenum; param:GLfixed);cdecl;
(* Const before type ignored *)
    glPointParameterxv : procedure(pname:GLenum; params:pGLfixed);cdecl;
    glPointSizex : procedure(size:GLfixed);cdecl;
    glPolygonOffsetx : procedure(factor:GLfixed; units:GLfixed);cdecl;
    glPopMatrix : procedure;cdecl;
    glPushMatrix : procedure;cdecl;
    glReadPixels : procedure(x:GLint; y:GLint; width:GLsizei; height:GLsizei; format:GLenum; 
      _type:GLenum; pixels:pGLvoid);cdecl;
    glRotatex : procedure(angle:GLfixed; x:GLfixed; y:GLfixed; z:GLfixed);cdecl;
    glSampleCoverage : procedure(value:GLclampf; invert:GLboolean);cdecl;
    glSampleCoveragex : procedure(value:GLclampx; invert:GLboolean);cdecl;
    glScalex : procedure(x:GLfixed; y:GLfixed; z:GLfixed);cdecl;
    glScissor : procedure(x:GLint; y:GLint; width:GLsizei; height:GLsizei);cdecl;
    glShadeModel : procedure(mode:GLenum);cdecl;
    glStencilFunc : procedure(func:GLenum; ref:GLint; mask:GLuint);cdecl;
    glStencilMask : procedure(mask:GLuint);cdecl;
    glStencilOp : procedure(fail:GLenum; zfail:GLenum; zpass:GLenum);cdecl;
(* Const before type ignored *)
    glTexCoordPointer : procedure(size:GLint; _type:GLenum; stride:GLsizei; pointer:pGLvoid);cdecl;
    glTexEnvi : procedure(target:GLenum; pname:GLenum; param:GLint);cdecl;
    glTexEnvx : procedure(target:GLenum; pname:GLenum; param:GLfixed);cdecl;
(* Const before type ignored *)
    glTexEnviv : procedure(target:GLenum; pname:GLenum; params:pGLint);cdecl;
(* Const before type ignored *)
    glTexEnvxv : procedure(target:GLenum; pname:GLenum; params:pGLfixed);cdecl;
(* Const before type ignored *)
    glTexImage2D : procedure(target:GLenum; level:GLint; internalformat:GLint; width:GLsizei; height:GLsizei; 
      border:GLint; format:GLenum; _type:GLenum; pixels:pGLvoid);cdecl;
    glTexParameteri : procedure(target:GLenum; pname:GLenum; param:GLint);cdecl;
    glTexParameterx : procedure(target:GLenum; pname:GLenum; param:GLfixed);cdecl;
(* Const before type ignored *)
    glTexParameteriv : procedure(target:GLenum; pname:GLenum; params:pGLint);cdecl;
(* Const before type ignored *)
    glTexParameterxv : procedure(target:GLenum; pname:GLenum; params:pGLfixed);cdecl;
(* Const before type ignored *)
    glTexSubImage2D : procedure(target:GLenum; level:GLint; xoffset:GLint; yoffset:GLint; width:GLsizei; 
      height:GLsizei; format:GLenum; _type:GLenum; pixels:pGLvoid);cdecl;
    glTranslatex : procedure(x:GLfixed; y:GLfixed; z:GLfixed);cdecl;
(* Const before type ignored *)
    glVertexPointer : procedure(size:GLint; _type:GLenum; stride:GLsizei; pointer:pGLvoid);cdecl;
    glViewport : procedure(x:GLint; y:GLint; width:GLsizei; height:GLsizei);cdecl;
  {------------------------------------------------------------------------*
   * Required OES extension functions
   *------------------------------------------------------------------------ }
  { GL_OES_read_format  }

  const
     GL_OES_read_format = 1;     
  { GL_OES_compressed_paletted_texture  }
     GL_OES_compressed_paletted_texture = 1;     
  { GL_OES_point_size_array  }
     GL_OES_point_size_array = 1;     
(* Const before type ignored *)

  var
    glPointSizePointerOES : procedure(_type:GLenum; stride:GLsizei; pointer:pGLvoid);cdecl;
  { GL_OES_point_sprite  }

  const
     GL_OES_point_sprite = 1;     

implementation

  uses
    SysUtils, dynlibs;

  var
    hlib : tlibhandle;


  procedure Freegles11;
    begin
//      FreeLibrary(hlib);
      glAlphaFunc:=nil;
      glClearColor:=nil;
      glClearDepthf:=nil;
      glClipPlanef:=nil;
      glColor4f:=nil;
      glDepthRangef:=nil;
      glFogf:=nil;
      glFogfv:=nil;
      glFrustumf:=nil;
      glGetClipPlanef:=nil;
      glGetFloatv:=nil;
      glGetLightfv:=nil;
      glGetMaterialfv:=nil;
      glGetTexEnvfv:=nil;
      glGetTexParameterfv:=nil;
      glLightModelf:=nil;
      glLightModelfv:=nil;
      glLightf:=nil;
      glLightfv:=nil;
      glLineWidth:=nil;
      glLoadMatrixf:=nil;
      glMaterialf:=nil;
      glMaterialfv:=nil;
      glMultMatrixf:=nil;
      glMultiTexCoord4f:=nil;
      glNormal3f:=nil;
      glOrthof:=nil;
      glPointParameterf:=nil;
      glPointParameterfv:=nil;
      glPointSize:=nil;
      glPolygonOffset:=nil;
      glRotatef:=nil;
      glScalef:=nil;
      glTexEnvf:=nil;
      glTexEnvfv:=nil;
      glTexParameterf:=nil;
      glTexParameterfv:=nil;
      glTranslatef:=nil;
      glActiveTexture:=nil;
      glAlphaFuncx:=nil;
      glBindBuffer:=nil;
      glBindTexture:=nil;
      glBlendFunc:=nil;
      glBufferData:=nil;
      glBufferSubData:=nil;
      glClear:=nil;
      glClearColorx:=nil;
      glClearDepthx:=nil;
      glClearStencil:=nil;
      glClientActiveTexture:=nil;
      glClipPlanex:=nil;
      glColor4ub:=nil;
      glColor4x:=nil;
      glColorMask:=nil;
      glColorPointer:=nil;
      glCompressedTexImage2D:=nil;
      glCompressedTexSubImage2D:=nil;
      glCopyTexImage2D:=nil;
      glCopyTexSubImage2D:=nil;
      glCullFace:=nil;
      glDeleteBuffers:=nil;
      glDeleteTextures:=nil;
      glDepthFunc:=nil;
      glDepthMask:=nil;
      glDepthRangex:=nil;
      glDisable:=nil;
      glDisableClientState:=nil;
      glDrawArrays:=nil;
      glDrawElements:=nil;
      glEnable:=nil;
      glEnableClientState:=nil;
      glFinish:=nil;
      glFlush:=nil;
      glFogx:=nil;
      glFogxv:=nil;
      glFrontFace:=nil;
      glFrustumx:=nil;
      glGetBooleanv:=nil;
      glGetBufferParameteriv:=nil;
      glGetClipPlanex:=nil;
      glGenBuffers:=nil;
      glGenTextures:=nil;
      glGetError:=nil;
      glGetFixedv:=nil;
      glGetIntegerv:=nil;
      glGetLightxv:=nil;
      glGetMaterialxv:=nil;
      glGetPointerv:=nil;
      glGetString:=nil;
      glGetTexEnviv:=nil;
      glGetTexEnvxv:=nil;
      glGetTexParameteriv:=nil;
      glGetTexParameterxv:=nil;
      glHint:=nil;
      glIsBuffer:=nil;
      glIsEnabled:=nil;
      glIsTexture:=nil;
      glLightModelx:=nil;
      glLightModelxv:=nil;
      glLightx:=nil;
      glLightxv:=nil;
      glLineWidthx:=nil;
      glLoadIdentity:=nil;
      glLoadMatrixx:=nil;
      glLogicOp:=nil;
      glMaterialx:=nil;
      glMaterialxv:=nil;
      glMatrixMode:=nil;
      glMultMatrixx:=nil;
      glMultiTexCoord4x:=nil;
      glNormal3x:=nil;
      glNormalPointer:=nil;
      glOrthox:=nil;
      glPixelStorei:=nil;
      glPointParameterx:=nil;
      glPointParameterxv:=nil;
      glPointSizex:=nil;
      glPolygonOffsetx:=nil;
      glPopMatrix:=nil;
      glPushMatrix:=nil;
      glReadPixels:=nil;
      glRotatex:=nil;
      glSampleCoverage:=nil;
      glSampleCoveragex:=nil;
      glScalex:=nil;
      glScissor:=nil;
      glShadeModel:=nil;
      glStencilFunc:=nil;
      glStencilMask:=nil;
      glStencilOp:=nil;
      glTexCoordPointer:=nil;
      glTexEnvi:=nil;
      glTexEnvx:=nil;
      glTexEnviv:=nil;
      glTexEnvxv:=nil;
      glTexImage2D:=nil;
      glTexParameteri:=nil;
      glTexParameterx:=nil;
      glTexParameteriv:=nil;
      glTexParameterxv:=nil;
      glTexSubImage2D:=nil;
      glTranslatex:=nil;
      glVertexPointer:=nil;
      glViewport:=nil;
      glPointSizePointerOES:=nil;
    end;


  procedure Loadgles11(lib : pchar);
    begin
      Freegles11;
      hlib:=LoadLibrary(lib);
      if hlib=0 then
	begin
         raise Exception.Create(format('Could not load library: %s',[lib]));
	end;
      pointer(glAlphaFunc):=GetProcAddress(hlib,'glAlphaFunc');
      pointer(glClearColor):=GetProcAddress(hlib,'glClearColor');
      pointer(glClearDepthf):=GetProcAddress(hlib,'glClearDepthf');
      pointer(glClipPlanef):=GetProcAddress(hlib,'glClipPlanef');
      pointer(glColor4f):=GetProcAddress(hlib,'glColor4f');
      pointer(glDepthRangef):=GetProcAddress(hlib,'glDepthRangef');
      pointer(glFogf):=GetProcAddress(hlib,'glFogf');
      pointer(glFogfv):=GetProcAddress(hlib,'glFogfv');
      pointer(glFrustumf):=GetProcAddress(hlib,'glFrustumf');
      pointer(glGetClipPlanef):=GetProcAddress(hlib,'glGetClipPlanef');
      pointer(glGetFloatv):=GetProcAddress(hlib,'glGetFloatv');
      pointer(glGetLightfv):=GetProcAddress(hlib,'glGetLightfv');
      pointer(glGetMaterialfv):=GetProcAddress(hlib,'glGetMaterialfv');
      pointer(glGetTexEnvfv):=GetProcAddress(hlib,'glGetTexEnvfv');
      pointer(glGetTexParameterfv):=GetProcAddress(hlib,'glGetTexParameterfv');
      pointer(glLightModelf):=GetProcAddress(hlib,'glLightModelf');
      pointer(glLightModelfv):=GetProcAddress(hlib,'glLightModelfv');
      pointer(glLightf):=GetProcAddress(hlib,'glLightf');
      pointer(glLightfv):=GetProcAddress(hlib,'glLightfv');
      pointer(glLineWidth):=GetProcAddress(hlib,'glLineWidth');
      pointer(glLoadMatrixf):=GetProcAddress(hlib,'glLoadMatrixf');
      pointer(glMaterialf):=GetProcAddress(hlib,'glMaterialf');
      pointer(glMaterialfv):=GetProcAddress(hlib,'glMaterialfv');
      pointer(glMultMatrixf):=GetProcAddress(hlib,'glMultMatrixf');
      pointer(glMultiTexCoord4f):=GetProcAddress(hlib,'glMultiTexCoord4f');
      pointer(glNormal3f):=GetProcAddress(hlib,'glNormal3f');
      pointer(glOrthof):=GetProcAddress(hlib,'glOrthof');
      pointer(glPointParameterf):=GetProcAddress(hlib,'glPointParameterf');
      pointer(glPointParameterfv):=GetProcAddress(hlib,'glPointParameterfv');
      pointer(glPointSize):=GetProcAddress(hlib,'glPointSize');
      pointer(glPolygonOffset):=GetProcAddress(hlib,'glPolygonOffset');
      pointer(glRotatef):=GetProcAddress(hlib,'glRotatef');
      pointer(glScalef):=GetProcAddress(hlib,'glScalef');
      pointer(glTexEnvf):=GetProcAddress(hlib,'glTexEnvf');
      pointer(glTexEnvfv):=GetProcAddress(hlib,'glTexEnvfv');
      pointer(glTexParameterf):=GetProcAddress(hlib,'glTexParameterf');
      pointer(glTexParameterfv):=GetProcAddress(hlib,'glTexParameterfv');
      pointer(glTranslatef):=GetProcAddress(hlib,'glTranslatef');
      pointer(glActiveTexture):=GetProcAddress(hlib,'glActiveTexture');
      pointer(glAlphaFuncx):=GetProcAddress(hlib,'glAlphaFuncx');
      pointer(glBindBuffer):=GetProcAddress(hlib,'glBindBuffer');
      pointer(glBindTexture):=GetProcAddress(hlib,'glBindTexture');
      pointer(glBlendFunc):=GetProcAddress(hlib,'glBlendFunc');
      pointer(glBufferData):=GetProcAddress(hlib,'glBufferData');
      pointer(glBufferSubData):=GetProcAddress(hlib,'glBufferSubData');
      pointer(glClear):=GetProcAddress(hlib,'glClear');
      pointer(glClearColorx):=GetProcAddress(hlib,'glClearColorx');
      pointer(glClearDepthx):=GetProcAddress(hlib,'glClearDepthx');
      pointer(glClearStencil):=GetProcAddress(hlib,'glClearStencil');
      pointer(glClientActiveTexture):=GetProcAddress(hlib,'glClientActiveTexture');
      pointer(glClipPlanex):=GetProcAddress(hlib,'glClipPlanex');
      pointer(glColor4ub):=GetProcAddress(hlib,'glColor4ub');
      pointer(glColor4x):=GetProcAddress(hlib,'glColor4x');
      pointer(glColorMask):=GetProcAddress(hlib,'glColorMask');
      pointer(glColorPointer):=GetProcAddress(hlib,'glColorPointer');
      pointer(glCompressedTexImage2D):=GetProcAddress(hlib,'glCompressedTexImage2D');
      pointer(glCompressedTexSubImage2D):=GetProcAddress(hlib,'glCompressedTexSubImage2D');
      pointer(glCopyTexImage2D):=GetProcAddress(hlib,'glCopyTexImage2D');
      pointer(glCopyTexSubImage2D):=GetProcAddress(hlib,'glCopyTexSubImage2D');
      pointer(glCullFace):=GetProcAddress(hlib,'glCullFace');
      pointer(glDeleteBuffers):=GetProcAddress(hlib,'glDeleteBuffers');
      pointer(glDeleteTextures):=GetProcAddress(hlib,'glDeleteTextures');
      pointer(glDepthFunc):=GetProcAddress(hlib,'glDepthFunc');
      pointer(glDepthMask):=GetProcAddress(hlib,'glDepthMask');
      pointer(glDepthRangex):=GetProcAddress(hlib,'glDepthRangex');
      pointer(glDisable):=GetProcAddress(hlib,'glDisable');
      pointer(glDisableClientState):=GetProcAddress(hlib,'glDisableClientState');
      pointer(glDrawArrays):=GetProcAddress(hlib,'glDrawArrays');
      pointer(glDrawElements):=GetProcAddress(hlib,'glDrawElements');
      pointer(glEnable):=GetProcAddress(hlib,'glEnable');
      pointer(glEnableClientState):=GetProcAddress(hlib,'glEnableClientState');
      pointer(glFinish):=GetProcAddress(hlib,'glFinish');
      pointer(glFlush):=GetProcAddress(hlib,'glFlush');
      pointer(glFogx):=GetProcAddress(hlib,'glFogx');
      pointer(glFogxv):=GetProcAddress(hlib,'glFogxv');
      pointer(glFrontFace):=GetProcAddress(hlib,'glFrontFace');
      pointer(glFrustumx):=GetProcAddress(hlib,'glFrustumx');
      pointer(glGetBooleanv):=GetProcAddress(hlib,'glGetBooleanv');
      pointer(glGetBufferParameteriv):=GetProcAddress(hlib,'glGetBufferParameteriv');
      pointer(glGetClipPlanex):=GetProcAddress(hlib,'glGetClipPlanex');
      pointer(glGenBuffers):=GetProcAddress(hlib,'glGenBuffers');
      pointer(glGenTextures):=GetProcAddress(hlib,'glGenTextures');
      pointer(glGetError):=GetProcAddress(hlib,'glGetError');
      pointer(glGetFixedv):=GetProcAddress(hlib,'glGetFixedv');
      pointer(glGetIntegerv):=GetProcAddress(hlib,'glGetIntegerv');
      pointer(glGetLightxv):=GetProcAddress(hlib,'glGetLightxv');
      pointer(glGetMaterialxv):=GetProcAddress(hlib,'glGetMaterialxv');
      pointer(glGetPointerv):=GetProcAddress(hlib,'glGetPointerv');
      pointer(glGetString):=GetProcAddress(hlib,'glGetString');
      pointer(glGetTexEnviv):=GetProcAddress(hlib,'glGetTexEnviv');
      pointer(glGetTexEnvxv):=GetProcAddress(hlib,'glGetTexEnvxv');
      pointer(glGetTexParameteriv):=GetProcAddress(hlib,'glGetTexParameteriv');
      pointer(glGetTexParameterxv):=GetProcAddress(hlib,'glGetTexParameterxv');
      pointer(glHint):=GetProcAddress(hlib,'glHint');
      pointer(glIsBuffer):=GetProcAddress(hlib,'glIsBuffer');
      pointer(glIsEnabled):=GetProcAddress(hlib,'glIsEnabled');
      pointer(glIsTexture):=GetProcAddress(hlib,'glIsTexture');
      pointer(glLightModelx):=GetProcAddress(hlib,'glLightModelx');
      pointer(glLightModelxv):=GetProcAddress(hlib,'glLightModelxv');
      pointer(glLightx):=GetProcAddress(hlib,'glLightx');
      pointer(glLightxv):=GetProcAddress(hlib,'glLightxv');
      pointer(glLineWidthx):=GetProcAddress(hlib,'glLineWidthx');
      pointer(glLoadIdentity):=GetProcAddress(hlib,'glLoadIdentity');
      pointer(glLoadMatrixx):=GetProcAddress(hlib,'glLoadMatrixx');
      pointer(glLogicOp):=GetProcAddress(hlib,'glLogicOp');
      pointer(glMaterialx):=GetProcAddress(hlib,'glMaterialx');
      pointer(glMaterialxv):=GetProcAddress(hlib,'glMaterialxv');
      pointer(glMatrixMode):=GetProcAddress(hlib,'glMatrixMode');
      pointer(glMultMatrixx):=GetProcAddress(hlib,'glMultMatrixx');
      pointer(glMultiTexCoord4x):=GetProcAddress(hlib,'glMultiTexCoord4x');
      pointer(glNormal3x):=GetProcAddress(hlib,'glNormal3x');
      pointer(glNormalPointer):=GetProcAddress(hlib,'glNormalPointer');
      pointer(glOrthox):=GetProcAddress(hlib,'glOrthox');
      pointer(glPixelStorei):=GetProcAddress(hlib,'glPixelStorei');
      pointer(glPointParameterx):=GetProcAddress(hlib,'glPointParameterx');
      pointer(glPointParameterxv):=GetProcAddress(hlib,'glPointParameterxv');
      pointer(glPointSizex):=GetProcAddress(hlib,'glPointSizex');
      pointer(glPolygonOffsetx):=GetProcAddress(hlib,'glPolygonOffsetx');
      pointer(glPopMatrix):=GetProcAddress(hlib,'glPopMatrix');
      pointer(glPushMatrix):=GetProcAddress(hlib,'glPushMatrix');
      pointer(glReadPixels):=GetProcAddress(hlib,'glReadPixels');
      pointer(glRotatex):=GetProcAddress(hlib,'glRotatex');
      pointer(glSampleCoverage):=GetProcAddress(hlib,'glSampleCoverage');
      pointer(glSampleCoveragex):=GetProcAddress(hlib,'glSampleCoveragex');
      pointer(glScalex):=GetProcAddress(hlib,'glScalex');
      pointer(glScissor):=GetProcAddress(hlib,'glScissor');
      pointer(glShadeModel):=GetProcAddress(hlib,'glShadeModel');
      pointer(glStencilFunc):=GetProcAddress(hlib,'glStencilFunc');
      pointer(glStencilMask):=GetProcAddress(hlib,'glStencilMask');
      pointer(glStencilOp):=GetProcAddress(hlib,'glStencilOp');
      pointer(glTexCoordPointer):=GetProcAddress(hlib,'glTexCoordPointer');
      pointer(glTexEnvi):=GetProcAddress(hlib,'glTexEnvi');
      pointer(glTexEnvx):=GetProcAddress(hlib,'glTexEnvx');
      pointer(glTexEnviv):=GetProcAddress(hlib,'glTexEnviv');
      pointer(glTexEnvxv):=GetProcAddress(hlib,'glTexEnvxv');
      pointer(glTexImage2D):=GetProcAddress(hlib,'glTexImage2D');
      pointer(glTexParameteri):=GetProcAddress(hlib,'glTexParameteri');
      pointer(glTexParameterx):=GetProcAddress(hlib,'glTexParameterx');
      pointer(glTexParameteriv):=GetProcAddress(hlib,'glTexParameteriv');
      pointer(glTexParameterxv):=GetProcAddress(hlib,'glTexParameterxv');
      pointer(glTexSubImage2D):=GetProcAddress(hlib,'glTexSubImage2D');
      pointer(glTranslatex):=GetProcAddress(hlib,'glTranslatex');
      pointer(glVertexPointer):=GetProcAddress(hlib,'glVertexPointer');
      pointer(glViewport):=GetProcAddress(hlib,'glViewport');
      pointer(glPointSizePointerOES):=GetProcAddress(hlib,'glPointSizePointerOES');
    end;

procedure initModule;
begin
    Loadgles11('libGLESv1_CM.so');
end;

procedure freeModule;
begin
  Freegles11;
end;

end.
