## EventDatabase.gd  (Autoload: EventDatabase)
## 奇遇事件数据库：Q-101~Q-119（第一重天）共19个事件。
## 提供事件池随机抽取和效果工具方法。
extends Node

# ── 第一重天事件 ID 池 ─────────────────────────────────────────────
const FIRST_HEAVEN_POOL: Array[String] = [
	"Q-101","Q-102","Q-103","Q-104","Q-105",
	"Q-106","Q-107","Q-108","Q-109","Q-110",
	"Q-111","Q-112","Q-113","Q-114","Q-115",
	"Q-116","Q-117","Q-118","Q-119",
]

# ── 事件专属宝物（不在 ShopDatabase 中，由事件直接授予）─────────────
const EVENT_ARTIFACTS: Dictionary = {
	"EVENT_R_BRONZE_GOLEM": {
		"id": "EVENT_R_BRONZE_GOLEM",
		"name": "铜傀随从",
		"rarity": "yellow",
		"effect_desc": "每场战斗第1回合，铜傀替你挡1次伤害（最多12点）。",
		"artifact_detail": "锈迹斑斑，却还记得主人的气息。"
	},
}

# ── 事件数据（var 而非 const 以规避 GDScript 嵌套 Array 限制）────────
var EVENTS: Dictionary = {}

func _ready() -> void:
	_ensure_events()


func _ensure_events() -> void:
	if not EVENTS.is_empty():
		return
	_build_events_1()
	_build_events_2()
	_build_events_3()


