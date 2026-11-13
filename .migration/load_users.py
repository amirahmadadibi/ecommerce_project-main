#!/usr/bin/env python3
"""Load legacy PocketBase users and comments into Supabase shop schema."""
import json
import urllib.request
import urllib.error

BASE = "https://api.expertflutter.pro"
ANON = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNzkyNjExMDE2LCJleHAiOjE5NTAyOTEwMTZ9.FBp_VS-DHv4do8PkYX4I7yf7I8kaQ4lgNeX25Z80ZUg"

def load(name):
    d = json.load(open(f'data/{name}.json'))
    return d['items'] if isinstance(d, dict) else d

def post(table, rows):
    url = f"{BASE}/rest/v1/{table}"
    body = json.dumps(rows).encode()
    req = urllib.request.Request(url, data=body, method='POST', headers={
        'apikey': ANON,
        'Authorization': f'Bearer {ANON}',
        'Content-Type': 'application/json',
        'Prefer': 'resolution=ignore-duplicates',
    })
    try:
        with urllib.request.urlopen(req, timeout=120) as r:
            return r.status
    except urllib.error.HTTPError as e:
        print(f"ERROR {table}: {e.code} {e.read().decode()[:300]}")
        raise

def ts(s):
    if not s: return None
    return s.replace(' ', 'T').replace('Z', '') + '+00:00'

# --- users (batch 500) ---
users = load('users')
rows = [{
    'id': u['id'],
    'username': u.get('username'),
    'name': u.get('name') or '',
    'avatar': u.get('avatar') or None,
    'created_at': ts(u.get('created')),
    'updated_at': ts(u.get('updated')),
} for u in users]
for i in range(0, len(rows), 500):
    post('users', rows[i:i+500])
    print(f'users batch {i//500 + 1} ok ({len(rows[i:i+500])})')

# --- comments (batch 300) ---
comments = load('comment')
rows = [{
    'id': c['id'],
    'text': c['text'],
    'user_id': c['user_id'],
    'product_id': c.get('product_id'),
    'created_at': ts(c.get('created')),
    'updated_at': ts(c.get('updated')),
} for c in comments]
for i in range(0, len(rows), 300):
    post('comment', rows[i:i+300])
    print(f'comment batch {i//300 + 1} ok ({len(rows[i:i+300])})')

print('USERS + COMMENTS LOADED')
