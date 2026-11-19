@echo on
setlocal

mkdir Build
cd Build

:: ============================================================
:: 1. USER CONFIGURATION (EDIT THESE PATHS)
:: ============================================================

:: Path to the unpacked Qt Source Code (e.g., qt-everywhere-src-6.11.3)
set "QT_BASE_SRC=Z:/Qt/qtbase-everywhere-src-6.11.3"
set "QT_TOOLS_SRC=Z:/Qt/qttools-everywhere-src-6.11.3"

:: Path to Qt installation folder
set "QT_INSTALL_DIR=Z:/Qt/Qt6"

:: Path to your MinGW OpenSSL installation (Must contain include\ and lib\)
set "OPENSSL_DIR=Z:/openssl-master"

:: Path to your MinGW bin directory (where g++.exe is located)
set "MINGW_BIN=Z:/w64devkit/bin"

:: Path to your CMake bin directory
set "CMAKE_ROOT=Z:/cmake-4.2.8-windows-x86_64"

:: Path to your Ninja directory
set "NINJA_ROOT=Z:/ninja"

:: Path to your LLVM directory
set "LLVM_INSTALL_DIR=Z:/libclang"


:: ============================================================
:: 2. ENVIRONMENT SETUP
:: ============================================================

echo Setting up environment...
set "PATH=%MINGW_BIN%;%CMAKE_ROOT%/bin;%NINJA_ROOT%;%PATH%"

:: ============================================================
:: 3. CONFIGURE QT base
:: ============================================================

echo Starting Configure...

call "%QT_BASE_SRC%\configure.bat" ^
    -release ^
    -platform win32-g++ ^
    -shared ^
    -opensource -confirm-license ^
    -opengl desktop ^
    -no-pch ^
    -no-icu ^
    -no-dbus ^
    -no-glib ^
    -no-feature-sql ^
    -no-feature-testlib ^
    -nomake examples ^
    -nomake tests ^
    -prefix %QT_INSTALL_DIR% ^
    -- ^
    -DQT_FEATURE_designer=off ^
    -DQT_FEATURE_qtdiag=off

if %errorlevel% neq 0 (
    echo Configure failed!
    pause
    exit /b 1
)

:: ============================================================
:: 4. BUILD
:: ============================================================

echo Configure successful. Starting Build...
:: -j uses all available CPU cores
cmake --build . --parallel

if %errorlevel% neq 0 (
    echo Build failed!
    pause
    exit /b 1
)

echo ============================================
echo Build Complete.
echo ============================================

cmake --install .

echo ============================================
echo Install Complete.
echo ============================================

:: ============================================================
:: 5. CONFIGURE QT tools
:: ============================================================

cd ..
del /s /q Build
mkdir Build
cd Build

echo Starting Configure...

call "%QT_INSTALL_DIR%\bin\qt-configure-module.bat" ^
    "%QT_TOOLS_SRC%"

if %errorlevel% neq 0 (
    echo Configure failed!
    pause
    exit /b 1
)

:: ============================================================
:: 6. BUILD
:: ============================================================

echo Configure successful. Starting Build...
:: -j uses all available CPU cores
cmake --build . --parallel

if %errorlevel% neq 0 (
    echo Build failed!
    pause
    exit /b 1
)

echo ============================================
echo Build Complete.
echo ============================================

cmake --install .

echo ============================================
echo Install Complete.
echo ============================================

cd ..
del /s /q Build