func _build_events_1() -> void:
	# ──────────────────────────────────────────────────────────────────
	# Q-101  前世的残躯
	EVENTS["Q-101"] = {
		"id": "Q-101", "floor_pool": 1,
		"title": "❓ 前世的残躯",
		"desc": "你在血迹斑驳的地面上发现了一具尸体。\n走近后你浑身一震——那是你自己。\n前世的你倒在这里，手中死死攥着什么东西。\n尸体的嘴角似乎挂着一丝不甘的笑意。",
		"options": [
			{
				"text": "翻找遗体",
				"condition": "",
				"random": false,
				"effects": [
					{"type": "stones_range", "min": 20, "max": 40},
					{"type": "card_random", "rarity": "黄品"},
				],
			},
			{
				"text": "★ 夺取手中之物",
				"condition": "",
				"random": true,
				"pre_effects": [],
				"effects": [],
				"random_outcomes": [
					{
						"weight": 70,
						"result_desc": "宝物到手！获得一件随机黄品宝器。",
						"effects": [{"type": "artifact_random", "rarity": "yellow"}],
					},
					{
						"weight": 30,
						"result_desc": "手中之物是诅咒……牌库塞入了1张【暗伤】。",
						"effects": [{"type": "curse_card", "card_id": "curse_dark_wound"}],
					},
				],
			},
			{
				"text": "默哀后离开",
				"condition": "",
				"random": false,
				"effects": [
					{"type": "heal", "amount": 10},
					{"type": "dao_xing_start", "amount": 1},
				],
				"flavor": "你向前世的自己鞠躬。这一世，你会走得更远。",
			},
		],
	}

	# ──────────────────────────────────────────────────────────────────
	# Q-102  垂死的剑修
	EVENTS["Q-102"] = {
		"id": "Q-102", "floor_pool": 1,
		"title": "❓ 垂死的剑修",
		"desc": "一个奄奄一息的剑修靠在断壁上，腹部被贯穿。\n他看着你，嘴角溢出鲜血：\n「道友……我撑不住了……\n但我这套剑法……不能就这么断了……你愿意接下吗？」",
		"options": [
			{
				"text": "接受他的传承",
				"condition": "",
				"random": false,
				"effects": [
					{"type": "heal", "amount": -8},
					{"type": "card_random", "rarity": "玄品", "subtype": "attack"},
				],
			},
			{
				"text": "给他一颗灵丹",
				"condition": "has_type:elixir",
				"random": false,
				"effects": [
					{"type": "consumable_spend_type", "category": "elixir", "count": 1},
					{"type": "card_random", "rarity": "玄品"},
					{"type": "stones", "amount": 15},
				],
			},
			{
				"text": "索要他身上的灵石",
				"condition": "",
				"random": false,
				"effects": [
					{"type": "stones", "amount": 30},
					{"type": "dao_xing_start", "amount": -1},
				],
				"flavor": "他失望地闭上眼睛，你失去了一分道心。",
			},
		],
	}

	# ──────────────────────────────────────────────────────────────────
	# Q-103  血池
	EVENTS["Q-103"] = {
		"id": "Q-103", "floor_pool": 1,
		"title": "❓ 血池",
		"desc": "前方是一洼暗红色的血池，表面冒着诡异的气泡。\n池中沉着一把发光的断剑，散发着强烈的灵力波动。\n但血池的气息让你本能地感到不安……",
		"options": [
			{
				"text": "★ 跳入血池取剑",
				"condition": "",
				"random": true,
				"pre_effects": [{"type": "heal_pct", "pct": -0.15}],
				"effects": [],
				"random_outcomes": [
					{
						"weight": 50,
						"result_desc": "断剑中封存着一件宝器！",
						"effects": [{"type": "artifact_random", "rarity": "mystique"}],
					},
					{
						"weight": 50,
						"result_desc": "拿到了一张玄品术法牌，但血池侵蚀了你的气机。",
						"effects": [{"type": "card_random", "rarity": "玄品", "subtype": "attack"}],
					},
				],
			},
			{
				"text": "★ 用长物挑取断剑",
				"condition": "",
				"random": true,
				"pre_effects": [],
				"effects": [],
				"random_outcomes": [
					{
						"weight": 60,
						"result_desc": "成功取出！获得一张黄品术法牌。",
						"effects": [{"type": "card_random", "rarity": "黄品", "subtype": "attack"}],
					},
					{
						"weight": 40,
						"result_desc": "断剑坠入池底，什么也没得到。",
						"effects": [],
					},
				],
			},
			{
				"text": "在血池边修炼",
				"condition": "",
				"random": false,
				"effects": [
					{"type": "perm_shield", "amount": 5},
				],
				"flavor": "血池中残留的灵力浸润了你的体魄。",
			},
		],
	}

	# ──────────────────────────────────────────────────────────────────
	# Q-104  疯修的宝箱
	EVENTS["Q-104"] = {
		"id": "Q-104", "floor_pool": 1,
		"title": "❓ 疯修的宝箱",
		"desc": "一个满身伤痕的疯修蹲在角落，护着一个上锁的箱子。\n他疯疯癫癫地自言自语：\n「我的……都是我的……你想要？拿命来换！\n不……拿灵石也行……」",
		"options": [
			{
				"text": "★ 用灵石交换（50灵石）",
				"condition": "stones_gte:50",
				"random": true,
				"pre_effects": [{"type": "stones_spend", "amount": 50}],
				"effects": [],
				"random_outcomes": [
					{
						"weight": 34,
						"result_desc": "宝箱里有一件宝器！",
						"effects": [{"type": "artifact_random", "rarity": "yellow"}],
					},
					{
						"weight": 33,
						"result_desc": "宝箱里有两张黄品卡牌！",
						"effects": [
							{"type": "card_random", "rarity": "黄品"},
							{"type": "card_random", "rarity": "黄品"},
						],
					},
					{
						"weight": 33,
						"result_desc": "宝箱里有三件消耗品！",
						"effects": [
							{"type": "consumable_random", "count": 3, "category": "elixir"},
						],
					},
				],
			},
			{
				"text": "强行夺取（进入战斗）",
				"condition": "",
				"random": false,
				"effects": [
					{"type": "stones", "amount": 30},
					{"type": "battle_event", "enemy_id": "event_feng_xiu_can_qu"},
				],
			},
			{
				"text": "无视他离开",
				"condition": "",
				"random": false,
				"effects": [],
				"flavor": "什么也没发生，安全前行。",
			},
		],
	}

	# ──────────────────────────────────────────────────────────────────
	# Q-105  刻满文字的石壁
	EVENTS["Q-105"] = {
		"id": "Q-105", "floor_pool": 1,
		"title": "❓ 刻满文字的石壁",
		"desc": "一面巨大的石壁上刻满了密密麻麻的文字和阵图。\n仔细辨认后，这似乎是某位前辈留下的修炼笔记。\n但文字极其晦涩，强行参悟可能会走火入魔。",
		"options": [
			{
				"text": "★ 全力参悟",
				"condition": "",
				"random": true,
				"pre_effects": [],
				"effects": [],
				"random_outcomes": [
					{
						"weight": 40,
						"result_desc": "顿悟！道行大进，还领会了一张玄品卡牌！",
						"effects": [
							{"type": "dao_xing_start", "amount": 2},
							{"type": "card_random", "rarity": "玄品"},
						],
					},
					{
						"weight": 35,
						"result_desc": "小有所得，获得1层道行。",
						"effects": [{"type": "dao_xing_start", "amount": 1}],
					},
					{
						"weight": 25,
						"result_desc": "走火入魔！受到10点伤害。",
						"effects": [{"type": "heal", "amount": -10}],
					},
				],
			},
			{
				"text": "抄录下来慢慢研究",
				"condition": "",
				"random": false,
				"effects": [{"type": "dao_xing_start", "amount": 1}],
				"flavor": "稳中有进，虽无大悟，却埋下了一粒种子。",
			},
			{
				"text": "破坏石壁取出内嵌灵石",
				"condition": "",
				"random": false,
				"effects": [{"type": "stones", "amount": 25}],
				"flavor": "石壁碎裂——前辈的智慧化为乌有。",
			},
		],
	}

	# ──────────────────────────────────────────────────────────────────
	# Q-106  铜傀工坊残骸
	EVENTS["Q-106"] = {
		"id": "Q-106", "floor_pool": 1,
		"title": "❓ 铜傀工坊残骸",
		"desc": "你误入了一处被遗弃的铜傀工坊。\n地上散落着各种零件和半成品。\n其中一具铜傀似乎还能修复，但需要消耗灵力。",
		"options": [
			{
				"text": "修复铜傀为己用",
				"condition": "",
				"random": false,
				"effects": [
					{"type": "heal", "amount": -10},
					{"type": "artifact_event", "artifact_id": "EVENT_R_BRONZE_GOLEM"},
				],
				"flavor": "铜傀站起来，向你深深鞠躬，它认主了。",
			},
			{
				"text": "拆解零件",
				"condition": "",
				"random": false,
				"effects": [
					{"type": "stones", "amount": 35},
					{"type": "perm_shield", "amount": 5},
				],
			},
			{
				"text": "搜刮工坊",
				"condition": "",
				"random": false,
				"effects": [
					{"type": "stones", "amount": 20},
					{"type": "card_random", "rarity": "黄品"},
				],
			},
		],
	}



