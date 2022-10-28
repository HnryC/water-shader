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

fn rand(tex_coords: vec2<f32>) -> vec2<f32> {
    let x = sin(tex_coords.x) * 1239.98;
    let y = cos(tex_coords.y) * 1239.98;
    var x_sighn = 0.0;
    if x >= 0.0 {
        x_sighn += 1.0;
    } else {
        x_sighn -= 1.0;
    }

    var y_sighn = 0.0;
    if y >= 0.0 {
        y_sighn += 1.0;
    } else {
        y_sighn -= 1.0;
    }

    return vec2<f32>(x_sighn * fract(x), y_sighn * fract(y));
}

@fragment
fn fs_main_water(in: VertexOutput) -> @location(0) vec4<f32> {
    let random = rand(in.tex_coords + in.time) * 0.005;
    return textureSample(t_diffuse, s_diffuse, vec2<f32>(in.tex_coords.x + random.x, in.tex_coords.y + random.y));
}
