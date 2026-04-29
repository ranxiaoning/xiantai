import json
with open('scripts/data/all_card.json', encoding='utf-8') as f:
    data = json.load(f)
lookup = {str(c['id']): c for c in data['cards']}
for cid in ['1', '2', '8', '20', '21']:
    c = lookup[cid]
    print(cid, c['name'], 'cost_ling:', c['cost_ling'], 'cost_dao:', c['cost_dao'])