func _build_events_2() -> void:
	# Q-107 ~ Q-112
	EVENTS["Q-107"] = {
		"id": "Q-107", "floor_pool": 1,
		"title": "❓ 赌徒的骰子",
		"desc": "一个笑容诡异的渡劫者挡住你的去路。\n「道友，来玩个小游戏吧？我这骰子可有意思得很。\n赢了，你带走我的宝贝。输了……嘿嘿……」",
		"options": [
			{
				"text": "★ 赌一把（赌注：20灵石）",
				"condition": "stones_gte:20",
				"random": true,
				"pre_effects": [{"type": "stones_spend", "amount": 20}],
				"effects": [],
				"random_outcomes": [
					{
						"weight": 50,
						"result_desc": "赢了！净赚 40 灵石！",
						"effects": [{"type": "stones", "amount": 60}],
					},
					{
						"weight": 50,
						"result_desc": "输了……20 灵石打了水漂。",
						"effects": [],
					},
				],
			},
			{
				"text": "★ 赌大的（赌注：50灵石）",
				"condition": "stones_gte:50",
				"random": true,
				"pre_effects": [{"type": "stones_spend", "amount": 50}],
				"effects": [],
				"random_outcomes": [
					{
						"weight": 50,
						"result_desc": "赢了！获得一件随机玄品宝器！",
						"effects": [{"type": "artifact_random", "rarity": "mystique"}],
					},
					{
						"weight": 50,
						"result_desc": "输了……50 灵石付诸东流。",
						"effects": [],
					},
				],
			},
			{
				"text": "掀桌子抢劫（进入战斗）",
				"condition": "",
				"random": false,
				"effects": [
					{"type": "stones", "amount": 40},
					{"type": "consumable_random", "count": 1, "category": ""},
					{"type": "battle_event", "enemy_id": "event_tan_lan_du_jie"},
				],
			},
			{
				"text": "不感兴趣，离开",
				"condition": "",
				"random": false,
				"effects": [],
			},
		],
	}

	# ──────────────────────────────────────────────────────────────────
	# Q-108  被封印的剑灵
	EVENTS["Q-108"] = {
		"id": "Q-108", "floor_pool": 1,
		"title": "❓ 被封印的剑灵",
		"desc": "你发现了一把被锁链缠绕的古剑。剑身微微颤抖，发出细弱的嗡鸣声。\n「放我出来……我被困在这里太久了……\n解开封印，我会给你力量……」",
		"options": [
			{
				"text": "★ 解开封印",
				"condition": "",
				"random": true,
				"pre_effects": [],
				"effects": [],
				"random_outcomes": [
					{
						"weight": 60,
						"result_desc": "剑灵感恩，赐予永久起始剑意+3！",
						"effects": [{"type": "dao_xing_start", "amount": 3}],
					},
					{
						"weight": 40,
						"result_desc": "剑灵是邪物！战斗开始！先给你一张卡牌作为补偿……",
						"effects": [
							{"type": "card_random", "rarity": "玄品", "subtype": "attack"},
							{"type": "battle_event", "enemy_id": "normal_xue_ling_kuang_tu"},
						],
					},
				],
			},
			{
				"text": "无视剑灵的请求",
				"condition": "",
				"random": false,
				"effects": [{"type": "stones", "amount": 10}],
				"flavor": "拆解锁链上的材料，换了点灵石。",
			},
			{
				"text": "与剑灵交谈，获取情报",
				"condition": "",
				"random": false,
				"effects": [
					{"type": "dao_xing_start", "amount": 1},
				],
				"flavor": "剑灵告诉你前方守门人的一处弱点。你的道心更加坚定。",
			},
		],
	}

	# ──────────────────────────────────────────────────────────────────
	# Q-109  前辈的藏宝处
	EVENTS["Q-109"] = {
		"id": "Q-109", "floor_pool": 1,
		"title": "❓ 前辈的藏宝处",
		"desc": "你注意到墙壁上有一处暗格，打开后发现一个小储物袋。\n里面有几件物品，但储物袋的灵力已经快要散尽，\n你只能选择拿走其中一件。",
		"options": [
			{
				"text": "拿走丹药",
				"condition": "",
				"random": false,
				"effects": [
					{"type": "consumable_get", "id": "D-02"},
					{"type": "consumable_get", "id": "D-03"},
				],
			},
			{
				"text": "拿走卡牌",
				"condition": "",
				"random": false,
				"effects": [{"type": "card_random", "rarity": "玄品"}],
			},
			{
				"text": "拿走灵石",
				"condition": "",
				"random": false,
				"effects": [{"type": "stones", "amount": 60}],
			},
		],
	}

	# ──────────────────────────────────────────────────────────────────
	# Q-110  天道裂缝
	EVENTS["Q-110"] = {
		"id": "Q-110", "floor_pool": 1,
		"title": "❓ 天道裂缝",
		"desc": "你感到空气中有一丝异样的波动。\n循着感觉走去，你发现了一道微小的空间裂缝。\n裂缝中散发着纯净的灵力，但同时也带有天道的法则压迫。",
		"options": [
			{
				"text": "吸收裂缝中的灵力",
				"condition": "",
				"random": false,
				"effects": [
					{"type": "dao_xing_start", "amount": 1},
					{"type": "heal", "amount": 15},
				],
				"flavor": "灵力涌入体内，但你感到有什么目光落在了你身上……",
			},
			{
				"text": "★ 将裂缝扩大",
				"condition": "",
				"random": true,
				"pre_effects": [],
				"effects": [],
				"random_outcomes": [
					{
						"weight": 30,
						"result_desc": "发现隐藏空间！获得一件玄品宝器和50灵石！",
						"effects": [
							{"type": "artifact_random", "rarity": "mystique"},
							{"type": "stones", "amount": 50},
						],
					},
					{
						"weight": 70,
						"result_desc": "裂缝坍塌，受到12点伤害！",
						"effects": [{"type": "heal", "amount": -12}],
					},
				],
			},
			{
				"text": "用裂缝中的灵力升级卡牌",
				"condition": "has_non_upgraded",
				"random": false,
				"effects": [{"type": "card_upgrade_choose"}],
				"flavor": "裂缝中的法则精华浸润了你的一张卡牌。",
			},
		],
	}

	# ──────────────────────────────────────────────────────────────────
	# Q-111  同路者
	EVENTS["Q-111"] = {
		"id": "Q-111", "floor_pool": 1,
		"title": "❓ 同路者",
		"desc": "你遇到了另一个还保持着理智的修士。\n他看起来很疲惫，但眼中还有光：\n「道友，我们合作如何？前面有个棘手的精英，一个人恐怕不好对付。」",
		"options": [
			{
				"text": "与他合作",
				"condition": "",
				"random": false,
				"effects": [
					{"type": "dao_xing_start", "amount": 1},
				],
				"flavor": "并肩前行，你们互相传授了一些经验。",
			},
			{
				"text": "分享你的补给（消耗15灵石）",
				"condition": "stones_gte:15",
				"random": false,
				"effects": [
					{"type": "stones_spend", "amount": 15},
					{"type": "card_random", "rarity": "黄品"},
					{"type": "dao_xing_start", "amount": 2},
				],
				"flavor": "他感激地把自己的发现全都告诉了你。",
			},
			{
				"text": "拒绝合作",
				"condition": "",
				"random": false,
				"effects": [],
				"flavor": "他有些失落，但也理解。各走各路。",
			},
			{
				"text": "趁其不备袭击他（获得道义惩罚）",
				"condition": "",
				"random": false,
				"effects": [
					{"type": "stones", "amount": 45},
					{"type": "consumable_random", "count": 1, "category": ""},
					{"type": "curse_card", "card_id": "curse_xin_mo"},
					{"type": "curse_card", "card_id": "curse_xin_mo"},
					{"type": "battle_event", "enemy_id": "event_li_zhi_xiu_shi"},
				],
			},
		],
	}

	# ──────────────────────────────────────────────────────────────────
	# Q-112  断裂的锁链桥
	EVENTS["Q-112"] = {
		"id": "Q-112", "floor_pool": 1,
		"title": "❓ 断裂的锁链桥",
		"desc": "前方的天道锁链断裂了一截，形成了一道深渊。\n深渊对面似乎有些什么在发光。\n你可以冒险跳过去，但失败的代价可能很大。",
		"options": [
			{
				"text": "★ 纵身一跃",
				"condition": "",
				"random": true,
				"pre_effects": [],
				"effects": [],
				"random_outcomes": [
					{
						"weight": 70,
						"result_desc": "安全跳过！获得对面的宝器！",
						"effects": [{"type": "artifact_random", "rarity": "yellow"}],
					},
					{
						"weight": 30,
						"result_desc": "差点坠落，勉强攀上来，失去 20% 当前HP！",
						"effects": [{"type": "heal_pct", "pct": -0.20}],
					},
				],
			},
			{
				"text": "寻找其他路径绕过去",
				"condition": "",
				"random": false,
				"effects": [{"type": "stones", "amount": 15}],
				"flavor": "耗时较长，但安全到达，路上还捡到了一些灵石。",
			},
			{
				"text": "使用符箓搭建桥梁（消耗1张符箓）",
				"condition": "has_type:talisman",
				"random": false,
				"effects": [
					{"type": "consumable_spend_type", "category": "talisman", "count": 1},
					{"type": "artifact_random", "rarity": "yellow"},
				],
			},
		],
	}



