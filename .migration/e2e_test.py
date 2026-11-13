#!/usr/bin/env python3
"""End-to-end test: simulate every app API call against the new Supabase backend
and compare against PocketBase source data."""
import json
import urllib.request
import urllib.error

BASE = "https://api.expertflutter.pro"
ANON = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNzkyNjExMDE2LCJleHAiOjE5NTAyOTEwMTZ9.FBp_VS-DHv4do8PkYX4I7yf7I8kaQ4lgNeX25Z80ZUg"
PUB = f"{BASE}/storage/v1/object/public/shop-images/"

def get(path, token=None):
    headers = {'apikey': ANON}
    if token:
        headers['Authorization'] = f'Bearer {token}'
    req = urllib.request.Request(f"{BASE}{path}", headers=headers)
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.load(r)

def load(name):
    d = json.load(open(f'data/{name}.json'))
    return d['items'] if isinstance(d, dict) else d

passed, failed = 0, 0
def check(name, cond, detail=''):
    global passed, failed
    if cond:
        passed += 1
        print(f"  PASS {name}")
    else:
        failed += 1
        print(f"  FAIL {name} {detail}")

print("== 1. Categories ==")
sb_cats = get('rest/v1/category?select=*')
pb_cats = load('category')
check('category count', len(sb_cats) == len(pb_cats), f"{len(sb_cats)} vs {len(pb_cats)}")
pb_cat = next(c for c in pb_cats if c['id'] == sb_cats[0]['id'])
sb_cat = sb_cats[0]
check('category fields', sb_cat['title'] == pb_cat['title'] and sb_cat['color'] == pb_cat['color'])
check('category icon URL', sb_cat['icon'] == f"{PUB}category_{pb_cat['id']}_icon_{pb_cat['icon']}")
check('category thumbnail URL', sb_cat['thumbnail'] == f"{PUB}category_{pb_cat['id']}_thumbnail_{pb_cat['thumbnail']}")

print("== 2. Banners ==")
sb_banners = get('rest/v1/banner?select=*')
pb_banners = load('banner')
check('banner count', len(sb_banners) == len(pb_banners))
check('banner category link', all(any(b['category_id'] == pb.get('categoryId') for pb in pb_banners if pb['id'] == b['id']) for b in sb_banners))

print("== 3. Products ==")
sb_products = get('rest/v1/products?select=*')
pb_products = load('products')
check('product count', len(sb_products) == len(pb_products))
pb_p = next(p for p in pb_products if p['id'] == sb_products[0]['id'])
sb_p = sb_products[0]
check('product name', sb_p['name'] == pb_p['name'])
check('product price', sb_p['price'] == pb_p['price'] and sb_p['discount_price'] == pb_p['discount_price'])
check('product category', sb_p['category'] == pb_p['category'])

print("== 4. Hotest filter (app: popularity=eq.Hotest) ==")
hot = get('rest/v1/products?select=*&popularity=eq.Hotest')
pb_hot = [p for p in pb_products if p['popularity'] == 'Hotest']
check('hotest count', len(hot) == len(pb_hot), f"{len(hot)} vs {len(pb_hot)}")

print("== 5. Best Seller filter ==")
bs = get('rest/v1/products?select=*&popularity=eq.Best Seller')
pb_bs = [p for p in pb_products if p['popularity'] == 'Best Seller']
check('best seller count', len(bs) == len(pb_bs))

print("== 6. Products by category (all-category special id) ==")
allp = get('rest/v1/products?select=*')
check('all-category returns all', len(allp) == len(pb_products))
cat_filter = get(f"rest/v1/products?select=*&category=eq.{pb_products[0]['category']}")
pb_cf = [p for p in pb_products if p['category'] == pb_products[0]['category']]
check('category filter count', len(cat_filter) == len(pb_cf))

print("== 7. Gallery ==")
sb_gallery = get('rest/v1/gallery?select=*')
pb_gallery = load('gallery')
check('gallery count', len(sb_gallery) == len(pb_gallery))
prod_id = pb_gallery[0]['product_id']
g = get(f"rest/v1/gallery?select=*&product_id=eq.{prod_id}")
pb_g = [x for x in pb_gallery if x['product_id'] == prod_id]
check('gallery filter by product', len(g) == len(pb_g))

