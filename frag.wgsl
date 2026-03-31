@group(0) @binding(0) var<uniform> resolution: vec2f;
@group(0) @binding(1) var<uniform> mouse:   vec3f;
@group(0) @binding(2) var videoSampler:   sampler;
@group(0) @binding(3) var backBuffer:     texture_2d<f32>;
@group(1) @binding(0) var videoBuffer:    texture_external;

@fragment 
fn fs( @builtin(position) pos : vec4f ) -> @location(0) vec4f {
  let p = pos.xy / resolution;

  let video = textureSampleBaseClampToEdge( videoBuffer, videoSampler, p );

  let fb = textureSample( backBuffer, videoSampler, p );

  let out = video * .05 + fb * .975;

  // Test: draw a circle at mouse position
  let mouseDist = distance( p, mouse.xy );
  let circle = smoothstep( 0.05, 0.04, mouseDist );
  
  // Add red circle if mouse is clicked, white if just hovering
  let mouseColor = mix( vec4f(1., 1., 1., 1.), vec4f(1., 0., 0., 1.), mouse.z );
  
  return mix( vec4f(out.rgb, 1.), mouseColor, circle );
}

// Keyboard input
// Mouse input
// Slider input
// Audio Input

