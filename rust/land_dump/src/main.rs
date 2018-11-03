extern crate integral_geometry;
extern crate land2d;
extern crate landgen;
extern crate lfprng;
extern crate png;
extern crate structopt;

use png::HasParameters;
use std::fs::File;
use std::io::BufWriter;
use std::path::Path;
use structopt::StructOpt;

use integral_geometry::{Point, Rect, Size};
use landgen::outline_template::OutlineTemplate;
use landgen::template_based::TemplatedLandGenerator;
use landgen::LandGenerationParameters;
use landgen::LandGenerator;
use lfprng::LaggedFibonacciPRNG;

#[derive(StructOpt, Debug)]
#[structopt(name = "basic")]
struct Opt {
    #[structopt(short = "s", long = "seed", default_value = "TEST_SEED")]
    seed: String,
    #[structopt(short = "d", long = "dump-before-distort")]
    dump_before_distort: bool,
    #[structopt(short = "b", long = "dump-before-bezierize")]
    dump_before_bezierize: bool,
}

fn template() -> OutlineTemplate {
    let mut template = OutlineTemplate::new(Size::new(4096, 2048));
    template.islands = vec![vec![
        Rect::new(100, 2050, 1, 1),
        Rect::new(100, 500, 400, 1200),
        Rect::new(3600, 500, 400, 1200),
        Rect::new(3900, 2050, 1, 1),
    ]];
    template.fill_points = vec![Point::new(2047, 2047)];

    template
}

fn dump(
    seed: &[u8],
    skip_distort: bool,
    skip_bezier: bool,
    file_name: &Path,
) -> std::io::Result<()> {
    let params = LandGenerationParameters::new(0 as u8, 255, 100, skip_distort, skip_bezier);
    let landgen = TemplatedLandGenerator::new(template());
    let mut prng = LaggedFibonacciPRNG::new(seed);
    let land = landgen.generate_land(&params, &mut prng);

    let file = File::create(file_name)?;
    let ref mut w = BufWriter::new(file);

    let mut encoder = png::Encoder::new(w, land.width() as u32, land.height() as u32); // Width is 2 pixels and height is 1.
    encoder
        .set(png::ColorType::Grayscale)
        .set(png::BitDepth::Eight);
    let mut writer = encoder.write_header()?;

    writer.write_image_data(land.raw_pixels()).unwrap();

    Ok(())
}

fn main() {
    let opt = Opt::from_args();
    println!("{:?}", opt);

    if opt.dump_before_distort {
        dump(
            opt.seed.as_str().as_bytes(),
            true,
            true,
            Path::new("out.before_distort.png"),
        )
        .unwrap();
    }
    if opt.dump_before_bezierize {
        dump(
            opt.seed.as_str().as_bytes(),
            false,
            true,
            Path::new("out.before_bezier.png"),
        )
        .unwrap();
    }
    dump(
        opt.seed.as_str().as_bytes(),
        false,
        true,
        Path::new("out.full.png"),
    )
    .unwrap();
}
