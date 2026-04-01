// shader inputs
@group(0) @binding(0) var<uniform> resolution: vec2f;
@group(0) @binding(1) var<uniform> slider: vec4f;
@group(0) @binding(2) var<uniform> audio: vec4f;
@group(0) @binding(3) var<uniform> time: f32;
@group(0) @binding(4) var<storage, read> ripples: ripple_buffer;
@group(0) @binding(5) var video_sampler: sampler;
@group(1) @binding(0) var video_buffer: texture_external;

// how many ripples we can check
const max_ripples = 32;

// this stores all ripple data
struct ripple_buffer {
    data: array<vec4f, max_ripples>
};

// squared length of a 2d point
fn vector_length_squared(point: vec2f) -> f32 {
    return dot(point, point);
}

// makes one repeatable random value
fn random_value(point: vec2f) -> f32 {
    return fract(sin(fract(sin(point.x) * 34.1423423) + point.y) * 12.24233523);
}

// gets one worley value from a point
fn worley_value(point: vec2f) -> f32 {
    // start with a very big distance
    var closest_distance: f32 = 1e30;

    // this is the cell the point is in
    let cell_point = floor(point);

    // check nearby cells too
    for (var x_offset: i32 = -1; x_offset <= 1; x_offset = x_offset + 1) {
        for (var y_offset: i32 = -1; y_offset <= 1; y_offset = y_offset + 1) {
            // test one nearby cell
            let test_cell = cell_point + vec2f(f32(x_offset), f32(y_offset));

            // make a random feature point inside that cell
            let feature_point = test_cell + vec2f(
                random_value(test_cell),
                random_value(test_cell + vec2f(1.234, 4.567))
            );

            // get the distance to that feature point
            let current_distance = vector_length_squared(point - feature_point);

            // keep the smallest one
            closest_distance = min(closest_distance, current_distance);
        }
    }

    // turn that distance into a worley pattern
    return 10.0 * exp(-2.2 * abs(2.0 * closest_distance - 1.0));
}

// mixes a few worley layers together
fn water_noise(point: vec2f) -> f32 {
    // big layer
    let first_layer = worley_value(point * 5.0 + vec2f(0.05 * time));

    // medium layer
    let second_layer = worley_value(point * 50.0 + vec2f(0.12 - 0.1 * time));

    // weird extra layer
    let third_layer = worley_value(point * -10.0 + vec2f(0.03 * time));

    // mix them into one water pattern
    return sqrt(sqrt(sqrt(first_layer * sqrt(second_layer * 2.0) * sqrt(sqrt(third_layer)))));
}

// this gives one ripple its ring shape
fn ripple_shape(distance_from_ring: f32) -> f32 {
    return sin(31.0 * distance_from_ring)
        * smoothstep(-0.12, -0.06, distance_from_ring)
        * smoothstep(0.0, -0.06, distance_from_ring);
}

