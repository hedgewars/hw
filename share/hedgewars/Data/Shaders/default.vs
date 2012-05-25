// !!!just testing!!! 
// This is not GLSL 1.3+ compatible, as its using the compatibility profile!
varying vec4 tint;

void main()
{
    gl_Position = ftransform();
    gl_TexCoord[0] = gl_MultiTexCoord0;
    tint = gl_Color;
}
