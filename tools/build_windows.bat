@echo off
::edit these variables if you need
set PASCAL=C:\FPC\2.6.0\bin\i386-win32\
set QTDIR=C:\QtSDK\Desktop\Qt\4.7.4\mingw\bin
set PATH=%PATH%;%PASCAL%
set BUILD_TYPE="Debug"

:setup
set CURRDIR="%CD%"
cd ..

echo Fetching all DLLs...
if %BUILD_TYPE%=="Debug" (
    for %%G in (QtCored4 QtGuid4 QtNetworkd4) do xcopy /d/y %QTDIR%\%%G.dll %CD%\bin\
)
:: should you libgcc dynamically you should try adding libgcc_s_dw2-1 and mingwm10
for %%G in (QtCore4 QtGui4 QtNetwork4) do (
    xcopy /d/y %QTDIR%\%%G.dll %CD%\bin\
)

if not exist %CD%\misc\winutils\bin\ mkdir %CD%\misc\winutils\bin\
if not exist %CD%\misc\winutils\bin\SDL.dll cscript %CD%\tools\w32DownloadUnzip.vbs http://www.libsdl.org/release/SDL-1.2.15-win32.zip %CD%\misc\winutils\bin
if not exist %CD%\misc\winutils\bin\SDL_image.dll cscript %CD%\tools\w32DownloadUnzip.vbs http://www.libsdl.org/projects/SDL_image/release/SDL_image-1.2.12-win32.zip %CD%\misc\winutils\bin
if not exist %CD%\misc\winutils\bin\SDL_net.dll cscript %CD%\tools\w32DownloadUnzip.vbs http://www.libsdl.org/projects/SDL_net/release/SDL_net-1.2.8-win32.zip %CD%\misc\winutils\bin
if not exist %CD%\misc\winutils\bin\SDL_mixer.dll cscript %CD%\tools\w32DownloadUnzip.vbs http://www.libsdl.org/projects/SDL_mixer/release/SDL_mixer-1.2.12-win32.zip %CD%\misc\winutils\bin
if not exist %CD%\misc\winutils\bin\SDL_ttf.dll cscript %CD%\tools\w32DownloadUnzip.vbs  http://www.libsdl.org/projects/SDL_ttf/release/SDL_ttf-2.0.11-win32.zip %CD%\misc\winutils\bin

::for video recording
if not exist %CD%\misc\winutils\bin\avformat-54.dll cscript %CD%\tools\w32DownloadUnzip.vbs http://hedgewars.googlecode.com/files/libav-win32-20121022-dll.zip %CD%\misc\winutils\bin

::this is needed because fpc png unit hardcodes libpng-1.2.12
if not exist %CD%\misc\winutils\bin\libpng13.dll copy /y %CD%\misc\winutils\bin\libpng15-15.dll %CD%\misc\winutils\bin\libpng13.dll

xcopy /d/y %CD%\misc\winutils\bin\*.dll %CD%\bin\

::setting up the environment...
call %QTDIR%\qtenv2.bat

echo Running cmake...
set ERRORLEVEL=
cmake . -G "MinGW Makefiles" -DPNG_LIBRARY="%CD%\misc\winutils\bin\libpng13.dll" -DCMAKE_BUILD_TYPE="%BUILD_TYPE%" -DCMAKE_PREFIX_PATH="%CD%\misc\winutils\\"
:: prefix should be last

if %ERRORLEVEL% NEQ 0 goto exitpoint

echo Running make...
set ERRORLEVEL=
mingw32-make VERBOSE=1
if %ERRORLEVEL% NEQ 0 goto exitpoint

echo Installing...
set ERRORLEVEL=
mingw32-make install > nul
if %ERRORLEVEL% NEQ 0 goto exitpoint

echo Creating commodity shortcut...
copy /y %CD%\misc\winutils\Hedgewars.lnk C:%HOMEPATH%\Desktop\Hedgewars.lnk

echo ALL DONE, Hedgewars has been successfully compiled and installed

:exitpoint
cd %CURRDIR%
pause
