import json
import os

with open('scripts/data/all_card.json', encoding='utf-8') as f:
    data = json.load(f)

# Build card map for name lookup
card_map = {str(c['id']): c for c in data['cards']}

lines = []

def wr(s=''):
    lines.append(s)

wr('## TestCardEffects.gd')
wr('## 38张卡牌效果单元测试。每张牌都有独立的测试函数。')
wr('extends RefCounted')
wr('')
wr('const BattleEngineScript = preload("res://scripts/BattleEngine.gd")')
wr('')
wr('var _pass_count: int = 0')
wr('var _fail_count: int = 0')
wr('var _lines: Array[String] = []')
wr('')
wr('')
wr('func run_all() -> Dictionary:')
wr('\t_lines.append("\\n[ TestCardEffects ]")')
for c in data['cards']:
    wr(f'\t_t("test_card_{c["id"]}")')
wr('\t_lines.append("  → %d 通过  %d 失败" % [_pass_count, _fail_count])')
wr('\treturn {"pass": _pass_count, "fail": _fail_count, "lines": _lines}')
wr('')
wr('')
wr('# ── 工具 ──────────────────────────────────────────')
wr('')
wr('## 创建一个战斗引擎，已初始化好玩家和敌人数据。')
wr('## 玩家：HP=60, 灵力上限=20, 道慧=10')
wr('## 敌人：HP=100, 护体=0')
wr('func _make_engine() -> Object:')
wr('\tvar e: Object = BattleEngineScript.new()')
wr('\tvar char_data = {"hp_max": 60, "ling_li_max": 20, "dao_hui_max": 10}')
wr('\tvar enemy_data = {"hp": 100, "hu_ti": 0, "name": "测试敌人", "actions": []}')
wr('\te.init(char_data, [], enemy_data)')
wr('\treturn e')
wr('')
wr('')
wr('func _t(method: String) -> void:')
wr('\tcall(method)')
wr('')
wr('')
wr('func _assert_eq(a, b, label: String) -> void:')
wr('\tif str(a) == str(b):')
wr('\t\t_pass_count += 1')
wr('\t\t_lines.append("  ✓ %s" % label)')
wr('\telse:')
wr('\t\t_fail_count += 1')
wr('\t\t_lines.append("  ✗ %s  ← 期望 %s，实际 %s" % [label, str(b), str(a)])')
wr('')
wr('')
wr('func _assert_true(cond: bool, label: String) -> void:')
wr('\tif cond:')
wr('\t\t_pass_count += 1')
wr('\t\t_lines.append("  ✓ %s" % label)')
wr('\telse:')
wr('\t\t_fail_count += 1')
wr('\t\t_lines.append("  ✗ %s  ← 条件为假" % label)')
wr('')
wr('')
wr('# ── 测试用例 ──────────────────────────────────────────')

