#!/bin/sh
#
# This script bootstraps SDL dependencies for the iOS build.
# It also applies set of patches to fix "SDL.h not found" issue.
#
# Usage: cd project_files/HedgewarsMobile/bootstrap && ./bootstrap_sdl.sh

set -ex

mkdir ../../../../Library
cd ../../../../Library
# SDL
git clone --branch release-2.32.10 --single-branch https://github.com/libsdl-org/SDL.git
# SDL_image
git clone --branch release-2.8.8 --single-branch https://github.com/libsdl-org/SDL_image.git && \
cd SDL_image && git apply ../../hedgewars/project_files/HedgewarsMobile/bootstrap/SDL_image.diff && cd ..
# SDL_image
git clone --branch release-2.8.1 --single-branch https://github.com/libsdl-org/SDL_mixer.git && \
cd SDL_mixer && git apply ../../hedgewars/project_files/HedgewarsMobile/bootstrap/SDL_mixer.diff && cd ..
# SDL_net
git clone --branch release-2.2.0 --single-branch https://github.com/libsdl-org/SDL_net.git && \
cd SDL_net && git apply ../../hedgewars/project_files/HedgewarsMobile/bootstrap/SDL_net.diff && cd ..
# SDL_ttf
git clone --branch release-2.24.0 --single-branch https://github.com/libsdl-org/SDL_ttf.git && \
cd SDL_ttf && git apply ../../hedgewars/project_files/HedgewarsMobile/bootstrap/SDL_ttf.diff && \
cd external && ./download.sh
