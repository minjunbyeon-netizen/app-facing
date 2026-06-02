import json, os

src = os.path.join(os.path.dirname(__file__), '..', 'data', 'rehab.json')
out_dir = os.path.join(os.path.dirname(__file__), '..', 'data', 'movements')
os.makedirs(out_dir, exist_ok=True)

with open(src, encoding='utf-8') as f:
    data = json.load(f)

manifest = []

for m in data['movements']:
    # 종목별 파일 저장
    path = os.path.join(out_dir, f"{m['id']}.json")
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(m, f, ensure_ascii=False, indent=2)
    print(f"  wrote {path}")

    # manifest에는 질문 있는 pain_site만
    sites = [
        {'id': ps['id'], 'name': ps['name']}
        for ps in m.get('pain_sites', [])
        if ps.get('questions') and len(ps['questions']) > 0
    ]
    manifest.append({'id': m['id'], 'name': m['name'], 'pain_sites': sites})

mpath = os.path.join(out_dir, 'manifest.json')
with open(mpath, 'w', encoding='utf-8') as f:
    json.dump(manifest, f, ensure_ascii=False, indent=2)
print(f"  wrote {mpath}")
print("완료")
