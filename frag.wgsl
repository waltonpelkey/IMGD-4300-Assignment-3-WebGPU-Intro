@group(0) @binding(0) var<uniform> resolution: vec2f;
@group(0) @binding(1) var<uniform> mouse:   vec3f;
@group(0) @binding(4) var<uniform> keyboard: vec4f;
@group(0) @binding(5) var<uniform> slider:   vec4f;
@group(0) @binding(6) var<uniform> audio:    vec4f;
@group(0) @binding(2) var videoSampler:   sampler;
@group(0) @binding(3) var backBuffer:     texture_2d<f32>;
@group(1) @binding(0) var videoBuffer:    texture_external;

@fragment 
fn fs( @builtin(position) pos : vec4f ) -> @location(0) vec4f {
  let p = pos.xy / resolution;

  let video = textureSampleBaseClampToEdge( videoBuffer, videoSampler, p );

  let fb = textureSample( backBuffer, videoSampler, p );

  // Fully controlled grayscale from slider.
  let gray = clamp(slider.x, 0.0, 1.0);

  // Audio-reactive brightness from low/mid/high levels.
  let a = clamp(audio.x * 0.6 + audio.y * 0.3 + audio.z * 0.1, 0.0, 1.0);
  let mixed = mix(vec3f(gray), vec3f(1.0), a);

  return vec4f(mixed, 1.0);
}
