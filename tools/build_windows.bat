@echo off
::edit these variables if you need
set PASCAL=C:\FPC\2.4.4\bin\i386-win32\
set QTDIR=C:\QtSDK\Desktop\Qt\4.7.4\mingw\bin
set PATH=%PATH%;%PASCAL%

:setup
set CURRDIR="%CD%"
cd ..

echo Fetching all DLLs...
for %%G in (QtCore4 QtGui4 QtNetwork4 libgcc_s_dw2-1 mingwm10) do (
    xcopy /d/y %QTDIR%\%%G.dll bin\
)

if not exist %CD%\misc\winutils\bin\ mkdir %CD%\misc\winutils\bin\
if not exist %CD%\misc\winutils\bin\SDL.dll cscript %CD%\tools\w32DownloadUnzip.vbs http://www.libsdl.org/release/SDL-1.2.15-win32.zip %CD%\misc\winutils\bin
if not exist %CD%\misc\winutils\bin\SDL_image.dll cscript %CD%\tools\w32DownloadUnzip.vbs http://www.libsdl.org/projects/SDL_image/release/SDL_image-1.2.12-win32.zip %CD%\misc\winutils\bin
if not exist %CD%\misc\winutils\bin\SDL_net.dll cscript %CD%\tools\w32DownloadUnzip.vbs http://www.libsdl.org/projects/SDL_net/release/SDL_net-1.2.8-win32.zip %CD%\misc\winutils\bin
if not exist %CD%\misc\winutils\bin\SDL_mixer.dll cscript %CD%\tools\w32DownloadUnzip.vbs http://www.libsdl.org/projects/SDL_mixer/release/SDL_mixer-1.2.12-win32.zip %CD%\misc\winutils\bin
if not exist %CD%\misc\winutils\bin\SDL_ttf.dll cscript %CD%\tools\w32DownloadUnzip.vbs  http://www.libsdl.org/projects/SDL_ttf/release/SDL_ttf-2.0.11-win32.zip %CD%\misc\winutils\bin

xcopy /d/y %CD%\misc\winutils\bin\*.dll bin
xcopy /d/y %CD%\misc\winutils\bin\*.txt bin

::setting up the environment...
call %QTDIR%\qtenv2.bat

echo Running cmake...
set ERRORLEVEL=
cmake -G "MinGW Makefiles" -DCMAKE_INCLUDE_PATH="%CD%\misc\winutils\include" -DCMAKE_LIBRARY_PATH="%CD%\misc\winutils\lib" .

if %ERRORLEVEL% NEQ 0 goto exitpoint

echo Running make...
set ERRORLEVEL=
mingw32-make
if %ERRORLEVEL% NEQ 0 goto exitpoint

echo Installing...
set ERRORLEVEL=
mingw32-make install > nul
if %ERRORLEVEL% NEQ 0 goto exitpoint

echo Creating commodity shortcut...
COPY /y %CD%\misc\winutils\Hedgewars.lnk C:%HOMEPATH%\Desktop\Hedgewars.lnk

echo ALL DONE, Hedgewars has been successfully compiled and installed

:exitpoint
cd %CURRDIR%
pause