func _build_events_3() -> void:
	# Q-113 ~ Q-119
	EVENTS["Q-113"] = {
		"id": "Q-113", "floor_pool": 1,
		"title": "❓ 荒废炼丹炉",
		"desc": "一座锈迹斑斑的丹炉横在路旁，炉火早已熄灭。\n炉壁上还残留着丹道阵纹，内部弥散着微弱的灵力余韵。\n或许还能发挥最后一丝用处。",
		"options": [
			{
				"text": "祭入1张卡牌炼制",
				"condition": "deck_size_gte:2",
				"random": false,
				"effects": [
					{"type": "card_remove_choose"},
					{"type": "consumable_random", "count": 2, "category": "elixir"},
					{"type": "heal", "amount": 15},
				],
			},
			{
				"text": "用符箓点燃炉火（消耗1张符箓）",
				"condition": "has_type:talisman",
				"random": false,
				"effects": [
					{"type": "consumable_spend_type", "category": "talisman", "count": 1},
					{"type": "consumable_random", "count": 3, "category": "elixir"},
				],
			},
			{
				"text": "拆解炉体换取材料",
				"condition": "",
				"random": false,
				"effects": [{"type": "stones", "amount": 35}],
			},
			{
				"text": "在余温中调息",
				"condition": "",
				"random": false,
				"effects": [{"type": "heal", "amount": 15}],
				"flavor": "炉灰的余温驱散了寒意，你稍作休整。",
			},
		],
	}

	# ──────────────────────────────────────────────────────────────────
	# Q-114  游荡的药鬼  [新增]
	EVENTS["Q-114"] = {
		"id": "Q-114", "floor_pool": 1,
		"title": "❓ 游荡的药鬼",
		"desc": "一缕幽魂在路边游荡，手中抱着一堆丹瓶——\n那是一位死于炼丹事故的药师，死后仍不舍他的丹药。\n「要……要买丹药吗？我这里有……很多……」",
		"options": [
			{
				"text": "花灵石购买（40灵石）",
				"condition": "stones_gte:40",
				"random": false,
				"effects": [
					{"type": "stones_spend", "amount": 40},
					{"type": "consumable_random", "count": 2, "category": "elixir", "rarity_filter": "yellow"},
				],
			},
			{
				"text": "以血肉为报酬（最大HP永久-8）",
				"condition": "",
				"random": false,
				"effects": [
					{"type": "max_hp_perm", "amount": -8},
					{"type": "consumable_random", "count": 2, "category": "elixir", "rarity_filter": "mystique"},
					{"type": "heal", "amount": 20},
				],
				"flavor": "鬼魂贪婪地吸走了一缕生机，给你留下了精品。",
			},
			{
				"text": "移除1张卡牌换取珍品",
				"condition": "deck_size_gte:2",
				"random": false,
				"effects": [
					{"type": "card_remove_choose"},
					{"type": "consumable_random", "count": 1, "category": "elixir", "rarity_filter": "mystique"},
					{"type": "consumable_random", "count": 1, "category": "elixir", "rarity_filter": "yellow"},
				],
			},
			{
				"text": "驱散鬼魂，搜刮遗物",
				"condition": "",
				"random": false,
				"effects": [
					{"type": "stones", "amount": 20},
					{"type": "consumable_random", "count": 1, "category": "elixir", "rarity_filter": "yellow"},
				],
			},
		],
	}

	# ──────────────────────────────────────────────────────────────────
	# Q-115  残损符箓  [新增]
	EVENTS["Q-115"] = {
		"id": "Q-115", "floor_pool": 1,
		"title": "❓ 残损符箓",
		"desc": "一张符箓扭曲地贴在墙壁上，符文已有多处断裂。\n但其中残留的灵力依然不容小觑——\n断裂的符文有时反而会引发更猛烈的反应。",
		"options": [
			{
				"text": "★ 强行激活",
				"condition": "",
				"random": true,
				"pre_effects": [],
				"effects": [],
				"random_outcomes": [
					{
						"weight": 50,
						"result_desc": "符箓虽残却激活成功！获得2张黄品符箓！",
						"effects": [
							{"type": "consumable_random", "count": 2, "category": "talisman", "rarity_filter": "yellow"},
						],
					},
					{
						"weight": 50,
						"result_desc": "符文失控爆炸！受到12点伤害！",
						"effects": [{"type": "heal", "amount": -12}],
					},
				],
			},
			{
				"text": "仔细修复（消耗20灵石）",
				"condition": "stones_gte:20",
				"random": false,
				"effects": [
					{"type": "stones_spend", "amount": 20},
					{"type": "consumable_random", "count": 1, "category": "talisman", "rarity_filter": "yellow"},
				],
			},
			{
				"text": "拆解符文精华",
				"condition": "",
				"random": false,
				"effects": [{"type": "dao_xing_start", "amount": 2}],
				"flavor": "破碎的符文中蕴含的剑意残片，恰好是你所缺少的。",
			},
			{
				"text": "丢弃不理",
				"condition": "",
				"random": false,
				"effects": [],
			},
		],
	}

	# ──────────────────────────────────────────────────────────────────
	# Q-116  垂死的行商  [新增]
	EVENTS["Q-116"] = {
		"id": "Q-116", "floor_pool": 1,
		"title": "❓ 垂死的行商",
		"desc": "一个行商倒在角落，货物散落一地。\n他的伤势来自前方精英怪物的袭击。\n「道友……求你救我……我还有好货……」\n他的眼中同时有恳求和算计。",
		"options": [
			{
				"text": "施救（当场失去12 HP）",
				"condition": "",
				"random": false,
				"effects": [
					{"type": "heal", "amount": -12},
					{"type": "artifact_random", "rarity": "yellow"},
				],
				"flavor": "他感激地赠予你一件宝物，随后踉踉跄跄离开了。",
			},
			{
				"text": "买下他的货物（35灵石）",
				"condition": "stones_gte:35",
				"random": false,
				"effects": [
					{"type": "stones_spend", "amount": 35},
					{"type": "consumable_random", "count": 1, "category": ""},
					{"type": "consumable_random", "count": 1, "category": "talisman", "rarity_filter": "yellow"},
				],
			},
			{
				"text": "见死不救，搜刮散落货物",
				"condition": "",
				"random": false,
				"effects": [
					{"type": "stones", "amount": 25},
					{"type": "max_hp_perm", "amount": -5},
				],
				"flavor": "他失望地闭上眼睛。你拾起了灵石，也拾起了一份沉重。",
			},
			{
				"text": "查看他的路线图后离开",
				"condition": "",
				"random": false,
				"effects": [{"type": "stones", "amount": 15}],
			},
		],
	}

	# ──────────────────────────────────────────────────────────────────
	# Q-117  传承试炼台  [新增]
	EVENTS["Q-117"] = {
		"id": "Q-117", "floor_pool": 1,
		"title": "❓ 传承试炼台",
		"desc": "一座古老的方台矗立在此，台上用古文写着：\n「有能者自取，无能者请走。」\n台侧摆着一套功法简牍，被一道法阵封印——\n必须通过试炼，法阵才会自行解除。",
		"options": [
			{
				"text": "挑战试炼（对决：试炼傀儡）",
				"condition": "",
				"random": false,
				"effects": [
					{"type": "battle_event", "enemy_id": "event_shi_lian_kui_lei", "post_upgrade": true},
				],
				"flavor": "试炼傀儡已准备就绪——胜者方可得到升级机会。",
			},
			{
				"text": "参悟台上的功法文字",
				"condition": "",
				"random": false,
				"effects": [{"type": "dao_xing_start", "amount": 1}],
			},
			{
				"text": "拆除试炼台，取走核心",
				"condition": "",
				"random": false,
				"effects": [
					{"type": "stones", "amount": 30},
					{"type": "perm_shield", "amount": 5},
				],
				"flavor": "台石轰然碎裂——古人的苦心全数散尽。",
			},
		],
	}

	# ──────────────────────────────────────────────────────────────────
	# Q-118  枯竭的灵泉  [新增]
	EVENTS["Q-118"] = {
		"id": "Q-118", "floor_pool": 1,
		"title": "❓ 枯竭的灵泉",
		"desc": "一处石缝中曾经涌出的灵泉已近枯竭，\n底部仅余浅浅一层带着金光的灵液。\n泉眼深处似乎还有更多能量可以汲取——\n只是代价未知。",
		"options": [
			{
				"text": "盘坐调息，汲取余韵",
				"condition": "",
				"random": false,
				"effects": [{"type": "heal", "amount": 20}],
				"flavor": "灵泉的温度让疲惫稍稍褪去。",
			},
			{
				"text": "深度炼化，竭泽而渔",
				"condition": "",
				"random": false,
				"effects": [
					{"type": "heal_full"},
					{"type": "max_hp_perm", "amount": -5},
				],
				"flavor": "你吸干了最后一滴灵液，伤势全愈——但身体的极限也略有收缩。",
			},
			{
				"text": "用符箓引导灵泉复苏（消耗1张符箓）",
				"condition": "has_type:talisman",
				"random": false,
				"effects": [
					{"type": "consumable_spend_type", "category": "talisman", "count": 1},
					{"type": "max_hp_perm", "amount": 5},
					{"type": "heal", "amount": 15},
				],
				"flavor": "符箓净化了泉眼，灵泉缓缓复苏，将力量回赐于你。",
			},
			{
				"text": "收集残留灵液为药材",
				"condition": "",
				"random": false,
				"effects": [{"type": "consumable_get", "id": "D-02"}],
			},
		],
	}

	# ──────────────────────────────────────────────────────────────────
	# Q-119  剑魂残影传招  [新增]
	EVENTS["Q-119"] = {
		"id": "Q-119", "floor_pool": 1,
		"title": "❓ 剑魂残影传招",
		"desc": "一道半透明的剑修虚影悬浮在空中，无声地演练着精妙的剑术。\n这是某位强者留下的残影——他的灵脉已经拓宽。\n模拟那种开辟灵脉的感觉，你或许能突破自身限制。",
		"options": [
			{
				"text": "倾力领悟，强行拓展灵脉（失去10 HP）",
				"condition": "",
				"random": false,
				"effects": [
					{"type": "heal", "amount": -10},
					{"type": "ling_li_max_perm", "amount": 1},
				],
				"flavor": "一阵剧痛后，你感到体内有什么东西被撑开了。",
			},
			{
				"text": "只学其中一式防御招数",
				"condition": "",
				"random": false,
				"effects": [{"type": "card_random", "rarity": "黄品", "subtype": "skill"}],
			},
			{
				"text": "细心抄录，留待日后参悟",
				"condition": "",
				"random": false,
				"effects": [{"type": "dao_xing_start", "amount": 1}],
				"flavor": "传承剑魂的眼中满是欣慰，它的形体渐渐消散——「你有这份心，比我强。」",
			},
		],
	}


