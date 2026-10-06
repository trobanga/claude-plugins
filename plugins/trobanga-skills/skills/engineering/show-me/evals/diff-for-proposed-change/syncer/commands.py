from config import load_config
from store import Store
from sync import Syncer


def run_sync():
    cfg = load_config()
    Syncer(cfg, Store(cfg.db_path)).sync()


def run_status():
    cfg = load_config()
    print(Store(cfg.db_path).last_synced())
