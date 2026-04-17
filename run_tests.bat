@echo off
chcp 65001 >nul
echo 正在导入资源...
Godot_v4.6.2-stable_win64.exe --headless --import >nul 2>&1

echo 正在运行《无尽仙台》自动化测试...
echo.

set GODOT=Godot_v4.6.2-stable_win64.exe
set PROJECT_PATH=.

"%GODOT%" --headless --path "%PROJECT_PATH%" -s res://tests/TestMain.gd

set EXIT_CODE=%errorlevel%
echo.
if %EXIT_CODE%==0 (
    echo [PASS] 所有测试通过。结果见 tests\results\latest.txt
) else (
    echo [FAIL] 存在失败的测试。结果见 tests\results\latest.txt
)

exit /b %EXIT_CODE%
