## EnemyDatabase.gd  (Autoload: EnemyDatabase)
## ═══════════════════════════════════════════════════════════════
## 敌人数据库：按照《需求文档/敌人类型.md》定义5种基础怪物原型。
## 每种怪物拥有 普通形态 和 精英形态，进入关卡时随机选择一种类型。
##
## 注意：GDScript 4 的 const 字典不支持嵌套 Array，且嵌套 Dictionary
## 在 duplicate(true) 后可能丢失 key，因此全部改用 var + _ready() 初始化。
##
## 敌人动作字段说明：
##   type        动作类型："attack"/"defend"/"buff"/"debuff"
##   damage      造成伤害值（attack类型）
##   shield      护体增加值（defend类型）
##   hits        多段攻击次数（默认1）
##   self_status    施加给自身的状态 {"key":..., "stacks":n}
##   player_status  施加给玩家的状态 {"key":..., "stacks":n}
##   player_status_2 第二个玩家状态（const限制，分为两个字段）
##   insert_card    插入污染牌 {"card_id":..., "target":"discard"/"draw_top"}
##   heal_self_on_dmg  true=造成HP伤害时等量回血
##   self_shield_after  攻击后自身获得身形值
##   is_shen_xing   true=身形（临时）/false=永久护体
## ═══════════════════════════════════════════════════════════════
extends Node

# ── 怪物数据（var 而非 const，避免 GDScript const 嵌套限制）────────

var NORMAL_XUE_LING_KUANG_TU: Dictionary
var NORMAL_NI_YING_SI_SHI: Dictionary
var NORMAL_QING_TONG_WEI_JIA: Dictionary
var NORMAL_FU_HUA_ZHOU_SHI: Dictionary
var NORMAL_TUN_SHI_YOU_YAN: Dictionary
var ELITE_XUE_YU_KUANG_MO: Dictionary
var ELITE_AN_YING_CI_KE: Dictionary
var ELITE_QING_TONG_JU_XIANG: Dictionary
var ELITE_SHEN_YUAN_DA_ZHOU_SHI: Dictionary
var ELITE_YUAN_GU_SHI_TIAN_CHONG: Dictionary

## 奇遇事件专用敌人
var EVENT_FENG_XIU_CAN_QU: Dictionary    # Q-104 疯修·残躯
var EVENT_TAN_LAN_DU_JIE: Dictionary     # Q-107 贪婪的渡劫者
var EVENT_LI_ZHI_XIU_SHI: Dictionary     # Q-111 理智修士
var EVENT_SHI_LIAN_KUI_LEI: Dictionary   # Q-117 试炼傀儡

## 普通/精英怪物 ID 池
const NORMAL_POOL: Array[String] = [
	"normal_xue_ling_kuang_tu",
	"normal_ni_ying_si_shi",
	"normal_qing_tong_wei_jia",
	"normal_fu_hua_zhou_shi",
	"normal_tun_shi_you_yan",
]
const ELITE_POOL: Array[String] = [
	"elite_xue_yu_kuang_mo",
	"elite_an_ying_ci_ke",
	"elite_qing_tong_ju_xiang",
	"elite_shen_yuan_da_zhou_shi",
	"elite_yuan_gu_shi_tian_chong",
]

var _all: Dictionary = {}

func _ready() -> void:
	_init_enemies()
	_init_event_enemies()
	for e in [
		NORMAL_XUE_LING_KUANG_TU, NORMAL_NI_YING_SI_SHI,
		NORMAL_QING_TONG_WEI_JIA, NORMAL_FU_HUA_ZHOU_SHI, NORMAL_TUN_SHI_YOU_YAN,
		ELITE_XUE_YU_KUANG_MO, ELITE_AN_YING_CI_KE,
		ELITE_QING_TONG_JU_XIANG, ELITE_SHEN_YUAN_DA_ZHOU_SHI, ELITE_YUAN_GU_SHI_TIAN_CHONG,
		EVENT_FENG_XIU_CAN_QU, EVENT_TAN_LAN_DU_JIE,
		EVENT_LI_ZHI_XIU_SHI, EVENT_SHI_LIAN_KUI_LEI,
	]:
		_all[e["id"]] = e


