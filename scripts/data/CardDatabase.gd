## CardDatabase.gd  (Autoload: CardDatabase)
## 所有卡牌的静态数据定义。
extends Node

var _all: Dictionary = {}

func _ready() -> void:
	_load_cards_from_json()

func _load_cards_from_json() -> void:
	# 绝对路径在 editor / headless / 导出包 均可靠，优先使用；res:// 作备用
	var abs_path: String = ProjectSettings.globalize_path("res://") + "scripts/data/all_card.json"
	var res_path: String = "res://scripts/data/all_card.json"

	var content: String = ""
	if FileAccess.file_exists(abs_path):
		content = FileAccess.get_file_as_string(abs_path)
	elif FileAccess.file_exists(res_path):
		content = FileAccess.get_file_as_string(res_path)

	if content.is_empty():
		push_error("CardDatabase: 无法读取 all_card.json（尝试路径：%s）" % abs_path)
		return

	var json := JSON.new()
	if json.parse(content) != OK:
		push_error("CardDatabase: 解析 JSON 失败：" + json.get_error_message())
		return

	var data = json.get_data()
	if typeof(data) != TYPE_DICTIONARY or not data.has("cards"):
		push_error("CardDatabase: JSON 格式错误，缺少 cards 字段")
		return

	_all.clear()
	for c in data["cards"]:
		# int() 归一化：防止 JSON 解析将整数返回为 float，导致 str(1.0)="1.0" 而非 "1"
		var card_id: String = str(int(c.get("id", 0)))
		var card := {
			"id":        card_id,
			"name":      c.get("name", ""),
			"rarity":    c.get("rarity", ""),
			"ling_li":   int(c.get("cost_ling", 0)),
			"dao_hui":   int(c.get("cost_dao",  0)),
			"card_type": "attack" if c.get("type") == "术法" else ("skill" if c.get("type") == "秘法" else "power"),
			"keywords":  c.get("keywords", []),
			"desc":      c.get("effect", ""),
			"desc_up":   c.get("effect", ""),
			"is_upgraded": false,
		}
		_all[card_id] = card
	Log.info("CardDatabase", "加载完毕，共 %d 张卡牌" % _all.size())


func get_card(id) -> Dictionary:
	if _all.is_empty():
		_load_cards_from_json()
	# 归一化 id → 整数字符串（兼容传入 int / float / String 三种情况）
	var id_str: String
	match typeof(id):
		TYPE_INT, TYPE_FLOAT:
			id_str = str(int(id))
		_:
			id_str = str(id)
	if _all.has(id_str):
		return _all[id_str].duplicate()
	push_error("CardDatabase: 未知卡牌 id = " + id_str)
	return {}

func get_starting_deck_ids() -> Array[String]:
	## 初始牌组：点星剑法(id=1)×4 + 剑气护体(id=20)×4（对应设计文档初始起手牌）
	var deck: Array[String] = []
	for _i in range(4):
		deck.append("1")
	for _i in range(4):
		deck.append("20")
	return deck