# ── 公开 API ──────────────────────────────────────────────────────

func get_event(event_id: String) -> Dictionary:
	_ensure_events()
	return EVENTS.get(event_id, {})


func get_random_event_id(_floor: int) -> String:
	## 按楼层选择事件池，从未触发的事件中随机抽取。
	## MVP：1-16层全部使用第一重天事件池。
	_ensure_events()
	var pool: Array[String] = FIRST_HEAVEN_POOL.duplicate()

	# 排除已触发的事件
	var available: Array[String] = []
	for eid in pool:
		if not GameState.visited_events.has(eid) and EVENTS.has(eid):
			available.append(eid)

	if available.is_empty():
		# 所有事件都已触发，重置并重新使用全池
		for eid2 in pool:
			if EVENTS.has(eid2):
				available.append(eid2)

	if available.is_empty():
		return "Q-101"

	return available[randi() % available.size()]


## 条件检查
func check_condition(condition: String) -> bool:
	if condition.is_empty():
		return true
	var parts: PackedStringArray = condition.split(":", false, 2)
	if parts.is_empty():
		return true
	var part0: String = parts[0]
	var part1: String = parts[1] if parts.size() > 1 else ""
	match part0:
		"stones_gte":
			return GameState.spirit_stones >= int(part1)
		"has_type":
			return _has_consumable_of_type(part1)
		"has_type_count":
			var sub: PackedStringArray = part1.split(":", false, 1)
			if sub.size() < 2:
				return false
			return _count_consumable_of_type(sub[0]) >= int(sub[1])
		"dao_xing_gte":
			return GameState.dao_xing_battle_start >= int(part1)
		"has_non_upgraded":
			return _has_non_upgraded_card()
		"deck_size_gte":
			return GameState.deck.size() >= int(part1)
		"deck_rarity_count":
			var sub2: PackedStringArray = part1.split(":", false, 1)
			if sub2.size() < 2:
				return false
			return _count_deck_rarity(sub2[0]) >= int(sub2[1])
	return false


