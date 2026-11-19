FROM debian:trixie

ENV DEBIAN_FRONTEND=noninteractive

RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y wine32 wine64 wget xvfb 7zip xz-utils unzip innoextract && \
    rm -rf /var/lib/apt/lists/*

ENV WINEPREFIX=/wine64
ENV WINEARCH=win64

RUN xvfb-run --auto-servernum /usr/lib/wine/wine64 wineboot --init

# Prepare build environment for Qt

WORKDIR /

RUN wget --no-verbose \
        https://github.com/clamwin/openssl/archive/refs/heads/master.zip \
        https://github.com/ninja-build/ninja/releases/download/v1.13.2/ninja-win.zip \
        https://github.com/skeeto/w64devkit/releases/download/v2.5.0/w64devkit-x64-2.5.0.7z.exe \
        https://github.com/Kitware/CMake/releases/download/v4.2.8/cmake-4.2.8-windows-x86_64.zip \
        https://download.qt.io/development_releases/prebuilt/libclang/libclang-release_21.1.2-based-windows-mingw_64.7z
        
RUN mkdir ninja && cd ninja && unzip ../ninja-win.zip && rm ../ninja-win.zip

RUN find . -maxdepth 1 -type f -name '*.zip' -print -exec unzip -q {} \; -delete && \
    7z x *.exe && \
    rm *.exe && \
    7z x *.7z && \
    rm *.7z && \
    mv -v openssl-master/lib/mingw/x64/* openssl-master/lib

# Prepare static Qt build

WORKDIR /Qt

RUN wget --no-verbose \
        https://download.qt.io/official_releases/qt/6.11/6.11.3/submodules/qttools-everywhere-src-6.11.3.tar.xz \
        https://download.qt.io/official_releases/qt/6.11/6.11.3/submodules/qtbase-everywhere-src-6.11.3.tar.xz
        
RUN find . -maxdepth 1 -type f -name '*.tar.xz' -print -exec tar xf {} \; -delete        

COPY ./build-qt.cmd .

RUN xvfb-run --auto-servernum wine cmd /c build-qt.cmd && rm -rdf qttools-everywhere-src-6.11.3 qtbase-everywhere-src-6.11.3

# Prepare other dependencies for Hedgewars

WORKDIR /

# RUST

RUN wget -qO- https://static.rust-lang.org/dist/rust-1.100.0-x86_64-pc-windows-gnu.tar.xz | tar xJ --verbose

RUN rust-1.100.0-x86_64-pc-windows-gnu/install.sh --prefix=/RUST && \
        rm -rdf rust-1.100.0-x86_64-pc-windows-gnu

COPY ./config.toml /wine64/drive_c/users/root/.cargo/

# SDL libs download

RUN wget --no-verbose \
        https://github.com/libsdl-org/SDL/releases/download/release-2.32.8/SDL2-devel-2.32.8-mingw.zip \
        https://github.com/libsdl-org/SDL_image/releases/download/release-2.8.6/SDL2_image-devel-2.8.6-mingw.zip \
        https://github.com/libsdl-org/SDL_net/releases/download/release-2.2.0/SDL2_net-devel-2.2.0-mingw.zip \
        https://github.com/libsdl-org/SDL_ttf/releases/download/release-2.24.0/SDL2_ttf-devel-2.24.0-mingw.zip \
        https://github.com/libsdl-org/SDL_mixer/releases/download/release-2.8.1/SDL2_mixer-devel-2.8.1-mingw.zip

# NSIS

RUN wget --no-verbose https://sourceforge.net/projects/nsis/files/NSIS%203/3.11/nsis-3.11.zip/download -O nsis.zip

# Upack cabal, NSIS and SDL libs

RUN find *.zip -print -exec unzip -q {} \; -delete

# FPC

RUN wget --no-verbose http://downloads.freepascal.org/fpc/dist/3.2.2/i386-win32/fpc-3.2.2.i386-win32.exe \
        http://downloads.freepascal.org/fpc/dist/3.2.2/i386-win32/fpc-3.2.2.i386-win32.cross.x86_64-win64.exe

RUN innoextract fpc-3.2.2.i386-win32.exe fpc-3.2.2.i386-win32.cross.x86_64-win64.exe && \
        mv app FPC && \
        rm *.exe

COPY ./fpc.cfg FPC/bin/i386-win32

# PHYSFS

RUN wget -qO- https://github.com/icculus/physfs/archive/refs/tags/release-3.2.0.tar.gz | tar xz --verbose

COPY ./build-physfs.cmd .

RUN cd physfs-release-3.2.0 && wine cmd /c z:/build-physfs.cmd && rm -rdf /build-physfs.cmd /physfs-release-3.2.0

# FFMPEG

RUN wget --no-verbose https://github.com/BtbN/FFmpeg-Builds/releases/download/autobuild-2025-11-30-12-53/ffmpeg-n7.1.3-7-gf65fc0b137-win64-lgpl-shared-7.1.zip \
        && unzip ffmpeg-n7.1.3-7-gf65fc0b137-win64-lgpl-shared-7.1.zip \
        && rm *.zip \
        && mv ffmpeg-n7.1.3-7-gf65fc0b137-win64-lgpl-shared-7.1 ffmpeg
        
# HACKS

RUN ln --force --symbolic /FPC/bin/i386-win32/x86_64-win64-ld.exe /FPC/bin/i386-win32/ld.exe

# prefetch/prebuild some stuff

RUN wine cmd /c "set PATH=z:/RUST/bin && \
        cargo new --lib z:/prefetch && \
        cd z:/prefetch && \
        cargo add byteorder@1.2 cbindgen gl log netbuf nom@7.1 png@0.17 && \
        cargo add queues@1.1 rand@0.9 saturate serde@1.0 serde_yaml@0.9 serde_derive@0.9 toml@0.8 && \
        cargo fetch" && \
        rm -rf /prefetch
        

