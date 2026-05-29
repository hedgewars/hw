cmake_minimum_required(VERSION 3.22)

corrosion_import_crate(
    MANIFEST_PATH Cargo.toml
    CRATES lib-hwengine-future
    FLAGS ${CARGO_FLAGS}
    NO_LINKER_OVERRIDE
)

corrosion_install(TARGETS hwengine_future DESTINATION ${target_library_install_dir})

