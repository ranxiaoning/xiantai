@echo off
chcp 65001 >nul

set GODOT=Godot_v4.6.2-stable_win64.exe

if not exist "%GODOT%" (
    echo [ERROR] %GODOT% not found in project root.
    exit /b 1
)

if /I "%~1"=="--list" goto run_capture_headless
if /I "%~1"=="--help" goto run_capture_headless
if /I "%~1"=="-h" goto run_capture_headless

echo Preparing Godot imports...
"%GODOT%" --headless --import >nul 2>&1

:run_capture
"%GODOT%" --windowed --position -32000,-32000 --resolution 1280x720 --path . -s res://tools/UiCapture.gd -- %*
exit /b %errorlevel%

:run_capture_headless
"%GODOT%" --headless --path . -s res://tools/UiCapture.gd -- %*
exit /b %errorlevel%
