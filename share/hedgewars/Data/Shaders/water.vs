#ifdef GL_ES
precision mediump float;
#endif

attribute vec2 vertex;
attribute vec4 color;

varying vec4 vcolor;

uniform mat4 mvp;

void main()
{
    vec4 p = mvp * vec4(vertex, 0.0, 1.0);
    gl_Position = p;
    vcolor = color;
}
