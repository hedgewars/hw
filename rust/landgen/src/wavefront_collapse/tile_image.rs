use vec2d::Vec2D;
use std::rc::Rc;
use integral_geometry::Size;

pub struct TileImage<T> {
    image: Rc<Vec2D<T>>,
    flip: bool,
    mirror: bool,
}

impl<T: Copy> TileImage<T> {
    pub fn new(image: Vec2D<T>) -> Self {
        Self {
            image: Rc::new(image),
            flip: false,
            mirror: false,
        }
    }

    pub fn mirrored(&self) -> Self {
        Self {
            image: self.image.clone(),
            flip: self.flip,
            mirror: !self.mirror,
        }
    }

    pub fn flipped(&self) -> Self {
        Self {
            image: self.image.clone(),
            flip: !self.flip,
            mirror: self.mirror,
        }
    }

    pub fn split(&self, rows: usize, columns: usize) -> Vec<TileImage<T>> {
        let mut result = Vec::new();
        let self_image = self.image.as_ref();
        let (result_width, result_height) = (self_image.width() / columns, self.image.height() / rows);

        for row in 0..rows {
            for column in 0..columns {
                let mut tile_pixels = Vec::new();

                for out_row in 0..result_height {
                    tile_pixels.push(self_image[row * result_height + out_row][column*result_width..(column+1)*result_width].iter());
                }

                let tile_image = Vec2D::from_iter(tile_pixels.into_iter().flatten().map(|p| *p), &Size::new(result_width, result_height));

                result.push(TileImage::new(tile_image.expect("correct calculation of tile dimensions")));
            }
        }

        result
    }
}

#[cfg(test)]
mod tests {
    use super::TileImage;
    use integral_geometry::Size;
    use vec2d::Vec2D;

    #[test]
    fn test_split() {
        let size = Size::new(6, 4);
        let sample_data = Vec2D::from_iter((0..24).into_iter(), &size);

        assert!(sample_data.is_some());

        let sample_data = sample_data.unwrap();
        let big_tile = TileImage::new(sample_data);
        let subtiles = big_tile.split(2, 2);

        assert_eq!(subtiles.len(), 4);
    }
}