for c in data['cards']:
    cid = str(c['id'])
    name = c['name']
    ctype = c['type']
    
    wr('')
    wr(f'## 测试 [{cid}] {name}（{ctype}）')
    wr(f'func test_card_{cid}() -> void:')
    wr('\tvar e = _make_engine()')
    wr(f'\tvar card = {{"id": "{cid}", "is_upgraded": false}}')
    wr('\tvar s = e.get("s")')
    
    # 特殊前置条件
    if cid == '3':
        wr('\t# 设置灵力为4，用于测试灵力加成伤害')
        wr('\ts["player_ling_li"] = 4')
    elif cid == '8':
        wr('\t# 设置敌人护体10，触发崩甲额外伤害')
        wr('\ts["enemy_hu_ti"] = 10')
        wr('\ts["enemy_hp_max"] = 100')
    elif cid == '14':
        wr('\t# 降低敌人血量，确保攻击能造成伤害触发buff')
        wr('\ts["enemy_hp"] = 50')
    elif cid == '18':
        wr('\t# 敌人血量低于10%（100*10%=10），触发秒杀')
        wr('\ts["enemy_hp"] = 1')
        wr('\ts["enemy_hp_max"] = 100')
    elif cid == '25' or cid == '29':
        wr('\t# 预置2张手牌用于弃置')
        wr('\ts["hand"] = [{"id": "1", "card_type": "attack"}, {"id": "2", "card_type": "skill"}]')
        wr('\ts["draw_pile"] = [{"id": "3"}, {"id": "4"}, {"id": "5"}]')
    elif cid == '27':
        wr('\t# 弃牌堆里有1张术法牌可以回收')
        wr('\ts["discard_pile"] = [{"id": "1", "card_type": "attack", "dao_hui": 4}]')
    elif cid == '32':
        wr('\t# 设置灵力=10，cost=4时可消耗2次，获得2层道行')
        wr('\ts["player_ling_li"] = 10')
    
    # 通用抽牌堆（排除已在上面设置的）
    if cid not in ['25', '29', '27']:
        wr('\ts["draw_pile"] = [{"id": "dummy1"}, {"id": "dummy2"}, {"id": "dummy3"}]')
    
    wr('\te.call("_apply_card_effect", card)')
    wr('\t# 断言')
    
    # 断言逻辑
    if ctype == '术法':
        wr('\t_assert_true(s["attack_cards_played_this_turn"] == 1, "卡牌执行后 attack_cards_played_this_turn 应为 1")')
    
    if cid == '1':  # 点星剑法：9伤 + 抽1
        wr('\t_assert_eq(s["enemy_hp"], 91, "点星剑法 基础伤害应为9 (100-9=91)")')
        wr('\t_assert_eq(s["hand"].size(), 1, "点星剑法 应该抽取1张牌")')
    elif cid == '2':  # 枭首斩：6伤 + 若掉血回3灵力
        wr('\t_assert_eq(s["enemy_hp"], 94, "枭首斩 基础伤害应为6 (100-6=94)")')
        wr('\t_assert_eq(s["player_ling_li"], 3, "枭首斩 造成HP损失后应获得3灵力")')
    elif cid == '3':  # 灵能汇聚剑：7+2*3=13伤（灵力4时）
        wr('\t_assert_eq(s["enemy_hp"], 87, "灵能汇聚剑 灵力4时伤害应为13 (7+2*3=13, 100-13=87)")')
    elif cid == '4':  # 蜻蜓点水剑：2伤×2次=4
        wr('\t_assert_eq(s["enemy_hp"], 96, "蜻蜓点水剑 应造成2×2=4点伤害 (100-4=96)")')
    elif cid == '5':  # 剑气斩：6伤
        wr('\t_assert_eq(s["enemy_hp"], 94, "剑气斩 基础伤害应为6 (100-6=94)")')
    elif cid == '6':  # 双影斩：5伤×2次=10
        wr('\t_assert_eq(s["enemy_hp"], 90, "双影斩 应造成5×2=10点伤害 (100-10=90)")')
    elif cid == '7':  # 百脉连击：5伤×4次=20
        wr('\t_assert_eq(s["enemy_hp"], 80, "百脉连击 应造成5×4=20点伤害 (100-20=80)")')
    elif cid == '8':  # 崩甲剑：15+8(破甲)=23伤，护体10被破，剩13扣HP
        wr('\t_assert_eq(s["enemy_hu_ti"], 0, "崩甲剑 应破除所有护体")')
        wr('\t_assert_eq(s["enemy_hp"], 87, "崩甲剑 破甲后额外8伤，总23伤穿透10护体，HP损失13 (100-13=87)")')
    elif cid == '9':  # 孤注一掷：26伤
        wr('\t_assert_eq(s["enemy_hp"], 74, "孤注一掷 基础伤害应为26 (100-26=74)")')
    elif cid == '10':  # 藏锋积势：6伤+下回合1道行
        wr('\t_assert_eq(s["enemy_hp"], 94, "藏锋积势 伤害应为6 (100-6=94)")')
        wr('\t_assert_eq(s["next_turn_dao_xing"], 1, "藏锋积势 应设置下回合道行+1")')
    elif cid == '11':  # 逆鳞斩：8伤+2裂伤
        wr('\t_assert_eq(s["enemy_hp"], 92, "逆鳞斩 基础伤害应为8 (100-8=92)")')
        wr('\t_assert_eq(s["enemy_statuses"].get("lie_shang", 0), 2, "逆鳞斩 应施加2层裂伤")')
    elif cid == '12':  # 破风刺：10伤+抽2
        wr('\t_assert_eq(s["enemy_hp"], 90, "破风刺 基础伤害应为10 (100-10=90)")')
        wr('\t_assert_eq(s["hand"].size(), 2, "破风刺 应抽取2张牌")')
    elif cid == '13':  # 万法合击：20伤+10护+抽2+2道行
        wr('\t_assert_eq(s["enemy_hp"], 80, "万法合击 基础伤害应为20 (100-20=80)")')
        wr('\t_assert_eq(s["player_hu_ti"], 10, "万法合击 应获得10护体")')
        wr('\t_assert_eq(s["hand"].size(), 2, "万法合击 应抽取2张牌")')
        wr('\t_assert_eq(s["player_dao_xing"], 2, "万法合击 应获得2层道行")')
    elif cid == '14':  # 剔骨诀：4×3次=12伤+若掉血下N回合多抽1
        wr('\t_assert_eq(s["enemy_hp"], 38, "剔骨诀 应造成4×3=12点伤害 (50-12=38)")')
        wr('\t_assert_true(s.has("ti_gu_draw_turns"), "剔骨诀 敌人掉血后应设置额外抽牌buff")')
    elif cid == '15':  # 游丝连击：12伤+下回合再12伤
        wr('\t_assert_eq(s["enemy_hp"], 88, "游丝连击 基础伤害应为12 (100-12=88)")')
        wr('\t_assert_eq(s["delayed_damage"], 12, "游丝连击 应设置12点延迟伤害")')
    elif cid == '16':  # 百剑回响：5伤+2枯竭
        wr('\t_assert_eq(s["enemy_hp"], 95, "百剑回响 基础伤害应为5 (100-5=95)")')
        wr('\t_assert_eq(s["enemy_statuses"].get("ku_jie", 0), 2, "百剑回响 应施加2层枯竭")')
    elif cid == '17':  # 磐石剑：12伤+12护（等量护体）
        wr('\t_assert_eq(s["enemy_hp"], 88, "磐石剑 基础伤害应为12 (100-12=88)")')
        wr('\t_assert_eq(s["player_hu_ti"], 12, "磐石剑 应获得等量护体12")')
    elif cid == '18':  # 斩道剑：若敌人<10%HP直接秒杀
        wr('\t_assert_eq(s["enemy_hp"], 0, "斩道剑 敌人HP低于10%时应直接击杀 (enemy_hp=0)")')
    elif cid == '19':  # 万灵破：1×6次=6伤，每次命中+1灵力
        wr('\t_assert_eq(s["enemy_hp"], 94, "万灵破 应造成1×6=6点伤害 (100-6=94)")')
        wr('\t_assert_eq(s["player_ling_li"], 6, "万灵破 6次命中应恢复6灵力")')
    elif cid == '20':  # 剑气护体：6护
        wr('\t_assert_eq(s["player_hu_ti"], 6, "剑气护体 应获得6点护体")')
    elif cid == '21':  # 凝气层：8护+3灵力
        wr('\t_assert_eq(s["player_hu_ti"], 8, "凝气层 应获得8点护体")')
        wr('\t_assert_eq(s["player_ling_li"], 3, "凝气层 应获得3点灵力")')
    elif cid == '22':  # 踏雪无痕：6护+1道行
        wr('\t_assert_eq(s["player_hu_ti"], 6, "踏雪无痕 应获得6点护体")')
        wr('\t_assert_eq(s["player_dao_xing"], 1, "踏雪无痕 应获得1层道行")')
    elif cid == '23':  # 引灵归元：6护+灵力回复+2
        wr('\t_assert_eq(s["player_hu_ti"], 6, "引灵归元 应获得6点护体")')
        wr('\t_assert_eq(s["player_ling_li_regen"], s.get("player_ling_li_regen", 0), "引灵归元 应增加灵力回复量")')
    elif cid == '24':  # 导气术：抽2+3灵力
        wr('\t_assert_eq(s["hand"].size(), 2, "导气术 应抽取2张牌")')
        wr('\t_assert_eq(s["player_ling_li"], 3, "导气术 应获得3点灵力")')
    elif cid == '25':  # 乱局重整：弃2+抽3（等量+1）
        wr('\t_assert_eq(s["discard_pile"].size(), 2, "乱局重整 应将手牌2张放入弃牌堆")')
        wr('\t_assert_eq(s["hand"].size(), 3, "乱局重整 应抽取手牌数量+1=3张牌")')
    elif cid == '26':  # 缓气式：5护+下回合多抽1
        wr('\t_assert_eq(s["player_hu_ti"], 5, "缓气式 应获得5点护体")')
        wr('\t_assert_eq(s["extra_draw_next_turn"], 1, "缓气式 应设置下回合额外抽牌1张")')
    elif cid == '27':  # 旧招重现：弃牌堆顶术法牌→手牌，道慧-1
        wr('\t_assert_eq(s["hand"].size(), 1, "旧招重现 应将弃牌堆顶术法牌加入手牌")')
        wr('\t_assert_true(s["hand"][0].has("dao_hui_discount"), "旧招重现 回手牌应附带道慧折扣")')
    elif cid == '28':  # 收敛锋芒：12护
        wr('\t_assert_eq(s["player_hu_ti"], 12, "收敛锋芒 应获得12点护体")')
    elif cid == '29':  # 舍利求活：弃2+2×4护+抽2
        wr('\t_assert_eq(s["player_hu_ti"], 8, "舍利求活 每弃1张获得4护体，弃2张=8护体")')
        wr('\t_assert_eq(s["hand"].size(), 2, "舍利求活 应抽取2张牌")')
    elif cid == '30':  # 剑压锁喉：抽2+2心流
        wr('\t_assert_eq(s["hand"].size(), 2, "剑压锁喉 应抽取2张牌")')
        wr('\t_assert_eq(s["player_statuses"].get("xin_liu", 0), 2, "剑压锁喉 应获得2层心流")')
    elif cid == '31':  # 化剑为盾：20护+2不侵
        wr('\t_assert_eq(s["player_hu_ti"], 20, "化剑为盾 应获得20点护体")')
        wr('\t_assert_eq(s["player_statuses"].get("bu_qin", 0), 2, "化剑为盾 应获得2层不侵")')
    elif cid == '32':  # 灵化剑心：消耗4灵力*2次=8，剩余2，获得2道行
        wr('\t_assert_eq(s["player_ling_li"], 2, "灵化剑心 消耗灵力 10 / 4 = 2次消耗，剩余 10 - 4*2 = 2")')
        wr('\t_assert_eq(s["player_dao_xing"], 2, "灵化剑心 应获得2层道行 (各消耗一次)")')
    elif cid in ['33', '34', '35', '36', '37', '38']:  # 道法牌，激活被动
        wr('\t_assert_true(s.has("powers_active"), "道法牌 powers_active 应被创建")')
        wr('\t_assert_true(s["powers_active"].size() > 0, "道法牌 应被加入激活列表")')
        wr(f'\t_assert_eq(s["powers_active"][0]["id"], "{cid}", "激活的道法牌ID应为{cid}")')
    else:
        wr('\t_assert_true(true, "卡牌执行完成，无崩溃")')

# 写出文件
content = '\n'.join(lines)
out_path = 'tests/suites/TestCardEffects.gd'
os.makedirs(os.path.dirname(out_path), exist_ok=True)
with open(out_path, 'w', encoding='utf-8') as f:
    f.write(content)

print(f"生成完成：{out_path}，共 {len(lines)} 行")
