@echo off
echo Register right click menu for audio files.
set dir=%~dp0
for /f "delims=" %%i in ('type "reg\RightClickMenuRegister.reg.in" ^& break ^> "reg\RightClickMenuRegister.reg" ') do (
    set "line=%%i"
    setlocal enabledelayedexpansion
    >>"reg\RightClickMenuRegister.reg" echo(!line:@REPLACE@=%dir:\=\\%!
    endlocal
)
regedit /S "%~dp0reg\RightClickMenuRegister.reg"
echo Done.
IF %0 == "%~0" (
echo Press any key to exit...
pause >nul
)

