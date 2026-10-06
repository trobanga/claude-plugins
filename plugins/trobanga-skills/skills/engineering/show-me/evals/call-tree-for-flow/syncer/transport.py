import json
import urllib.request


def fetch_page(base_url, token, cursor=None):
    url = f"{base_url}/items" + (f"?cursor={cursor}" if cursor else "")
    req = urllib.request.Request(url, headers={"Authorization": f"Bearer {token}"})
    with urllib.request.urlopen(req, timeout=10) as resp:
        return json.load(resp)
