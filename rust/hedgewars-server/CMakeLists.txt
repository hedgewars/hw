cmake_minimum_required(VERSION 3.22)

option(BUILD_OFFICIAL_SERVER "Build with official server features" OFF)

if(BUILD_OFFICIAL_SERVER)
    set(server_features "official-server")
endif()

corrosion_import_crate(
    MANIFEST_PATH Cargo.toml
    FLAGS ${CARGO_FLAGS}
    FEATURES ${server_features}
    NO_LINKER_OVERRIDE
)

corrosion_install(TARGETS hedgewars-server DESTINATION ${target_binary_install_dir})

