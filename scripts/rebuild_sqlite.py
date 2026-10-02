"""Rebuild the four relational tables from CSV using only Python's standard library.
Run from the package root: python scripts/rebuild_sqlite.py
Creates blue_jays_rebuilt.sqlite without overwriting an existing database.
"""
import csv,json,sqlite3
from pathlib import Path
root=Path(__file__).resolve().parents[1]
target=root/'blue_jays_rebuilt.sqlite'
if target.exists(): raise SystemExit('Target exists. Choose a new filename before rebuilding.')
schema=json.loads((root/'metadata/schema.json').read_text())
con=sqlite3.connect(target);con.execute('PRAGMA foreign_keys=ON')
for name,meta in schema.items():
 defs=[]
 for c in meta['columns']:
  suffix=' PRIMARY KEY' if c['name']==meta['primary_key'] else '' if c['nullable'] else ' NOT NULL'
  defs.append('['+c['name']+'] '+c['type']+suffix)
 for field,parent,key in meta['foreign_keys']:
  defs.append(f'FOREIGN KEY ([{field}]) REFERENCES [{parent}]([{key}])')
 con.execute(f'CREATE TABLE [{name}] ('+', '.join(defs)+')')
 with (root/'data'/f'{name}.csv').open(encoding='utf-8',newline='') as f:
  records=list(csv.DictReader(f))
 def convert(v,typ):return None if v=='' else int(v) if typ=='INTEGER' else float(v) if typ=='REAL' else v
 rows=[tuple(convert(r[c['name']],c['type']) for c in meta['columns']) for r in records]
 con.executemany(f'INSERT INTO [{name}] VALUES ('+','.join('?' for _ in meta['columns'])+')',rows)
 assert len(rows)==meta['row_count']
con.executescript((root/'scripts/sqlite_views.sql').read_text())
assert not con.execute('PRAGMA foreign_key_check').fetchall()
assert con.execute('PRAGMA integrity_check').fetchone()[0]=='ok'
con.commit();con.close();print('Rebuilt and validated:',target.name)
