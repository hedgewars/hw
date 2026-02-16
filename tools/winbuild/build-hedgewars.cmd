@echo on

set ROOTPATH=Z:

set BUILDDIR=%ROOTPATH%/build-Hedgewars
set HWREPO=Z:/src

set CMAKE=%ROOTPATH%/cmake-4.2.1-windows-x86_64/bin/cmake.exe
set CPACK=%ROOTPATH%/cmake-4.2.1-windows-x86_64/bin/cpack.exe

set PATH=%ROOTPATH%/nsis-3.11;%PATH%
set PATH=%ROOTPATH%/FPC/bin/i386-win32;%PATH%
set PATH=%ROOTPATH%/ninja;%PATH%
set PATH=%ROOTPATH%/RUST/bin;%PATH%
set PATH=%ROOTPATH%/ghc-9.12.3-x86_64-unknown-mingw32/bin;%PATH%
set PATH=%ROOTPATH%/w64devkit/bin;%PATH%

set SDL2_DIR=%ROOTPATH%/SDL2-2.32.8/x86_64-w64-mingw32
set SDL2IMAGEDIR=%ROOTPATH%/SDL2_image-2.8.6/x86_64-w64-mingw32
set SDL2NETDIR=%ROOTPATH%/SDL2_net-2.2.0/x86_64-w64-mingw32
set SDL2TTFDIR=%ROOTPATH%/SDL2_ttf-2.24.0/x86_64-w64-mingw32
set SDL2MIXERDIR=%ROOTPATH%/SDL2_mixer-2.8.1/x86_64-w64-mingw32

set Qt6_DIR=%ROOTPATH%/Qt/Qt6
set OPENSSL_ROOT_DIR=%ROOTPATH%/openssl-master

set CMAKE_PREFIX_PATH=%ROOTPATH%/ffmpeg;%ROOTPATH%/zlib1211;%ROOTPATH%/libpng16;%ROOTPATH%/physfs

set GREP=%ROOTPATH%/w64devkit/bin/grep.exe
set SED=%ROOTPATH%/w64devkit/bin/sed.exe

echo Removing old build dir...
del /s /q "%BUILDDIR%"
%CMAKE% -E make_directory "%BUILDDIR%"

set DLLS_DIR=%BUILDDIR%/win_dlls

%CMAKE% -E make_directory "%DLLS_DIR%/plugins/tls" "%DLLS_DIR%/plugins/imageformats" "%DLLS_DIR%/plugins/platforms"

copy /y "%SDL2_DIR%/bin/*.dll" "%DLLS_DIR%/"
copy /y "%SDL2IMAGEDIR%/bin/*.dll" "%DLLS_DIR%/"
copy /y "%SDL2NETDIR%/bin/*.dll" "%DLLS_DIR%/"
copy /y "%SDL2TTFDIR%/bin/*.dll" "%DLLS_DIR%/"
copy /y "%SDL2MIXERDIR%/bin/*.dll" "%DLLS_DIR%/"
copy /y "%ROOTPATH%/ffmpeg/bin/*.dll" "%DLLS_DIR%/"
copy /y "%ROOTPATH%/physfs/bin/*.dll" "%DLLS_DIR%/"
copy /y "%Qt6_DIR%/bin/Qt6Core.dll" "%DLLS_DIR%/"
copy /y "%Qt6_DIR%/bin/Qt6Gui.dll" "%DLLS_DIR%/"
copy /y "%Qt6_DIR%/bin/Qt6Network.dll" "%DLLS_DIR%/"
copy /y "%Qt6_DIR%/bin/Qt6Widgets.dll" "%DLLS_DIR%/"

copy /y "%Qt6_DIR%/plugins/platforms/qwindows.dll" "%DLLS_DIR%/plugins/platforms"     

echo Configuring...
cd %BUILDDIR%
%CMAKE% -G Ninja -DCMAKE_BUILD_TYPE="Release" ^
      -DWIN32_WIN64_CROSS_COMPILE=on ^
      -DCABAL_FLAGS="-j --project-file=tools/winbuild/cabal.project.local" ^
      -DEXTERNAL_BIN_DIR="%DLLS_DIR%" ^
      %HWREPO%

@if %errorlevel% neq 0 (
    @echo Configure failed!
    @exit /b 1
@)


echo Building...

%CMAKE% --build . --verbose --parallel

@if %errorlevel% neq 0 (
    @echo Build failed!
    @exit /b 1
@)

echo Creating package...

%CPACK% -G ZIP
%CPACK% -G NSIS

