uniform sampler2D tex0;
uniform vec4 tint;
uniform bool enableTexture;

varying vec2 tex;


void main()
{
    if(enableTexture){
        gl_FragColor = texture2D(tex0, tex) * tint;
    }else{
        gl_FragColor = tint;
    }
}
