@echo off
chcp 65001 >nul

echo 正在导入资源...
Godot_v4.6.2-stable_win64.exe --headless --import >nul 2>&1

echo 启动游戏...
Godot_v4.6.2-stable_win64.exe --path .
