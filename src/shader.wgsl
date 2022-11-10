// Vertex shader
struct VertexOutput {
    @builtin(position) clip_position: vec4<f32>,
    @location(0) tex_coords: vec2<f32>,
    @location(1) time: f32
};

struct VertexInput {
    @location(0) pos: vec3<f32>,
    @location(1) tex_coords: vec2<f32>,
    @location(2) seed: f32,
}

@vertex
fn vs_main(model: VertexInput) -> VertexOutput {
    var out: VertexOutput;
    out.tex_coords = model.tex_coords;
    out.clip_position = vec4<f32>(model.pos, 1.0);
    out.time = model.seed;
    return out;
}

@group(0) @binding(0)
var t_diffuse: texture_2d<f32>;
@group(0)@binding(1)
var s_diffuse: sampler;

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    return textureSample(t_diffuse, s_diffuse, in.tex_coords);
}

fn rand(tex_coords: vec2<f32>) -> vec2<f32> {
    // Psudo random number generator
    let tex_coords = vec2( dot(tex_coords,vec2(127.1,311.7)),
              dot(tex_coords,vec2(269.5,183.3)) );
    return -1.0 + 2.0 * fract(sin(tex_coords) * 43758.5453123);
}

fn noise(tex_coords: vec2<f32>) -> f32 {
    // Gradient noise
    let i = floor(tex_coords);
    let f = fract(tex_coords);

    let u = f*f*(3.0 - 2.0 * f);

    return mix( mix( dot( rand(i + vec2(0.0,0.0) ), f - vec2(0.0,0.0) ),
                     dot( rand(i + vec2(1.0,0.0) ), f - vec2(1.0,0.0) ), u.x),
                mix( dot( rand(i + vec2(0.0,1.0) ), f - vec2(0.0,1.0) ),
                     dot( rand(i + vec2(1.0,1.0) ), f - vec2(1.0,1.0) ), u.x), u.y);
}

@fragment
fn fs_main_water(in: VertexOutput) -> @location(0) vec4<f32> {
    // Used for testing noise function
    // let random = noise(vec2<f32>(in.time + in.tex_coords.x, in.time + in.tex_coords.y));
    // return vec4<f32>(random, random, random, 1.0);

    // Creates random offset for each pixel
    let random = (noise(vec2<f32>(in.time + in.tex_coords.x, in.time + in.tex_coords.y)) - 0.5) * 0.01 * clamp((in.tex_coords.y - 0.5) * -3.0, 0.3, 1.0);
    return textureSample(t_diffuse, s_diffuse, vec2<f32>(clamp(in.tex_coords.x + random, 0.0, 1.0), clamp(in.tex_coords.y + random, 0.0, 0.5)));
}
