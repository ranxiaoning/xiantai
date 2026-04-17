## Log.gd
## Logger 的静态封装，解决 GDScript 解析器无法在编译期验证 Autoload 实例方法的问题。
## class_name 使其在全局可见，static func 使其无需实例化即可调用。
## 所有脚本统一通过 Log.info / Log.warn / Log.error 记录日志。
##
## 用法：
##   Log.info("MainMenu", "主菜单加载完成")
##   Log.error("Battle", "伤害计算出错: " + str(err))
extends Node


static func debug(tag: String, msg: String) -> void:
	_call_logger("debug", tag, msg)
	print("[DBG][%s] %s" % [tag, msg])


static func info(tag: String, msg: String) -> void:
	_call_logger("info", tag, msg)
	print("[INF][%s] %s" % [tag, msg])


static func warn(tag: String, msg: String) -> void:
	_call_logger("warn", tag, msg)
	push_warning("[WRN][%s] %s" % [tag, msg])


static func error(tag: String, msg: String) -> void:
	_call_logger("error", tag, msg)
	push_error("[ERR][%s] %s" % [tag, msg])


static func _call_logger(method: String, tag: String, msg: String) -> void:
	# 运行时通过 root 节点获取 Logger autoload，避免编译期类型验证问题
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var logger := tree.root.get_node_or_null("Logger")
	if logger:
		logger.call(method, tag, msg)
