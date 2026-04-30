@echo off
:: !! 全量回归测试 !! 仅在 git commit 前使用。
:: 日常开发请用 run_suite.bat <SuiteName> 精准运行受影响的 suite。
chcp 65001 >nul
set GODOT=Godot_v4.6.2-stable_win64.exe

echo [全量回归] 正在导入资源...
"%GODOT%" --headless --import >nul 2>&1

echo 正在运行《无尽仙台》自动化测试...
"%GODOT%" --headless --path . -s res://tests/TestMain.gd -- %* 2>nul

set EXIT_CODE=%errorlevel%
echo.
type tests\results\latest.txt
echo.
if %EXIT_CODE%==0 (
    echo [PASS] 全部通过
) else (
    echo [FAIL] 存在失败，见上方详情
)

exit /b %EXIT_CODE%
