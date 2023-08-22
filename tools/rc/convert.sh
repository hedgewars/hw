#!/usr/bin/env sh

ls ../rc || exit

rm -rdfv build engine
mkdir -p build engine
cd build
cmake -DNOSERVER=on -DBUILD_ENGINE_C=on -DLUA_SYSTEM=on -DNOVIDEOREC=off ../../../
cmake --build . --target engine_c

# this one you can get from pip: pip install scan-build
intercept-build cmake --build . --target hwengine
c2rust transpile --emit-build-files --emit-modules --reduce-type-annotations --binary hwengine compile_commands.json --output-dir=../engine

cd ../engine
sed -i 's/f128.*//g' Cargo.toml
sed -i 's/extern crate f128.*//g' lib.rs
sed -i 's/mod src {/mod src{\npub mod to_f64;/g' lib.rs
find -type f -name '*.rs' -exec sed -i 's/f128/f64/g' {} \; -exec sed -i 's/f64::f64/f64/g' {} \; -exec sed -i 's/use ::f64;/use crate::src::to_f64::to_f64;/g' {} \; -exec sed -i 's/f64::new/to_f64/g' {} \;
cp ../to_f64.rs src/