## 随机获取指定稀有度的卡牌 ID（rarity 使用中文：黄品/玄品/地品/天品）
func get_random_card_by_rarity(rarity: String, subtype: String = "") -> String:
	var all_cards: Array[Dictionary] = CardDatabase.get_all_cards()
	var filtered: Array[String] = []
	for c in all_cards:
		if c.get("rarity", "") == rarity:
			var base_id: String = str(c.get("id", ""))
			if base_id.ends_with("+"):
				continue
			if not subtype.is_empty() and c.get("card_type", "") != subtype:
				continue
			filtered.append(base_id)
	if filtered.is_empty():
		# 回退：忽略 subtype 限制
		if not subtype.is_empty():
			return get_random_card_by_rarity(rarity)
		return ""
	return filtered[randi() % filtered.size()]


## 随机获取指定稀有度的宝物（rarity 使用英文：yellow/mystique/earth/heaven）
func get_random_artifact_by_rarity(rarity: String) -> Dictionary:
	var all_arts: Array[Dictionary] = ShopDatabase.get_all_artifacts()
	var owned_ids: Array[String] = []
	for a in GameState.artifacts:
		owned_ids.append(str(a.get("id", "")))
	var filtered: Array[Dictionary] = []
	for a in all_arts:
		if a.get("rarity", "") == rarity and not owned_ids.has(str(a.get("id", ""))):
			filtered.append(a)
	if filtered.is_empty():
		if not all_arts.is_empty():
			return all_arts[randi() % all_arts.size()]
		return {}
	return filtered[randi() % filtered.size()]


