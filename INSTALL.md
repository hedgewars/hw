Building and installing Hedgewars
=================================

This file explains to you how to build/compile Hedgewars and how to install it.

See also: <https://hedgewars.org/kb/BuildingHedgewars>

Dependencies
------------
### Hardware dependencies
See README.md.

### Core dependencies

To compile and install Hedgewars, you need at least:

- A C++ compiler (e.g. GCC)
- CMake >= 2.6.0
- A make program (e.g. GNU Make)
- Free Pascal Compiler (FPC) >= 2.2.4
- Qt 5
- SDL >= 2.0
- SDL\_net >= 2.0
- SDL\_mixer >= 2.0
- SDL\_image >= 2.0
- SDL\_ttf >= 2.0
- PhysFS >= 3.0.0

On FreeBSD, you also need the package “fpc-rtl-extra”.

### Recommended optional dependencies

These are not strictly required to build Hedgewars, but it's
usually better to have them installed. Hedgewars has fallback mechanisms
in if these are not found on your system.

- Lua = 5.1.0

### Optional dependencies

For some additional features, you can optionally install these dependencies:

- For PNG screenshots:
    - libpng >= 1.2
- For video recording:
    - FFmpeg or Libav
- For the Hedgewars Server:
    - Rust toolchain (`rustc` and `cargo`)
    - TLS development headers (e.g. OpenSSL), if building with `tls-connections` or `official-server` features

Lua will be automatically built if not found.

### Hedgewars Server dependencies

The Hedgewars Server (`hedgewars-server` in `rust/hedgewars-server`) is an
**optional** separate application.
It provides the online lobby and allows players to create rooms.
You will also be able to launch the server from the frontend
(network play → local network → start server).

**Most players do not need this!**

To compile it, you need:

- Rust toolchain (`rustc` and `cargo`)

Crate dependencies are declared in `rust/hedgewars-server/Cargo.toml` (pinned
in `rust/Cargo.lock`) and fetched automatically by `cargo` unless building
offline (`-DBUILD_OFFLINE=ON`).

Optional Cargo features:

- `tls-connections`: enables TLS support (`tokio-native-tls`; requires system TLS development libraries on Unix)
- `official-server`: enables official-server database and replay-checker support (`mysql_async`, `sha1`, and `tls-connections`)

Building
--------

### Summary

To build and install Hedgewars, obtain all dependencies, then run:

   $ cmake .
   $ make
   # make install

### Step 1: Configure

For a default install with all dependencis, use this command:

    $ cmake .

To build with a custom install directory, instead run:

    $ cmake -DCMAKE_INSTALL_PREFIX="<install_prefix>" .

(Replace `<install_prefix>` with the directoy in which you
want Hedgewars to be installed.)

Add the `-DNOSERVER=ON` switch if you do not want to build
the server.

#### CMake options

For more detailed build settings, change some CMake options.
Run `ccmake` for an interactive way to edit them.

Important CMake options:

- `CMAKE_INSTALL_PREFIX`: Installation directory
- `NOSERVER`: Set to `ON` to *not* build the server
- `NOVIDEOREC`: Set to `ON` to *not* build the video recorder
- `BUILD_OFFICIAL_SERVER`: Set to `ON` to build the server with the `official-server` Cargo feature
- `BUILD_OFFLINE`: Set to `ON` to pass `--offline` to `cargo`
- `CARGO_FLAGS`: Additional flags to pass to `cargo`

### Step 2: Make

Run:

    $ make

This creates the following files:

- `bin/hedgewars`: Hedgewars
- `bin/hwengine`: Game engine, can be used to play demos and saved games
- `bin/hedgewars-server`: Hedgewars Server (optional)

### Step 3: Installation

To install Hedgewars to the install directory run:

    # make install

That's all! Enjoy!

### Building the Hedgewars Server only

The Hedgewars Server can also be built separately using `cargo` from the
repository root (or inside `rust/hedgewars-server`):

    $ cargo build --release --manifest-path rust/hedgewars-server/Cargo.toml

To enable official-server features (database support, TLS, and replay checking):

    $ cargo build --release --manifest-path rust/hedgewars-server/Cargo.toml --features official-server

The resulting executable is written to `rust/target/release/hedgewars-server`.
For most users, building the server separately is not needed; use the `cmake`
instructions above instead.

Troubleshooting
---------------

### Qt is installed but it can't be found

If this happens, set the following CMake option:

    QT_QMAKE_EXECUTABLE="<path_to_qmake>"

(Replace `<path_to_qmake>` with the path to the `qmake` application.)

If this didn't work, make sure you have the correct Qt version
(see above).

### Issues building the Hedgewars Server (Rust / Cargo)

Make sure `rustc` and `cargo` are installed and available in your `PATH`.
If you are building in an environment without network access, pre-fetch or
vendor the Cargo dependencies and pass `-DBUILD_OFFLINE=ON` to CMake (or
`--offline` to `cargo`).

If you don't need the server, set the CMake option `NOSERVER=ON` so the
server isn't built at all.

### Error messages related to libavcodec / libavformat

Update Libav or FFmpeg (whatever is present on your system) to
the latest version or install one of them if you haven't already.
Then try to build again.

If this still doesn't work and you give up, set the CMake option
`NOVIDEOREC=ON`, but then the video recording functionality will
not be available.

### Error messages related to Lua, “undefined reference to `lua_tonumber'”, and so on
If you get error messages like these:

* /home/username/hw/hedgewars//uScript.pas:226: undefined reference to `lua_tonumber'
* /home/username/hw/hedgewars/CMakeFiles/hwengine.dir/uScript.o: In function `LUATOVISUALGEARTYPEORD':

There might be something wrong with your Lua installation. Try to install Lua 5.1.
If this doesn't work, or you don't want to install Lua 5.1, try to build Hedgewars
with the bundled Lua version.

To build with the bundled Lua version, adding the CMake option `SYSTEM_LUA=OFF`, then
repeat the building process.

### Cleaning up

In case you want to start over and start with a clean build,
run `make clean`, then go back to step 2.

If things got seriously out of hand, you may want to reset
*everything* (even your configuration). If you use the
Mercural repository, you can run `hg purge --all`. Proceed with
step 1.

### Still can't build Hedgewars?

Visit us in the forums or IRC (see `README.md`) and ask for help.
