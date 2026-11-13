#!/bin/bash
# End-to-end test: simulate every app API call against the new Supabase backend
BASE="https://api.expertflutter.pro"
ANON="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNzkyNjExMDE2LCJleHAiOjE5NTAyOTEwMTZ9.FBp_VS-DHv4do8PkYX4I7yf7I8kaQ4lgNeX25Z80ZUg"
PASS=0; FAIL=0
T=$(mktemp -d)
cd "$(dirname "$0")"

check() { if [ "$2" = "1" ]; then PASS=$((PASS+1)); echo "  PASS $1"; else FAIL=$((FAIL+1)); echo "  FAIL $1 ${3:-}"; fi; }
get() { curl -s -m 30 "$BASE/$1" -H "apikey: $ANON" -o "$T/resp.json"; cat "$T/resp.json"; }

echo "== 1. Categories =="
get 'rest/v1/category?select=*' > /dev/null
python3 /dev/stdin "$T/resp.json" <<'PYEOF' > "$T/r1"
import json, sys
sb = json.load(open(sys.argv[1]))
pb = json.load(open('data/category.json'))['items']
pbm = {c['id']: c for c in pb}
ok = len(sb) == len(pb)
for c in sb:
    p = pbm.get(c['id'])
    if not p: ok = False; break
    if c['title'] != p['title'] or c['color'] != p['color']: ok = False; break
    if not c['icon'].endswith(f"category_{p['id']}_icon_{p['icon']}"): ok = False; break
    if not c['thumbnail'].endswith(f"category_{p['id']}_thumbnail_{p['thumbnail']}"): ok = False; break
print(1 if ok else 0)
PYEOF
check "category count + fields + image URLs (8)" "$(cat "$T/r1")"

echo "== 2. Banners =="
get 'rest/v1/banner?select=*' > /dev/null
python3 -c "import json,sys; print(1 if len(json.load(open('$T/resp.json')))==4 else 0)" > "$T/r2"
check "banner count = 4" "$(cat "$T/r2")"

echo "== 3. Products =="
get 'rest/v1/products?select=*' > /dev/null
python3 /dev/stdin "$T/resp.json" <<'PYEOF' > "$T/r3"
import json, sys
sb = json.load(open(sys.argv[1]))
pb = {p['id']: p for p in json.load(open('data/products.json'))['items']}
ok = len(sb) == len(pb)
for p in sb:
    q = pb.get(p['id'])
    if not q: ok = False; break
    if p['name'] != q['name'] or p['price'] != q['price'] or p['discount_price'] != q['discount_price']: ok = False; break
    if p['category'] != q['category'] or p['quantity'] != q['quantity'] or p['popularity'] != q['popularity']: ok = False; break
    if not p['thumbnail'].endswith(f"product_{q['id']}_{q['thumbnail']}"): ok = False; break
print(1 if ok else 0)
PYEOF
check "product fields + thumbnails match (7)" "$(cat "$T/r3")"

echo "== 4+5. Popularity filters =="
get 'rest/v1/products?select=*&popularity=eq.Hotest' > /dev/null
python3 -c "
import json
sb = json.load(open('$T/resp.json'))
pb = [p for p in json.load(open('data/products.json'))['items'] if p['popularity']=='Hotest']
print(1 if {p['id'] for p in sb}=={p['id'] for p in pb} else 0)" > "$T/r4"
check "hotest filter" "$(cat "$T/r4")"
get 'rest/v1/products?select=*&popularity=eq.Best%20Seller' > /dev/null
python3 -c "
import json
sb = json.load(open('$T/resp.json'))
pb = [p for p in json.load(open('data/products.json'))['items'] if p['popularity']=='Best Seller']
print(1 if {p['id'] for p in sb}=={p['id'] for p in pb} else 0)" > "$T/r5"
check "best seller filter" "$(cat "$T/r5")"

echo "== 6. Category filter (all + specific) =="
get 'rest/v1/products?select=*' > /dev/null
python3 -c "import json; print(1 if len(json.load(open('$T/resp.json')))==7 else 0)" > "$T/r6a"
check "all-category returns all products" "$(cat "$T/r6a")"
CATID=$(python3 -c "import json; print(json.load(open('data/products.json'))['items'][0]['category'])")
get "rest/v1/products?select=*&category=eq.$CATID" > /dev/null
python3 -c "
import json
sb = json.load(open('$T/resp.json'))
pb = [p for p in json.load(open('data/products.json'))['items'] if p['category']=='$CATID']
print(1 if {p['id'] for p in sb}=={p['id'] for p in pb} else 0)" > "$T/r6b"
check "specific category filter ($CATID)" "$(cat "$T/r6b")"

echo "== 7. Gallery =="
get 'rest/v1/gallery?select=*' > /dev/null
python3 /dev/stdin "$T/resp.json" <<'PYEOF' > "$T/r7"
import json, sys
sb = json.load(open(sys.argv[1]))
pb = {g['id']: g for g in json.load(open('data/gallery.json'))['items']}
ok = len(sb) == len(pb)
for g in sb:
    q = pb.get(g['id'])
    if not q or g['product_id'] != q['product_id']: ok = False; break
    if not g['image'].endswith(f"gallery_{q['id']}_{q['image']}"): ok = False; break
print(1 if ok else 0)
PYEOF
check "gallery count + image URLs (10)" "$(cat "$T/r7")"

echo "== 8. Variant types =="
get 'rest/v1/variants_type?select=*' > /dev/null
python3 /dev/stdin "$T/resp.json" <<'PYEOF' > "$T/r8"
import json, sys
sb = json.load(open(sys.argv[1]))
pb = {v['id']: v for v in json.load(open('data/variants_type.json'))['items']}
ok = len(sb) == len(pb) and all(v['type'] == pb[v['id']]['type'] and v['title'] == pb[v['id']]['title'] and v['name'] == pb[v['id']]['name'] for v in sb)
print(1 if ok else 0)
PYEOF
check "variant types match (3)" "$(cat "$T/r8")"

