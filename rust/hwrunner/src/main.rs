use glutin::{
    dpi::LogicalSize,
    Event,
    WindowEvent,
    EventsLoop,
    GlWindow,
    GlContext
};

use gfx::{
    texture,
    format,
    Encoder
};

use gfx_window_glutin::init_existing;

use hedgewars_engine::EngineInstance;

fn init(event_loop: &EventsLoop, size: LogicalSize) -> GlWindow {
    use glutin::{
        ContextBuilder,
        WindowBuilder
    };

    let window = WindowBuilder::new()
        .with_title("hwengine")
        .with_dimensions(size);

    let context = ContextBuilder::new();
    GlWindow::new(window, context, event_loop).unwrap()
}

fn main() {
    let mut event_loop = EventsLoop::new();
    let window = init(&event_loop, LogicalSize::new(1024.0, 768.0));

    let (mut device, mut factory, color_view, depth_view) =
        init_existing::<format::Rgba8, format::Depth>(&window);

    let mut encoder: Encoder<_, _> = factory.create_command_buffer().into();

    let engine = EngineInstance::new();

    let mut is_running = true;
    while is_running {
        event_loop.poll_events(|event| {
            match event {
                Event::WindowEvent { event, ..} => match event {
                    WindowEvent::CloseRequested => {
                        is_running = false;
                    },
                    _ => ()
                },
                _ => ()
            }
        });

        encoder.clear(&color_view, [0.5, 0.0, 0.0, 1.0]);
        engine.render(&mut encoder, &color_view);

        encoder.flush(&mut device);

        window.swap_buffers().unwrap();
    }
}
