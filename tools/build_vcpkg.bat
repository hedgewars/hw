@echo off
setlocal
::CONFIG START
::edit these variables if necessary

::change between Debug and Release
set BUILD_TYPE=Release
::path where Hedgewars will be installed to
::default is %ProgramFiles%\hedgewars and requires running this script as administrator  
set INSTALL_LOCATION=
::set if vcpkg is not on path
set VCPKG_PATH=%VCPKG_ROOT%
::set if CMake is not on path
set CMAKE_PATH=
::set if FPC is not on path
set PASCAL_PATH=
::set to 1 if x86 to x64 cross-compiler is not enabled automatically
set FORCE_X64_CROSS_COMPILE=
::set to 1 to build the game server
set BUILD_SERVER=

::CONFIG END
            
:setup
set CURRDIR="%CD%"
cd %CURRDIR%\..\

set PATH=%PASCAL_PATH%;%VCPKG_PATH%;%CMAKE_PATH%;%PATH%

if "%VSCMD_ARG_TGT_ARCH%" == "x64" (
    set FORCE_X64_CROSS_COMPILE=1
)

if "%FORCE_X64_CROSS_COMPILE%" NEQ "" (
    set CROSS_COMPILE_FLAG=-DWIN32_WIN64_CROSS_COMPILE=1
    if "%INSTALL_LOCATION%" == "" (
        set INSTALL_LOCATION=%ProgramFiles%/hedgewars
    )
) else (
    set CROSS_COMPILE_FLAG=
)

if "%INSTALL_LOCATION%" NEQ "" (
    set PREFIX_FLAG=-DCMAKE_INSTALL_PREFIX=%INSTALL_LOCATION%
) else (
    set PREFIX_FLAG=
)

if "%BUILD_SERVER%" == "" (
    set BUILD_SERVER_FLAG=-DNOSERVER=1
) else (
    set BUILD_SERVER_FLAG=
)             

echo Running cmake...
set ERRORLEVEL=

cmake . -DCMAKE_TOOLCHAIN_FILE="%VCPKG_PATH%\scripts\buildsystems\vcpkg.cmake" -G"NMake Makefiles" %CROSS_COMPILE_FLAG% %BUILD_SERVER_FLAG% "%PREFIX_FLAG%" -DCMAKE_BUILD_TYPE="%BUILD_TYPE%" -DSDL2_BUILDING_LIBRARY=1 -DNOVIDEOREC=1

if %ERRORLEVEL% NEQ 0 goto exitpoint

echo Configuration completed successfully

echo Building...
set ERRORLEVEL=

nmake

if %ERRORLEVEL% NEQ 0 goto exitpoint

echo Build completed successfully

nmake install

:exitpoint
cd %CURRDIR%

endlocal
pause