## 随机获取消耗品（category: ""=任意, "elixir"/"talisman"/"formation"；rarity_filter: ""=任意）
func get_random_consumable(category: String = "", rarity_filter: String = "") -> Dictionary:
	var all_items: Array[Dictionary] = ShopDatabase.get_all_items()
	var filtered: Array[Dictionary] = []
	for item in all_items:
		if not category.is_empty() and item.get("category", "") != category:
			continue
		if not rarity_filter.is_empty() and item.get("rarity", "") != rarity_filter:
			continue
		filtered.append(item)
	if filtered.is_empty():
		return {}
	return filtered[randi() % filtered.size()]


## 获取事件专属宝物
func get_event_artifact(artifact_id: String) -> Dictionary:
	return EVENT_ARTIFACTS.get(artifact_id, {}).duplicate(true)


# ── 内部工具 ──────────────────────────────────────────────────────

func _has_consumable_of_type(category: String) -> bool:
	for c in GameState.consumables:
		if c.get("category", "") == category:
			return true
	return false


func _count_consumable_of_type(category: String) -> int:
	var cnt := 0
	for c in GameState.consumables:
		if c.get("category", "") == category:
			cnt += 1
	return cnt


func _has_non_upgraded_card() -> bool:
	for card_id in GameState.deck:
		if not str(card_id).ends_with("+"):
			return true
	return false


func _count_deck_rarity(rarity: String) -> int:
	var cnt := 0
	for card_id in GameState.deck:
		var cdata: Dictionary = CardDatabase.get_card(card_id)
		if cdata.get("rarity", "") == rarity:
			cnt += 1
	return cnt
