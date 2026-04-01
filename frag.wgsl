@group(0) @binding(0) var<uniform> resolution: vec2f;
@group(0) @binding(1) var<uniform> mouse:   vec3f;
@group(0) @binding(4) var<uniform> keyboard: vec4f;
@group(0) @binding(5) var<uniform> slider:   vec4f;
@group(0) @binding(6) var<uniform> audio:    vec4f;
@group(0) @binding(7) var<uniform> time:     f32;
@group(0) @binding(2) var videoSampler:   sampler;
@group(0) @binding(3) var backBuffer:     texture_2d<f32>;
@group(1) @binding(0) var videoBuffer:    texture_external;

fn length2(p: vec2f) -> f32 {
    return dot(p, p);
}

fn noise2(p: vec2f) -> f32 {
    return fract(sin(fract(sin(p.x) * 43.13311) + p.y) * 31.0011);
}

fn worley(p: vec2f) -> f32 {
    var d: f32 = 1e30;
    let ip = floor(p);
    for (var xo: i32 = -1; xo <= 1; xo = xo + 1) {
        for (var yo: i32 = -1; yo <= 1; yo = yo + 1) {
            let tp = ip + vec2f(f32(xo), f32(yo));
            let f = tp + vec2f(noise2(tp), noise2(tp + vec2f(1.234, 4.567)));
            let dd = length2(p - f);
            d = min(d, dd);
        }
    }
    return 3.0 * exp(-4.0 * abs(2.5 * d - 1.0));
}

fn fworley(p: vec2f) -> f32 {
    let a = worley(p * 5.0 + vec2f(0.05 * time));
    let b = worley(p * 50.0 + vec2f(0.12 - 0.1 * time));
    let c = worley(p * -10.0 + vec2f(0.03 * time));
    return sqrt(sqrt(sqrt(a * sqrt(b) * sqrt(sqrt(c)))));
}

@fragment 
fn fs( @builtin(position) pos : vec4f ) -> @location(0) vec4f {
    let uv = pos.xy / resolution;
    let coords = uv * (resolution / vec2f(1500.0, 1500.0));
    let t = fworley(coords);
    let gradient = exp(-length2(abs(0.7 * uv - vec2f(1.0))));
    let intensity = clamp(t * gradient, 0.0, 1.0);
    let color = vec3f(intensity * 0.1, intensity * 1.1 * intensity, pow(intensity, 0.5 - intensity));
    return vec4f(color, 1.0);
}
