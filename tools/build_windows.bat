@echo off
:edit these variables if you need
SET PASCAL=C:\FPC\2.4.4\bin\i386-win32\
SET QTDIR=C:\QtSDK\Desktop\Qt\4.7.4\mingw\bin
SET PATH=%PATH%;%PASCAL%

:SETUP
cd ..
if not exist bin mkdir bin
cd bin

echo Copying the DLLs...
xcopy /d/y ..\misc\winutils\bin\* .
xcopy /d/y %QTDIR%\QtCore4.dll .
xcopy /d/y %QTDIR%\QtGui4.dll .
xcopy /d/y %QTDIR%\QtNetwork4.dll .
xcopy /d/y %QTDIR%\libgcc_s_dw2-1.dll .
xcopy /d/y %QTDIR%\mingwm10.dll .

echo Setting up the environment...
call %QTDIR%\qtenv2.bat

echo Running cmake...
set errorlevel=
cmake -G "MinGW Makefiles" -DCMAKE_INCLUDE_PATH="%CD%\..\misc\winutils\include" -DCMAKE_LIBRARY_PATH="%CD%\..\misc\winutils\lib" ..

if %errorlevel% NEQ 0 goto exit

echo Running make...
set errorlevel=
mingw32-make -lSDL -lSDL_Mixer install

if %errorlevel% NEQ 0 goto exit

echo Creating shortcut...
if /i "%PROGRAMFILES(X86)%"=="" (
	COPY /y ..\misc\winutils\Hedgewars_x86.lnk C:\%HOMEPATH%\Desktop\Hedgewars.lnk 
) else (
	COPY /y ..\misc\winutils\Hedgewars_x64.lnk C:\%HOMEPATH%\Desktop\Hedgewars.lnk
)
echo ALL DONE, Hedgewars has been successfully compiled and installed

:exit
cd ../tools
pause
