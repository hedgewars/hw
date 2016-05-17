precision mediump float;

attribute vec2 vertex;
attribute vec2 texcoord;
attribute vec4 colors;

varying vec2 tex;

uniform mat4 mvp;

void main()
{
    vec4 p = mvp * vec4(vertex, 0.0, 1.0);
    gl_Position = p;
    tex = texcoord;
}