print("== 8. Variant types ==")
sb_vt = get('rest/v1/variants_type?select=*')
pb_vt = load('variants_type')
check('variant types count', len(sb_vt) == len(pb_vt))
check('variant type fields', sb_vt[0]['type'] == pb_vt[0]['type'] and sb_vt[0]['title'] == pb_vt[0]['title'])

print("== 9. Variants ==")
sb_v = get('rest/v1/variants?select=*')
pb_v = load('variants')
check('variants count', len(sb_v) == len(pb_v))
check('variant fields', sb_v[0]['price_change'] == pb_v[0]['price_change'] and sb_v[0]['value'] == pb_v[0]['value'])

print("== 10. Properties ==")
sb_pr = get('rest/v1/properties?select=*')
pb_pr = load('properties')
check('properties count', len(sb_pr) == len(pb_pr))

print("== 11. Comments with embedded user (app expand replacement) ==")
comments = get('rest/v1/comment?select=id,text,user_id,product_id,user:users(id,username,name,avatar)&product_id=eq.'
               + json.load(open('data/properties.json'))['items'][0]['product_id'] + '&order=created_at.desc&limit=100')
pb_comments = load('comment')
target = [c for c in pb_comments if c['product_id'] == json.load(open('data/properties.json'))['items'][0]['product_id']]
check('comment embed returns items', len(comments) == len(target), f"{len(comments)} vs {len(target)}")
check('comment has user object', comments and isinstance(comments[0].get('user'), dict))
pb_users = load('users')
u = next(us for us in pb_users if us['id'] == comments[0]['user_id'])
check('comment user name matches', (comments[0]['user'].get('name') or comments[0]['user'].get('username')) in (u['name'], u['username']))

print("== 12. Signup + auto sync (new user path) ==")
import urllib.request as ur
body = json.dumps({
    'email': f'e2e_test_{__import__("time").int(time.time() if False else 0)}@appleshop.local'.replace('time.time() if False else 0', '1'),
    'password': 'e2etest12345',
    'data': {'username': 'e2e_test_1', 'name': 'e2e_test_1'}
}).encode()
req = ur.Request(f"{BASE}/auth/v1/signup", data=body, method='POST', headers={
    'apikey': ANON, 'Content-Type': 'application/json'})
with ur.urlopen(req, timeout=30) as r:
    signup = json.load(r)
check('signup returns session', 'access_token' in signup and 'user' in signup)
new_uid = signup['user']['id']
new_token = signup['access_token']
sb_u = get(f"rest/v1/users?id=eq.{new_uid}&select=*")
check('trigger created shop.users row', len(sb_u) == 1 and sb_u[0]['id'] == new_uid)

print("== 13. Authenticated comment post (RLS) ==")
req = ur.Request(
    f"{BASE}/rest/v1/comment",
    data=json.dumps({'text': 'e2e test comment', 'user_id': new_uid, 'product_id': pb_products[0]['id']}).encode(),
    method='POST',
    headers={'apikey': ANON, 'Authorization': f'Bearer {new_token}', 'Content-Type': 'application/json',
             'Prefer': 'return=representation'})
with ur.urlopen(req, timeout=30) as r:
    status = r.status
check('comment insert 201', status == 201)

print("== 14. Image serving ==")
img_url = sb_cat['thumbnail']
req = ur.Request(img_url, method='HEAD')
with ur.urlopen(req, timeout=30) as r:
    check('image HEAD 200', r.status == 200 and 'image' in r.headers.get('Content-Type', ''))

print("== 15. Anon cannot write (RLS lock) ==")
try:
    req = ur.Request(
        f"{BASE}/rest/v1/comment",
        data=json.dumps({'text': 'hack', 'user_id': new_uid, 'product_id': pb_products[0]['id']}).encode(),
        method='POST',
        headers={'apikey': ANON, 'Content-Type': 'application/json'})
    ur.urlopen(req, timeout=30)
    check('anon comment blocked', False, 'should have failed')
except urllib.error.HTTPError as e:
    check('anon comment blocked', e.code in (401, 403), f"got {e.code}")

print(f"\n{'='*40}\nRESULT: {passed} passed, {failed} failed")
exit(1 if failed else 0)
