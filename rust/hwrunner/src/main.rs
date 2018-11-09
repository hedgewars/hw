use glutin::{
    dpi::LogicalSize,
    Event,
    WindowEvent,
    EventsLoop,
    GlWindow,
};

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
        })
    }
}