// this runs once for each pixel
@fragment
fn fs(@builtin(position) pos: vec4f) -> @location(0) vec4f {
    // turn screen position into 0 to 1 space
    let screen_uv = pos.xy / resolution;

    // fix the shape so circles stay circles
    let screen_shape = vec2f(resolution.x / resolution.y, 1.0);

    // add up ripple effects here
    var total_ripple_offset = vec2f(0.0, 0.0);
    var total_ripple_light = 0.0;
    var ripple_count = 0.0;

    // check every ripple we have
    for (var ripple_index = 0; ripple_index < max_ripples; ripple_index = ripple_index + 1) {
        // get one ripple from the list
        let ripple_data = ripples.data[ripple_index];

        // how long this ripple has been alive
        let ripple_time = time - ripple_data.z;

        // only use ripples that are still alive
        if (ripple_data.w > 0.0 && ripple_time >= 0.0 && ripple_time < 3.0) {
            // line from the ripple center to this pixel
            let ripple_line = (screen_uv - ripple_data.xy) * screen_shape;

            // distance from this pixel to the ripple center
            let ripple_distance = length(ripple_line);

            // current ripple size
            let ripple_size = 0.35 * ripple_data.w * (1.0 - exp(-1.5 * ripple_time));

            // how far this pixel is from the ripple ring
            let distance_from_ring = ripple_distance - ripple_size;

            // only keep pixels near the ripple ring
            let ripple_band = smoothstep(-0.12, -0.06, distance_from_ring)
                * smoothstep(0.0, -0.06, distance_from_ring);

            // only do the ripple math if this pixel is on the ring
            if (ripple_band > 0.001 && ripple_distance > 0.0001) {
                // tiny gap for checking the ring on both sides
                let sample_size = 0.003;

                // one sample a little before the ring
                let ring_before = distance_from_ring - sample_size;

                // one sample a little after the ring
                let ring_after = distance_from_ring + sample_size;

                // ripple value before the ring
                let wave_before = ripple_shape(ring_before);

                // ripple value after the ring
                let wave_after = ripple_shape(ring_after);

                // slope of the ripple
                let ripple_slope = (wave_after - wave_before) / (2.0 * sample_size);

                // fade the ripple out over time
                let ripple_fade = pow(1.0 - ripple_time / 3.0, 2.0);

                // add this ripple to the total offset and light
                total_ripple_offset += normalize(ripple_line) * ripple_slope * ripple_fade * 0.018;
                total_ripple_light += max(0.0, wave_after) * ripple_fade;
                ripple_count += 1.0;
            }
        }
    }

    // average all ripple effects
    var average_ripple_offset = vec2f(0.0, 0.0);
    var average_ripple_light = 0.0;
    if (ripple_count > 0.0) {
        average_ripple_offset = total_ripple_offset / ripple_count;
        average_ripple_light = total_ripple_light / ripple_count;
    }

    // move the water by the ripple amount
    let moved_uv = screen_uv - average_ripple_offset;

    // this moves the audio pattern across the screen
    let audio_flow = vec2f(
        0.05 + audio.x * 0.12,
        -0.04 - audio.y * 0.10
    );

    // point used for the audio worley distortion
    let audio_noise_point = moved_uv * 3.5 + time * audio_flow;

    // how strong the audio distortion should be
    let audio_strength = 0.002 + (audio.x + audio.y) * 0.002;

    // use worley to bend the water a little from audio
    let audio_distortion = vec2f(
        (worley_value(audio_noise_point + vec2f(1.3, 2.1))
            - worley_value(audio_noise_point + vec2f(4.7, 3.2))) * audio_strength,
        (worley_value(audio_noise_point + vec2f(2.4, 5.1))
            - worley_value(audio_noise_point + vec2f(6.2, 1.8))) * audio_strength
    );

    // final uv after ripple and audio movement
    let water_uv = moved_uv + audio_distortion;

    // point used for the main water noise
    let noise_point = water_uv * (resolution / vec2f(1500.0, 1500.0));

    // main water pattern amount
    let noise_amount = water_noise(noise_point);

    // darkens parts of the screen away from the bright area
    let light_dropoff = exp(-vector_length_squared(abs(0.7 * water_uv - vec2f(1.0))));

    // final brightness of the water
    let brightness = clamp(noise_amount * light_dropoff, 0.0, 1.0);

    // how much green to mix in
    let green_amount = clamp(slider.x, 0.0, 1.0);

    // dark blue water color
    let dark_blue = vec3f(0.08, 0.40, 1.0);

    // greener water color
    let blue_green = vec3f(0.12, 0.88, 1.0);

    // mix between the two water colors
    let water_color = mix(dark_blue, blue_green, green_amount);

    // base water color
    let base_color = water_color * (0.2 + 0.8 * brightness);

    // bright lines in the water
    let bright_color = vec3f(0.02, 0.05, 0.2) * pow(brightness, 5.0);

    // start the final color
    var final_color = base_color + bright_color;

    // add a little extra light from the ripples
    final_color += vec3f(average_ripple_light * 0.02);

    // bend the webcam a little so it feels more like a reflection
    let video_warp = vec2f(
        worley_value(noise_point + vec2f(2.0, 0.0)) - worley_value(noise_point + vec2f(5.0, 1.0)),
        worley_value(noise_point + vec2f(0.0, 3.0)) - worley_value(noise_point + vec2f(4.0, 6.0))
    ) * 0.01 + average_ripple_offset * 0.6;

    // sample the webcam in the normal screen direction
    let video_uv = clamp(vec2f(1.0 - water_uv.x, water_uv.y) + video_warp, vec2f(0.0), vec2f(1.0));
    let video_color = textureSampleBaseClampToEdge(video_buffer, video_sampler, video_uv).rgb;

    // tint the webcam so it feels like it is inside the water
    let reflected_video = video_color * vec3f(0.18, 0.35, 0.48);

    // mix in a little of the webcam reflection
    final_color = final_color + reflected_video * 0.65;

    // send the final color out
    return vec4f(final_color, 1.0);
}