func _init_enemies() -> void:
	# ─── 1. 纯粹强攻型：血灵狂徒（普通） ────────────────────────────
	# 循环2回合：试探攻击(6伤) → 全力重击(12伤)
	NORMAL_XUE_LING_KUANG_TU = {
		"id": "normal_xue_ling_kuang_tu",
		"name": "血灵狂徒",
		"lore": "不断施加生存压力，检验玩家基础生存能力。",
		"type": "normal", "archetype": "berserker",
		"hp": 45, "hu_ti": 0,
		"actions": [
			{"name":"试探攻击","intent_text":"试探攻击 · 6伤害","type":"attack","damage":6},
			{"name":"全力重击","intent_text":"全力重击 · 12伤害","type":"attack","damage":12},
		],
		"action_cycle": [0, 1],
	}

	# ─── 2. 蓄力爆发型：匿影死士（普通） ────────────────────────────
	# 循环3回合：屏息(身形+5) → 蓄力(无效果) → 绝影杀(20伤)
	NORMAL_NI_YING_SI_SHI = {
		"id": "normal_ni_ying_si_shi",
		"name": "匿影死士",
		"lore": "前两回合无害，第三回合爆发致命伤害。",
		"type": "normal", "archetype": "assassin",
		"hp": 40, "hu_ti": 0,
		"actions": [
			{"name":"屏息","intent_text":"屏息 · 获得5身形","type":"defend","shield":5,"is_shen_xing":true},
			{"name":"蓄力","intent_text":"蓄力 · 下回合致命","type":"buff","damage":0},
			{"name":"绝影杀","intent_text":"绝影杀 · 20伤害","type":"attack","damage":20},
		],
		"action_cycle": [0, 1, 2],
	}

	# ─── 3. 防守反击型：青铜卫甲（普通） ────────────────────────────
	# 初始护体15, 荆棘1层
	# 循环3回合：固化(+8护体) → 盾击(5伤+5身形) → 反震修补(+1荆棘)
	NORMAL_QING_TONG_WEI_JIA = {
		"id": "normal_qing_tong_wei_jia",
		"name": "青铜卫甲",
		"lore": "高护甲与反伤结合，惩罚多段攻击。",
		"type": "normal", "archetype": "tank",
		"hp": 35, "hu_ti": 15,
		"passive_jing_ci_n": 1,
		"actions": [
			{"name":"固化","intent_text":"固化 · 获得8护体","type":"defend","shield":8},
			{
				"name":"盾击","intent_text":"盾击 · 5伤+5身形",
				"type":"attack","damage":5,
				"self_shield_after":5,"self_shield_is_shen_xing":true
			},
			{
				"name":"反震修补","intent_text":"反震修补 · 获得1层荆棘",
				"type":"buff",
				"self_status":{"key":"jing_ci","stacks":1}
			},
		],
		"action_cycle": [0, 1, 2],
	}

	# ─── 4. 状态折磨型：腐化咒师（普通） ────────────────────────────
	# 循环3回合：暗语诅咒(3伤+暗伤→弃堆) → 剥夺(1枯竭) → 咒力释放(8伤)
	NORMAL_FU_HUA_ZHOU_SHI = {
		"id": "normal_fu_hua_zhou_shi",
		"name": "腐化咒师",
		"lore": "通过污染牌和Debuff破坏玩家卡组节奏。",
		"type": "normal", "archetype": "debuffer",
		"hp": 38, "hu_ti": 0,
		"actions": [
			{
				"name":"暗语诅咒","intent_text":"暗语诅咒 · 3伤+暗伤",
				"type":"attack","damage":3,
				"insert_card":{"card_id":"an_shang","target":"discard"}
			},
			{
				"name":"剥夺","intent_text":"剥夺 · 枯竭1层",
				"type":"debuff",
				"player_status":{"key":"ku_jie","stacks":1}
			},
			{"name":"咒力释放","intent_text":"咒力释放 · 8伤害","type":"attack","damage":8},
		],
		"action_cycle": [0, 1, 2],
	}

	# ─── 5. 持续成长型：吞噬蚰蜒（普通） ────────────────────────────
	# 循环3回合：吞食(+1道行) → 疯狂连击(3×2) → 撕咬(6伤)
	NORMAL_TUN_SHI_YOU_YAN = {
		"id": "normal_tun_shi_you_yan",
		"name": "吞噬蚰蜒",
		"lore": "DPS检测机，道行叠加，必须速杀。",
		"type": "normal", "archetype": "escalating",
		"hp": 50, "hu_ti": 0,
		"actions": [
			{
				"name":"吞食","intent_text":"吞食 · 获得1层道行",
				"type":"buff",
				"self_status":{"key":"dao_xing","stacks":1}
			},
			{"name":"疯狂连击","intent_text":"疯狂连击 · 3伤×2","type":"attack","damage":3,"hits":2},
			{"name":"撕咬","intent_text":"撕咬 · 6伤害","type":"attack","damage":6},
		],
		"action_cycle": [0, 1, 2],
	}

	# ─── 1E. 纯粹强攻型精英：血狱狂魔 ───────────────────────────────
	# 嗜血被动，循环3回合：重击(10)→重击(10)→血腥狂乱(6×3)
	ELITE_XUE_YU_KUANG_MO = {
		"id": "elite_xue_yu_kuang_mo",
		"name": "血狱狂魔",
		"lore": "精英化血灵狂徒，嗜血被动使其越战越强。",
		"type": "elite", "archetype": "berserker",
		"hp": 75, "hu_ti": 0,
		"passive_shi_xue": true,
		"actions": [
			{"name":"重击","intent_text":"重击 · 10伤害","type":"attack","damage":10},
			{"name":"重击","intent_text":"重击 · 10伤害","type":"attack","damage":10},
			{"name":"血腥狂乱","intent_text":"血腥狂乱 · 6伤×3","type":"attack","damage":6,"hits":3},
		],
		"action_cycle": [0, 1, 2],
	}

	# ─── 2E. 蓄力爆发型精英：暗影刺客 ───────────────────────────────
	# 初始不侵3次（受伤-50%），循环2回合：瞬步蓄力(+10身形)→绝影杀(24伤)
	ELITE_AN_YING_CI_KE = {
		"id": "elite_an_ying_ci_ke",
		"name": "暗影刺客",
		"lore": "精英刺客，自带不侵减伤，节奏加快为2回合。",
		"type": "elite", "archetype": "assassin",
		"hp": 65, "hu_ti": 0,
		"passive_bu_qin_hits": 3,
		"actions": [
			{"name":"瞬步蓄力","intent_text":"瞬步蓄力 · 获得10身形","type":"defend","shield":10,"is_shen_xing":true},
			{"name":"绝影杀","intent_text":"绝影杀 · 24伤害","type":"attack","damage":24},
		],
		"action_cycle": [0, 1],
	}

	# ─── 3E. 防守反击型精英：青铜巨像 ───────────────────────────────
	# 初始护体30, 荆棘3层
	# 循环3回合：巨像固化(+15护体)→重盾猛击(12伤+1震慑)→反震修补(+2荆棘)
	ELITE_QING_TONG_JU_XIANG = {
		"id": "elite_qing_tong_ju_xiang",
		"name": "青铜巨像",
		"lore": "精英铁王八，反伤3层，重盾附带震慑。",
		"type": "elite", "archetype": "tank",
		"hp": 55, "hu_ti": 30,
		"passive_jing_ci_n": 3,
		"actions": [
			{"name":"巨像固化","intent_text":"巨像固化 · 获得15护体","type":"defend","shield":15},
			{
				"name":"重盾猛击","intent_text":"重盾猛击 · 12伤+震慑",
				"type":"attack","damage":12,
				"player_status":{"key":"zhen_she","stacks":1}
			},
			{
				"name":"反震修补","intent_text":"反震修补 · 获得2层荆棘",
				"type":"buff",
				"self_status":{"key":"jing_ci","stacks":2}
			},
		],
		"action_cycle": [0, 1, 2],
	}

	# ─── 4E. 状态折磨型精英：深渊大咒师 ─────────────────────────────
	# 循环3回合：深渊诅咒(5伤+暗伤→抽牌堆顶)→全面剥夺(2枯竭+1裂伤)→咒力引爆(15伤)
	ELITE_SHEN_YUAN_DA_ZHOU_SHI = {
		"id": "elite_shen_yuan_da_zhou_shi",
		"name": "深渊大咒师",
		"lore": "污染更强烈，全面剥夺同时施加枯竭和裂伤。",
		"type": "elite", "archetype": "debuffer",
		"hp": 60, "hu_ti": 0,
		"passive_zai_e_halo": true,
		"actions": [
			{
				"name":"深渊诅咒","intent_text":"深渊诅咒 · 5伤+暗伤入顶",
				"type":"attack","damage":5,
				"insert_card":{"card_id":"an_shang","target":"draw_top"}
			},
			{
				"name":"全面剥夺","intent_text":"全面剥夺 · 2枯竭+1裂伤",
				"type":"debuff",
				"player_status":{"key":"ku_jie","stacks":2},
				"player_status_2":{"key":"lie_shang","stacks":1}
			},
			{"name":"咒力引爆","intent_text":"咒力引爆 · 15伤害","type":"attack","damage":15},
		],
		"action_cycle": [0, 1, 2],
	}

	# ─── 5E. 持续成长型精英：远古噬天虫 ─────────────────────────────
	# 初始道行2层，每回合+1道行
	# 循环2回合：疯狂连击(4×3)→深渊吞噬(10伤+吸血)
	ELITE_YUAN_GU_SHI_TIAN_CHONG = {
		"id": "elite_yuan_gu_shi_tian_chong",
		"name": "远古噬天虫",
		"lore": "精英养成怪，起始道行+2，每回合自动叠加，必须速杀。",
		"type": "elite", "archetype": "escalating",
		"hp": 85, "hu_ti": 10,
		"passive_dao_xing_n": 2,
		"passive_dao_xing_per_turn": 1,
		"actions": [
			{"name":"疯狂连击","intent_text":"疯狂连击 · 4伤×3","type":"attack","damage":4,"hits":3},
			{"name":"深渊吞噬","intent_text":"深渊吞噬 · 10伤+吸血","type":"attack","damage":10,"heal_self_on_dmg":true},
		],
		"action_cycle": [0, 1],
	}


