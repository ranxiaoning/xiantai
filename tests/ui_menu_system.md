# 测试说明：主菜单系统

## 自动化测试（run_tests.bat 执行）

覆盖以下套件，结果见 `tests/results/latest.txt`：

| 套件文件 | 用例数 | 覆盖内容 |
|----------|--------|----------|
| `TestGlobalSettings.gd` | 14 | 常量、默认值、配置读写往返、越界/缺失/边界容错 |
| `TestLogger.gd` | 6 | 文件创建、内容写入、追加、超限清空、日志行格式 |

运行命令：
```bat
run_tests.bat
```

---

## 手动集成测试（需 Godot Editor 运行，无法 headless 自动化）

以下测试涉及 DisplayServer / 场景跳转，需人工在编辑器中执行：

| 编号 | 场景 | 步骤 | 预期 |
|------|------|------|------|
| M-01 | MainMenu | 启动游戏 | 标题"无尽仙台"可见，焦点落在"开始游戏" |
| M-02 | MainMenu | 键盘 ↓↓ | 焦点移动到"退出" |
| M-03 | MainMenu | 点击"选项" | 切换到 OptionsMenu |
| M-04 | OptionsMenu | 选分辨率→点"应用" | 窗口尺寸变化并居中 |
| M-05 | OptionsMenu | 勾选"全屏" | 分辨率下拉变灰 |
| M-06 | OptionsMenu | 拖动音量到 0% | 无 -inf dB 错误，标签显示 0% |
| M-07 | OptionsMenu | 点击"返回" | 回到 MainMenu，焦点正确 |
| M-08 | MainMenu | 点击"退出" | 进程正常退出 |
