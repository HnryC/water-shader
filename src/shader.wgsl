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

fn rand(tex_coords: vec2<f32>) -> f32 {
    return fract(sin(dot(tex_coords,
                         vec2(12.9898,78.233)))*
        43758.5453123);
//  return vec2<f32>(fract(pow(x, 5.0)), fract(pow(y, 5.0)));
//  return vec2<f32>(sin(tex_coords.x * 20.8333), cos(tex_coords.y * 20.));
}

fn noise(tex_coords: vec2<f32>) -> f32 {
    let i = floor(tex_coords);
    let f = fract(tex_coords);
    let a = rand(i);
    let b = rand(i + vec2<f32>(1.0, 0.0));
    let c = rand(i + vec2<f32>(0.0, 1.0));
    let d = rand(i + vec2<f32>(1.0, 1.0));

    let u = f*f*(3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a)* u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

@fragment
fn fs_main_water(in: VertexOutput) -> @location(0) vec4<f32> {
//  let random = noise(vec2<f32>(in.time * 30.0 + in.tex_coords.x, in.time * 33.3 + in.tex_coords.y));
//  return vec4<f32>(random, random, random, 1.0);
    let random = (noise(vec2<f32>(in.time + in.tex_coords.x, in.time + in.tex_coords.y)) - 0.5) * 0.01;
    return textureSample(t_diffuse, s_diffuse, vec2<f32>(clamp(in.tex_coords.x + random, 0.0, 1.0), clamp(in.tex_coords.y + random, 0.0, 0.5)));
}
