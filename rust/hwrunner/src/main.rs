use glutin::{
    dpi,
    Event,
    WindowEvent,
    DeviceEvent,
    ElementState,
    MouseButton,
    MouseScrollDelta,
    EventsLoop,
    WindowedContext,
    GlRequest,
    GlProfile,
    ContextTrait,
};

use hedgewars_engine::{
    instance::EngineInstance,
};

use integral_geometry::Point;

fn init(event_loop: &EventsLoop, size: dpi::LogicalSize) -> WindowedContext {
    use glutin::{
        ContextBuilder,
        WindowBuilder
    };

    let window = WindowBuilder::new()
        .with_title("hwengine")
        .with_dimensions(size);

    let cxt = ContextBuilder::new()
        .with_gl(GlRequest::Latest)
        .with_gl_profile(GlProfile::Core)
        .build_windowed(window, &event_loop).ok().unwrap();

    unsafe {
        cxt.make_current().unwrap();
        gl::load_with(|ptr| cxt.get_proc_address(ptr) as *const _);
        
        if let Some(sz) = cxt.get_inner_size() {
            let phys = sz.to_physical(cxt.get_hidpi_factor());
            
            gl::Viewport(0, 0, phys.width as i32, phys.height as i32);
        }
    }

    cxt
}

fn main() {
    let mut event_loop = EventsLoop::new();
    let (w, h) = (1024.0, 768.0);
    let window = init(&event_loop, dpi::LogicalSize::new(w, h));

    let mut engine = EngineInstance::new();

    let mut dragging = false;

    use std::time::Instant;

    let mut now = Instant::now();
    
    let mut is_running = true;
    while is_running {
        let curr = Instant::now();
        let delta = curr - now;
        now = curr;
        let ms = delta.as_secs() as f64 * 1000.0 + delta.subsec_millis() as f64;
        window.set_title(&format!("hwengine {:.3}ms", ms));
        
        event_loop.poll_events(|event| {
            match event {
                Event::WindowEvent { event, ..} => match event {
                    WindowEvent::CloseRequested => {
                        is_running = false;
                    },
                    WindowEvent::MouseInput { button, state, .. } => {
                        if let MouseButton::Right = button {
                            if let ElementState::Pressed = state {
                                dragging = true;
                            } else {
                                dragging = false;
                            }
                        }
                    }
                    WindowEvent::MouseWheel { delta, .. } => {
                        let zoom_change = match delta {
                            MouseScrollDelta::LineDelta(x, y) => {
                                y as f32 * 0.1f32
                            }
                            MouseScrollDelta::PixelDelta(delta) => {
                                let physical = delta.to_physical(window.get_hidpi_factor());
                                physical.y as f32 * 0.1f32
                            }
                        };
                        engine.world.move_camera(Point::ZERO, zoom_change);
                    }
                    _ => ()
                },
                Event::DeviceEvent { event, .. } => match event {
                    DeviceEvent::MouseMotion { delta } => {
                        if dragging {
                            engine.world.move_camera(
                                Point::new(delta.0 as i32, delta.1 as i32), 0.0
                            )
                        }
                    }
                    _ => {}
                }
                _ => ()
            }
        });

        unsafe { window.make_current().unwrap() };

        engine.render();

        window.swap_buffers().unwrap();
    }
}
