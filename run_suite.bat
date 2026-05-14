@echo off
chcp 65001 >nul
REM Targeted tests: run one or more suites.
REM Usage: run_suite.bat TestBattleEngineLogic
REM       run_suite.bat TestBattleEngineLogic TestCardEffects TestEnemyBehavior
REM
REM Suite name to common trigger files:
REM   TestScriptIntegrity   - new or deleted .gd files
REM   TestGlobalSettings    - GlobalSettings.gd
REM   TestLogger            - Logger.gd / Log.gd
REM   TestBattleData        - BattleEngine.gd data layer
REM   TestHandLayout        - HandLayout / CardRenderer
REM   TestCharacterSelect   - CharacterDatabase.gd / CharacterSelect.gd
REM   TestBattleEngineLogic - BattleEngine.gd
REM   TestMapGenerator      - MapGenerator.gd
REM   TestCardEffects       - BattleEngine.gd / CardDatabase.gd
REM   TestEnemyBehavior     - BattleEngine.gd / EnemyDatabase.gd
REM   TestSpiritStones      - GameState.gd / CardDatabase.gd
REM   TestPlayerJourneyFlow - basic player journey flow

set GODOT=Godot_v4.6.2-stable_win64.exe

if "%~1"=="" (
    echo 用法: run_suite.bat ^<SuiteName^> [SuiteName2 ...]
    echo 例如: run_suite.bat TestBattleEngineLogic TestCardEffects
    exit /b 1
)

echo 正在导入资源...
"%GODOT%" --headless --import >nul 2>&1

REM Convert each argument into a --suite Xxx pair.
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
