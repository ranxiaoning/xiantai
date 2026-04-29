import json
import re

with open('scripts/data/all_card.json', encoding='utf-8') as f:
    data = json.load(f)

cases = []

cases.append('\tvar base := 0\n\tvar dmg := 0\n\tvar shield := 0\n\tvar hits := 0\n\tvar extra := 0\n\tvar bonus_ling := 0\n\tmatch id:\n')

for c in data['cards']:
    cid = str(c['id'])
    effect = c['effect']
    
    gd = f'\t\t\"{cid}\":\n'
    
    if cid == '2':
        gd += f'\t\t\tbase = 10 if upgraded else 6\n'
        gd += f'\t\t\tdmg = _calc_player_damage(base)\n'
        gd += f'\t\t\tvar hp_before = s[\"enemy_hp\"]\n'
        gd += f'\t\t\t_deal_damage_to_enemy(dmg)\n'
        gd += f'\t\t\tif s[\"enemy_hp\"] < hp_before:\n'
        gd += f'\t\t\t\ts[\"player_ling_li\"] = min(s[\"player_ling_li\"] + 3, s[\"player_ling_li_max\"])\n'
        gd += f'\t\t\ts[\"attack_cards_played_this_turn\"] += 1\n'
    elif cid == '3':
        gd += f'\t\t\tbase = 10 if upgraded else 7\n'
        gd += f'\t\t\textra = 4 if upgraded else 3\n'
        gd += f'\t\t\tbase += floor(s[\"player_ling_li\"] / 2.0) * extra\n'
        gd += f'\t\t\tdmg = _calc_player_damage(base)\n'
        gd += f'\t\t\t_deal_damage_to_enemy(dmg)\n'
        gd += f'\t\t\ts[\"attack_cards_played_this_turn\"] += 1\n'
    elif cid == '4':
        gd += f'\t\t\tbase = 2\n'
        gd += f'\t\t\thits = 3 if upgraded else 2\n'
        gd += f'\t\t\tfor _i in range(hits):\n'
        gd += f'\t\t\t\tdmg = _calc_player_damage(base)\n'
        gd += f'\t\t\t\t_deal_damage_to_enemy(dmg)\n'
        gd += f'\t\t\ts[\"attack_cards_played_this_turn\"] += 1\n'
    elif cid == '6':
        gd += f'\t\t\tbase = 7 if upgraded else 5\n'
        gd += f'\t\t\thits = 2\n'
        gd += f'\t\t\tfor _i in range(hits):\n'
        gd += f'\t\t\t\tdmg = _calc_player_damage(base)\n'
        gd += f'\t\t\t\t_deal_damage_to_enemy(dmg)\n'
        gd += f'\t\t\ts[\"attack_cards_played_this_turn\"] += 1\n'
    elif cid == '7':
        gd += f'\t\t\tbase = 6 if upgraded else 5\n'
        gd += f'\t\t\thits = 5 if upgraded else 4\n'
        gd += f'\t\t\tfor _i in range(hits):\n'
        gd += f'\t\t\t\tdmg = _calc_player_damage(base)\n'
        gd += f'\t\t\t\t_deal_damage_to_enemy(dmg)\n'
        gd += f'\t\t\ts[\"attack_cards_played_this_turn\"] += 1\n'
    elif cid == '8':
        gd += f'\t\t\tbase = 20 if upgraded else 15\n'
        gd += f'\t\t\tdmg = _calc_player_damage(base)\n'
        gd += f'\t\t\tif s[\"enemy_hu_ti\"] > 0:\n'
        gd += f'\t\t\t\tdmg += 12 if upgraded else 8\n'
        gd += f'\t\t\t_deal_damage_to_enemy(dmg)\n'
        gd += f'\t\t\ts[\"attack_cards_played_this_turn\"] += 1\n'
    elif cid == '14':
        gd += f'\t\t\tbase = 5 if upgraded else 4\n'
        gd += f'\t\t\thits = 4 if upgraded else 3\n'
        gd += f'\t\t\tvar hp_before = s[\"enemy_hp\"]\n'
        gd += f'\t\t\tfor _i in range(hits):\n'
        gd += f'\t\t\t\tdmg = _calc_player_damage(base)\n'
        gd += f'\t\t\t\t_deal_damage_to_enemy(dmg)\n'
        gd += f'\t\t\tif s[\"enemy_hp\"] < hp_before:\n'
        gd += f'\t\t\t\ts[\"ti_gu_draw_turns\"] = 3 if upgraded else 2\n'
        gd += f'\t\t\ts[\"attack_cards_played_this_turn\"] += 1\n'
    elif cid == '15':
        gd += f'\t\t\tbase = 16 if upgraded else 12\n'
        gd += f'\t\t\tdmg = _calc_player_damage(base)\n'
        gd += f'\t\t\t_deal_damage_to_enemy(dmg)\n'
        gd += f'\t\t\ts[\"delayed_damage\"] = s.get(\"delayed_damage\", 0) + (16 if upgraded else 12)\n'
        gd += f'\t\t\ts[\"attack_cards_played_this_turn\"] += 1\n'
    elif cid == '18':
        gd += f'\t\t\tbase = 30 if upgraded else 20\n'
        gd += f'\t\t\tdmg = _calc_player_damage(base)\n'
        gd += f'\t\t\tif s[\"enemy_hp\"] <= s[\"enemy_hp_max\"] * (0.15 if upgraded else 0.10):\n'
        gd += f'\t\t\t\t_deal_damage_to_enemy(99999)\n'
        gd += f'\t\t\telse:\n'
        gd += f'\t\t\t\t_deal_damage_to_enemy(dmg)\n'
        gd += f'\t\t\ts[\"attack_cards_played_this_turn\"] += 1\n'
    elif cid == '19':
        gd += f'\t\t\tbase = 1\n'
        gd += f'\t\t\thits = 8 if upgraded else 6\n'
        gd += f'\t\t\tfor _i in range(hits):\n'
        gd += f'\t\t\t\tdmg = _calc_player_damage(base)\n'
        gd += f'\t\t\t\t_deal_damage_to_enemy(dmg)\n'
        gd += f'\t\t\t\ts[\"player_ling_li\"] = min(s[\"player_ling_li\"] + 1, s[\"player_ling_li_max\"])\n'
        gd += f'\t\t\ts[\"attack_cards_played_this_turn\"] += 1\n'
    elif cid == '25':
        gd += f'\t\t\tvar hs = s[\"hand\"].size()\n'
        gd += f'\t\t\tfor card_ in s[\"hand\"]:\n'
        gd += f'\t\t\t\ts[\"discard_pile\"].append(card_)\n'
        gd += f'\t\t\ts[\"hand\"].clear()\n'
        gd += f'\t\t\t_draw_cards(hs + (2 if upgraded else 1))\n'
    elif cid == '27':
        gd += f'\t\t\tvar found = null\n'
        gd += f'\t\t\tfor i in range(s[\"discard_pile\"].size()-1, -1, -1):\n'
        gd += f'\t\t\t\tif s[\"discard_pile\"][i].get(\"card_type\") == \"attack\":\n'
        gd += f'\t\t\t\t\tfound = s[\"discard_pile\"][i]\n'
        gd += f'\t\t\t\t\ts[\"discard_pile\"].remove_at(i)\n'
        gd += f'\t\t\t\t\tbreak\n'
        gd += f'\t\t\tif found:\n'
        gd += f'\t\t\t\tfound[\"dao_hui\"] = max(0, found.get(\"dao_hui\",0) - (2 if upgraded else 1))\n'
        gd += f'\t\t\t\ts[\"hand\"].append(found)\n'
    elif cid == '29':
        gd += f'\t\t\tvar hs = s[\"hand\"].size()\n'
        gd += f'\t\t\tfor card_ in s[\"hand\"]:\n'
        gd += f'\t\t\t\ts[\"discard_pile\"].append(card_)\n'
        gd += f'\t\t\ts[\"hand\"].clear()\n'
        gd += f'\t\t\t_add_player_hu_ti(hs * (5 if upgraded else 4))\n'
        gd += f'\t\t\t_draw_cards(2)\n'
    elif cid == '32':
        gd += f'\t\t\tvar cost = 3 if upgraded else 4\n'
        gd += f'\t\t\twhile s[\"player_ling_li\"] >= cost:\n'
        gd += f'\t\t\t\ts[\"player_ling_li\"] -= cost\n'
        gd += f'\t\t\t\ts[\"player_dao_xing\"] += 1\n'
    else:
        # Generic parse
        # Dmg
        dmg_m = re.search(r'造成 (\d+)(?:\((\d+)\))? 点伤害', effect)
        if dmg_m:
            b, u = dmg_m.group(1), dmg_m.group(2) or dmg_m.group(1)
            gd += f'\t\t\tbase = {u} if upgraded else {b}\n'
            gd += f'\t\t\tdmg = _calc_player_damage(base)\n'
            gd += f'\t\t\t_deal_damage_to_enemy(dmg)\n'
            if c['type'] == '术法':
                gd += f'\t\t\ts[\"attack_cards_played_this_turn\"] += 1\n'
        
        # Shield
        sh_m = re.search(r'获得 (\d+)(?:\((\d+)\))? 点护体', effect)
        if sh_m:
            b, u = sh_m.group(1), sh_m.group(2) or sh_m.group(1)
            gd += f'\t\t\tshield = {u} if upgraded else {b}\n'
            gd += f'\t\t\t_add_player_hu_ti(shield)\n'
        if '获得等量护体' in effect:
            gd += f'\t\t\t_add_player_hu_ti(dmg)\n'
            
        # Draw
        dr_m = re.search(r'抽取 (\d+)(?:\((\d+)\))? 张牌', effect)
        if dr_m:
            b, u = dr_m.group(1), dr_m.group(2) or dr_m.group(1)
            gd += f'\t\t\t_draw_cards({u} if upgraded else {b})\n'
            
        # Lingli
        li_m = re.search(r'(?:，|获得) (\d+)(?:\((\d+)\))? 点灵力', effect)
        if li_m and '每多 2 点灵力' not in effect and '灵力回复' not in effect:
            b, u = li_m.group(1), li_m.group(2) or li_m.group(1)
            gd += f'\t\t\tbonus_ling = {u} if upgraded else {b}\n'
            gd += f'\t\t\ts[\"player_ling_li\"] = min(s[\"player_ling_li\"] + bonus_ling, s[\"player_ling_li_max\"])\n'
            
        # Daoxing
        dao_m = re.search(r'获得 (\d+)(?:\((\d+)\))? 层【道行】', effect)
        if dao_m and '每回合开始时' not in effect and '下回合获得' not in effect:
            b, u = dao_m.group(1), dao_m.group(2) or dao_m.group(1)
            gd += f'\t\t\ts[\"player_dao_xing\"] += {u} if upgraded else {b}\n'
        if '下回合获得 1(2) 层【道行】' in effect:
            gd += f'\t\t\ts[\"next_turn_dao_xing\"] = s.get(\"next_turn_dao_xing\", 0) + (2 if upgraded else 1)\n'
            
        # Statuses
        if '【裂伤】' in effect:
            ls_m = re.search(r'附加 (\d+)(?:\((\d+)\))? 层【裂伤】', effect)
            if ls_m:
                b, u = ls_m.group(1), ls_m.group(2) or ls_m.group(1)
                gd += f'\t\t\ts[\"enemy_statuses\"][\"lie_shang\"] = s[\"enemy_statuses\"].get(\"lie_shang\", 0) + ({u} if upgraded else {b})\n'
        if '【枯竭】' in effect:
            kj_m = re.search(r'施加 (\d+)(?:\((\d+)\))? 层【枯竭】', effect)
            if kj_m:
                b, u = kj_m.group(1), kj_m.group(2) or kj_m.group(1)
                gd += f'\t\t\ts[\"enemy_statuses\"][\"ku_jie\"] = s[\"enemy_statuses\"].get(\"ku_jie\", 0) + ({u} if upgraded else {b})\n'
        if '【心流】' in effect:
            xl_m = re.search(r'获得 (\d+)(?:\((\d+)\))? 层【心流】', effect)
            if xl_m:
                b, u = xl_m.group(1), xl_m.group(2) or xl_m.group(1)
                gd += f'\t\t\ts[\"player_statuses\"][\"xin_liu\"] = s[\"player_statuses\"].get(\"xin_liu\", 0) + ({u} if upgraded else {b})\n'
        if '【不侵】' in effect:
            gd += f'\t\t\ts[\"player_statuses\"][\"bu_qin\"] = s[\"player_statuses\"].get(\"bu_qin\", 0) + 2\n'
            
        # Specials
        if '本局永久提升每回合灵力回复 2(3) 点' in effect:
            gd += f'\t\t\ts[\"player_ling_li_regen\"] += (3 if upgraded else 2)\n'
        if '下回合额外多抽 1 张牌' in effect:
            gd += f'\t\t\ts[\"extra_draw_next_turn\"] += 1\n'
            
        # Powers
        if c['type'] == '道法':
            gd += f'\t\t\tif not s.has(\"powers_active\"):\n'
            gd += f'\t\t\t\ts[\"powers_active\"] = []\n'
            gd += f'\t\t\ts[\"powers_active\"].append({{\"id\": \"{cid}\", \"upgraded\": upgraded}})\n'
            
    cases.append(gd)
    
cases.append('\t\t_:\n\t\t\tpush_warning(\"BattleEngine: 未实现效果的卡牌 id = \" + id)\n')

with open('CardLogicGen.txt', 'w', encoding='utf-8') as f:
    f.writelines(cases)
