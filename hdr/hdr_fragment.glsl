#version 330 core

out vec4 FragColor;

in vec2 TexCoords;

uniform sampler2D screenTexture;

void main() {
  const float gamma = 2.2;
  const float exposure = 5.0;
  vec3 hdrColor = texture(screenTexture, TexCoords).rgb;
  vec3 result = vec3(1.0) - exp(-hdrColor * exposure);

  // Apply gamma correction
  result = pow(hdrColor, vec3(1.0 / gamma));
  FragColor = vec4(result, 1.0);
}
