#version 130

uniform sampler2D tex0;
uniform vec4 tint;

in vec2 tex;

out vec4 color;

void main()
{
    color = texture(tex0, tex) * tint;
}
