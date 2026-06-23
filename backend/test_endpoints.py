import urllib.request
import json

BASE = "http://127.0.0.1:8000/api"

def get(path):
    try:
        req = urllib.request.Request(BASE + path)
        resp = urllib.request.urlopen(req, timeout=5)
        data = json.loads(resp.read())
        if isinstance(data, list):
            return "OK [%d items]" % len(data)
        elif isinstance(data, dict):
            if "results" in data:
                return "OK [%d items, page]" % len(data["results"])
            keys = list(data.keys())[:6]
            return "OK keys=%s" % keys
        return "OK %s" % type(data).__name__
    except Exception as e:
        return "ERROR %s" % e

endpoints = [
    "/auth/login/",
    "/auth/token/refresh/",
    "/auth/me/",
    "/auth/users/",
    "/tasks/",
    "/tasks/categories/",
    "/tasks/skills/",
    "/tasks/my/",
    "/tasks/bids/my/",
    "/wallet/",
    "/wallet/transactions/",
    "/messaging/conversations/",
    "/companies/",
]

for ep in endpoints:
    print("%-40s => %s" % (ep, get(ep)))
