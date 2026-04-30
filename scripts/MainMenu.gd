## MainMenu.gd
## 主菜单逻辑：开始游戏 / 选项 / 退出。
extends Control

const OPTIONS_SCENE    := "res://scenes/OptionsMenu.tscn"
const CHAR_SELECT_SCENE := "res://scenes/CharacterSelect.tscn"


func _ready() -> void:
	theme = load("res://theme/main_theme.tres")
	Log.info("MainMenu", "主菜单加载完成")
	MusicManager.play("menu")
	$Buttons/BtnStart.grab_focus()
	_setup_visual_fx()
	_setup_title_deco()
	_play_entrance_anim()


# ── 视觉效果 ──────────────────────────────────

func _setup_visual_fx() -> void:
	var fx: Control = load("res://scripts/MenuParticles.gd").new()
	add_child(fx)
	move_child(fx, 1)  # BG 之后，Overlay 之前


func _setup_title_deco() -> void:
	# 标题呼吸（循环 tween）
	var tw := create_tween().set_loops()
	tw.tween_property($TitleArea/Title, "modulate:a", 0.78, 2.2).set_trans(Tween.TRANS_SINE)
	tw.tween_property($TitleArea/Title, "modulate:a", 1.00, 2.2).set_trans(Tween.TRANS_SINE)

	# 副标题加装饰破折号
	$TitleArea/Subtitle.text = "—  ENDLESS IMMORTAL PLATFORM  —"


func _play_entrance_anim() -> void:
	await get_tree().process_frame  # 等布局计算完成
	var btns: Array = [$Buttons/BtnStart, $Buttons/BtnOptions, $Buttons/BtnExit]
	for i in btns.size():
		var btn: Button = btns[i]
		btn.modulate.a  = 0.0
		btn.pivot_offset = btn.size * 0.5
		btn.scale = Vector2(0.90, 0.90)
		var t := create_tween()
		t.tween_interval(0.35 + i * 0.13)
		t.tween_property(btn, "modulate:a", 1.0, 0.40) \
		  .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t.parallel().tween_property(btn, "scale", Vector2.ONE, 0.40) \
		  .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# ── 按钮回调 ──────────────────────────────────

func _on_btn_start_pressed() -> void:
	get_tree().change_scene_to_file(CHAR_SELECT_SCENE)


func _on_btn_options_pressed() -> void:
	get_tree().change_scene_to_file(OPTIONS_SCENE)


func _on_btn_exit_pressed() -> void:
	get_tree().quit()