func _init_event_enemies() -> void:
	# ─── 疯修·残躯（Q-104 强行夺取）──────────────────────────────────
	EVENT_FENG_XIU_CAN_QU = {
		"id": "event_feng_xiu_can_qu",
		"name": "疯修·残躯",
		"lore": "失去理智的修士，徒手搏斗，力量因疯狂而倍增。",
		"type": "normal", "archetype": "berserker",
		"hp": 45, "hu_ti": 0,
		"actions": [
			{"name": "乱撕", "intent_text": "乱撕 · 9伤害", "type": "attack", "damage": 9},
			{"name": "狂咬", "intent_text": "狂咬 · 15伤害", "type": "attack", "damage": 15},
		],
		"action_cycle": [0, 1],
	}
	# ─── 贪婪的渡劫者（Q-107 掀桌子抢劫）──────────────────────────────
	EVENT_TAN_LAN_DU_JIE = {
		"id": "event_tan_lan_du_jie",
		"name": "贪婪的渡劫者",
		"lore": "专攻富有的旅人，出手快狠准。",
		"type": "normal", "archetype": "assassin",
		"hp": 35, "hu_ti": 0,
		"actions": [
			{"name": "偷袭", "intent_text": "偷袭 · 10伤害", "type": "attack", "damage": 10},
			{"name": "连刺", "intent_text": "连刺 · 6伤×2", "type": "attack", "damage": 6, "hits": 2},
		],
		"action_cycle": [0, 1],
	}
	# ─── 理智修士（Q-111 趁其不备袭击他）─────────────────────────────
	EVENT_LI_ZHI_XIU_SHI = {
		"id": "event_li_zhi_xiu_shi",
		"name": "理智修士",
		"lore": "身经百战，警觉性极高，攻防兼备。",
		"type": "normal", "archetype": "balanced",
		"hp": 30, "hu_ti": 0,
		"actions": [
			{"name": "防御", "intent_text": "防御 · 获得7身形", "type": "defend", "shield": 7, "is_shen_xing": true},
			{"name": "反击", "intent_text": "反击 · 13伤害", "type": "attack", "damage": 13},
		],
		"action_cycle": [0, 1],
	}
	# ─── 试炼傀儡（Q-117 挑战试炼）───────────────────────────────────
	EVENT_SHI_LIAN_KUI_LEI = {
		"id": "event_shi_lian_kui_lei",
		"name": "试炼傀儡",
		"lore": "古法阵驱动的守护者，专为考验来者而生。",
		"type": "normal", "archetype": "tank",
		"hp": 30, "hu_ti": 5,
		"actions": [
			{"name": "固守", "intent_text": "固守 · 获得5护体", "type": "defend", "shield": 5},
			{"name": "试炼击", "intent_text": "试炼击 · 8伤害", "type": "attack", "damage": 8},
		],
		"action_cycle": [0, 1],
	}


