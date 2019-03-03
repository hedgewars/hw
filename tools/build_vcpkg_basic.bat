@echo off
::edit these variables if necessary
set BUILD_TYPE="Debug"
::set if vcpkg is not on path
set VCPKG_PATH=%VCPKG_ROOT%
::set if CMake is not on path
set CMAKE_PATH=
::set if FPC is not on path
set PASCAL_PATH=

:setup
set CURRDIR="%CD%"
cd %CURRDIR%\..\

set PATH=%PASCAL_PATH%;%VCPKG_PATH%;%CMAKE_PATH%;%PATH%

echo Running cmake...
set ERRORLEVEL=

cmake . -DCMAKE_TOOLCHAIN_FILE="%VCPKG_PATH%\scripts\buildsystems\vcpkg.cmake" -G"NMake Makefiles" -DNOPNG=1 -DNOSERVER=1 -DNOVIDEOREC=1 -DCMAKE_BUILD_TYPE="%BUILD_TYPE%" -DSDL2_BUILDING_LIBRARY=1

if %ERRORLEVEL% NEQ 0 goto exitpoint

echo Configuration completed successfully

echo Building...
set ERRORLEVEL=

nmake

if %ERRORLEVEL% NEQ 0 goto exitpoint

echo Build completed successfully

:exitpoint
cd %CURRDIR%
pause
