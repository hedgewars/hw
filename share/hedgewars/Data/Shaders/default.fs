// !!!just testing!!! 
// This is not GLSL 1.3+ compatible, as its using the compatibility profile!
uniform sampler2D tex0;
varying vec4 tint;

void main()
{
    gl_FragColor = texture2D(tex0, gl_TexCoord[0].st) * tint;
}