func get_enemy(id: String) -> Dictionary:
	## 返回指定ID怪物的深拷贝（避免共享引用污染）
	return _all.get(id, {}).duplicate(true)


func get_enemy_by_id(id: String) -> Dictionary:
	## 精确获取（测试用，绕过随机）
	return get_enemy(id)


func get_enemy_for_node(node_type: String, _floor: int) -> Dictionary:
	## 根据节点类型随机返回对应池中的敌人
	var pool: Array[String]
	if node_type == "boss":
		return get_enemy("elite_xue_yu_kuang_mo")
	elif node_type == "elite":
		pool = ELITE_POOL
	elif node_type == "event_battle":
		var eid: String = GameState.event_battle_enemy_id
		if not eid.is_empty() and _all.has(eid):
			return get_enemy(eid)
		pool = NORMAL_POOL
	else:
		pool = NORMAL_POOL
	var idx: int = randi() % pool.size()
	return get_enemy(pool[idx])


## 兼容旧接口（BattleScene.gd 使用）
func get_battle_node_enemy(_node_id: String) -> Dictionary:
	var ntype: String = GameState.pending_battle_node_type
	var nfloor: int   = GameState.pending_battle_node_floor
	if ntype.is_empty():
		ntype = "normal"
	return get_enemy_for_node(ntype, nfloor)
