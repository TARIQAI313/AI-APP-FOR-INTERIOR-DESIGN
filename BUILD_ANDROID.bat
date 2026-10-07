@echo off
call "%~dp0scripts\build_android.bat"
set "REVERIE_BUILD_EXIT=%ERRORLEVEL%"
pause
exit /b %REVERIE_BUILD_EXIT%
