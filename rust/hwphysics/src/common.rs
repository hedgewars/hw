pub type GearId = u16;
pub trait GearData {}

pub trait GearDataProcessor<T: GearData> {
    fn add(&mut self, gear_id: GearId, gear_data: T);
}

pub trait GearDataAggregator<T: GearData> {
    fn find_processor(&mut self) -> &mut GearDataProcessor<T>;
}
