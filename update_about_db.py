#!/usr/bin/env python3
import psycopg2

conn = psycopg2.connect(host='127.0.0.1', port=5432, dbname='new_api', user='postgres', password='postgres')
cur = conn.cursor()

with open('/tmp/about_v4.html', 'r') as f:
    content = f.read()

cur.execute("UPDATE options SET value=%s WHERE key='About'", (content,))
conn.commit()

cur.execute("SELECT length(value) FROM options WHERE key='About'")
row = cur.fetchone()
print('DB value length:', row[0])

# Verify key markers
cur.execute("SELECT value FROM options WHERE key='About'")
val = cur.fetchone()[0]
print('Has onerror:', 'onerror' in val)
print('Has /logo.png:', '/logo.png' in val)
print('Has ea-lang-:', 'ea-lang-' in val)

conn.close()
