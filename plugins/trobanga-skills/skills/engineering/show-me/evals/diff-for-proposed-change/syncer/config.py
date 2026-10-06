import os
from dataclasses import dataclass


@dataclass
class Config:
    base_url: str
    token: str
    db_path: str


def load_config() -> Config:
    return Config(os.environ["SYNCER_URL"], os.environ["SYNCER_TOKEN"], os.environ.get("SYNCER_DB", "syncer.db"))
