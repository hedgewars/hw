// !!!just testing!!! 
// This is not GLSL 1.3+ compatible, as its using the compatibility profile!
uniform mat4 mvp;
varying vec4 tint;

void main()
{
    gl_Position = mvp * gl_Vertex;
    gl_TexCoord[0] = gl_MultiTexCoord0;
    tint = gl_Color;
}
