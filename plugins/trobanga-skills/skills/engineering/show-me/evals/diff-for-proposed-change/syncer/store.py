import sqlite3


class Store:
    def __init__(self, path):
        self.db = sqlite3.connect(path)

    def cursor(self):
        row = self.db.execute("SELECT value FROM meta WHERE key='cursor'").fetchone()
        return row[0] if row else None

    def set_cursor(self, value):
        self.db.execute("REPLACE INTO meta VALUES ('cursor', ?)", (value,))

    def upsert(self, items):
        self.db.executemany("REPLACE INTO items VALUES (?, ?)", [(i["id"], i["name"]) for i in items])

    def last_synced(self):
        return self.db.execute("SELECT max(updated) FROM items").fetchone()[0]
