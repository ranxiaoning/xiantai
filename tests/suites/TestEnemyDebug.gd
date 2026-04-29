## TestEnemyDebug.gd - 临时诊断脚本（运行后查看输出）
extends RefCounted

const BattleEngineScript = preload("res://scripts/BattleEngine.gd")

func run_all() -> Dictionary:
	var lines: Array[String] = []
	lines.append("\n[ TestEnemyDebug ]")
	
	# 诊断1：腐化咒师 R1 - insert_card 是否执行
	var e1 = BattleEngineScript.new()
	var char_d = {"hp_max": 80, "ling_li_max": 20, "dao_hui_max": 10}
	var db = load("res://scripts/data/EnemyDatabase.gd").new()
	db.call("_ready")
	var enemy = db.call("get_enemy_by_id", "normal_fu_hua_zhou_shi")
	e1.init(char_d, [], enemy)
	var s1 = e1.get("s")
	s1["enemy_dao_xing"] = 0
	s1["enemy_jing_ci"] = 0
	s1["enemy_shen_xing"] = 0
	s1["enemy_hp_max"] = s1["enemy_hp"]
	
	lines.append("  [诊断] 腐化咒师 actions[0] type: %s" % enemy["actions"][0].get("type","?"))
	lines.append("  [诊断] actions[0] has insert_card: %s" % str(enemy["actions"][0].has("insert_card")))
	lines.append("  [诊断] actions[0] get insert_card: %s" % str(enemy["actions"][0].get("insert_card", "NULL")))
	
	e1.call("_enemy_turn")
	lines.append("  [诊断] 执行后 discard_pile size: %d" % s1["discard_pile"].size())
	e1.free()
	
	# 诊断2：青铜巨像 R2 - player_status 是否执行
	var e2 = BattleEngineScript.new()
	var enemy2 = db.call("get_enemy_by_id", "elite_qing_tong_ju_xiang")
	e2.init(char_d, [], enemy2)
	var s2 = e2.get("s")
	s2["enemy_dao_xing"] = 0
	s2["enemy_jing_ci"] = enemy2.get("passive_jing_ci_n", 0)
	s2["enemy_shen_xing"] = 0
	s2["enemy_hp_max"] = s2["enemy_hp"]
	
	lines.append("  [诊断] 青铜巨像 actions[1] type: %s" % enemy2["actions"][1].get("type","?"))
	lines.append("  [诊断] actions[1] has player_status: %s" % str(enemy2["actions"][1].has("player_status")))
	lines.append("  [诊断] actions[1] get player_status: %s" % str(enemy2["actions"][1].get("player_status", "NULL")))
	
	# 先执行R1（固化）
	e2.call("_enemy_turn")
	lines.append("  [诊断] R1后 enemy_hu_ti: %d" % s2["enemy_hu_ti"])
	# 执行R2（重盾猛击）
	e2.call("_enemy_turn")
	lines.append("  [诊断] R2后 player_statuses: %s" % str(s2["player_statuses"]))
	e2.free()
	
	db.free()
	lines.append("  → 诊断完成")
	return {"pass": 0, "fail": 0, "lines": lines}
