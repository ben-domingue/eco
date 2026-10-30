#!/usr/bin/env python3
"""Inspect file listings for a handful of candidate datasets (metadata only; at
most one small CSV head per dataset to judge structure)."""
import json, sys, urllib.parse, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from eco_discover import http, UA
import urllib.request

def dryad(doi):
    enc = urllib.parse.quote(doi, safe="")
    d = http(f"https://datadryad.org/api/v2/datasets/{enc}")
    if "_error" in d: return {"doi": doi, "error": d["_error"]}
    ver = d.get("_links", {}).get("stash:version", {}).get("href", "")
    files = http(f"https://datadryad.org{ver}/files", {"per_page": 50}) if ver else {}
    fl = [(f.get("path"), f.get("size"), f.get("mimeType"), f.get("_links", {}).get("stash:download", {}).get("href"))
          for f in files.get("_embedded", {}).get("stash:files", [])]
    return {"doi": doi, "title": d.get("title"), "license": d.get("license"), "abstract": (d.get("abstract") or "")[:400],
            "methods": (d.get("methods") or "")[:400], "files": fl}

def head_csv(download_href, n=6, max_bytes=2_000_000):
    url = "https://datadryad.org" + download_href
    req = urllib.request.Request(url, headers=UA)
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            raw = r.read(max_bytes).decode("utf-8", "replace")
        lines = raw.splitlines()
        return lines[:n], len(lines)
    except Exception as e:
        return [f"ERR {e}"], 0

if __name__ == "__main__":
    dois = sys.argv[1:]
    for doi in dois:
        info = dryad(doi)
        print("=" * 100); print(json.dumps({k: v for k, v in info.items() if k != "files"}, indent=1)[:1200])
        for p, s, m, h in info.get("files", []):
            print(f"  FILE {p} {s} {m}")
        small = [(p, s, m, h) for p, s, m, h in info.get("files", []) if p and h and p.lower().endswith((".csv", ".txt")) and "readme" not in p.lower() and (s or 0) < 2_000_000]
        if small:
            p, s, m, h = small[0]
            lines, n = head_csv(h)
            print(f"  --- head of {p} ({n} lines read):")
            for l in lines: print("   ", l[:220])
