#!/usr/bin/env python3
import json, sys, os, urllib.parse, urllib.request
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from eco_discover import http, UA

def head(url, n=5, max_bytes=300_000):
    req = urllib.request.Request(url, headers=UA)
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            raw = r.read(max_bytes).decode("utf-8", "replace")
        ls = raw.splitlines(); return ls[:n], len(ls)
    except Exception as e: return [f"ERR {e}"], 0

print("########## ZENODO (incl. Dryad mirrors)")
for doi in ["10.5061/dryad.3xsj3txfv", "10.5061/dryad.2jm63xsnp", "10.5281/zenodo.17602", "10.5061/dryad.7m0cfxq1r", "10.5061/dryad.cvdncjt22"]:
    d = http("https://zenodo.org/api/records", {"q": f'doi:"{doi}"', "size": 1})
    hits = d.get("hits", {}).get("hits", [])
    if not hits: print("no zenodo record for", doi); continue
    h = hits[0]; md = h["metadata"]
    print("=" * 90); print(doi, "|", md.get("title", "")[:90], "|", md.get("license", {}).get("id"), "| zenodo id", h["id"])
    files = h.get("files", [])
    for f in files: print(f"  FILE {f.get('key')} {f.get('size')}")
    small = [f for f in files if f.get("key", "").lower().endswith(".csv") and f.get("size", 0) < 300_000]
    for f in small[:2]:
        ls, n = head(f["links"]["self"])
        print(f"  --- head of {f['key']} ({n} lines):")
        for l in ls: print("    ", l[:200])

print("\n########## SCIENCEBASE")
for item in ["https://www.sciencebase.gov/catalog/item/5e4ac6e7e4b0ff554f6e6a7b"]:
    pass
d = http("https://www.sciencebase.gov/catalog/items", {"q": "loon occupancy", "format": "json", "max": 3, "fields": "title,files,identifiers"})
for it in d.get("items", []):
    print("=" * 90); print(it.get("title")[:100], "|", it.get("link", {}).get("url"))
    for f in (it.get("files") or [])[:12]: print(f"  FILE {f.get('name')} {f.get('size')} {f.get('contentType')}")
d = http("https://www.sciencebase.gov/catalog/items", {"q": "North American Breeding Bird Survey Dataset", "format": "json", "max": 3, "fields": "title,files,identifiers"})
for it in d.get("items", []):
    print("=" * 90); print(it.get("title")[:100], "|", it.get("link", {}).get("url"))
    for f in (it.get("files") or [])[:12]: print(f"  FILE {f.get('name')} {f.get('size')} {f.get('contentType')}")

print("\n########## DATAVERSE")
for pid in ["doi:10.7910/DVN/KS4HIR", "doi:10.18710/ZLW59W", "doi:10.5683/SP4/FH7WY6", "doi:10.5683/SP4/KDEB13"]:
    base = "https://dataverse.harvard.edu" if "10.7910" in pid else ("https://dataverse.no" if "10.18710" in pid else "https://borealisdata.ca")
    d = http(f"{base}/api/datasets/:persistentId/", {"persistentId": pid})
    data = d.get("data", {}); lv = data.get("latestVersion", {})
    lic = lv.get("license", {}); lic = lic.get("name") if isinstance(lic, dict) else lic
    print("=" * 90); print(pid, "|", lic, "| terms:", (lv.get("termsOfUse") or "")[:80])
    for f in lv.get("files", [])[:12]:
        df = f.get("dataFile", {}); print(f"  FILE {df.get('filename')} {df.get('filesize')} {df.get('contentType')}")

print("\n########## GBIF sampling-event examples")
d = http("https://api.gbif.org/v1/dataset/search", {"q": "point count", "type": "SAMPLING_EVENT", "limit": 6})
for r in d.get("results", []):
    print(f"  {r.get('title','')[:90]} | {r.get('doi')} | {r.get('license')} | records {r.get('recordCount')} | pub {r.get('publishingOrganizationTitle','')[:40]}")
d = http("https://api.gbif.org/v1/dataset/search", {"type": "SAMPLING_EVENT", "limit": 0})
print("  TOTAL sampling-event datasets on GBIF:", d.get("count"))
d = http("https://api.gbif.org/v1/dataset/search", {"q": "absence", "type": "SAMPLING_EVENT", "limit": 0})
print("  ... mentioning 'absence':", d.get("count"))

print("\n########## NEON organismal products")
d = http("https://data.neonscience.org/api/v0/products")
for p in d.get("data", []):
    nm = p.get("productName", "")
    if any(k in nm.lower() for k in ("bird", "mammal", "beetle", "mosquito", "fish", "tick", "amphib", "zooplankton", "macroinvert", "plant")):
        print(f"  {p.get('productCode')} | {nm[:70]} | sites {len(p.get('siteCodes', []))}")
