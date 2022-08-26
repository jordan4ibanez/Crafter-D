#version 410 core

in vec2 outputTextureCoordinate;
in vec3 outputColor;
out vec4 fragColor;

uniform sampler2D textureSampler;
uniform float light;

void main()
{
    fragColor = texture(textureSampler, outputTextureCoordinate) * vec4(outputColor, 1.0) * light;
}