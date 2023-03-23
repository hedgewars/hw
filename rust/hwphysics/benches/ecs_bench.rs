use criterion::{black_box, criterion_group, criterion_main, Criterion};
use hwphysics::{
    common::GearId,
    data::{GearDataManager}
};

#[derive(Clone, Copy, Default)]
struct V {
    position: u64,
    velocity: u64
}

pub fn benchmark(c: &mut Criterion) {
    const SIZE: usize = 4 * 1024;
    let mut items = [V::default(); SIZE];

    c.bench_function("array run", |b| b.iter(|| {
        for item in &mut items {
            item.velocity += black_box(item.position);
        }
    }));

    let mut manager = GearDataManager::new();
    manager.register::<V>();
    for i in 1..=items.len() {
        let gear_id = GearId::new(i as u16).unwrap();
        manager.add(gear_id, &items[i - 1]);
    }

    c.bench_function("component run", |b| b.iter(|| {
        manager.iter().run(|(item,): (&mut V,)| item.velocity += black_box(item.position) );
    }));
}

criterion_group!(benches, benchmark);
criterion_main!(benches);