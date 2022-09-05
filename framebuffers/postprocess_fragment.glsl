#version 330 core

out vec4 FragColor;

in vec2 TexCoords;

uniform sampler2D screenTexture;

void main() {

  ivec2 texture_size = textureSize(screenTexture, 0);
  vec2 offset = 1.0 / texture_size;
  vec2 offsets[9] = vec2[](
    vec2(-offset.x,  offset.y), // top-left
    vec2( 0.0f,      offset.y), // top-center
    vec2( offset.x,  offset.y), // top-right
    vec2(-offset.x,  0.0f),   // center-left
    vec2( 0.0f,      0.0f),   // center-center
    vec2( offset.x,  0.0f),   // center-right
    vec2(-offset.x, -offset.y), // bottom-left
    vec2( 0.0f,     -offset.y), // bottom-center
    vec2( offset.x, -offset.y)  // bottom-right
  );

  // Sharp
  /*
  float kernel[9] = float[](
    -1, -1, -1,
    -1,  9, -1,
    -1, -1, -1
  );
  */

  // Blur
  /*
  float kernel[9] = float[](
    1.0/16,  2.0/16,  1.0/16,
    2.0/16,  4.0/16,  2.0/16,
    1.0/16,  2.0/16,  1.0/16
  );
  */

  // Edges
  float kernel[9] = float[](
    1,  1, 1,
    1, -8, 1,
    1,  1, 1
  );


  // Test
  /*
  float kernel[9] = float[](
    -1.0,  1.0, -1.0,
     1.0,  2.0,  1.0,
    -1.0,  1.0, -1.0
  );
  */

  // Normal
  /*
  float kernel[9] = float[](
    0, 0, 0,
    0, 1, 0,
    0, 0, 0
  );
  */

  vec3 sampleTex[9];
  for(int i=0; i < 9; i++){
    sampleTex[i] = vec3(texture(screenTexture, TexCoords.st + offsets[i]));
  }

  vec3 color = vec3(0.0);
  for(int i=0; i < 9; i++){
    color += sampleTex[i] * kernel[i];
  }
  FragColor = vec4(color, 1.0);

  // Grayscale post processing
  //FragColor = texture(screenTexture, TexCoords);
  //float avg = 0.2126 * FragColor.r + 0.7152 * FragColor.g + 0.0722 * FragColor.b;
  //FragColor = vec4(avg, avg, avg, 1.0);
}
