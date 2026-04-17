## MainMenu.gd
## 主菜单逻辑：开始游戏 / 选项 / 退出。
extends Control

const OPTIONS_SCENE := "res://scenes/OptionsMenu.tscn"
const CHAR_SELECT_SCENE := "res://scenes/CharacterSelect.tscn"


func _ready() -> void:
	Log.info("MainMenu", "主菜单加载完成")
	MusicManager.play("menu")
	$Buttons/BtnStart.grab_focus()


# ── 按钮回调 ──────────────────────────────────

func _on_btn_start_pressed() -> void:
	get_tree().change_scene_to_file(CHAR_SELECT_SCENE)


func _on_btn_options_pressed() -> void:
	get_tree().change_scene_to_file(OPTIONS_SCENE)


func _on_btn_exit_pressed() -> void:
	get_tree().quit()
