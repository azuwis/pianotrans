@echo off
echo Unregister right click menu for audio files.
regedit /S "%~dp0reg\RightClickMenuUnregister.reg"
echo Done.
IF %0 == "%~0" (
echo Press any key to exit...
pause >nul
)

