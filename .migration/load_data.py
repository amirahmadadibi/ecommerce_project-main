#!/usr/bin/env python3
"""One-time migration: load PocketBase data into Supabase shop schema via PostgREST."""
import json
import urllib.request
import urllib.error

BASE = "https://api.expertflutter.pro"
ANON = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNzkyNjExMDE2LCJleHAiOjE5NTAyOTEwMTZ9.FBp_VS-DHv4do8PkYX4I7yf7I8kaQ4lgNeX25Z80ZUg"
PUB = f"{BASE}/storage/v1/object/public/shop-images/"

def load(name):
    d = json.load(open(f'data/{name}.json'))
    return d['items'] if isinstance(d, dict) else d

def post(table, rows):
    """Insert rows into schema-qualified table via PostgREST."""
    url = f"{BASE}/rest/v1/{table}"
    body = json.dumps(rows).encode()
    req = urllib.request.Request(url, data=body, method='POST', headers={
        'apikey': ANON,
        'Authorization': f'Bearer {ANON}',
        'Content-Type': 'application/json',
        'Prefer': 'resolution=ignore-duplicates',
    })
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            return r.status
    except urllib.error.HTTPError as e:
        print(f"ERROR {table}: {e.code} {e.read().decode()[:500]}")
        raise

def ts(s):
    if not s: return None
    return s.replace(' ', 'T').replace('Z', '') + '+00:00' if 'T' not in s else s.replace('Z', '') + '+00:00'

def ts2(s):
    if not s: return None
    return s.replace(' ', 'T').replace('Z', '') + ':00' if False else s.replace(' ', 'T').replace('Z', '') + '+00:00'

# --- category ---
rows = []
for c in load('category'):
    rows.append({
        'id': c['id'], 'title': c['title'], 'color': c.get('color'),
        'icon': f"{PUB}category_{c['id']}_icon_{c['icon']}" if c.get('icon') else None,
        'thumbnail': f"{PUB}category_{c['id']}_thumbnail_{c['thumbnail']}" if c.get('thumbnail') else None,
        'created_at': ts2(c.get('created')), 'updated_at': ts2(c.get('updated')),
    })
post('category', rows); print('category ok', len(rows))

# --- banner ---
rows = []
for b in load('banner'):
    rows.append({
        'id': b['id'],
        'thumbnail': f"{PUB}banner_{b['id']}_{b['thumbnail']}" if b.get('thumbnail') else None,
        'category_id': b.get('categoryId'),
        'created_at': ts2(b.get('created')), 'updated_at': ts2(b.get('updated')),
    })
post('banner', rows); print('banner ok', len(rows))

# --- products ---
rows = []
for p in load('products'):
    rows.append({
        'id': p['id'], 'name': p['name'],
        'thumbnail': f"{PUB}product_{p['id']}_{p['thumbnail']}" if p.get('thumbnail') else None,
        'description': p.get('description'),
        'price': p['price'], 'discount_price': p['discount_price'],
        'popularity': p.get('popularity'), 'quantity': p['quantity'],
        'category': p.get('category'),
        'created_at': ts2(p.get('created')), 'updated_at': ts2(p.get('updated')),
    })
post('products', rows); print('products ok', len(rows))

# --- gallery ---
rows = []
for g in load('gallery'):
    rows.append({
        'id': g['id'],
        'image': f"{PUB}gallery_{g['id']}_{g['image']}" if g.get('image') else None,
        'product_id': g.get('product_id'),
        'created_at': ts2(g.get('created')), 'updated_at': ts2(g.get('updated')),
    })
post('gallery', rows); print('gallery ok', len(rows))

# --- variants_type ---
rows = []
for vt in load('variants_type'):
    rows.append({
        'id': vt['id'], 'name': vt.get('name'), 'title': vt.get('title'), 'type': vt.get('type'),
        'created_at': ts2(vt.get('created')), 'updated_at': ts2(vt.get('updated')),
    })
post('variants_type', rows); print('variants_type ok', len(rows))

# --- variants ---
rows = []
for v in load('variants'):
    rows.append({
        'id': v['id'], 'name': v.get('name'), 'type_id': v.get('type_id'),
        'value': v.get('value'), 'price_change': v['price_change'],
        'product_id': v.get('product_id'),
        'created_at': ts2(v.get('created')), 'updated_at': ts2(v.get('updated')),
    })
post('variants', rows); print('variants ok', len(rows))

# --- properties ---
rows = []
for pr in load('properties'):
    rows.append({
        'id': pr['id'], 'title': pr.get('title'), 'value': pr.get('value'),
        'product_id': pr.get('product_id'),
        'created_at': ts2(pr.get('created')), 'updated_at': ts2(pr.get('updated')),
    })
post('properties', rows); print('properties ok', len(rows))

print('ALL CATALOG DATA LOADED')
