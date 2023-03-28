use criterion::{black_box, criterion_group, criterion_main, Criterion};
use hwphysics::{common::GearId, data::GearDataManager};

#[derive(Clone, Copy, Default)]
struct P {
    position: u64,
}

#[derive(Clone, Copy, Default)]
struct V {
    velocity: u64,
}

#[derive(Clone, Copy, Default)]
struct Pv {
    position: u64,
    velocity: u64,
}

const SIZE: usize = 4 * 1024;

pub fn array_run(c: &mut Criterion) {
    let mut items = [Pv::default(); SIZE];

    c.bench_function("array run", |b| {
        b.iter(|| {
            for item in &mut items {
                item.velocity += black_box(item.position);
            }
        })
    });
}

pub fn component_run(c: &mut Criterion) {
    let mut manager = GearDataManager::new();

    manager.register::<P>();
    manager.register::<V>();

    for i in 1..=SIZE {
        let gear_id = GearId::new(i as u16).unwrap();
        manager.add(gear_id, &P::default());
        manager.add(gear_id, &V::default());
    }

    c.bench_function("component run", |b| {
        b.iter(|| {
            manager
                .iter()
                .run(|(p, v): (&mut P, &mut V)| v.velocity += black_box(p.position));
        })
    });
}

pub fn component_multirun(c: &mut Criterion) {
    for n in (16..=64).step_by(16) {
        let mut manager = GearDataManager::new();

        manager.register::<P>();
        manager.register::<V>();

        for i in 1..=(SIZE / n) {
            let gear_id = GearId::new(i as u16).unwrap();
            manager.add(gear_id, &P::default());
            manager.add(gear_id, &V::default());
        }

        c.bench_function(&format!("component run {}", n), |b| {
            b.iter(|| {
                for i in 0..n {
                    manager
                        .iter()
                        .run(|(p, v): (&mut P, &mut V)| v.velocity += black_box(p.position));
                }
            })
        });
    }
}

pub fn component_add_remove(c: &mut Criterion) {
    let mut manager = GearDataManager::new();
    let mut gears1 = vec![];
    let mut gears2 = vec![];

    manager.register::<P>();
    manager.register::<V>();

    for i in 1..=SIZE {
        let gear_id = GearId::new(i as u16).unwrap();
        manager.add(gear_id, &P::default());
        if i % 2 == 0 {
            manager.add(gear_id, &V::default());
            gears1.push(gear_id);
        } else {
            gears2.push(gear_id);
        }
    }

    c.bench_function("component add/remove", |b| {
        b.iter(|| {
            for id in &gears2 {
                manager.add(*id, &V::default());
            }
            for id in &gears1 {
                manager.remove::<V>(*id);
            }
            std::mem::swap(&mut gears1, &mut gears2);
        })
    });
}

criterion_group!(benches, array_run, component_run, component_multirun, component_add_remove);
criterion_main!(benches);
