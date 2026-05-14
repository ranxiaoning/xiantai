# UI 诊断截图工具

`capture_ui.bat` 是给开发与协作代理使用的视觉诊断工具，不属于自动化测试 suite，也不输出通过/失败结论。

## Agent debug workflow

Agents should reach for this tool while debugging UI, scene loading, layout, visual state, or Godot runtime issues where a screenshot or node tree would reduce guesswork. Good triggers include reports of blank screens, wrong scenes, overlapping controls, hidden buttons, clipped text, and resolution-specific layout behavior.

Captures default to an offscreen real Godot render window. Use `--visible` only when a human explicitly wants to watch the capture window on the desktop.

Use the captured PNG together with `nodes.txt`: the screenshot shows the visual state, while the node summary records visible controls, positions, sizes, and key text.

## 用法

```bat
capture_ui.bat --list
capture_ui.bat main_menu
capture_ui.bat battle --size 1920x1080 --wait 90
capture_ui.bat all
capture_ui.bat main_menu --visible
```

## 预设

当前内置预设：

`main_menu`、`options`、`character_select`、`game_map`、`battle`、`reward`、`shop`、`bonfire`、`event`。

默认使用离屏真实 Godot 渲染窗口，按预设构造必要的 `GameState`，等待渲染稳定后截图；这不是纯 headless 截图。需要人工观察窗口时可显式添加 `--visible`。默认角色为 `chen_tian_feng`，事件页默认使用 `Q-101`。

## 输出

结果写入 `tests/results/ui-captures/<run_id>/`，该目录已被 `.gitignore` 忽略。

每次运行至少包含：

- `<preset>_<width>x<height>.png`
- `manifest.json`
- `nodes.txt`

`manifest.json` 记录截图命令、分辨率、等待帧数和每张 PNG 的路径；`nodes.txt` 记录场景节点、可见性、位置、尺寸和关键文本，便于对照截图排查 UI 问题。

## 验收边界

- 该工具用于“看见具体场景”，不替代 `run_suite.bat`。
- 新增或修改 `.gd` 后仍按项目规则运行 `run_suite.bat TestScriptIntegrity`。
- UI 视觉判断仍以人工查看截图为准。
