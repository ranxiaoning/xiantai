# Remove GameMap Floating Animation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 移除 GameMap 中节点的上下浮动动画，保留错落的坐标排布和优化的连线样式。

**Architecture:** 
从 `scripts/GameMap.gd` 中清理掉所有与浮动动画相关的变量和逻辑代码（`_node_float_data` 和 `_process`），恢复节点的静态显示。

**Tech Stack:** Godot 4.3 (GDScript).

---

### Task 1: Cleanup Floating Logic in GameMap.gd

**Files:**
- Modify: `scripts/GameMap.gd`

- [ ] **Step 1: Remove `_node_float_data` variable**
Remove the dictionary declaration used to store animation state.

- [ ] **Step 2: Remove `_process` function**
Delete the entire `_process(delta)` override that updates node positions.

- [ ] **Step 3: Remove animation initialization**
In `_create_node_button`, delete the code block that initializes phase, speed, and base_y for each node.

- [ ] **Step 4: Manual verification**
运行游戏并进入地图。确认节点不再上下浮动，但坐标依然保持错落（Jitter）且连线依然是优化的样式。

- [ ] **Step 5: Commit**

```bash
git add scripts/GameMap.gd
git commit -m "style(map): remove node floating animation as per user feedback"
```
