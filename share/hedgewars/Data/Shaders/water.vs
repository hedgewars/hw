#version 130

in vec2 vertex;
in vec4 color;
out vec4 vcolor;

uniform mat4 mvp;

void main()
{
    vec4 p = mvp * vec4(vertex, 0.0f, 1.0f);
    gl_Position = p;
    vcolor = color;
}
