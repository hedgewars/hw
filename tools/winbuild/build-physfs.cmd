@echo on

set ROOTPATH=Z:

set CMAKE=%ROOTPATH%/cmake-4.2.8-windows-x86_64/bin/cmake.exe

set PATH=%ROOTPATH%/w64devkit/bin;%PATH%
set PATH=%ROOTPATH%/ninja;%PATH%

echo Configuring...

%CMAKE% -G Ninja -DCMAKE_BUILD_TYPE="Release" -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DCMAKE_INSTALL_PREFIX="%ROOTPATH%/physfs" .

if %errorlevel% neq 0 (
    echo Configure failed!
    exit /b 1
)


echo Building...

%CMAKE% --build . --verbose

if %errorlevel% neq 0 (
    echo Build failed!
    exit /b 1
)

echo Installing...

%CMAKE% --install .

