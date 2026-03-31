@group(0) @binding(0) var<uniform> resolution: vec2f;
@group(0) @binding(1) var<uniform> mouse:   vec3f;
@group(0) @binding(4) var<uniform> keyboard: vec4f;
@group(0) @binding(5) var<uniform> slider:   vec4f;
@group(0) @binding(2) var videoSampler:   sampler;
@group(0) @binding(3) var backBuffer:     texture_2d<f32>;
@group(1) @binding(0) var videoBuffer:    texture_external;

@fragment 
fn fs( @builtin(position) pos : vec4f ) -> @location(0) vec4f {
  let p = pos.xy / resolution;

  let video = textureSampleBaseClampToEdge( videoBuffer, videoSampler, p );

  let fb = textureSample( backBuffer, videoSampler, p );

  let out = video * .05 + fb * .975;

  // Slider debug effect: overlay color based on slider.x value
  let overlay = vec4f(1.0, 0.0, 0.0, 1.0);
  let finalColor = mix(vec4f(out.rgb, 1.0), overlay, slider.x);

  return finalColor;
}
