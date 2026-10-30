#!/usr/bin/env python3
"""Light discovery pass: where does ecological detection data live?

Connectors for Dataverse, Zenodo, Dryad, Figshare and OSF are adapted from
ben-domingue/irw src/automated_finding/irw_discover_updated.py (same endpoints,
same pagination and sleep discipline). Ecology-specific connectors (EDI/PASTA,
DataONE, ScienceBase, NEON, GBIF sampling-event datasets) are new.

Every HTTP response is cached in discovery/cache/ so re-runs cost nothing.
Output: hit counts per (source, query) and a sample of records per source,
written to discovery/raw_hits.csv for hand curation into ../discovery_log.csv.
"""
import csv, hashlib, json, os, sys, time, urllib.parse, urllib.request, urllib.error

HERE = os.path.dirname(os.path.abspath(__file__))
CACHE = os.path.join(HERE, "cache"); os.makedirs(CACHE, exist_ok=True)
UA = {"User-Agent": "eco-irw-scout/0.1 (research; ben.domingue@gmail.com)"}

QUERIES = [
    "detection history", "occupancy model", "capture history", "capture-recapture",
    "N-mixture", "repeated counts", "point count", "camera trap",
    "detection/non-detection", "encounter history",
]

def _cache_key(method, url, body):
    return hashlib.sha1(f"{method} {url} {body or ''}".encode()).hexdigest()

def http(url, params=None, json_body=None, method=None, sleep=0.6):
    if params:
        url = url + ("&" if "?" in url else "?") + urllib.parse.urlencode(params, doseq=True)
    body = json.dumps(json_body).encode() if json_body is not None else None
    method = method or ("POST" if body else "GET")
    key = os.path.join(CACHE, _cache_key(method, url, body) + ".json")
    if os.path.exists(key):
        with open(key) as f: return json.load(f)
    req = urllib.request.Request(url, data=body, method=method, headers={**UA, "Accept": "application/json"})
    if body: req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req, timeout=40) as r:
            txt = r.read().decode("utf-8", "replace")
    except urllib.error.HTTPError as e:
        txt = json.dumps({"_error": e.code, "_body": e.read().decode("utf-8", "replace")[:500]})
    except Exception as e:
        txt = json.dumps({"_error": str(e)})
    time.sleep(sleep)
    try: data = json.loads(txt)
    except Exception: data = {"_raw": txt[:2000]}
    with open(key, "w") as f: json.dump(data, f)
    return data

# ---- connectors: each returns (total_count, [records]) with a uniform record dict
def rec(source, title, url, doi="", license="", year="", extra=""):
    return {"source": source, "title": (title or "").strip()[:200], "url": url, "doi": doi,
            "license": license, "year": str(year)[:10], "extra": extra}

def dataverse(q, per=20):
    d = http("https://dataverse.harvard.edu/api/search", {"q": f'"{q}"', "type": "dataset", "per_page": per})
    if "_error" in d: return None, []
    data = d.get("data", {})
    return data.get("total_count", 0), [rec("dataverse", it.get("name"), it.get("url"), it.get("global_id", ""),
                                            "", it.get("published_at", ""), it.get("description", "")[:200] if it.get("description") else "")
                                        for it in data.get("items", [])]

def zenodo(q, per=20):
    d = http("https://zenodo.org/api/records", {"q": f'"{q}"', "size": per, "type": "dataset"})
    if "_error" in d: return None, []
    hits = d.get("hits", {})
    out = []
    for h in hits.get("hits", []):
        md = h.get("metadata", {})
        lic = md.get("license", {}); lic = lic.get("id", "") if isinstance(lic, dict) else str(lic)
        files = ",".join(sorted({f.get("key", "").rsplit(".", 1)[-1].lower() for f in h.get("files", [])}))
        out.append(rec("zenodo", md.get("title"), h.get("links", {}).get("self_html") or f"https://zenodo.org/records/{h.get('id')}",
                       h.get("doi", ""), lic, md.get("publication_date", ""), f"files:{files}"))
    return hits.get("total", 0), out

def dryad(q, per=20):
    d = http("https://datadryad.org/api/v2/search", {"q": q, "per_page": per})
    if "_error" in d: return None, []
    sets = d.get("_embedded", {}).get("stash:datasets", [])
    return d.get("total", 0), [rec("dryad", s.get("title"), f"https://datadryad.org/dataset/{s.get('identifier','')}",
                                   s.get("identifier", ""), s.get("license", ""), s.get("publicationDate", ""),
                                   ";".join(s.get("keywords", [])[:6])) for s in sets]

def figshare(q, per=20):
    d = http("https://api.figshare.com/v2/articles/search", json_body={"search_for": f'"{q}"', "page_size": per, "item_type": 3})
    if isinstance(d, dict) and "_error" in d: return None, []
    if not isinstance(d, list): return None, []
    # figshare search has no total; record page size only
    return len(d), [rec("figshare", a.get("title"), a.get("url_public_html"), a.get("doi", ""), "", a.get("published_date", "")) for a in d]

