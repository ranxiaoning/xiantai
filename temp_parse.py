import json

with open('scripts/data/all_card.json', encoding='utf-8') as f:
    data = json.load(f)

for c in data['cards']:
    print(f"{c['id']}: {c['name']} - {c['effect']}")
