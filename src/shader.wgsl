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
    out.time = 0.8;
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
    let x = sin(tex_coords.x) * 21.23;
    let y = cos(tex_coords.y) * 12.27;
    return (fract(pow(x, 5.0)) + fract(pow(y, 5.0))) * 0.5;
//  return vec2<f32>(fract(pow(x, 5.0), fract(pow(y, 5.0)));
}

@fragment
fn fs_main_water(in: VertexOutput) -> @location(0) vec4<f32> {
    let random = rand(vec2<f32>(in.time * 30.0 + in.tex_coords.x, in.time * 33.3 + in.tex_coords.y));
    return vec4<f32>(random, random, random, 1.0);
//  let random = rand(vec2<f32>(in.time * 30.0, in.time * 33.3)) * 0.05;
//  return textureSample(t_diffuse, s_diffuse, vec2<f32>(in.tex_coords.x + random.x, in.tex_coords.y + random.y));
}