def osf(q, per=20):
    d = http("https://api.osf.io/v2/nodes/", {"filter[title]": q, "page[size]": per})
    if "_error" in d: return None, []
    total = d.get("links", {}).get("meta", {}).get("total", 0)
    return total, [rec("osf", n["attributes"].get("title"), n.get("links", {}).get("html"), "", "",
                       n["attributes"].get("date_created", "")) for n in d.get("data", [])]

def edi(q, per=20):
    # PASTA's own search endpoint returns 403 for unauthenticated users (checked
    # 2026-10-30), so EDI is queried through DataONE, where it is member node urn:node:EDI.
    d = http("https://cn.dataone.org/cn/v2/query/solr/",
             {"q": f'(title:"{q}" OR abstract:"{q}" OR keywords:"{q}") AND formatType:METADATA AND -obsoletedBy:* AND datasource:"urn:node:EDI"',
              "fl": "id,title,dateUploaded", "rows": per, "wt": "json"})
    if "_error" in d: return None, []
    resp = d.get("response", {})
    out = []
    for x in resp.get("docs", []):
        pid = x.get("id", "")
        out.append(rec("edi", x.get("title"), f"https://portal.edirepository.org/nis/mapbrowse?packageid={pid}",
                       pid if pid.startswith("doi:") else "", "CC0 or CC-BY (EDI policy)", x.get("dateUploaded", "")))
    return resp.get("numFound", 0), out

def dataone(q, per=20):
    d = http("https://cn.dataone.org/cn/v2/query/solr/",
             {"q": f'(title:"{q}" OR abstract:"{q}" OR keywords:"{q}") AND formatType:METADATA AND -obsoletedBy:*',
              "fl": "id,title,datasource,rightsHolder,dateUploaded,formatId", "rows": per, "wt": "json"})
    if "_error" in d: return None, []
    resp = d.get("response", {})
    return resp.get("numFound", 0), [rec("dataone", x.get("title"), f"https://search.dataone.org/view/{urllib.parse.quote(x.get('id',''), safe='')}",
                                         x.get("id", "") if str(x.get("id", "")).startswith("doi:") else "", "",
                                         x.get("dateUploaded", ""), x.get("datasource", "")) for x in resp.get("docs", [])]

def sciencebase(q, per=20):
    d = http("https://www.sciencebase.gov/catalog/items", {"q": q, "format": "json", "max": per,
                                                             "fields": "title,webLinks,dates,identifiers",
                                                             "filter": "browseCategory=Data"})
    if "_error" in d: return None, []
    out = []
    for it in d.get("items", []):
        doi = next((i.get("key") for i in (it.get("identifiers") or []) if "doi" in str(i.get("type", "")).lower()), "")
        out.append(rec("sciencebase", it.get("title"), it.get("link", {}).get("url"), doi, "Public domain (USGS)", ""))
    return d.get("total", 0), out

def gbif_sampling_event(q, per=20):
    d = http("https://api.gbif.org/v1/dataset/search", {"q": q, "type": "SAMPLING_EVENT", "limit": per})
    if "_error" in d: return None, []
    return d.get("count", 0), [rec("gbif_sampling_event", r.get("title"), f"https://www.gbif.org/dataset/{r.get('key')}",
                                   r.get("doi", ""), r.get("license", ""), "", f"records:{r.get('recordCount','')}")
                               for r in d.get("results", [])]

def neon(q=None, per=50):
    d = http("https://data.neonscience.org/api/v0/products")
    if "_error" in d: return None, []
    keep = ("bird", "mammal", "beetle", "mosquito", "fish", "tick", "plant", "herbaceous", "amphib", "zooplankton", "macroinvert")
    out = []
    for p in d.get("data", []):
        name = p.get("productName", "")
        if any(k in name.lower() for k in keep):
            out.append(rec("neon", name, f"https://data.neonscience.org/data-products/{p.get('productCode')}", "",
                           "CC0 (NEON policy)", "", p.get("productCode", "")))
    return len(out), out

SOURCES = {"dataverse": dataverse, "zenodo": zenodo, "dryad": dryad, "figshare": figshare, "osf": osf,
           "edi": edi, "dataone": dataone, "sciencebase": sciencebase, "gbif_sampling_event": gbif_sampling_event}

def main():
    counts, samples = [], []
    for name, fn in SOURCES.items():
        for q in QUERIES:
            total, recs = fn(q)
            counts.append({"source": name, "query": q, "hit_count": "" if total is None else total,
                           "status": "error" if total is None else "ok"})
            for r in recs: samples.append({**r, "query": q})
            print(f"{name:20s} {q:25s} {total}", file=sys.stderr)
    total, recs = neon()
    counts.append({"source": "neon", "query": "(product catalogue, organismal products)", "hit_count": total, "status": "ok"})
    for r in recs: samples.append({**r, "query": "catalogue"})
    with open(os.path.join(HERE, "hit_counts.csv"), "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=["source", "query", "hit_count", "status"]); w.writeheader(); w.writerows(counts)
    with open(os.path.join(HERE, "raw_hits.csv"), "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=["source", "query", "title", "url", "doi", "license", "year", "extra"]); w.writeheader(); w.writerows(samples)

if __name__ == "__main__":
    main()