echo "== 9. Variants =="
get 'rest/v1/variants?select=*' > /dev/null
python3 /dev/stdin "$T/resp.json" <<'PYEOF' > "$T/r9"
import json, sys
sb = json.load(open(sys.argv[1]))
pb = {v['id']: v for v in json.load(open('data/variants.json'))['items']}
ok = len(sb) == len(pb) and all(
    v['price_change'] == pb[v['id']]['price_change'] and
    v['value'] == pb[v['id']]['value'] and
    v['type_id'] == pb[v['id']]['type_id'] and
    v['product_id'] == pb[v['id']]['product_id'] for v in sb)
print(1 if ok else 0)
PYEOF
check "variants match (9)" "$(cat "$T/r9")"

echo "== 10. Properties =="
get 'rest/v1/properties?select=*' > /dev/null
python3 -c "import json; d=json.load(open('$T/resp.json')); print(1 if len(d)==1 and d[0]['title']=='حافظه داخلی' else 0)" > "$T/r10"
check "properties (1)" "$(cat "$T/r10")"

echo "== 11. Comments + embedded user =="
PID2=$(python3 -c "import json; print(json.load(open('data/properties.json'))['items'][0]['product_id'])")
get "rest/v1/comment?select=id,text,user_id,product_id,user:users(id,username,name,avatar)&product_id=eq.$PID2&order=created_at.desc&limit=100" > /dev/null
python3 /dev/stdin "$T/resp.json" "$PID2" <<'PYEOF' > "$T/r11"
import json, sys
sb = json.load(open(sys.argv[1]))
pid = sys.argv[2]
pb = [c for c in json.load(open('data/comment.json')) if c['product_id'] == pid]
pbu = {u['id']: u for u in json.load(open('data/users.json'))}
ok = len(sb) == len(pb)
for c in sb:
    u = pbu.get(c['user_id'])
    if not u or not isinstance(c.get('user'), dict): ok = False; break
    if c['text'] != next(p['text'] for p in pb if p['id'] == c['id']): ok = False; break
print(1 if ok else 0)
PYEOF
check "comments + embed match product $PID2" "$(cat "$T/r11")"

echo "== 12. Signup + trigger sync =="
curl -s -m 30 -X POST "$BASE/auth/v1/signup" -H "apikey: $ANON" -H "Content-Type: application/json" \
  -d '{"email":"e2e_gdhqyv@appleshop.local","password":"e2etest12345","data":{"username":"e2e_gdhqyv","name":"e2e_gdhqyv"}}' -o "$T/signup.json"
TOKEN=$(python3 -c "import json; print(json.load(open('$T/signup.json')).get('access_token',''))" 2>/dev/null)
USERID=$(python3 -c "import json; print(json.load(open('$T/signup.json')).get('user',{}).get('id',''))" 2>/dev/null)
check "signup returns session" "$([ -n "$TOKEN" ] && [ -n "$USERID" ] && echo 1 || echo 0)"
get "rest/v1/users?id=eq.$USERID&select=*" > /dev/null
python3 -c "
import json
d = json.load(open('$T/resp.json'))
print(1 if len(d)==1 and d[0]['id']=='$USERID' and (d[0].get('username') or '')!='' else 0)" > "$T/r12"
check "trigger created shop.users row with username" "$(cat "$T/r12")"

echo "== 13. Authenticated comment post (RLS) =="
PRODID=$(python3 -c "import json; print(json.load(open('data/products.json'))['items'][0]['id'])")
CODE=$(curl -s -m 30 -o /dev/null -w "%{http_code}" -X POST "$BASE/rest/v1/comment" \
  -H "apikey: $ANON" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
  -d "{\"text\":\"e2e final test comment\",\"user_id\":\"$USERID\",\"product_id\":\"$PRODID\"}")
check "authed comment insert 201" "$([ "$CODE" = "201" ] && echo 1 || echo 0)" "got $CODE"

echo "== 14. Image serving =="
get 'rest/v1/category?select=thumbnail&limit=1' > /dev/null
IMGURL=$(python3 -c "import json; print(json.load(open('$T/resp.json'))[0]['thumbnail'])")
CODE=$(curl -s -m 20 -o /dev/null -w "%{http_code}" "$IMGURL")
check "image served 200" "$([ "$CODE" = "200" ] && echo 1 || echo 0)" "got $CODE"

echo "== 15. Anon cannot write (RLS lock) =="
CODE=$(curl -s -m 20 -o /dev/null -w "%{http_code}" -X POST "$BASE/rest/v1/comment" \
  -H "apikey: $ANON" -H "Content-Type: application/json" \
  -d "{\"text\":\"hack\",\"user_id\":\"$USERID\",\"product_id\":\"$PRODID\"}")
check "anon comment blocked (401/403)" "$([ "$CODE" = "401" ] || [ "$CODE" = "403" ] && echo 1 || echo 0)" "got $CODE"

echo "== 16. Login =="
CODE=$(curl -s -m 20 -o /dev/null -w "%{http_code}" -X POST "$BASE/auth/v1/token?grant_type=password" \
  -H "apikey: $ANON" -H "Content-Type: application/json" \
  -d '{"email":"e2e_gdhqyv@appleshop.local","password":"e2etest12345"}')
check "login 200" "$([ "$CODE" = "200" ] && echo 1 || echo 0)" "got $CODE"

echo
echo "======================================"
echo "RESULT: $PASS passed, $FAIL failed"
rm -rf "$T"
exit $([ "$FAIL" = "0" ] && echo 0 || echo 1)
