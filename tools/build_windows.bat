@echo off
::edit these variables if you need
set PASCAL=C:\FPC\2.4.4\bin\i386-win32\
set QTDIR=C:\QtSDK\Desktop\Qt\4.7.4\mingw\bin
set PATH=%PATH%;%PASCAL%

:setup
set CURRDIR="%CD%"
cd ..

echo Copying the DLLs...
REM xcopy /d/y %CD%\misc\winutils\bin\* .
xcopy /d/y %QTDIR%\QtCore4.dll bin
xcopy /d/y %QTDIR%\QtGui4.dll bin
xcopy /d/y %QTDIR%\QtNetwork4.dll bin
xcopy /d/y %QTDIR%\libgcc_s_dw2-1.dll bin
xcopy /d/y %QTDIR%\mingwm10.dll bin

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
