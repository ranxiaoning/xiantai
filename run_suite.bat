@echo off
:: 精准测试：只跑指定的一个或多个 suite
:: 用法：run_suite.bat TestBattleEngineLogic
::       run_suite.bat TestBattleEngineLogic TestCardEffects TestEnemyBehavior
::
:: Suite 名称 → 对应改动文件：
::   TestScriptIntegrity   — 任意 .gd 新增/删除时
::   TestGlobalSettings    — GlobalSettings.gd
::   TestLogger            — Logger.gd / Log.gd
::   TestBattleData        — BattleEngine.gd（数据层）
::   TestHandLayout        — HandLayout / CardRenderer
::   TestCharacterSelect   — CharacterDatabase.gd / CharacterSelect.gd
::   TestBattleEngineLogic — BattleEngine.gd
::   TestMapGenerator      — MapGenerator.gd
::   TestCardEffects       — BattleEngine.gd / CardDatabase.gd
::   TestEnemyBehavior     — BattleEngine.gd / EnemyDatabase.gd
::   TestSpiritStones      — GameState.gd / CardDatabase.gd

chcp 65001 >nul
set GODOT=Godot_v4.6.2-stable_win64.exe

if "%~1"=="" (
    echo 用法: run_suite.bat ^<SuiteName^> [SuiteName2 ...]
    echo 例如: run_suite.bat TestBattleEngineLogic TestCardEffects
    exit /b 1
)

echo 正在导入资源...
"%GODOT%" --headless --import >nul 2>&1

:: 将每个参数转换为 --suite Xxx 形式
set SUITE_ARGS=
:build_args
if "%~1"=="" goto run
set SUITE_ARGS=%SUITE_ARGS% --suite %1
shift
goto build_args

:run
echo 正在运行 suite: %SUITE_ARGS%
"%GODOT%" --headless --path . -s res://tests/TestMain.gd -- %SUITE_ARGS% 2>nul

set EXIT_CODE=%errorlevel%
echo.
type tests\results\latest.txt
echo.
if %EXIT_CODE%==0 (
    echo [PASS] 通过
) else (
    echo [FAIL] 存在失败，见上方详情
)

exit /b %EXIT_CODE%
