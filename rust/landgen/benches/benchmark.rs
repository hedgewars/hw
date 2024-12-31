use criterion::{black_box, criterion_group, criterion_main, Criterion};
use integral_geometry::{Point, Rect, Size};
use landgen;
use landgen::{LandGenerationParameters, LandGenerator};
use landgen::outline_template_based::outline_template::OutlineTemplate;
use landgen::outline_template_based::template_based::TemplatedLandGenerator;

pub fn generate_outline(c: &mut Criterion) {
    let template = OutlineTemplate {
    islands: vec![
        vec![
            Rect::from_box(273, 273, 2048, 2048),
            Rect::from_box(683, 683, 32, 63),
            Rect::from_box(1092, 1092, 2048, 2048),
        ],
        vec![
            Rect::from_box(1638, 1638, 2048, 2048),
            Rect::from_box(2048, 2048, 32, 63),
            Rect::from_box(2458, 2458, 2048, 2048),
        ],
        vec![
            Rect::from_box(3004, 3004, 2048, 2048),
            Rect::from_box(3413, 3413, 32, 63),
            Rect::from_box(3823, 3823, 2048, 2048),
        ],
    ],
    walls: vec![],
    fill_points: vec![Point::new(1, 0)],
    size: Size {
        width: 4096,
        height: 2048,
    },
    can_flip: false,
    can_invert: false,
    can_mirror: false,
    is_negative: false,
};

    let parameters = LandGenerationParameters::new(
     0u16,
     32768u16,
     10,
    false,
     false
    );

    c.bench_function("outline_generation", |b| b.iter(|| {
        fn prng() -> impl Iterator<Item = u32> {
            (0..).map(|i| (i as u64 * 31_234_773 % 2_017_234_567) as u32)
        }

        let gen = TemplatedLandGenerator::new(black_box(template.clone()));
        gen.generate_land(black_box(&parameters), &mut prng())
    }));
}

criterion_group!(benches, generate_outline);
criterion_main!(benches);
