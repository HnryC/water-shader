mod defs;
use wgpu::include_wgsl;
use winit::{
    event::*,
    event_loop::{ControlFlow, EventLoop},
    window::{Window, WindowBuilder},
};

// Structure which contains basic state information for the program
struct State {
    surface: wgpu::Surface,
    config: wgpu::SurfaceConfiguration,
    size: winit::dpi::PhysicalSize<u32>,
    device: wgpu::Device,
    queue: wgpu::Queue,
    background: defs::Background,
    sampler: wgpu::Sampler,
    water: defs::Water,
}

impl State {
    async fn new(window: &Window) -> Self {
        let size = window.inner_size();

        let instance = wgpu::Instance::new(wgpu::Backends::all());
        let surface = unsafe { instance.create_surface(window) };
        let adapter = instance
            .request_adapter(&wgpu::RequestAdapterOptionsBase {
                // Prefers dedicated gpu over cpu based gpu
                power_preference: wgpu::PowerPreference::HighPerformance,
                force_fallback_adapter: false,
                compatible_surface: Some(&surface),
            })
            .await
            .unwrap();

        let (device, queue) = adapter
            .request_device(
                &wgpu::DeviceDescriptor {
                    features: wgpu::Features::empty(),
                    limits: wgpu::Limits::default(),
                    label: None,
                },
                None,
            )
            .await
            .unwrap();
        let config = wgpu::SurfaceConfiguration {
            usage: wgpu::TextureUsages::RENDER_ATTACHMENT,
            format: surface.get_supported_formats(&adapter)[0],
            alpha_mode: wgpu::CompositeAlphaMode::Auto,
            width: size.width,
            height: size.height,
            present_mode: wgpu::PresentMode::Fifo,
        };

        // Background texture loading
        let diffuse_bytes = include_bytes!("top.jpg");
        let background_texture =
            defs::Texture::from_bytes(&device, &queue, diffuse_bytes, "top.jpg").unwrap();

        let shader = device.create_shader_module(include_wgsl!("shader.wgsl"));
        let background = defs::Background::new(
            background_texture,
            &device,
            &shader,
            adapter,
            &surface,
            size,
        );

        let sampler = device.create_sampler(&wgpu::SamplerDescriptor {
            address_mode_u: wgpu::AddressMode::ClampToEdge,
            address_mode_v: wgpu::AddressMode::ClampToEdge,
            address_mode_w: wgpu::AddressMode::ClampToEdge,
            mag_filter: wgpu::FilterMode::Linear,
            min_filter: wgpu::FilterMode::Nearest,
            mipmap_filter: wgpu::FilterMode::Nearest,
            ..Default::default()
        });

        let texture_bind_group_layout =
            device.create_bind_group_layout(&wgpu::BindGroupLayoutDescriptor {
                label: Some("Texture Bind Group Layout"),
                entries: &[
                    wgpu::BindGroupLayoutEntry {
                        binding: 0,
                        visibility: wgpu::ShaderStages::FRAGMENT,
                        ty: wgpu::BindingType::Texture {
                            sample_type: wgpu::TextureSampleType::Float { filterable: true },
                            view_dimension: wgpu::TextureViewDimension::D2,
                            multisampled: false,
                        },
                        count: None,
                    },
                    wgpu::BindGroupLayoutEntry {
                        binding: 1,
                        visibility: wgpu::ShaderStages::FRAGMENT,
                        ty: wgpu::BindingType::Sampler(wgpu::SamplerBindingType::Filtering),
                        count: None,
                    },
                ],
            });

        let water = defs::Water::new(&device, &shader, &config, &texture_bind_group_layout);
        surface.configure(&device, &config);
        State {
            surface,
            config,
            size,
            device,
            queue,
            background,
            sampler,
            water,
        }
    }

    // Updates internal size when window is resized
    fn resize(&mut self, new_size: winit::dpi::PhysicalSize<u32>) {
        if new_size.height == 0 || new_size.width == 0 {
            return;
        }

        self.size = new_size;
        self.config.width = self.size.width;
        self.config.height = self.size.height;
        self.surface.configure(&self.device, &self.config);
    }

    fn render(&mut self) -> Result<(), wgpu::SurfaceError> {
        // Create output texture for rendering
        let output = self.surface.get_current_texture()?;

        // Create a texture that can be read to and wrote from:
        //  Allows for water shader to read from rendered output so it would reflect moving
        //  characters
        let new = self.device.create_texture(&wgpu::TextureDescriptor {
            label: Some("New texture"),
            size: wgpu::Extent3d {
                width: self.size.width,
                height: self.size.height,
                depth_or_array_layers: 1,
            },
            mip_level_count: 1,
            sample_count: 1,
            dimension: wgpu::TextureDimension::D2,
            format: wgpu::TextureFormat::Bgra8UnormSrgb,
            usage: wgpu::TextureUsages::RENDER_ATTACHMENT
                | wgpu::TextureUsages::TEXTURE_BINDING
                | wgpu::TextureUsages::COPY_SRC,
        });

        // Draws background to both the screen texture and the texture to be read by self.water
        self.background.draw(&new, &self.device, &self.queue);
        self.background
            .draw(&output.texture, &self.device, &self.queue);

        // Creates view of output to be rendered to
        let view = output
            .texture
            .create_view(&wgpu::TextureViewDescriptor::default());

        self.water
            .draw(&self.device, &view, &self.sampler, &self.queue, &new);

        // Draws contents of output texture to screen
        output.present();

        Ok(())
    }
}

pub async fn run() {
    // Without env_logger wgpu errors are not useful
    env_logger::init();
    // Winit initilisation
    let event_loop = EventLoop::new();
    let window = WindowBuilder::new()
        .build(&event_loop)
        .expect("Failed to build window. Unable to recover from error.");
    // Asyncronous builder for the state struct
    let mut state = State::new(&window).await;

    event_loop.run(move |event, _, control_flow| match event {
        Event::WindowEvent {
            ref event,
            window_id,
        } if window_id == window.id() => {
            match event {
                // Nessacary to
                WindowEvent::CloseRequested => *control_flow = ControlFlow::Exit,

                WindowEvent::Resized(physical_size) => state.resize(*physical_size),
                WindowEvent::ScaleFactorChanged { new_inner_size, .. } => {
                    state.resize(**new_inner_size)
                }

                _ => {}
            }
        }

        Event::MainEventsCleared => {
            window.request_redraw();
        }

        Event::RedrawRequested(window_id) if window_id == window.id() => {
            match state.render() {
                Ok(_) => {}
                // Reconfigure lost surface
                Err(wgpu::SurfaceError::Lost) => {
                    state.resize(state.size);
                    eprintln!("Loss of surface");
                }
                // suicide
                Err(wgpu::SurfaceError::OutOfMemory) => {
                    *control_flow = ControlFlow::ExitWithCode(5)
                }

                // Other errors will be fixed in next frame
                Err(e) => eprintln!("{}", e),
            }
        }

        _ => {}
    });
}
